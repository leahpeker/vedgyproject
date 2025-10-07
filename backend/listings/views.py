"""Django views for VedgyProject"""

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_http_methods
from django_ratelimit.decorators import ratelimit

from .forms import ListingForm, LoginForm, SignupForm
from .models import Listing, ListingPhoto, ListingStatus
from .utils import save_picture


# Public views
def index(request):
    """Homepage"""
    return render(request, "index.html")


def browse_listings(request):
    """Browse active listings"""
    listings = (
        Listing.objects.filter(status=ListingStatus.ACTIVE)
        .select_related("user")
        .prefetch_related("photos")
    )

    # Apply filters
    city = request.GET.get("city")
    if city:
        listings = listings.filter(city=city)

    borough = request.GET.get("borough")
    if borough:
        listings = listings.filter(borough=borough)

    rental_type = request.GET.get("rental_type")
    if rental_type:
        listings = listings.filter(rental_type=rental_type)

    room_type = request.GET.get("room_type")
    if room_type:
        listings = listings.filter(room_type=room_type)

    vegan_household = request.GET.get("vegan_household")
    if vegan_household:
        listings = listings.filter(vegan_household=vegan_household)

    furnished = request.GET.get("furnished")
    if furnished:
        listings = listings.filter(furnished=furnished)

    seeking_roommate = request.GET.get("seeking_roommate")
    if seeking_roommate == "true":
        listings = listings.filter(seeking_roommate=True)

    min_price = request.GET.get("min_price")
    max_price = request.GET.get("max_price")

    # Validate price range
    if min_price and max_price:
        try:
            min_val = int(min_price)
            max_val = int(max_price)
            if min_val > max_val:
                # Swap if min is greater than max
                min_price, max_price = max_price, min_price
        except ValueError:
            # Invalid price values, ignore them
            min_price = None
            max_price = None

    if min_price:
        listings = listings.filter(price__gte=min_price)
    if max_price:
        listings = listings.filter(price__lte=max_price)

    # If HTMX request, return just the partial
    if request.headers.get('HX-Request'):
        return render(request, "_listings_partial.html", {"listings": listings})

    return render(request, "browse.html", {"listings": listings})


def listing_detail(request, listing_id):
    """View individual listing"""
    listing = get_object_or_404(
        Listing.objects.prefetch_related("photos"), id=listing_id
    )

    # Check permissions: only show non-active listings to owner or admin
    if listing.status != ListingStatus.ACTIVE:
        if not request.user.is_authenticated:
            return redirect("login")
        if listing.user_id != request.user.id and not request.user.is_staff:
            # Not the owner and not an admin
            return redirect("browse")

    # Check if user submitted payment
    if request.GET.get("payment") == "submitted":
        if (
            listing.status == ListingStatus.DRAFT
            and request.user.is_authenticated
            and listing.user_id == request.user.id
        ):
            listing.status = ListingStatus.PAYMENT_SUBMITTED
            listing.save()
            messages.success(
                request, "Payment submitted! Your listing is awaiting approval."
            )

    return render(request, "listing_detail.html", {"listing": listing})


# Auth views
@ratelimit(key='ip', rate='5/h', method='POST')
def signup(request):
    """User signup"""
    if request.user.is_authenticated:
        return redirect("index")

    if request.method == "POST":
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, f"Welcome to VedgyProject, {user.first_name}!")
            return redirect(request.GET.get("next", "index"))
    else:
        form = SignupForm()

    return render(request, "signup.html", {"form": form})


@ratelimit(key='ip', rate='10/h', method='POST')
def user_login(request):
    """User login"""
    if request.user.is_authenticated:
        return redirect("index")

    if request.method == "POST":
        form = LoginForm(request, data=request.POST)
        if form.is_valid():
            email = form.cleaned_data.get("username")
            password = form.cleaned_data.get("password")
            user = authenticate(request, username=email, password=password)
            if user is not None:
                login(request, user)
                messages.success(request, f"Welcome back, {user.first_name}!")
                return redirect(request.GET.get("next", "index"))
    else:
        form = LoginForm()

    return render(request, "login.html", {"form": form})


def user_logout(request):
    """User logout"""
    logout(request)
    messages.info(request, "You have been logged out.")
    return redirect("index")


# Password reset views (using Django's built-in functionality)
from django.contrib.auth.views import (
    PasswordResetView,
    PasswordResetDoneView,
    PasswordResetConfirmView,
    PasswordResetCompleteView,
)


class CustomPasswordResetView(PasswordResetView):
    """Custom password reset view with our template"""
    template_name = "password_reset.html"
    email_template_name = "password_reset_email.html"
    html_email_template_name = "password_reset_email.html"
    subject_template_name = "password_reset_subject.txt"
    success_url = "/password-reset/done/"


class CustomPasswordResetDoneView(PasswordResetDoneView):
    """Password reset email sent confirmation"""
    template_name = "password_reset_done.html"


class CustomPasswordResetConfirmView(PasswordResetConfirmView):
    """Password reset form"""
    template_name = "password_reset_confirm.html"
    success_url = "/password-reset/complete/"


