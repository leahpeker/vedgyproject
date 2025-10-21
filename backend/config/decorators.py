"""
Custom decorators for database error handling
"""
from functools import wraps
from django.db.utils import OperationalError, DatabaseError
from django.http import JsonResponse
from django.shortcuts import render


def handle_database_errors(view_func):
    """
    Decorator to catch database errors in views and return graceful error responses
    Use this on views that might fail if database is down
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        try:
            return view_func(request, *args, **kwargs)
        except (OperationalError, DatabaseError) as e:
            # Log the error
            print(f"Database error in {view_func.__name__}: {e}")

            # Return appropriate error response based on request type
            if request.headers.get('X-Requested-With') == 'XMLHttpRequest' or request.content_type == 'application/json':
                # For AJAX/API requests, return JSON error
                return JsonResponse({
                    'error': 'Database temporarily unavailable',
                    'message': 'Please try again in a moment'
                }, status=503)
            else:
                # For regular requests, render error page
                return render(request, 'errors/database_error.html', status=503)

    return wrapper
