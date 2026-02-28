"""API endpoints for listings."""

from uuid import UUID

from django.shortcuts import get_object_or_404
from ninja import Query, Router
from ninja_jwt.authentication import JWTAuth
from ninja_jwt.tokens import AccessToken

from .models import Listing, ListingStatus
from .schemas import DashboardOut, ListingFilters, ListingOut, PaginatedListings

router = Router()


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


# Dashboard must be defined before /{listing_id}/ to avoid route conflicts
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
