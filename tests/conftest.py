"""Test configuration and fixtures"""
import pytest
import tempfile
import os
from unittest.mock import Mock, patch
from datetime import datetime, date
from app import app, db, User, Admin, Listing, ListingPhoto

@pytest.fixture
def client():
    """Create a test client with clean database"""
    # Create a temporary database file
    db_fd, app.config['DATABASE'] = tempfile.mkstemp()
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    app.config['SECRET_KEY'] = 'test-secret-key'
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()
    
    os.close(db_fd)

@pytest.fixture
def app_context():
    """Application context for model tests"""
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def test_user():
    """Create a test user"""
    user = User(
        first_name='Test',
        last_name='User',
        email='test@example.com'
    )
    user.set_password('testpass123')
    db.session.add(user)
    db.session.commit()
    return user

@pytest.fixture
def test_admin():
    """Create a test admin"""
    admin = Admin(
        email='admin@example.com',
        name='Test Admin'
    )
    admin.set_password('adminpass123')
    db.session.add(admin)
    db.session.commit()
    return admin

@pytest.fixture
def logged_in_user(client, test_user):
    """User that's already logged in"""
    client.post('/login', data={
        'email': 'test@example.com',
        'password': 'testpass123'
    })
    return test_user

@pytest.fixture
def logged_in_admin(client, test_admin):
    """Admin that's already logged in"""
    client.post('/admin/login', data={
        'email': 'admin@example.com', 
        'password': 'adminpass123'
    })
    return test_admin

@pytest.fixture
def draft_listing(test_user):
    """Create a draft listing"""
    listing = Listing(
        title='Test Vegan House',
        description='A lovely vegan household',
        city='New York',
        price=1500,
        date_available=date(2024, 2, 1),
        rental_type='whole_space',
        room_type='private_room',
        vegan_household='fully_vegan',
        lister_relationship='owner',
        about_lister='I am a vegan homeowner',
        rental_requirements='Must be vegan',
        pet_policy='No pets allowed',
        furnished='partially_furnished',
        user_id=test_user.id,
        status='draft'
    )
    db.session.add(listing)
    db.session.commit()
    return listing

@pytest.fixture
def payment_submitted_listing(test_user):
    """Create a listing waiting for admin approval"""
    listing = Listing(
        title='Pending Approval House',
        description='Waiting for admin approval',
        city='Los Angeles',
        price=2000,
        date_available=date(2024, 3, 1),
        rental_type='shared_space',
        room_type='shared_room',
        vegan_household='mixed_household',
        lister_relationship='tenant',
        about_lister='Current tenant looking for roommate',
        rental_requirements='Vegan-friendly',
        pet_policy='Cats allowed',
        furnished='fully_furnished',
        user_id=test_user.id,
        status='payment_submitted'
    )
    db.session.add(listing)
    db.session.commit()
    return listing

@pytest.fixture
def active_listing(test_user):
    """Create an active/published listing"""
    listing = Listing(
        title='Active Vegan Space',
        description='Currently available',
        city='Chicago',
        price=1200,
        date_available=date(2024, 1, 15),
        rental_type='whole_space',
        room_type='private_room',
        vegan_household='fully_vegan',
        lister_relationship='owner',
        about_lister='Vegan landlord',
        rental_requirements='Vegan only',
        pet_policy='No pets',
        furnished='not_furnished',
        user_id=test_user.id,
        status='active'
    )
    db.session.add(listing)
    db.session.commit()
    return listing

@pytest.fixture
def listing_with_photos(active_listing):
    """Create a listing with photos"""
    photo1 = ListingPhoto(
        filename='test1.jpg',
        listing_id=active_listing.id
    )
    photo2 = ListingPhoto(
        filename='test2.jpg',
        listing_id=active_listing.id
    )
    db.session.add_all([photo1, photo2])
    db.session.commit()
    return active_listing

@pytest.fixture
def mock_b2_upload():
    """Mock B2 photo upload service"""
    with patch('app.upload_to_b2') as mock_upload:
        mock_upload.return_value = 'mocked_filename.jpg'
        yield mock_upload

@pytest.fixture
def sample_listing_data():
    """Sample data for creating listings"""
    return {
        'title': 'Sample Listing',
        'description': 'A great vegan space',
        'city': 'New York',
        'price': 1500,
        'date_available': '2024-02-01',
        'rental_type': 'whole_space',
        'room_type': 'private_room',
        'vegan_household': 'fully_vegan',
        'lister_relationship': 'owner',
        'about_lister': 'Vegan homeowner',
        'rental_requirements': 'Must be vegan',
        'pet_policy': 'No pets',
        'furnished': 'partially_furnished'
    }