class CustomPasswordResetCompleteView(PasswordResetCompleteView):
    """Password reset complete"""
    template_name = "password_reset_complete.html"


# Dashboard
@login_required
def dashboard(request):
    """User dashboard"""
    listings = (
        Listing.objects.filter(user=request.user)
        .prefetch_related("photos")
        .order_by("-created_at")
    )

    active_listings = [l for l in listings if l.status == ListingStatus.ACTIVE]
    draft_listings = [l for l in listings if l.status == ListingStatus.DRAFT]
    payment_submitted_listings = [
        l for l in listings if l.status == ListingStatus.PAYMENT_SUBMITTED
    ]
    deactivated_listings = [
        l for l in listings if l.status == ListingStatus.DEACTIVATED
    ]
    expired_listings = [l for l in listings if l.status == ListingStatus.EXPIRED]

    return render(
        request,
        "dashboard.html",
        {
            "active_listings": active_listings,
            "draft_listings": draft_listings,
            "payment_submitted_listings": payment_submitted_listings,
            "deactivated_listings": deactivated_listings,
            "expired_listings": expired_listings,
        },
    )


# Listing management
@login_required
def create_listing(request):
    """Create new listing"""
    if request.method == "POST":
        form = ListingForm(request.POST, request.FILES)
        if form.is_valid():
            listing = form.save(commit=False)
            listing.user = request.user
            listing.status = ListingStatus.DRAFT
            listing.save()

            # Handle photo uploads
            photos = request.FILES.getlist("photos")
            for photo in photos[:10]:  # Limit to 10 photos
                filename = save_picture(photo)
                if filename:
                    ListingPhoto.objects.create(listing=listing, filename=filename)

            messages.success(request, "Listing created!")
            return redirect("listing_preview", listing_id=listing.id)
    else:
        form = ListingForm()

    return render(request, "create_listing.html", {"form": form})


@login_required
def edit_listing(request, listing_id):
    """Edit existing listing"""
    listing = get_object_or_404(Listing, id=listing_id, user=request.user)

    if request.method == "POST":
        form = ListingForm(request.POST, request.FILES, instance=listing)
        if form.is_valid():
            form.save()

            # Handle photo uploads
            photos = request.FILES.getlist("photos")
            current_photo_count = listing.photos.count()
            remaining_slots = 10 - current_photo_count

            for photo in photos[:remaining_slots]:
                filename = save_picture(photo)
                if filename:
                    ListingPhoto.objects.create(listing=listing, filename=filename)

            messages.success(request, "Listing updated!")
            return redirect("listing_preview", listing_id=listing.id)
    else:
        form = ListingForm(instance=listing)

    return render(request, "edit_listing.html", {"form": form, "listing": listing})


@login_required
def listing_preview(request, listing_id):
    """Preview listing before publishing"""
    listing = get_object_or_404(
        Listing.objects.prefetch_related("photos"), id=listing_id, user=request.user
    )
    return render(request, "preview_listing.html", {"listing": listing})


@login_required
def pay_listing(request, listing_id):
    """Payment page for listing"""
    listing = get_object_or_404(
        Listing.objects.prefetch_related("photos"), id=listing_id, user=request.user
    )
    return render(request, "pay_listing.html", {"listing": listing})


@login_required
@require_http_methods(["POST"])
def delete_listing(request, listing_id):
    """Delete listing"""
    listing = get_object_or_404(Listing, id=listing_id, user=request.user)
    listing.delete()
    messages.success(request, "Listing deleted.")
    return redirect("dashboard")


@login_required
@require_http_methods(["POST"])
def deactivate_listing(request, listing_id):
    """Deactivate listing"""
    listing = get_object_or_404(Listing, id=listing_id, user=request.user)
    listing.status = ListingStatus.DEACTIVATED
    listing.save()
    messages.success(request, "Listing deactivated.")
    return redirect("dashboard")




@require_http_methods(["POST"])
def admin_approve_listing(request, listing_id):
    """Approve listing"""
    if not request.user.is_staff:
        messages.error(request, "You must be an admin to approve listings.")
        return redirect("login")

    listing = get_object_or_404(Listing, id=listing_id)
    listing.activate_listing()
    messages.success(request, f'Listing "{listing.title}" approved!')
    return redirect("listing_detail", listing_id=listing_id)


@require_http_methods(["POST"])
def admin_reject_listing(request, listing_id):
    """Reject listing"""
    if not request.user.is_staff:
        messages.error(request, "You must be an admin to reject listings.")
        return redirect("login")

    listing = get_object_or_404(Listing, id=listing_id)
    listing.status = ListingStatus.DRAFT
    listing.save()
    messages.info(request, f'Listing "{listing.title}" rejected.')
    return redirect("listing_detail", listing_id=listing_id)


# Static pages
def privacy_policy(request):
    """Privacy policy page"""
    return render(request, "privacy.html")


def about(request):
    """About page"""
    return render(request, "about.html")


def contact(request):
    """Contact page"""
    return render(request, "contact.html")
