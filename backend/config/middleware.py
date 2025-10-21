"""
Custom middleware for database connection handling
"""
import time
from django.conf import settings
from django.db import connection
from django.db.utils import OperationalError
from django.http import HttpResponse
from django.shortcuts import render


class DatabaseHealthCheckMiddleware:
    """
    Middleware to handle database connection issues gracefully with retry logic
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Try to ensure database connection with retries
        if not self._ensure_database_connection():
            # If all retries failed, show a friendly error page
            return self._render_database_error_page(request)

        response = self.get_response(request)
        return response

    def _ensure_database_connection(self):
        """
        Attempt to connect to database with exponential backoff retries
        Returns True if successful, False otherwise
        """
        for attempt in range(settings.DATABASE_RETRY_ATTEMPTS):
            try:
                # Try a simple database query to check connection
                connection.ensure_connection()
                return True
            except OperationalError as e:
                # If this is the last attempt, give up
                if attempt == settings.DATABASE_RETRY_ATTEMPTS - 1:
                    print(f"Database connection failed after {settings.DATABASE_RETRY_ATTEMPTS} attempts")
                    return False

                # Wait before retrying (exponential backoff)
                delay = settings.DATABASE_RETRY_DELAYS[attempt]
                print(f"Database connection attempt {attempt + 1} failed, retrying in {delay}s...")
                time.sleep(delay)

        return False

    def _render_database_error_page(self, request):
        """
        Render a friendly error page when database is unavailable
        """
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Service Temporarily Unavailable</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }
                .container {
                    text-align: center;
                    padding: 2rem;
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 1rem;
                    backdrop-filter: blur(10px);
                    max-width: 500px;
                }
                h1 { font-size: 2.5rem; margin-bottom: 1rem; }
                p { font-size: 1.1rem; line-height: 1.6; }
                .retry-btn {
                    margin-top: 2rem;
                    padding: 0.75rem 2rem;
                    font-size: 1rem;
                    background: white;
                    color: #667eea;
                    border: none;
                    border-radius: 0.5rem;
                    cursor: pointer;
                    font-weight: bold;
                }
                .retry-btn:hover { background: #f0f0f0; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>We'll be right back!</h1>
                <p>Our database is taking a quick nap. This usually resolves itself in a few moments.</p>
                <p>Please try refreshing the page in a moment.</p>
                <button class="retry-btn" onclick="location.reload()">Retry Now</button>
            </div>
        </body>
        </html>
        """
        return HttpResponse(html, status=503)
