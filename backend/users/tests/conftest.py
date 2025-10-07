"""Test configuration and fixtures for users app"""

import pytest
from django.test import Client

from users.models import User


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
