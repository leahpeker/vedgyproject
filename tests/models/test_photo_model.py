"""Test ListingPhoto model"""
import pytest
from backend.app import db
from backend.app.models import Listing, ListingPhoto

class TestListingPhoto:
    """Test ListingPhoto model"""
    
    def test_create_photo(self, app_context, active_listing):
        """Test photo creation"""
        photo = ListingPhoto(
            filename='test.jpg',
            listing_id=active_listing.id
        )
        db.session.add(photo)
        db.session.commit()
        
        # Fresh query to verify database persistence
        saved_photo = ListingPhoto.query.filter_by(filename='test.jpg').first()
        assert saved_photo is not None
        assert saved_photo.id is not None
        assert saved_photo.filename == 'test.jpg'
        assert saved_photo.listing_id == active_listing.id
        assert saved_photo.listing == active_listing
    
    def test_listing_photos_relationship(self, app_context, listing_with_photos):
        """Test listing-photos relationship"""
        # Fresh query to verify relationship
        fresh_listing = db.session.get(Listing, listing_with_photos.id)
        assert len(fresh_listing.photos) == 2
        assert fresh_listing.photos[0].filename == 'test1.jpg'
        assert fresh_listing.photos[1].filename == 'test2.jpg'
    
    def test_photo_deletion_cascades(self, app_context, listing_with_photos):
        """Test that deleting listing deletes associated photos"""
        listing_id = listing_with_photos.id
        
        # Verify photos exist
        photos_before = ListingPhoto.query.filter_by(listing_id=listing_id).all()
        assert len(photos_before) == 2
        
        # Delete the listing
        db.session.delete(listing_with_photos)
        db.session.commit()
        
        # Photos should be deleted too (cascade)
        photos_after = ListingPhoto.query.filter_by(listing_id=listing_id).all()
        assert len(photos_after) == 0
    
    def test_photo_requires_listing(self, app_context):
        """Test photo requires a valid listing_id"""
        # Try to create photo without listing
        orphan_photo = ListingPhoto(
            filename='orphan.jpg'
            # Missing listing_id
        )
        db.session.add(orphan_photo)
        
        # This should raise an error
        with pytest.raises(Exception):
            db.session.commit()