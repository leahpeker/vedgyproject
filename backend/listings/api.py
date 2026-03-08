"""API endpoints for listings."""

from uuid import UUID

from django.shortcuts import get_object_or_404
from ninja import File, Query, Router
from ninja.files import UploadedFile
from ninja_jwt.authentication import JWTAuth
from ninja_jwt.tokens import AccessToken

from .models import Listing, ListingPhoto, ListingStatus
from .schemas import (
    DashboardOut,
    ListingFilters,
    ListingIn,
    ListingOut,
    PaginatedListings,
    PhotoOut,
)
from .utils import delete_photo_file, save_picture

router = Router()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _get_jwt_user(request):
    """Try to extract user from JWT Bearer token. Returns None if not present or invalid."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    try:
        token = AccessToken(auth_header.split(" ", 1)[1])
        from django.contrib.auth import get_user_model

        User = get_user_model()
        return User.objects.get(id=token["user_id"])
    except Exception:
        return None


def _get_owned_listing(request, listing_id: UUID):
    """Return (listing, None) if auth user owns it, or (None, error_tuple)."""
    listing = get_object_or_404(
        Listing.objects.select_related("user").prefetch_related("photos"),
        id=listing_id,
    )
    if listing.user_id != request.auth.id:
        return None, (
            403,
            {"detail": "You do not have permission to modify this listing."},
        )
    return listing, None


# ---------------------------------------------------------------------------
# Public browse
# ---------------------------------------------------------------------------


@router.get("/", response=PaginatedListings)
def browse_listings(request, filters: Query[ListingFilters]):
    """Browse active listings with optional filters."""
    listings = (
        Listing.objects.filter(status=ListingStatus.ACTIVE)
        .select_related("user")
        .prefetch_related("photos")
    )

    if filters.city:
        listings = listings.filter(city=filters.city)
    if filters.borough:
        listings = listings.filter(borough=filters.borough)
    if filters.rental_type:
        listings = listings.filter(rental_type=filters.rental_type)
    if filters.room_type:
        listings = listings.filter(room_type=filters.room_type)
    if filters.vegan_household:
        listings = listings.filter(vegan_household=filters.vegan_household)
    if filters.furnished:
        listings = listings.filter(furnished=filters.furnished)
    if filters.seeking_roommate is not None:
        listings = listings.filter(seeking_roommate=filters.seeking_roommate)
    if filters.price_min is not None:
        listings = listings.filter(price__gte=filters.price_min)
    if filters.price_max is not None:
        listings = listings.filter(price__lte=filters.price_max)

    count = listings.count()
    page_size = min(filters.page_size, 100)
    offset = (filters.page - 1) * page_size
    page_qs = listings[offset : offset + page_size]

    return PaginatedListings(
        items=[ListingOut.from_listing(l) for l in page_qs],
        count=count,
        page=filters.page,
        page_size=page_size,
    )


# ---------------------------------------------------------------------------
# Authenticated: create listing
# ---------------------------------------------------------------------------


@router.post("/", auth=JWTAuth(), response={201: ListingOut})
def create_listing(request, data: ListingIn):
    """Create a new draft listing."""
    listing = Listing.objects.create(
        user=request.auth,
        status=ListingStatus.DRAFT,
        title=data.title or "",
        description=data.description or "",
        city=data.city or "",
        borough=data.borough,
        price=data.price,
        start_date=data.start_date,
        end_date=data.end_date,
        rental_type=data.rental_type or "",
        room_type=data.room_type or "",
        vegan_household=data.vegan_household or "",
        furnished=data.furnished or "",
        lister_relationship=data.lister_relationship or "",
        seeking_roommate=data.seeking_roommate,
        about_lister=data.about_lister or "",
        rental_requirements=data.rental_requirements,
        pet_policy=data.pet_policy,
        phone_number=data.phone_number,
        include_phone=data.include_phone,
    )
    listing.refresh_from_db()
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return 201, ListingOut.from_listing(listing)


# ---------------------------------------------------------------------------
# Dashboard — must be defined before /{listing_id}/ to avoid route conflict
# ---------------------------------------------------------------------------


@router.get("/dashboard/", auth=JWTAuth(), response=DashboardOut)
def dashboard(request):
    """Get current user's listings grouped by status."""
    listings = (
        Listing.objects.filter(user=request.auth)
        .select_related("user")
        .prefetch_related("photos")
        .order_by("-created_at")
    )

    def by_status(status):
        return [ListingOut.from_listing(l) for l in listings if l.status == status]

    return DashboardOut(
        drafts=by_status(ListingStatus.DRAFT),
        payment_submitted=by_status(ListingStatus.PAYMENT_SUBMITTED),
        active=by_status(ListingStatus.ACTIVE),
        expired=by_status(ListingStatus.EXPIRED),
        deactivated=by_status(ListingStatus.DEACTIVATED),
    )


# ---------------------------------------------------------------------------
# Photo delete — must be defined before /{listing_id}/ to avoid conflict
# ---------------------------------------------------------------------------


@router.delete(
    "/photos/{photo_id}/",
    auth=JWTAuth(),
    response={204: None, 403: dict, 404: dict},
)
def delete_photo(request, photo_id: UUID):
    """Delete a listing photo (owner only)."""
    photo = get_object_or_404(
        ListingPhoto.objects.select_related("listing"), id=photo_id
    )
    if photo.listing.user_id != request.auth.id:
        return 403, {"detail": "You do not have permission to delete this photo."}
    delete_photo_file(photo.filename)
    photo.delete()
    return 204, None


