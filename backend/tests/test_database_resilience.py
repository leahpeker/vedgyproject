"""Tests for database resilience features"""

import time
from unittest.mock import Mock, patch

import pytest
from django.conf import settings
from django.db import connection
from django.db.utils import OperationalError
from django.test import Client, RequestFactory

from config.middleware import DatabaseHealthCheckMiddleware


@pytest.mark.django_db
class TestDatabaseHealthCheckMiddleware:
    """Test database health check middleware"""

    def test_middleware_allows_request_when_database_is_healthy(self):
        """Test that requests pass through when database is working"""
        factory = RequestFactory()
        request = factory.get("/")

        get_response = Mock(return_value="Response")
        middleware = DatabaseHealthCheckMiddleware(get_response)

        response = middleware(request)

        assert response == "Response"
        get_response.assert_called_once_with(request)

    @patch('config.middleware.connection.ensure_connection')
    def test_middleware_retries_on_database_failure(self, mock_ensure_connection):
        """Test that middleware retries connection on failure"""
        # Simulate database failure then success
        mock_ensure_connection.side_effect = [
            OperationalError("Connection failed"),
            None,  # Success on second try
        ]

        factory = RequestFactory()
        request = factory.get("/")
        get_response = Mock(return_value="Response")
        middleware = DatabaseHealthCheckMiddleware(get_response)

        with patch('time.sleep'):  # Skip actual sleep delays
            response = middleware(request)

        # Should succeed after retry
        assert response == "Response"
        assert mock_ensure_connection.call_count == 2

    @patch('config.middleware.connection.ensure_connection')
    def test_middleware_returns_error_page_after_max_retries(self, mock_ensure_connection):
        """Test that middleware returns 503 error after all retries fail"""
        # Simulate continuous database failure
        mock_ensure_connection.side_effect = OperationalError("Connection failed")

        factory = RequestFactory()
        request = factory.get("/")
        get_response = Mock(return_value="Response")
        middleware = DatabaseHealthCheckMiddleware(get_response)

        with patch('time.sleep'):  # Skip actual sleep delays
            response = middleware(request)

        # Should return error page
        assert response.status_code == 503
        assert b"We'll be right back!" in response.content
        # Should have tried the configured number of attempts
        assert mock_ensure_connection.call_count == settings.DATABASE_RETRY_ATTEMPTS

    @patch('config.middleware.connection.ensure_connection')
    def test_middleware_uses_exponential_backoff(self, mock_ensure_connection):
        """Test that middleware uses correct retry delays"""
        mock_ensure_connection.side_effect = OperationalError("Connection failed")

        factory = RequestFactory()
        request = factory.get("/")
        get_response = Mock(return_value="Response")
        middleware = DatabaseHealthCheckMiddleware(get_response)

        with patch('time.sleep') as mock_sleep:
            response = middleware(request)

        # Should use the configured delays (1s, 2s, 4s)
        assert mock_sleep.call_count == settings.DATABASE_RETRY_ATTEMPTS - 1
        # Check that delays match settings (excluding the last attempt which doesn't sleep)
        expected_delays = settings.DATABASE_RETRY_DELAYS[:settings.DATABASE_RETRY_ATTEMPTS - 1]
        actual_delays = [call.args[0] for call in mock_sleep.call_args_list]
        assert actual_delays == expected_delays


@pytest.mark.django_db
class TestDatabaseConnectionSettings:
    """Test database connection configuration"""

    def test_database_has_connection_health_checks_enabled(self):
        """Test that conn_health_checks is enabled"""
        db_config = settings.DATABASES['default']
        assert db_config.get('CONN_HEALTH_CHECKS') is True

    def test_database_has_connection_max_age(self):
        """Test that conn_max_age is configured"""
        db_config = settings.DATABASES['default']
        assert db_config.get('CONN_MAX_AGE') == 600

    def test_retry_settings_are_configured(self):
        """Test that retry settings exist and are valid"""
        assert hasattr(settings, 'DATABASE_RETRY_ATTEMPTS')
        assert hasattr(settings, 'DATABASE_RETRY_DELAYS')
        assert settings.DATABASE_RETRY_ATTEMPTS == 3
        assert settings.DATABASE_RETRY_DELAYS == [1, 2, 4]
        assert len(settings.DATABASE_RETRY_DELAYS) >= settings.DATABASE_RETRY_ATTEMPTS - 1


