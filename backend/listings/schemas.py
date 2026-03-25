"""Pydantic schemas for listings"""

from datetime import date, datetime
from uuid import UUID

from ninja import Schema

from .utils import get_photo_url


class UserOut(Schema):
    id: UUID
    first_name: str
    last_name: str


class PhotoOut(Schema):
    id: UUID
    filename: str
    url: str

    @staticmethod
    def from_photo(photo):
        return PhotoOut(
            id=photo.id,
            filename=photo.filename,
            url=get_photo_url(photo.filename),
        )


class ListingOut(Schema):
    id: UUID
    title: str
    description: str
    city: str
    borough: str | None = None
    neighborhood: str | None = None
    price: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    rental_type: str
    room_type: str
    vegan_household: str
    furnished: str
    size: str | None = None
    transportation: str | None = None
    lister_relationship: str
    seeking_roommate: bool
    about_lister: str | None = None
    rental_requirements: str | None = None
    pet_policy: str | None = None
    phone_number: str | None = None
    include_phone: bool
    status: str
    user: UserOut
    photos: list[PhotoOut] = []
    created_at: datetime
    expires_at: datetime | None = None

    @staticmethod
    def from_listing(listing):
        return ListingOut(
            id=listing.id,
            title=listing.title,
            description=listing.description,
            city=listing.city,
            borough=listing.borough,
            neighborhood=listing.neighborhood,
            price=listing.price,
            start_date=listing.start_date,
            end_date=listing.end_date,
            rental_type=listing.rental_type,
            room_type=listing.room_type,
            vegan_household=listing.vegan_household,
            furnished=listing.furnished,
            size=listing.size,
            transportation=listing.transportation,
            lister_relationship=listing.lister_relationship,
            seeking_roommate=listing.seeking_roommate,
            about_lister=listing.about_lister or None,
            rental_requirements=listing.rental_requirements,
            pet_policy=listing.pet_policy,
            phone_number=listing.phone_number,
            include_phone=listing.include_phone,
            status=listing.status,
            user=UserOut(
                id=listing.user.id,
                first_name=listing.user.first_name,
                last_name=listing.user.last_name,
            ),
            photos=[PhotoOut.from_photo(p) for p in listing.photos.all()],
            created_at=listing.created_at,
            expires_at=listing.expires_at,
        )


class ListingIn(Schema):
    title: str | None = None
    description: str | None = None
    city: str | None = None
    borough: str | None = None
    neighborhood: str | None = None
    price: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    rental_type: str | None = None
    room_type: str | None = None
    vegan_household: str | None = None
    furnished: str | None = None
    size: str | None = None
    transportation: str | None = None
    lister_relationship: str | None = None
    seeking_roommate: bool = False
    about_lister: str | None = None
    rental_requirements: str | None = None
    pet_policy: str | None = None
    phone_number: str | None = None
    include_phone: bool = False


class ListingFilters(Schema):
    city: str | None = None
    borough: str | None = None
    rental_type: str | None = None
    room_type: str | None = None
    vegan_household: str | None = None
    furnished: str | None = None
    seeking_roommate: bool | None = None
    price_min: int | None = None
    price_max: int | None = None
    page: int = 1
    page_size: int = 20


class PaginatedListings(Schema):
    items: list[ListingOut]
    count: int
    page: int
    page_size: int


class DashboardOut(Schema):
    drafts: list[ListingOut]
    payment_submitted: list[ListingOut]
    active: list[ListingOut]
    expired: list[ListingOut]
    deactivated: list[ListingOut]
