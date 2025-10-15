"""Django views for VedgyProject"""

import json

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.utils.http import url_has_allowed_host_and_scheme
from django.views.decorators.http import require_http_methods
from django_ratelimit.decorators import ratelimit
from pydantic import ValidationError

from .forms import ListingForm, LoginForm, SignupForm
from .models import Listing, ListingPhoto, ListingStatus, PricePeriod
from .schemas import ListingDraftSchema
from .utils import delete_photo_file, save_picture


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

    rental_types = request.GET.getlist("rental_type")
    if rental_types:
        listings = listings.filter(rental_type__in=rental_types)

    room_types = request.GET.getlist("room_type")
    if room_types:
        listings = listings.filter(room_type__in=room_types)

    vegan_households = request.GET.getlist("vegan_household")
    if vegan_households:
        listings = listings.filter(vegan_household__in=vegan_households)

    furnished_options = request.GET.getlist("furnished")
    if furnished_options:
        listings = listings.filter(furnished__in=furnished_options)

    seeking_roommate = request.GET.get("seeking_roommate")
    if seeking_roommate == "true":
        listings = listings.filter(seeking_roommate=True)
    elif seeking_roommate == "false":
        listings = listings.filter(seeking_roommate=False)

    # Get user's preferred price view for filtering (default: per_month)
    price_view = request.GET.get("price_view", PricePeriod.PER_MONTH)
    min_price = request.GET.get("min_price")
    max_price = request.GET.get("max_price")

    # Filter using converted equivalents based on selected view
    if price_view == PricePeriod.PER_NIGHT:
        if min_price:
            listings = listings.filter(price_per_night__gte=min_price)
        if max_price:
            listings = listings.filter(price_per_night__lte=max_price)
    elif price_view == PricePeriod.PER_WEEK:
        if min_price:
            listings = listings.filter(price_per_week__gte=min_price)
        if max_price:
            listings = listings.filter(price_per_week__lte=max_price)
    else:  # PricePeriod.PER_MONTH (default)
        if min_price:
            listings = listings.filter(price_per_month__gte=min_price)
        if max_price:
            listings = listings.filter(price_per_month__lte=max_price)

    # Prepare context with choices for filters
    context = {
        "listings": listings,
        "price_view": price_view,
        "rental_type_choices": Listing.RENTAL_TYPE_CHOICES,
        "room_type_choices": Listing.ROOM_TYPE_CHOICES,
        "furnished_choices": Listing.FURNISHED_CHOICES,
        "vegan_household_choices": Listing.VEGAN_HOUSEHOLD_CHOICES,
    }

    # If HTMX request, return just the partial
    if request.headers.get("HX-Request"):
        return render(request, "_listings_partial.html", {"listings": listings, "price_view": price_view})

    return render(request, "browse.html", context)


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
@ratelimit(key="ip", rate="5/h", method="POST")
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

            # Validate next parameter to prevent open redirects
            next_url = request.GET.get("next", "index")
            if url_has_allowed_host_and_scheme(
                url=next_url,
                allowed_hosts={request.get_host()},
                require_https=request.is_secure()
            ):
                return redirect(next_url)
            return redirect("index")
    else:
        form = SignupForm()

    return render(request, "signup.html", {"form": form})


@ratelimit(key="ip", rate="10/h", method="POST")
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

                # Validate next parameter to prevent open redirects
                next_url = request.GET.get("next", "index")
                if url_has_allowed_host_and_scheme(
                    url=next_url,
                    allowed_hosts={request.get_host()},
                    require_https=request.is_secure()
                ):
                    return redirect(next_url)
                return redirect("index")
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
    PasswordResetCompleteView,
    PasswordResetConfirmView,
    PasswordResetDoneView,
    PasswordResetView,
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

    return render(
        request,
        "create_listing.html",
        {"form": form, "listing": listing, "edit_mode": True},
    )


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
def delete_photo(request, photo_id):
    """Delete a photo from a listing"""
    photo = get_object_or_404(ListingPhoto, id=photo_id)

    # Check that user owns the listing
    if photo.listing.user != request.user:
        messages.error(request, "You don't have permission to delete this photo.")
        return redirect("dashboard")

    listing_id = photo.listing.id
    filename = photo.filename

    # Delete from database
    photo.delete()

    # Delete from B2 or local storage
    delete_photo_file(filename)

    messages.success(request, "Photo deleted successfully.")
    return redirect("edit_listing", listing_id=listing_id)


@login_required
@require_http_methods(["POST"])
def save_listing_draft(request, listing_id=None):
    """Auto-save listing draft (AJAX endpoint)"""
    # Get or create listing (do this first so 404 is raised before try block)
    if listing_id:
        listing = get_object_or_404(Listing, id=listing_id, user=request.user)
    else:
        listing = Listing(user=request.user, status=ListingStatus.DRAFT)

    try:
        # Prepare data from POST, converting checkbox values
        data = {}
        for key, value in request.POST.items():
            if key == "csrfmiddlewaretoken":
                continue
            # Convert checkbox values from "on" to boolean
            if key in ["seeking_roommate", "include_phone"]:
                data[key] = value == "on"
            else:
                data[key] = value if value else None

        # Validate with Pydantic (allows partial data)
        draft_data = ListingDraftSchema(**data)

        # Update listing with validated data (only non-None values)
        for field, value in draft_data.model_dump(exclude_none=True).items():
            setattr(listing, field, value)

        listing.save()

        return JsonResponse({
            "success": True,
            "listing_id": str(listing.id),
            "message": "Draft saved"
        })
    except ValidationError as e:
        return JsonResponse({
            "success": False,
            "error": "Validation error",
            "details": e.errors()
        }, status=400)
    except Exception as e:
        return JsonResponse({
            "success": False,
            "error": str(e)
        }, status=400)


@login_required
@require_http_methods(["POST"])
def deactivate_listing(request, listing_id):
    """Deactivate listing"""
    listing = get_object_or_404(Listing, id=listing_id, user=request.user)
    listing.status = ListingStatus.DEACTIVATED
    listing.save()
    messages.success(request, "Listing deactivated.")
    return redirect("dashboard")


@login_required
@require_http_methods(["POST"])
def admin_approve_listing(request, listing_id):
    """Approve listing"""
    if not request.user.is_staff:
        messages.error(request, "You must be an admin to approve listings.")
        return redirect("dashboard")

    listing = get_object_or_404(Listing, id=listing_id)
    listing.activate_listing()
    messages.success(request, f'Listing "{listing.title}" approved!')
    return redirect("listing_detail", listing_id=listing_id)


@login_required
@require_http_methods(["POST"])
def admin_reject_listing(request, listing_id):
    """Reject listing"""
    if not request.user.is_staff:
        messages.error(request, "You must be an admin to reject listings.")
        return redirect("dashboard")

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
