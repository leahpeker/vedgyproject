"""Test User model"""
import pytest
from app import db, User

class TestUser:
    """Test User model"""
    
    def test_create_user(self, app_context):
        """Test user creation"""
        user = User(
            first_name='John',
            last_name='Doe', 
            email='john@example.com'
        )
        user.set_password('password123')
        db.session.add(user)
        db.session.commit()
        
        # Fresh query to verify database persistence
        saved_user = User.query.filter_by(email='john@example.com').first()
        assert saved_user is not None
        assert saved_user.id is not None
        assert saved_user.first_name == 'John'
        assert saved_user.last_name == 'Doe'
        assert saved_user.email == 'john@example.com'
        assert saved_user.check_password('password123')
        assert not saved_user.check_password('wrongpassword')
    
    def test_user_can_create_listing(self, app_context, test_user):
        """Test user can create listings"""
        assert test_user.can_create_listing()
    
    def test_user_string_representation(self, app_context, test_user):
        """Test user __repr__ method"""
        # User model doesn't have custom __repr__, so it shows the ID
        assert str(test_user).startswith('<User ')
        assert test_user.id in str(test_user)
    
    def test_password_hashing(self, app_context):
        """Test password is properly hashed"""
        user = User(
            first_name='Test',
            last_name='User',
            email='hash@example.com'
        )
        user.set_password('mypassword')
        
        # Password should be hashed, not stored in plain text
        assert user.password_hash != 'mypassword'
        assert len(user.password_hash) > 20  # Bcrypt hashes are long
        
        # But check_password should still work
        assert user.check_password('mypassword')
        assert not user.check_password('wrongpassword')