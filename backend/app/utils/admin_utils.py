"""Admin utility functions"""
import os
from ..models import Admin
from .. import db

def create_default_admin():
    """Create default admin if none exists"""
    if Admin.query.first() is None:
        admin_email = os.environ.get('ADMIN_EMAIL')
        admin_password = os.environ.get('ADMIN_PASSWORD')
        admin_name = os.environ.get('ADMIN_NAME', 'Admin')

        if admin_email and admin_password:
            admin = Admin(
                email=admin_email,
                name=admin_name
            )
            admin.set_password(admin_password)
            db.session.add(admin)
            db.session.commit()
            print(f"✅ Default admin created: {admin_email}")
