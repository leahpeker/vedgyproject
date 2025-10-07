"""Django models for VedgyProject"""

import uuid
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
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


class User(AbstractUser):
    """Custom user model"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # Django requires username field, we'll use email
    username = models.CharField(max_length=150, unique=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username", "first_name", "last_name"]

    def can_create_listing(self):
        """Users can always create listings"""
        return True

    def __str__(self):
        return f"{self.first_name} {self.last_name}"


class Listing(models.Model):
    """Rental listing model"""

    # Choices
    RENTAL_TYPE_CHOICES = [
        ("sublet", "Sublet"),
        ("new_lease", "New Lease"),
        ("month_to_month", "Month to Month"),
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

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField()
    city = models.CharField(max_length=100)
    borough = models.CharField(max_length=50, blank=True, null=True)

    # Rental details
    rental_type = models.CharField(max_length=20, choices=RENTAL_TYPE_CHOICES)
    room_type = models.CharField(max_length=20, choices=ROOM_TYPE_CHOICES)
    price = models.IntegerField()  # Monthly rent

    # Availability
    date_available = models.DateField()
    furnished = models.CharField(max_length=30, choices=FURNISHED_CHOICES)

    # Household info
    vegan_household = models.CharField(max_length=30, choices=VEGAN_HOUSEHOLD_CHOICES)
    about_lister = models.TextField()
    lister_relationship = models.CharField(max_length=30)  # owner, manager, tenant
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
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="listings")
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
