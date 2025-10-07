"""Test configuration and fixtures for Django"""

from datetime import date

import pytest
from django.test import Client

from listings.models import Listing, ListingPhoto, ListingStatus, User


@pytest.fixture
def client():
    """Django test client"""
    return Client()


@pytest.fixture
def test_user(db):
    """Create a test user"""
    user = User.objects.create_user(
        username="test@example.com",
        email="test@example.com",
        password="testpass123",
        first_name="Test",
        last_name="User",
    )
    return user


@pytest.fixture
def test_admin(db):
    """Create a test admin (staff user)"""
    admin = User.objects.create_user(
        username="admin@example.com",
        email="admin@example.com",
        password="adminpass123",
        first_name="Admin",
        last_name="User",
        is_staff=True,
        is_superuser=True,
    )
    return admin


@pytest.fixture
def logged_in_user(client, test_user):
    """User that's already logged in"""
    client.login(username="test@example.com", password="testpass123")
    return test_user


@pytest.fixture
def logged_in_admin(client, test_admin):
    """Admin that's already logged in"""
    client.login(username="admin@example.com", password="adminpass123")
    return test_admin


@pytest.fixture
def draft_listing(test_user):
    """Create a draft listing"""
    listing = Listing.objects.create(
        title="Test Vegan House",
        description="A lovely vegan household",
        city="New York",
        price=1500,
        date_available=date(2024, 2, 1),
        rental_type="sublet",
        room_type="private_room",
        vegan_household="fully_vegan",
        lister_relationship="owner",
        about_lister="I am a vegan homeowner",
        rental_requirements="Must be vegan",
        pet_policy="No pets allowed",
        furnished="partially_furnished",
        phone_number="(555) 123-4567",
        include_phone=True,
        user=test_user,
        status=ListingStatus.DRAFT,
    )
    return listing


@pytest.fixture
def payment_submitted_listing(test_user):
    """Create a listing waiting for admin approval"""
    listing = Listing.objects.create(
        title="Pending Approval House",
        description="Waiting for admin approval",
        city="Los Angeles",
        price=2000,
        date_available=date(2024, 3, 1),
        rental_type="new_lease",
        room_type="shared_room",
        vegan_household="mixed_household",
        lister_relationship="tenant",
        about_lister="Current tenant looking for roommate",
        rental_requirements="Vegan-friendly",
        pet_policy="Cats allowed",
        furnished="fully_furnished",
        phone_number="(555) 987-6543",
        include_phone=False,
        user=test_user,
        status=ListingStatus.PAYMENT_SUBMITTED,
    )
    return listing


@pytest.fixture
def active_listing(test_user):
    """Create an active/published listing"""
    listing = Listing.objects.create(
        title="Active Vegan Space",
        description="Currently available",
        city="Chicago",
        price=1200,
        date_available=date(2024, 1, 15),
        rental_type="sublet",
        room_type="private_room",
        vegan_household="fully_vegan",
        lister_relationship="owner",
        about_lister="Vegan landlord",
        rental_requirements="Vegan only",
        pet_policy="No pets",
        furnished="unfurnished",
        phone_number="(555) 111-2222",
        include_phone=True,
        user=test_user,
        status=ListingStatus.ACTIVE,
    )
    return listing


@pytest.fixture
def listing_with_photos(active_listing):
    """Create a listing with photos"""
    photo1 = ListingPhoto.objects.create(filename="test1.jpg", listing=active_listing)
    photo2 = ListingPhoto.objects.create(filename="test2.jpg", listing=active_listing)
    return active_listing


@pytest.fixture
def sample_listing_data():
    """Sample data for creating listings"""
    return {
        "title": "Sample Listing",
        "description": "A great vegan space",
        "city": "New York",
        "price": 1500,
        "date_available": "2024-02-01",
        "rental_type": "sublet",
        "room_type": "private_room",
        "vegan_household": "fully_vegan",
        "lister_relationship": "owner",
        "about_lister": "Vegan homeowner",
        "rental_requirements": "Must be vegan",
        "pet_policy": "No pets",
        "furnished": "partially_furnished",
    }
