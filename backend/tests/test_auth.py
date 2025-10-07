"""Test authentication views"""

import pytest
from django.urls import reverse

from listings.models import User


@pytest.mark.django_db
class TestUserAuth:
    """Test user authentication"""

    def test_signup_new_user(self, client):
        """Test user signup"""
        response = client.post(
            reverse("signup"),
            {
                "first_name": "John",
                "last_name": "Doe",
                "email": "john@example.com",
                "password1": "SecurePass987!",
                "password2": "SecurePass987!",
            },
        )

        # Should redirect after successful signup
        assert response.status_code == 302

        # User should be created in database
        user = User.objects.filter(email="john@example.com").first()
        assert user is not None
        assert user.first_name == "John"
        assert user.last_name == "Doe"
        assert user.check_password("SecurePass987!")

    def test_signup_duplicate_email(self, client, test_user):
        """Test signup with existing email fails"""
        response = client.post(
            reverse("signup"),
            {
                "first_name": "Jane",
                "last_name": "Smith",
                "email": "test@example.com",  # Same as test_user
                "password1": "SecurePass987!",
                "password2": "SecurePass987!",
            },
        )

        # Should show the form again with validation error
        assert response.status_code == 200
        assert b"Email already registered" in response.content

    def test_signup_password_mismatch(self, client):
        """Test signup with mismatched passwords"""
        response = client.post(
            reverse("signup"),
            {
                "first_name": "John",
                "last_name": "Doe",
                "email": "john@example.com",
                "password1": "SecurePass987!",
                "password2": "DifferentPass123!",
            },
        )

        # Should show the form again
        assert response.status_code == 200
        # Should not create user
        user = User.objects.filter(email="john@example.com").first()
        assert user is None

    def test_login_valid_credentials(self, client, test_user):
        """Test login with valid credentials"""
        response = client.post(
            reverse("login"),
            {"username": "test@example.com", "password": "testpass123"},
        )

        # Should redirect after successful login
        assert response.status_code == 302

    def test_login_invalid_email(self, client):
        """Test login with invalid email"""
        response = client.post(
            reverse("login"),
            {"username": "nonexistent@example.com", "password": "password123"},
        )

        # Should show login form again (not redirect)
        assert response.status_code == 200

    def test_login_invalid_password(self, client, test_user):
        """Test login with wrong password"""
        response = client.post(
            reverse("login"),
            {"username": "test@example.com", "password": "wrongpassword"},
        )

        # Should show login form again (not redirect)
        assert response.status_code == 200

    def test_logout(self, client, logged_in_user):
        """Test user logout"""
        response = client.get(reverse("logout"))

        # Should redirect after logout
        assert response.status_code == 302

        # Should no longer be able to access protected routes
        protected_response = client.get(reverse("create_listing"))
        assert protected_response.status_code == 302  # Redirect to login