# ---------------------------------------------------------------------------
# Per-listing endpoints
# ---------------------------------------------------------------------------


@router.get("/{listing_id}/", response={200: ListingOut, 403: dict, 404: dict})
def listing_detail(request, listing_id: UUID):
    """Get a single listing by ID."""
    listing = get_object_or_404(
        Listing.objects.select_related("user").prefetch_related("photos"),
        id=listing_id,
    )

    # Non-active listings visible only to owner or staff
    if listing.status != ListingStatus.ACTIVE:
        jwt_user = _get_jwt_user(request)
        if jwt_user is None:
            return 403, {"detail": "You must be logged in to view this listing."}
        if listing.user_id != jwt_user.id and not jwt_user.is_staff:
            return 404, {"detail": "Listing not found."}

    return ListingOut.from_listing(listing)


@router.patch(
    "/{listing_id}/",
    auth=JWTAuth(),
    response={200: ListingOut, 403: dict, 404: dict},
)
def update_listing(request, listing_id: UUID, data: ListingIn):
    """Partially update a listing (owner only). All fields optional."""
    listing, err = _get_owned_listing(request, listing_id)
    if err:
        return err

    update_fields = []
    for field, value in data.dict(exclude_unset=True).items():
        setattr(listing, field, value)
        update_fields.append(field)

    if update_fields:
        listing.save(update_fields=update_fields)

    listing.refresh_from_db()
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return ListingOut.from_listing(listing)


@router.delete(
    "/{listing_id}/",
    auth=JWTAuth(),
    response={204: None, 403: dict, 404: dict},
)
def delete_listing(request, listing_id: UUID):
    """Delete a listing and all its photos (owner only)."""
    listing, err = _get_owned_listing(request, listing_id)
    if err:
        return err

    for photo in listing.photos.all():
        delete_photo_file(photo.filename)

    listing.delete()
    return 204, None


@router.post(
    "/{listing_id}/deactivate/",
    auth=JWTAuth(),
    response={200: ListingOut, 403: dict, 404: dict},
)
def deactivate_listing(request, listing_id: UUID):
    """Deactivate an active listing (owner only)."""
    listing, err = _get_owned_listing(request, listing_id)
    if err:
        return err

    listing.status = ListingStatus.DEACTIVATED
    listing.save(update_fields=["status"])
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return ListingOut.from_listing(listing)


@router.post(
    "/{listing_id}/photos/",
    auth=JWTAuth(),
    response={201: PhotoOut, 400: dict, 403: dict, 404: dict},
)
def upload_photo(request, listing_id: UUID, photo: UploadedFile = File(...)):
    """Upload a photo for a listing (owner only, max 10 photos)."""
    listing, err = _get_owned_listing(request, listing_id)
    if err:
        return err

    if listing.photos.count() >= 10:
        return 400, {"detail": "Maximum of 10 photos per listing."}

    filename, url = save_picture(photo)
    if not filename:
        return 400, {
            "detail": "Invalid image file. Accepted: JPG, PNG, GIF, HEIC (max 10MB)."
        }

    listing_photo = ListingPhoto.objects.create(listing=listing, filename=filename)
    # Use the url returned by save_picture — it reflects the actual storage
    # backend used (B2 or local fallback), avoiding a mismatch when B2 is
    # partially configured but credentials are invalid.
    return 201, PhotoOut(id=listing_photo.id, filename=filename, url=url)


# ---------------------------------------------------------------------------
# Staff-only: approve / reject
# ---------------------------------------------------------------------------


@router.post(
    "/{listing_id}/submit/",
    auth=JWTAuth(),
    response={200: ListingOut, 403: dict, 404: dict},
)
def submit_listing(request, listing_id: UUID):
    """Submit a draft listing for payment/review (owner only)."""
    listing, err = _get_owned_listing(request, listing_id)
    if err:
        return err

    listing.status = ListingStatus.PAYMENT_SUBMITTED
    listing.save(update_fields=["status"])
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return ListingOut.from_listing(listing)


@router.post(
    "/{listing_id}/approve/",
    auth=JWTAuth(),
    response={200: ListingOut, 403: dict, 404: dict},
)
def approve_listing(request, listing_id: UUID):
    """Approve a listing (staff only): sets ACTIVE with 30-day expiry."""
    if not request.auth.is_staff:
        return 403, {"detail": "Staff access required."}

    listing = get_object_or_404(
        Listing.objects.select_related("user").prefetch_related("photos"),
        id=listing_id,
    )
    listing.activate_listing()
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return ListingOut.from_listing(listing)


@router.post(
    "/{listing_id}/reject/",
    auth=JWTAuth(),
    response={200: ListingOut, 403: dict, 404: dict},
)
def reject_listing(request, listing_id: UUID):
    """Reject a listing back to DRAFT (staff only)."""
    if not request.auth.is_staff:
        return 403, {"detail": "Staff access required."}

    listing = get_object_or_404(
        Listing.objects.select_related("user").prefetch_related("photos"),
        id=listing_id,
    )
    listing.status = ListingStatus.DRAFT
    listing.save(update_fields=["status"])
    listing = (
        Listing.objects.prefetch_related("photos")
        .select_related("user")
        .get(id=listing.id)
    )
    return ListingOut.from_listing(listing)
