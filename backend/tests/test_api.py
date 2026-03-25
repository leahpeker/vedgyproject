"""Tests for the Django Ninja API endpoints (Phase 1 + Phase 4)."""

import io
import json
from unittest.mock import patch

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client
from ninja_jwt.tokens import RefreshToken
from PIL import Image

from listings.models import Listing, ListingPhoto, ListingStatus
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


@pytest.fixture
def staff_user(db):
    """A staff user for admin-only endpoint tests."""
    return User.objects.create_user(
        email="staff@example.com",
        password="staffpass123",
        first_name="Staff",
        last_name="User",
        is_staff=True,
    )


@pytest.fixture
def staff_auth_headers(staff_user):
    refresh = RefreshToken.for_user(staff_user)
    return {"HTTP_AUTHORIZATION": f"Bearer {refresh.access_token}"}


def _make_test_image(fmt="JPEG", size=(20, 20)):
    """Return a SimpleUploadedFile containing a minimal valid image."""
    buf = io.BytesIO()
    Image.new("RGB", size, color=(100, 150, 200)).save(buf, format=fmt)
    buf.seek(0)
    ext = "jpg" if fmt == "JPEG" else fmt.lower()
    return SimpleUploadedFile(f"test.{ext}", buf.read(), content_type=f"image/{ext}")


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


