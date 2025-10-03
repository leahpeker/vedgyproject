"""Utility decorators"""
from functools import wraps
from flask import redirect, url_for
from flask_login import current_user
from ..models import Admin

def admin_required(f):
    """Decorator to require admin authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not isinstance(current_user, Admin):
            return redirect(url_for('admin.admin_login'))
        return f(*args, **kwargs)
    return decorated_function