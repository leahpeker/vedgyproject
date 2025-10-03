"""Routes package"""
from .auth import auth_bp
from .admin import admin_bp
from .public import public_bp
from .listings import listings_bp
from .listing_management import listing_management_bp
from .dashboard import dashboard_bp

__all__ = ['auth_bp', 'admin_bp', 'public_bp', 'listings_bp', 'listing_management_bp', 'dashboard_bp']