@pytest.mark.django_db
class TestDatabaseConnectionRecovery:
    """Test that database operations recover from temporary failures"""

    def test_database_connection_actually_works(self):
        """Baseline test: verify database is working normally"""
        from users.models import User

        # Should be able to query database
        users = User.objects.all()
        assert users is not None

    @patch('django.db.backends.base.base.BaseDatabaseWrapper.ensure_connection')
    def test_view_handles_database_error_gracefully(self, mock_ensure_connection):
        """Test that views handle database errors without crashing"""
        # Simulate a temporary database issue
        mock_ensure_connection.side_effect = [
            OperationalError("Connection refused"),
            None,  # Recover on retry
        ]

        client = Client()

        with patch('time.sleep'):  # Skip delays
            response = client.get("/")

        # Should get a response (either success or graceful error)
        assert response.status_code in [200, 503]


@pytest.mark.django_db
class TestErrorPageRendering:
    """Test that error pages render correctly"""

    @patch('config.middleware.connection.ensure_connection')
    def test_database_error_page_contains_helpful_message(self, mock_ensure_connection):
        """Test that error page has user-friendly content"""
        mock_ensure_connection.side_effect = OperationalError("Connection failed")

        factory = RequestFactory()
        request = factory.get("/browse")
        get_response = Mock()
        middleware = DatabaseHealthCheckMiddleware(get_response)

        with patch('time.sleep'):
            response = middleware(request)

        # Check response content
        assert response.status_code == 503
        content = response.content.decode('utf-8')
        assert "We'll be right back!" in content
        assert "database" in content.lower()
        assert "Retry Now" in content

    @patch('config.middleware.connection.ensure_connection')
    def test_database_error_page_has_retry_button(self, mock_ensure_connection):
        """Test that error page includes retry functionality"""
        mock_ensure_connection.side_effect = OperationalError("Connection failed")

        factory = RequestFactory()
        request = factory.get("/")
        get_response = Mock()
        middleware = DatabaseHealthCheckMiddleware(get_response)

        with patch('time.sleep'):
            response = middleware(request)

        content = response.content.decode('utf-8')
        assert "location.reload()" in content  # Has retry JavaScript
        assert "Retry Now" in content  # Has retry button


@pytest.mark.django_db
class TestDatabaseResilienceIntegration:
    """Integration tests for database resilience"""

    def test_middleware_does_not_interfere_with_normal_requests(self, client, test_user):
        """Test that middleware doesn't slow down or break normal requests"""
        # Make several requests to ensure middleware works normally
        response1 = client.get("/")
        assert response1.status_code == 200

        response2 = client.get("/browse/")
        assert response2.status_code == 200

        # Login should work normally
        client.login(username="test@example.com", password="testpass123")
        response3 = client.get("/dashboard/")
        assert response3.status_code == 200

    def test_middleware_processes_requests_in_correct_order(self):
        """Test that middleware is positioned correctly in middleware stack"""
        middleware_classes = settings.MIDDLEWARE

        # Find the index of our middleware
        db_middleware_index = None
        for i, middleware in enumerate(middleware_classes):
            if 'DatabaseHealthCheckMiddleware' in middleware:
                db_middleware_index = i
                break

        assert db_middleware_index is not None, "DatabaseHealthCheckMiddleware not found in MIDDLEWARE"

        # Should be after SecurityMiddleware and WhiteNoiseMiddleware
        # but before SessionMiddleware (so we check DB before loading sessions)
        security_index = next(i for i, m in enumerate(middleware_classes) if 'SecurityMiddleware' in m)
        session_index = next(i for i, m in enumerate(middleware_classes) if 'SessionMiddleware' in m)

        assert db_middleware_index > security_index
        assert db_middleware_index < session_index


@pytest.mark.django_db
class TestLocalDatabaseTesting:
    """Tests for local development database testing"""

    def test_can_manually_test_database_connection(self):
        """
        Demonstrates how to manually test database connection.

        To test locally:
        1. Stop your database: brew services stop postgresql (or similar)
        2. Try to access the app
        3. Should see friendly error page
        4. Restart database: brew services start postgresql
        5. Retry button should work
        """
        from django.db import connection

        # Verify connection works
        connection.ensure_connection()
        assert connection.is_usable()

        # You can manually disconnect to test:
        # connection.close()
        # Then try to make a request

    def test_database_connection_info(self):
        """Display database connection info for debugging"""
        db_config = settings.DATABASES['default']

        # These settings should be present
        assert 'NAME' in db_config or 'default' in str(db_config)
        assert 'ENGINE' in db_config or 'default' in str(db_config)

        print("\nDatabase Configuration:")
        print(f"  Retry Attempts: {settings.DATABASE_RETRY_ATTEMPTS}")
        print(f"  Retry Delays: {settings.DATABASE_RETRY_DELAYS}")
        print(f"  Connection Max Age: {db_config.get('CONN_MAX_AGE', 'Not set')}")
        print(f"  Health Checks: {db_config.get('CONN_HEALTH_CHECKS', 'Not set')}")
