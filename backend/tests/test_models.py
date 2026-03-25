"""Test Django models"""

from datetime import date, timedelta

import pytest
from django.core.management import call_command
from django.utils import timezone

from listings.models import Listing, ListingPhoto, ListingStatus
from users.models import User


@pytest.mark.django_db
class TestUser:
    """Test User model"""

    def test_create_user(self):
        """Test user creation"""
        user = User.objects.create_user(
            username="john@example.com",
            email="john@example.com",
            password="password123",
            first_name="John",
            last_name="Doe",
        )

        # Verify database persistence
        saved_user = User.objects.get(email="john@example.com")
        assert saved_user is not None
        assert saved_user.id is not None
        assert saved_user.first_name == "John"
        assert saved_user.last_name == "Doe"
        assert saved_user.email == "john@example.com"
        assert saved_user.check_password("password123")
        assert not saved_user.check_password("wrongpassword")

    def test_user_can_create_listing(self, test_user):
        """Test user can create listings"""
        assert test_user.can_create_listing()

    def test_user_string_representation(self, test_user):
        """Test user __str__ method"""
        assert str(test_user) == "Test User"

    def test_password_hashing(self):
        """Test password is properly hashed"""
        user = User.objects.create_user(
            username="hash@example.com",
            email="hash@example.com",
            password="mypassword",
            first_name="Test",
            last_name="User",
        )

        # Password should be hashed, not stored in plain text
        assert user.password != "mypassword"
        assert len(user.password) > 20  # Django hashes are long

        # But check_password should still work
        assert user.check_password("mypassword")
        assert not user.check_password("wrongpassword")


@pytest.mark.django_db
class TestListing:
    """Test Listing model"""

    def test_create_listing(self, test_user):
        """Test listing creation"""
        listing = Listing.objects.create(
            title="Vegan House",
            description="A nice vegan place",
            city="New York",
            price=1500,
            start_date=date(2024, 2, 1),
            rental_type="sublet",
            room_type="private_room",
            vegan_household="fully_vegan",
            lister_relationship="owner",
            about_lister="Vegan homeowner",
            rental_requirements="Must be vegan",
            pet_policy="No pets",
            furnished="partially_furnished",
            user=test_user,
            status=ListingStatus.DRAFT,
        )

        # Verify
        saved_listing = Listing.objects.get(id=listing.id)
        assert saved_listing.title == "Vegan House"
        assert saved_listing.user == test_user
        assert saved_listing.status == ListingStatus.DRAFT

    def test_listing_string_representation(self, draft_listing):
        """Test listing __str__ method"""
        assert str(draft_listing) == "Test Vegan House (Draft)"

    def test_activate_listing(self, payment_submitted_listing):
        """Test listing activation"""
        payment_submitted_listing.activate_listing()
        payment_submitted_listing.refresh_from_db()

        assert payment_submitted_listing.status == ListingStatus.ACTIVE
        assert payment_submitted_listing.expires_at is not None

    def test_listing_optional_fields(self, test_user):
        """Test listing with neighborhood, size, transportation fields"""
        listing = Listing.objects.create(
            title="Full Fields Listing",
            description="Testing optional fields",
            city="New York",
            borough="Brooklyn",
            neighborhood="Williamsburg",
            size="12x10 feet",
            transportation="Near L train",
            price=1800,
            start_date=date(2024, 3, 1),
            rental_type="sublet",
            room_type="private_room",
            vegan_household="fully_vegan",
            lister_relationship="owner",
            about_lister="Vegan",
            furnished="fully_furnished",
            user=test_user,
        )

        saved = Listing.objects.get(id=listing.id)
        assert saved.neighborhood == "Williamsburg"
        assert saved.size == "12x10 feet"
        assert saved.transportation == "Near L train"

    def test_listing_status_choices(self):
        """Test listing status choices are valid"""
        assert ListingStatus.DRAFT in dict(ListingStatus.CHOICES)
        assert ListingStatus.ACTIVE in dict(ListingStatus.CHOICES)
        assert ListingStatus.PAYMENT_SUBMITTED in dict(ListingStatus.CHOICES)
        assert ListingStatus.EXPIRED in dict(ListingStatus.CHOICES)
        assert ListingStatus.DEACTIVATED in dict(ListingStatus.CHOICES)


@pytest.mark.django_db
class TestExpireListingsCommand:
    """Test the expire_listings management command."""

    def test_expires_past_due_active_listings(self, active_listing):
        """Active listing with expired expires_at gets transitioned to expired."""
        active_listing.expires_at = timezone.now() - timedelta(hours=1)
        active_listing.save()

        call_command("expire_listings")

        active_listing.refresh_from_db()
        assert active_listing.status == ListingStatus.EXPIRED

    def test_does_not_expire_future_listings(self, active_listing):
        """Active listing with future expires_at stays active."""
        active_listing.expires_at = timezone.now() + timedelta(days=10)
        active_listing.save()

        call_command("expire_listings")

        active_listing.refresh_from_db()
        assert active_listing.status == ListingStatus.ACTIVE


@pytest.mark.django_db
class TestListingPhoto:
    """Test ListingPhoto model"""

    def test_create_photo(self, draft_listing):
        """Test photo creation"""
        photo = ListingPhoto.objects.create(listing=draft_listing, filename="test.jpg")

        # Verify
        saved_photo = ListingPhoto.objects.get(id=photo.id)
        assert saved_photo.listing == draft_listing
        assert saved_photo.filename == "test.jpg"

    def test_photo_string_representation(self, listing_with_photos):
        """Test photo __str__ method"""
        photo = listing_with_photos.photos.first()
        assert "Active Vegan Space" in str(photo)
        assert "test1.jpg" in str(photo)

    def test_listing_photos_relationship(self, listing_with_photos):
        """Test listing-photos relationship"""
        assert listing_with_photos.photos.count() == 2
        photo_filenames = [p.filename for p in listing_with_photos.photos.all()]
        assert "test1.jpg" in photo_filenames
        assert "test2.jpg" in photo_filenames
