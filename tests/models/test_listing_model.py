"""Test Listing model"""
import pytest
from datetime import date
from backend.app import db
from backend.app.models import Listing, ListingStatus

class TestListing:
    """Test Listing model"""
    
    def test_create_listing(self, app_context, test_user):
        """Test listing creation"""
        listing = Listing(
            title='Test House',
            description='A test house',
            city='Test City',
            price=1000,
            date_available=date(2024, 1, 1),
            rental_type='whole_space',
            room_type='private_room',
            vegan_household='fully_vegan',
            lister_relationship='owner',
            about_lister='Test lister',
            rental_requirements='Test requirements',
            pet_policy='No pets',
            furnished='not_furnished',
            phone_number='(555) 123-4567',
            include_phone=True,
            user_id=test_user.id,
            status=ListingStatus.DRAFT.value
        )
        db.session.add(listing)
        db.session.commit()
        
        # Fresh query to verify database persistence
        saved_listing = Listing.query.filter_by(title='Test House').first()
        assert saved_listing is not None
        assert saved_listing.id is not None
        assert saved_listing.title == 'Test House'
        assert saved_listing.user_id == test_user.id
        assert saved_listing.status == ListingStatus.DRAFT.value
    
    def test_listing_status_transitions(self, app_context, draft_listing):
        """Test listing status changes"""
        listing_id = draft_listing.id
        
        # Start as draft
        assert draft_listing.status == ListingStatus.DRAFT.value
        
        # Submit for payment
        draft_listing.status = ListingStatus.PAYMENT_SUBMITTED.value
        db.session.commit()
        
        # Fresh query to verify database update
        updated_listing = db.session.get(Listing, listing_id)
        assert updated_listing.status == ListingStatus.PAYMENT_SUBMITTED.value
        
        # Activate listing
        updated_listing.activate_listing()
        db.session.commit()
        
        # Fresh query to verify activation
        active_listing = db.session.get(Listing, listing_id)
        assert active_listing.status == ListingStatus.ACTIVE.value
        assert active_listing.paid_at is not None
        assert active_listing.expires_at is not None
    
    def test_listing_display_methods(self, app_context, draft_listing):
        """Test listing display helper methods"""
        assert draft_listing.get_lister_relationship_display() == 'I own the space'
        assert draft_listing.get_furnished_display() == 'Partially furnished'
        assert draft_listing.get_vegan_household_display() == 'Fully vegan household'
    
    def test_listing_string_representation(self, app_context, draft_listing):
        """Test listing __repr__ method"""
        assert str(draft_listing) == '<Listing Test Vegan House>'
    
    def test_listing_user_relationship(self, app_context, draft_listing, test_user):
        """Test listing belongs to user"""
        # Fresh query to verify relationship
        fresh_listing = db.session.get(Listing, draft_listing.id)
        assert fresh_listing.user == test_user
        assert fresh_listing.user.email == test_user.email
    
    def test_listing_required_fields(self, app_context, test_user):
        """Test listing requires certain fields"""
        # Try to create listing without required fields
        incomplete_listing = Listing(
            user_id=test_user.id
            # Missing required fields like title, description, etc.
        )
        db.session.add(incomplete_listing)
        
        # This should raise an error when committing
        with pytest.raises(Exception):
            db.session.commit()