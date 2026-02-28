"""Tests for the Django Ninja API endpoints (Phase 1)."""

import json

import pytest
from django.test import Client
from ninja_jwt.tokens import RefreshToken

from listings.models import Listing, ListingStatus
from users.models import User


@pytest.fixture
def api_client():
    return Client()


@pytest.fixture
def auth_headers(test_user):
    """Return Authorization header dict for test_user."""
    refresh = RefreshToken.for_user(test_user)
    return {"HTTP_AUTHORIZATION": f"Bearer {refresh.access_token}"}


@pytest.fixture
def other_user(db):
    """A second user for permission tests."""
    return User.objects.create_user(
        email="other@example.com",
        password="otherpass123",
        first_name="Other",
        last_name="Person",
    )


@pytest.fixture
def other_auth_headers(other_user):
    refresh = RefreshToken.for_user(other_user)
    return {"HTTP_AUTHORIZATION": f"Bearer {refresh.access_token}"}


# =============================================================================
# Auth API tests
# =============================================================================


class TestSignup:
    @pytest.mark.django_db
    def test_signup_success(self, api_client):
        response = api_client.post(
            "/api/auth/signup/",
            data=json.dumps(
                {
                    "email": "new@example.com",
                    "first_name": "New",
                    "last_name": "User",
                    "password1": "strongpass123!",
                    "password2": "strongpass123!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 201
        data = response.json()
        assert "access" in data
        assert "refresh" in data
        assert User.objects.filter(email="new@example.com").exists()

    @pytest.mark.django_db
    def test_signup_duplicate_email(self, api_client, test_user):
        response = api_client.post(
            "/api/auth/signup/",
            data=json.dumps(
                {
                    "email": "test@example.com",
                    "first_name": "Dup",
                    "last_name": "User",
                    "password1": "strongpass123!",
                    "password2": "strongpass123!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400
        assert "already exists" in response.json()["detail"]

    @pytest.mark.django_db
    def test_signup_password_mismatch(self, api_client):
        response = api_client.post(
            "/api/auth/signup/",
            data=json.dumps(
                {
                    "email": "new@example.com",
                    "first_name": "New",
                    "last_name": "User",
                    "password1": "strongpass123!",
                    "password2": "differentpass456!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400
        assert "do not match" in response.json()["detail"]

    @pytest.mark.django_db
    def test_signup_weak_password(self, api_client):
        response = api_client.post(
            "/api/auth/signup/",
            data=json.dumps(
                {
                    "email": "new@example.com",
                    "first_name": "New",
                    "last_name": "User",
                    "password1": "123",
                    "password2": "123",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400


class TestLogin:
    @pytest.mark.django_db
    def test_login_success(self, api_client, test_user):
        response = api_client.post(
            "/api/auth/login/",
            data=json.dumps(
                {
                    "email": "test@example.com",
                    "password": "testpass123",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 200
        data = response.json()
        assert "access" in data
        assert "refresh" in data

    @pytest.mark.django_db
    def test_login_wrong_password(self, api_client, test_user):
        response = api_client.post(
            "/api/auth/login/",
            data=json.dumps(
                {
                    "email": "test@example.com",
                    "password": "wrongpassword",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 401
        assert "Invalid" in response.json()["detail"]

    @pytest.mark.django_db
    def test_login_nonexistent_email(self, api_client):
        response = api_client.post(
            "/api/auth/login/",
            data=json.dumps(
                {
                    "email": "nobody@example.com",
                    "password": "anything",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 401


class TestRefresh:
    @pytest.mark.django_db
    def test_refresh_success(self, api_client, test_user):
        refresh = RefreshToken.for_user(test_user)
        response = api_client.post(
            "/api/auth/refresh/",
            data=json.dumps({"refresh": str(refresh)}),
            content_type="application/json",
        )
        assert response.status_code == 200
        data = response.json()
        assert "access" in data
        assert "refresh" in data

    @pytest.mark.django_db
    def test_refresh_invalid_token(self, api_client):
        response = api_client.post(
            "/api/auth/refresh/",
            data=json.dumps({"refresh": "invalid-token"}),
            content_type="application/json",
        )
        assert response.status_code == 401


class TestMe:
    @pytest.mark.django_db
    def test_me_authenticated(self, api_client, test_user, auth_headers):
        response = api_client.get("/api/auth/me/", **auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["first_name"] == "Test"
        assert data["last_name"] == "User"
        assert data["id"] == str(test_user.id)

    @pytest.mark.django_db
    def test_me_unauthenticated(self, api_client):
        response = api_client.get("/api/auth/me/")
        assert response.status_code == 401


class TestPasswordReset:
    @pytest.mark.django_db
    def test_password_reset_existing_email(self, api_client, test_user):
        response = api_client.post(
            "/api/auth/password-reset/",
            data=json.dumps({"email": "test@example.com"}),
            content_type="application/json",
        )
        assert response.status_code == 200
        assert "reset link" in response.json()["message"]

    @pytest.mark.django_db
    def test_password_reset_nonexistent_email(self, api_client):
        """Should return 200 even for non-existent emails (don't leak info)."""
        response = api_client.post(
            "/api/auth/password-reset/",
            data=json.dumps({"email": "nobody@example.com"}),
            content_type="application/json",
        )
        assert response.status_code == 200


# =============================================================================
# Listings API tests
# =============================================================================


class TestBrowseListings:
    @pytest.mark.django_db
    def test_browse_empty(self, api_client):
        response = api_client.get("/api/listings/")
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0
        assert data["items"] == []

    @pytest.mark.django_db
    def test_browse_returns_active_only(
        self, api_client, active_listing, draft_listing
    ):
        response = api_client.get("/api/listings/")
        data = response.json()
        assert data["count"] == 1
        assert data["items"][0]["id"] == str(active_listing.id)

    @pytest.mark.django_db
    def test_browse_filter_by_city(self, api_client, active_listing):
        # Active listing is in Chicago
        response = api_client.get("/api/listings/?city=Chicago")
        assert response.json()["count"] == 1

        response = api_client.get("/api/listings/?city=Boston")
        assert response.json()["count"] == 0

    @pytest.mark.django_db
    def test_browse_filter_by_price_range(self, api_client, active_listing):
        # Active listing price is 1200
        response = api_client.get("/api/listings/?price_min=1000&price_max=1500")
        assert response.json()["count"] == 1

        response = api_client.get("/api/listings/?price_min=1500")
        assert response.json()["count"] == 0

    @pytest.mark.django_db
    def test_browse_filter_by_room_type(self, api_client, active_listing):
        response = api_client.get("/api/listings/?room_type=private_room")
        assert response.json()["count"] == 1

        response = api_client.get("/api/listings/?room_type=shared_room")
        assert response.json()["count"] == 0

    @pytest.mark.django_db
    def test_browse_pagination(self, api_client, test_user):
        # Create 25 active listings
        for i in range(25):
            Listing.objects.create(
                title=f"Listing {i}",
                city="NYC",
                price=1000,
                rental_type="sublet",
                room_type="private_room",
                vegan_household="fully_vegan",
                lister_relationship="owner",
                furnished="unfurnished",
                user=test_user,
                status=ListingStatus.ACTIVE,
            )

        # Default page size is 20
        response = api_client.get("/api/listings/")
        data = response.json()
        assert data["count"] == 25
        assert len(data["items"]) == 20
        assert data["page"] == 1

        # Page 2
        response = api_client.get("/api/listings/?page=2")
        data = response.json()
        assert len(data["items"]) == 5
        assert data["page"] == 2

    @pytest.mark.django_db
    def test_browse_includes_photos(self, api_client, listing_with_photos):
        response = api_client.get("/api/listings/")
        data = response.json()
        listing = data["items"][0]
        assert len(listing["photos"]) == 2
        assert "url" in listing["photos"][0]
        assert "filename" in listing["photos"][0]


class TestListingDetail:
    @pytest.mark.django_db
    def test_active_listing_public(self, api_client, active_listing):
        response = api_client.get(f"/api/listings/{active_listing.id}/")
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Active Vegan Space"
        assert data["user"]["first_name"] == "Test"

    @pytest.mark.django_db
    def test_draft_listing_forbidden_anonymous(self, api_client, draft_listing):
        response = api_client.get(f"/api/listings/{draft_listing.id}/")
        assert response.status_code == 403

    @pytest.mark.django_db
    def test_draft_listing_visible_to_owner(
        self, api_client, draft_listing, auth_headers
    ):
        response = api_client.get(f"/api/listings/{draft_listing.id}/", **auth_headers)
        assert response.status_code == 200

    @pytest.mark.django_db
    def test_draft_listing_hidden_from_other_user(
        self, api_client, draft_listing, other_auth_headers
    ):
        response = api_client.get(
            f"/api/listings/{draft_listing.id}/", **other_auth_headers
        )
        assert response.status_code == 404

    @pytest.mark.django_db
    def test_nonexistent_listing_404(self, api_client):
        response = api_client.get("/api/listings/00000000-0000-0000-0000-000000000000/")
        assert response.status_code == 404


class TestDashboard:
    @pytest.mark.django_db
    def test_dashboard_requires_auth(self, api_client):
        response = api_client.get("/api/listings/dashboard/")
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_dashboard_groups_by_status(
        self,
        api_client,
        auth_headers,
        draft_listing,
        active_listing,
        payment_submitted_listing,
    ):
        response = api_client.get("/api/listings/dashboard/", **auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert len(data["drafts"]) == 1
        assert len(data["active"]) == 1
        assert len(data["payment_submitted"]) == 1
        assert len(data["expired"]) == 0
        assert len(data["deactivated"]) == 0

    @pytest.mark.django_db
    def test_dashboard_only_own_listings(
        self, api_client, other_auth_headers, active_listing
    ):
        """Other user should not see test_user's listings."""
        response = api_client.get("/api/listings/dashboard/", **other_auth_headers)
        data = response.json()
        assert len(data["active"]) == 0


# =============================================================================
# OpenAPI docs
# =============================================================================


class TestOpenAPIDocs:
    @pytest.mark.django_db
    def test_api_docs_accessible(self, api_client):
        response = api_client.get("/api/docs")
        assert response.status_code == 200

    @pytest.mark.django_db
    def test_openapi_schema(self, api_client):
        response = api_client.get("/api/openapi.json")
        assert response.status_code == 200
        data = response.json()
        assert data["info"]["title"] == "Vedgy API"
        assert "/api/auth/login/" in data["paths"]
        assert "/api/listings/" in data["paths"]
