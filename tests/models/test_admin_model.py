"""Test Admin model"""
import pytest
from backend.app import db
from backend.app.models import Admin

class TestAdmin:
    """Test Admin model"""
    
    def test_create_admin(self, app_context):
        """Test admin creation"""
        admin = Admin(
            email='admin@example.com',
            name='Admin User'
        )
        admin.set_password('adminpass')
        db.session.add(admin)
        db.session.commit()
        
        # Fresh query to verify database persistence
        saved_admin = Admin.query.filter_by(email='admin@example.com').first()
        assert saved_admin is not None
        assert saved_admin.id is not None
        assert saved_admin.email == 'admin@example.com'
        assert saved_admin.name == 'Admin User'
        assert saved_admin.check_password('adminpass')
        assert not saved_admin.check_password('wrongpass')
    
    def test_admin_password_hashing(self, app_context):
        """Test admin password is properly hashed"""
        admin = Admin(
            email='security@example.com',
            name='Security Admin'
        )
        admin.set_password('securepass')
        
        # Password should be hashed, not stored in plain text
        assert admin.password_hash != 'securepass'
        assert len(admin.password_hash) > 20  # Bcrypt hashes are long
        
        # But check_password should still work
        assert admin.check_password('securepass')
        assert not admin.check_password('wrongpassword')
    
    def test_admin_unique_email(self, app_context, test_admin):
        """Test admin email must be unique"""
        # Try to create another admin with same email
        duplicate_admin = Admin(
            email='admin@example.com',  # Same as test_admin
            name='Duplicate Admin'
        )
        duplicate_admin.set_password('password')
        db.session.add(duplicate_admin)
        
        # This should raise an integrity error
        with pytest.raises(Exception):
            db.session.commit()