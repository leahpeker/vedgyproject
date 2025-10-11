"""Test Django views"""

import pytest
from django.urls import reverse

from listings.models import ListingStatus, Listing
from users.models import User


@pytest.mark.django_db
class TestPublicViews:
    """Test public-facing views"""

    def test_index_page(self, client):
        """Test homepage loads"""
        response = client.get(reverse("index"))
        assert response.status_code == 200
        assert b"VedgyProject" in response.content

    def test_browse_listings_empty(self, client):
        """Test browse page with no listings"""
        response = client.get(reverse("browse"))
        assert response.status_code == 200

    def test_browse_listings_with_active(self, client, active_listing):
        """Test browse page shows active listings"""
        response = client.get(reverse("browse"))
        assert response.status_code == 200
        assert active_listing.title.encode() in response.content

    def test_browse_listings_hides_draft(self, client, draft_listing):
        """Test browse page hides draft listings"""
        response = client.get(reverse("browse"))
        assert response.status_code == 200
        assert draft_listing.title.encode() not in response.content

    def test_listing_detail(self, client, active_listing):
        """Test individual listing detail page"""
        response = client.get(reverse("listing_detail", args=[active_listing.id]))
        assert response.status_code == 200
        assert active_listing.title.encode() in response.content
        assert active_listing.description.encode() in response.content


@pytest.mark.django_db
class TestAuthViews:
    """Test authentication views"""

    def test_signup_page_loads(self, client):
        """Test signup page loads"""
        response = client.get(reverse("signup"))
        assert response.status_code == 200
        assert b"Create Account" in response.content

    def test_login_page_loads(self, client):
        """Test login page loads"""
        response = client.get(reverse("login"))
        assert response.status_code == 200
        assert b"Sign In" in response.content


@pytest.mark.django_db
class TestListingManagement:
    """Test listing management views"""

    def test_create_listing_requires_login(self, client):
        """Test create listing requires authentication"""
        response = client.get(reverse("create_listing"))
        assert response.status_code == 302  # Redirect to login

    def test_create_listing_page_loads(self, client, logged_in_user):
        """Test create listing page loads for logged in user"""
        response = client.get(reverse("create_listing"))
        assert response.status_code == 200
        assert b"Create New Listing" in response.content

    def test_create_listing_post(self, client, logged_in_user, sample_listing_data):
        """Test creating a listing"""
        response = client.post(reverse("create_listing"), sample_listing_data)

        # Should redirect to preview
        assert response.status_code == 302

        # Listing should be created
        assert logged_in_user.listings.count() == 1
        listing = logged_in_user.listings.first()
        assert listing.title == sample_listing_data["title"]
        assert listing.status == ListingStatus.DRAFT

    def test_edit_listing_own(self, client, logged_in_user, draft_listing):
        """Test editing own listing"""
        response = client.get(reverse("edit_listing", args=[draft_listing.id]))
        assert response.status_code == 200
        assert draft_listing.title.encode() in response.content

    def test_edit_listing_not_owner(self, client, logged_in_user, db):
        """Test cannot edit someone else's listing"""
        # Create another user and their listing
        

        other_user = User.objects.create_user(
            username="other@example.com",
            email="other@example.com",
            password="password",
            first_name="Other",
            last_name="User",
        )
        other_listing = Listing.objects.create(
            title="Other User Listing",
            description="Not yours",
            city="New York",
            price=1000,
            start_date="2024-02-01",
            rental_type="sublet",
            room_type="private_room",
            vegan_household="fully_vegan",
            lister_relationship="owner",
            about_lister="Other",
            rental_requirements="None",
            pet_policy="No pets",
            furnished="unfurnished",
            user=other_user,
            status=ListingStatus.DRAFT,
        )

        response = client.get(reverse("edit_listing", args=[other_listing.id]))
        assert response.status_code == 404  # Not found (can't access)

    def test_delete_listing(self, client, logged_in_user, draft_listing):
        """Test deleting own listing"""
        response = client.post(reverse("delete_listing", args=[draft_listing.id]))

        # Should redirect
        assert response.status_code == 302

        # Listing should be deleted
        assert logged_in_user.listings.count() == 0

    def test_deactivate_listing(self, client, logged_in_user, active_listing):
        """Test deactivating listing"""
        response = client.post(reverse("deactivate_listing", args=[active_listing.id]))

        # Should redirect
        assert response.status_code == 302

        # Listing should be deactivated
        active_listing.refresh_from_db()
        assert active_listing.status == ListingStatus.DEACTIVATED


@pytest.mark.django_db
class TestDashboard:
    """Test user dashboard"""

    def test_dashboard_requires_login(self, client):
        """Test dashboard requires authentication"""
        response = client.get(reverse("dashboard"))
        assert response.status_code == 302  # Redirect to login

    def test_dashboard_shows_own_listings(
        self, client, logged_in_user, draft_listing, active_listing
    ):
        """Test dashboard shows user's listings"""
        response = client.get(reverse("dashboard"))
        assert response.status_code == 200
        assert draft_listing.title.encode() in response.content
        assert active_listing.title.encode() in response.content

    def test_dashboard_empty(self, client, logged_in_user):
        """Test dashboard with no listings"""
        response = client.get(reverse("dashboard"))
        assert response.status_code == 200
        assert b"No listings yet" in response.content


@pytest.mark.django_db
class TestAdminViews:
    """Test admin views"""

    def test_admin_approve_listing(
        self, client, logged_in_admin, payment_submitted_listing
    ):
        """Test admin can approve listing"""
        response = client.post(
            reverse("admin_approve", args=[payment_submitted_listing.id])
        )

        # Should redirect
        assert response.status_code == 302

        # Listing should be active
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.ACTIVE
        assert payment_submitted_listing.expires_at is not None

    def test_admin_reject_listing(
        self, client, logged_in_admin, payment_submitted_listing
    ):
        """Test admin can reject listing"""
        response = client.post(
            reverse("admin_reject", args=[payment_submitted_listing.id])
        )

        # Should redirect
        assert response.status_code == 302

        # Listing should be back to draft
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.DRAFT
