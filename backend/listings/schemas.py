"""Pydantic schemas for listings"""

from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ListingDraftSchema(BaseModel):
    """Schema for draft listing auto-save - all fields optional"""

    model_config = ConfigDict(str_strip_whitespace=True)

    title: Optional[str] = None
    description: Optional[str] = None
    city: Optional[str] = None
    borough: Optional[str] = None
    price: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    rental_type: Optional[str] = None
    room_type: Optional[str] = None
    vegan_household: Optional[str] = None
    lister_relationship: Optional[str] = None
    about_lister: Optional[str] = None
    rental_requirements: Optional[str] = None
    pet_policy: Optional[str] = None
    furnished: Optional[str] = None
    phone_number: Optional[str] = None
    seeking_roommate: bool = False
    include_phone: bool = False