class TestPasswordResetConfirm:
    @staticmethod
    def _get_uid_and_token(user):
        """Generate a valid uidb64 and token for the given user."""
        from django.contrib.auth.tokens import default_token_generator
        from django.utils.http import urlsafe_base64_encode

        uid = urlsafe_base64_encode(str(user.pk).encode())
        token = default_token_generator.make_token(user)
        return uid, token

    @pytest.mark.django_db
    def test_valid_reset(self, api_client, test_user):
        uid, token = self._get_uid_and_token(test_user)
        response = api_client.post(
            "/api/auth/password-reset-confirm/",
            data=json.dumps(
                {
                    "uidb64": uid,
                    "token": token,
                    "new_password1": "newstrongpass123!",
                    "new_password2": "newstrongpass123!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 200
        assert "reset" in response.json()["message"].lower()
        # Verify the password actually changed
        test_user.refresh_from_db()
        assert test_user.check_password("newstrongpass123!")

    @pytest.mark.django_db
    def test_invalid_token(self, api_client, test_user):
        uid, _ = self._get_uid_and_token(test_user)
        response = api_client.post(
            "/api/auth/password-reset-confirm/",
            data=json.dumps(
                {
                    "uidb64": uid,
                    "token": "bad-token",
                    "new_password1": "newstrongpass123!",
                    "new_password2": "newstrongpass123!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400
        assert "invalid" in response.json()["detail"].lower()

    @pytest.mark.django_db
    def test_password_mismatch(self, api_client, test_user):
        uid, token = self._get_uid_and_token(test_user)
        response = api_client.post(
            "/api/auth/password-reset-confirm/",
            data=json.dumps(
                {
                    "uidb64": uid,
                    "token": token,
                    "new_password1": "newstrongpass123!",
                    "new_password2": "differentpass456!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400
        assert "do not match" in response.json()["detail"]

    @pytest.mark.django_db
    def test_weak_password(self, api_client, test_user):
        uid, token = self._get_uid_and_token(test_user)
        response = api_client.post(
            "/api/auth/password-reset-confirm/",
            data=json.dumps(
                {
                    "uidb64": uid,
                    "token": token,
                    "new_password1": "123",
                    "new_password2": "123",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400

    @pytest.mark.django_db
    def test_invalid_uid(self, api_client):
        response = api_client.post(
            "/api/auth/password-reset-confirm/",
            data=json.dumps(
                {
                    "uidb64": "bad-uid",
                    "token": "any-token",
                    "new_password1": "newstrongpass123!",
                    "new_password2": "newstrongpass123!",
                }
            ),
            content_type="application/json",
        )
        assert response.status_code == 400


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


# =============================================================================
# Listing CRUD API tests (Phase 4)
# =============================================================================


class TestCreateListing:
    @pytest.mark.django_db
    def test_create_requires_auth(self, api_client):
        response = api_client.post(
            "/api/listings/",
            data=json.dumps({"title": "My Listing", "city": "Chicago"}),
            content_type="application/json",
        )
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_create_draft(self, api_client, auth_headers, test_user):
        response = api_client.post(
            "/api/listings/",
            data=json.dumps({"title": "My New Listing", "city": "Chicago"}),
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "My New Listing"
        assert data["city"] == "Chicago"
        assert data["status"] == "draft"
        assert (
            Listing.objects.filter(user=test_user, status=ListingStatus.DRAFT).count()
            == 1
        )

    @pytest.mark.django_db
    def test_create_empty_draft(self, api_client, auth_headers, test_user):
        """All fields are optional — can create a completely empty draft."""
        response = api_client.post(
            "/api/listings/",
            data=json.dumps({}),
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 201
        assert response.json()["title"] == ""
        assert response.json()["status"] == "draft"

    @pytest.mark.django_db
    def test_create_sets_owner(self, api_client, auth_headers, test_user):
        response = api_client.post(
            "/api/listings/",
            data=json.dumps({"title": "Owner Check"}),
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 201
        listing_id = response.json()["id"]
        listing = Listing.objects.get(id=listing_id)
        assert listing.user_id == test_user.id


class TestUpdateListing:
    @pytest.mark.django_db
    def test_update_own_listing(self, api_client, auth_headers, draft_listing):
        response = api_client.patch(
            f"/api/listings/{draft_listing.id}/",
            data=json.dumps({"title": "Updated Title", "city": "Boston"}),
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["city"] == "Boston"
        # Unchanged field is preserved
        assert data["price"] == 1500

    @pytest.mark.django_db
    def test_update_requires_auth(self, api_client, draft_listing):
        response = api_client.patch(
            f"/api/listings/{draft_listing.id}/",
            data=json.dumps({"title": "Hacked"}),
            content_type="application/json",
        )
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_update_other_user_forbidden(
        self, api_client, other_auth_headers, draft_listing
    ):
        response = api_client.patch(
            f"/api/listings/{draft_listing.id}/",
            data=json.dumps({"title": "Stolen"}),
            content_type="application/json",
            **other_auth_headers,
        )
        assert response.status_code == 403
        # Title is unchanged
        draft_listing.refresh_from_db()
        assert draft_listing.title == "Test Vegan House"

    @pytest.mark.django_db
    def test_update_partial_fields_only(self, api_client, auth_headers, draft_listing):
        """Only the supplied fields are changed; others stay the same."""
        response = api_client.patch(
            f"/api/listings/{draft_listing.id}/",
            data=json.dumps({"price": 2000}),
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["price"] == 2000
        assert data["title"] == "Test Vegan House"


class TestDeleteListing:
    @pytest.mark.django_db
    def test_delete_own_listing(self, api_client, auth_headers, draft_listing):
        listing_id = draft_listing.id
        with patch("listings.api.delete_photo_file"):
            response = api_client.delete(f"/api/listings/{listing_id}/", **auth_headers)
        assert response.status_code == 204
        assert not Listing.objects.filter(id=listing_id).exists()

    @pytest.mark.django_db
    def test_delete_requires_auth(self, api_client, draft_listing):
        response = api_client.delete(f"/api/listings/{draft_listing.id}/")
        assert response.status_code == 401
        assert Listing.objects.filter(id=draft_listing.id).exists()

    @pytest.mark.django_db
    def test_delete_other_user_forbidden(
        self, api_client, other_auth_headers, draft_listing
    ):
        response = api_client.delete(
            f"/api/listings/{draft_listing.id}/", **other_auth_headers
        )
        assert response.status_code == 403
        assert Listing.objects.filter(id=draft_listing.id).exists()

    @pytest.mark.django_db
    def test_delete_cleans_up_photos(
        self, api_client, auth_headers, listing_with_photos
    ):
        listing_id = listing_with_photos.id
        photo_count = listing_with_photos.photos.count()
        assert photo_count == 2

        with patch("listings.api.delete_photo_file") as mock_delete:
            response = api_client.delete(f"/api/listings/{listing_id}/", **auth_headers)
        assert response.status_code == 204
        assert mock_delete.call_count == 2
        assert not ListingPhoto.objects.filter(listing_id=listing_id).exists()


class TestPhotoUpload:
    @pytest.mark.django_db
    def test_upload_photo(self, api_client, auth_headers, draft_listing):
        with patch("listings.api.save_picture", return_value="saved_abc123.jpg"):
            response = api_client.post(
                f"/api/listings/{draft_listing.id}/photos/",
                data={"photo": _make_test_image()},
                **auth_headers,
            )
        assert response.status_code == 201
        data = response.json()
        assert data["filename"] == "saved_abc123.jpg"
        assert "url" in data
        assert ListingPhoto.objects.filter(listing=draft_listing).count() == 1

    @pytest.mark.django_db
    def test_upload_requires_auth(self, api_client, draft_listing):
        response = api_client.post(
            f"/api/listings/{draft_listing.id}/photos/",
            data={"photo": _make_test_image()},
        )
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_upload_other_user_forbidden(
        self, api_client, other_auth_headers, draft_listing
    ):
        response = api_client.post(
            f"/api/listings/{draft_listing.id}/photos/",
            data={"photo": _make_test_image()},
            **other_auth_headers,
        )
        assert response.status_code == 403

    @pytest.mark.django_db
    def test_upload_invalid_file_returns_400(
        self, api_client, auth_headers, draft_listing
    ):
        with patch("listings.api.save_picture", return_value=None):
            bad_file = SimpleUploadedFile(
                "not_an_image.txt", b"not an image", content_type="text/plain"
            )
            response = api_client.post(
                f"/api/listings/{draft_listing.id}/photos/",
                data={"photo": bad_file},
                **auth_headers,
            )
        assert response.status_code == 400
        assert "Invalid image" in response.json()["detail"]

    @pytest.mark.django_db
    def test_upload_exceeds_10_photos(self, api_client, auth_headers, draft_listing):
        """11th photo upload is rejected with 400."""
        for i in range(10):
            ListingPhoto.objects.create(listing=draft_listing, filename=f"photo{i}.jpg")

        with patch("listings.api.save_picture", return_value="would_be_11th.jpg"):
            response = api_client.post(
                f"/api/listings/{draft_listing.id}/photos/",
                data={"photo": _make_test_image()},
                **auth_headers,
            )
        assert response.status_code == 400
        assert "Maximum of 10 photos" in response.json()["detail"]
        assert ListingPhoto.objects.filter(listing=draft_listing).count() == 10


class TestPhotoDelete:
    @pytest.mark.django_db
    def test_delete_own_photo(self, api_client, auth_headers, listing_with_photos):
        photo = listing_with_photos.photos.first()
        with patch("listings.api.delete_photo_file"):
            response = api_client.delete(
                f"/api/listings/photos/{photo.id}/", **auth_headers
            )
        assert response.status_code == 204
        assert not ListingPhoto.objects.filter(id=photo.id).exists()

    @pytest.mark.django_db
    def test_delete_photo_requires_auth(self, api_client, listing_with_photos):
        photo = listing_with_photos.photos.first()
        response = api_client.delete(f"/api/listings/photos/{photo.id}/")
        assert response.status_code == 401
        assert ListingPhoto.objects.filter(id=photo.id).exists()

    @pytest.mark.django_db
    def test_delete_photo_other_user_forbidden(
        self, api_client, other_auth_headers, listing_with_photos
    ):
        photo = listing_with_photos.photos.first()
        response = api_client.delete(
            f"/api/listings/photos/{photo.id}/", **other_auth_headers
        )
        assert response.status_code == 403
        assert ListingPhoto.objects.filter(id=photo.id).exists()

    @pytest.mark.django_db
    def test_delete_nonexistent_photo_404(self, api_client, auth_headers):
        response = api_client.delete(
            "/api/listings/photos/00000000-0000-0000-0000-000000000000/",
            **auth_headers,
        )
        assert response.status_code == 404


class TestDeactivateListing:
    @pytest.mark.django_db
    def test_deactivate_own_listing(self, api_client, auth_headers, active_listing):
        response = api_client.post(
            f"/api/listings/{active_listing.id}/deactivate/",
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "deactivated"
        active_listing.refresh_from_db()
        assert active_listing.status == ListingStatus.DEACTIVATED

    @pytest.mark.django_db
    def test_deactivate_requires_auth(self, api_client, active_listing):
        response = api_client.post(
            f"/api/listings/{active_listing.id}/deactivate/",
            content_type="application/json",
        )
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_deactivate_other_user_forbidden(
        self, api_client, other_auth_headers, active_listing
    ):
        response = api_client.post(
            f"/api/listings/{active_listing.id}/deactivate/",
            content_type="application/json",
            **other_auth_headers,
        )
        assert response.status_code == 403
        active_listing.refresh_from_db()
        assert active_listing.status == ListingStatus.ACTIVE


class TestSubmitListing:
    @pytest.mark.django_db
    def test_submit_own_listing(self, api_client, auth_headers, draft_listing):
        response = api_client.post(
            f"/api/listings/{draft_listing.id}/submit/",
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "payment_submitted"
        draft_listing.refresh_from_db()
        assert draft_listing.status == ListingStatus.PAYMENT_SUBMITTED

    @pytest.mark.django_db
    def test_submit_requires_auth(self, api_client, draft_listing):
        response = api_client.post(
            f"/api/listings/{draft_listing.id}/submit/",
            content_type="application/json",
        )
        assert response.status_code == 401

    @pytest.mark.django_db
    def test_submit_other_user_forbidden(
        self, api_client, other_auth_headers, draft_listing
    ):
        response = api_client.post(
            f"/api/listings/{draft_listing.id}/submit/",
            content_type="application/json",
            **other_auth_headers,
        )
        assert response.status_code == 403
        draft_listing.refresh_from_db()
        assert draft_listing.status == ListingStatus.DRAFT


class TestApproveListing:
    @pytest.mark.django_db
    def test_approve_as_staff(
        self, api_client, staff_auth_headers, payment_submitted_listing
    ):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/approve/",
            content_type="application/json",
            **staff_auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "active"
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.ACTIVE
        assert payment_submitted_listing.expires_at is not None

    @pytest.mark.django_db
    def test_approve_as_regular_user_forbidden(
        self, api_client, auth_headers, payment_submitted_listing
    ):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/approve/",
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 403
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.PAYMENT_SUBMITTED

    @pytest.mark.django_db
    def test_approve_requires_auth(self, api_client, payment_submitted_listing):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/approve/",
            content_type="application/json",
        )
        assert response.status_code == 401


class TestRejectListing:
    @pytest.mark.django_db
    def test_reject_as_staff(
        self, api_client, staff_auth_headers, payment_submitted_listing
    ):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/reject/",
            content_type="application/json",
            **staff_auth_headers,
        )
        assert response.status_code == 200
        assert response.json()["status"] == "draft"
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.DRAFT

    @pytest.mark.django_db
    def test_reject_as_regular_user_forbidden(
        self, api_client, auth_headers, payment_submitted_listing
    ):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/reject/",
            content_type="application/json",
            **auth_headers,
        )
        assert response.status_code == 403
        payment_submitted_listing.refresh_from_db()
        assert payment_submitted_listing.status == ListingStatus.PAYMENT_SUBMITTED

    @pytest.mark.django_db
    def test_reject_requires_auth(self, api_client, payment_submitted_listing):
        response = api_client.post(
            f"/api/listings/{payment_submitted_listing.id}/reject/",
            content_type="application/json",
        )
        assert response.status_code == 401
