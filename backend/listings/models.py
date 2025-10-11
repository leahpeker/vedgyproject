"""Django models for VedgyProject"""

import uuid
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


class ListingStatus:
    """Listing status choices"""

    DRAFT = "draft"
    PAYMENT_SUBMITTED = "payment_submitted"
    ACTIVE = "active"
    EXPIRED = "expired"
    DEACTIVATED = "deactivated"

    CHOICES = [
        (DRAFT, "Draft"),
        (PAYMENT_SUBMITTED, "Payment Submitted"),
        (ACTIVE, "Active"),
        (EXPIRED, "Expired"),
        (DEACTIVATED, "Deactivated"),
    ]


class Listing(models.Model):
    """Rental listing model"""

    # Choices
    RENTAL_TYPE_CHOICES = [
        ("sublet", "Sublet"),
        ("new_lease", "New Lease"),
        ("month_to_month", "Month to Month"),
        ("short_term", "Short Term")
    ]

    ROOM_TYPE_CHOICES = [
        ("private_room", "Private Room"),
        ("shared_room", "Shared Room"),
        ("entire_place", "Entire Place"),
    ]

    VEGAN_HOUSEHOLD_CHOICES = [
        ("fully_vegan", "Fully Vegan"),
        ("mixed_household", "Mixed Household"),
    ]

    FURNISHED_CHOICES = [
        ("fully_furnished", "Fully Furnished"),
        ("unfurnished", "Unfurnished"),
        ("partially_furnished", "Partially Furnished"),
    ]

    LISTER_RELATIONSHIP_CHOICES = [
        ("owner", "Owner"),
        ("manager", "Manager"),
        ("tenant", "Tenant"),
        ("roommate", "Roommate"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200, blank=True, default="")
    description = models.TextField(blank=True, default="")
    city = models.CharField(max_length=100, blank=True, default="")
    borough = models.CharField(max_length=50, blank=True, null=True)

    # Rental details
    rental_type = models.CharField(max_length=20, choices=RENTAL_TYPE_CHOICES, blank=True, default="")
    room_type = models.CharField(max_length=20, choices=ROOM_TYPE_CHOICES, blank=True, default="")
    price = models.IntegerField(null=True, blank=True)  # Monthly rent

    # Availability
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(blank=True, null=True)
    furnished = models.CharField(max_length=30, choices=FURNISHED_CHOICES, blank=True, default="")

    # Household info
    vegan_household = models.CharField(max_length=30, choices=VEGAN_HOUSEHOLD_CHOICES, blank=True, default="")
    about_lister = models.TextField(blank=True, default="")
    lister_relationship = models.CharField(max_length=30, choices=LISTER_RELATIONSHIP_CHOICES, blank=True, default="")
    seeking_roommate = models.BooleanField(default=False)
    rental_requirements = models.TextField(blank=True, null=True)
    pet_policy = models.CharField(max_length=200, blank=True, null=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    include_phone = models.BooleanField(default=False)

    # Status and expiration
    status = models.CharField(
        max_length=20, choices=ListingStatus.CHOICES, default=ListingStatus.DRAFT
    )
    expires_at = models.DateTimeField(blank=True, null=True)

    # Relationships
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listings")
    created_at = models.DateTimeField(auto_now_add=True)

    def activate_listing(self):
        """Activate listing after payment"""
        self.status = ListingStatus.ACTIVE
        self.expires_at = timezone.now() + timedelta(days=30)
        self.save()

    def __str__(self):
        status_display = dict(ListingStatus.CHOICES).get(self.status, self.status)
        return f"{self.title} ({status_display})"

    class Meta:
        ordering = ["-created_at"]


class ListingPhoto(models.Model):
    """Photos for listings"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    filename = models.CharField(max_length=255)
    listing = models.ForeignKey(
        Listing, on_delete=models.CASCADE, related_name="photos"
    )
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.filename} for {self.listing.title}"

    class Meta:
        ordering = ["uploaded_at"]
