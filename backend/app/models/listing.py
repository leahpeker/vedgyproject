"""Listing and ListingPhoto models"""
import uuid
from datetime import datetime, timedelta
from .base import ListingStatus, ListerRelationship, FurnishedStatus, VeganHouseholdType
from .. import db

class Listing(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    city = db.Column(db.String(100), nullable=False)
    borough = db.Column(db.String(50))  # For NYC, can be null for other cities
    neighborhood = db.Column(db.String(100))  # Optional neighborhood info
    
    # Rental details
    rental_type = db.Column(db.String(20), nullable=False)  # whole_space, shared_space
    room_type = db.Column(db.String(20), nullable=False)  # private_room, shared_room
    price = db.Column(db.Integer, nullable=False)  # Monthly rent
    seeking_roommate = db.Column(db.Boolean, default=False, nullable=False)  # Whether user is seeking a roommate vs just a tenant
    
    # Availability
    date_available = db.Column(db.Date, nullable=False)
    date_until = db.Column(db.Date)  # Optional end date
    transportation = db.Column(db.Text)  # Transportation info
    size = db.Column(db.String(50))  # Room/space size
    furnished = db.Column(db.String(30), nullable=False)  # not_furnished, partially_furnished, fully_furnished
    
    # Household info
    vegan_household = db.Column(db.String(30), nullable=False)  # fully_vegan, mixed_household
    about_lister = db.Column(db.Text, nullable=False)  # About the person posting
    lister_relationship = db.Column(db.String(30), nullable=False)  # owner, manager, tenant, etc.
    rental_requirements = db.Column(db.Text, nullable=False)  # Requirements for renters
    pet_policy = db.Column(db.Text, nullable=False) 
    phone_number = db.Column(db.Text, nullable=False) 
    include_phone = db.Column(db.Boolean, default=False, nullable=False)  # Whether to show phone in contact
    
    # Payment and expiration tracking
    status = db.Column(db.String(20), default=ListingStatus.DRAFT.value, nullable=False)
    paid_at = db.Column(db.DateTime, nullable=True)
    expires_at = db.Column(db.DateTime, nullable=True)  # 30 days from paid_at
    
    # Relationships
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    photos = db.relationship('ListingPhoto', backref='listing', lazy=True, cascade='all, delete-orphan')
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

    def __repr__(self):
        return f'<Listing {self.title}>'
    
    def activate_listing(self):
        """Activate listing after successful payment"""
        self.status = ListingStatus.ACTIVE.value
        self.paid_at = datetime.now()
        self.expires_at = datetime.now() + timedelta(days=30)
    
    def get_lister_relationship_display(self):
        """Get the human-readable display text for lister relationship"""
        return ListerRelationship.get_display_text(self.lister_relationship)
    
    def get_furnished_display(self):
        """Get the human-readable display text for furnished status"""
        return FurnishedStatus.get_display_text(self.furnished)
    
    def get_vegan_household_display(self):
        """Get the human-readable display text for vegan household type"""
        return VeganHouseholdType.get_display_text(self.vegan_household)

class ListingPhoto(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = db.Column(db.String(100), nullable=False)
    listing_id = db.Column(db.String(36), db.ForeignKey('listing.id'), nullable=False)
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())