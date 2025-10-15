"""Pydantic schemas for listings"""

from datetime import date

from pydantic import BaseModel, ConfigDict, Field


class ListingDraftSchema(BaseModel):
    """Schema for draft listing auto-save - all fields optional"""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: str | None = None
    description: str | None = None
    city: str | None = None
    borough: str | None = None
    price: int | None = None
    price_period: str | None = None
    start_date: date | None = None
    end_date: date | None = None
    rental_type: str | None = None
    room_type: str | None = None
    vegan_household: str | None = None
    lister_relationship: str | None = None
    about_lister: str | None = None
    rental_requirements: str | None = None
    pet_policy: str | None = None
    furnished: str | None = None
    phone_number: str | None = None
    seeking_roommate: bool = False
    include_phone: bool = False
