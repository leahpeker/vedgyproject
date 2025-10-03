"""Base model classes and enums"""
from enum import Enum

class ListingStatus(Enum):
    DRAFT = 'draft'
    PAYMENT_SUBMITTED = 'payment_submitted'
    ACTIVE = 'active'
    DEACTIVATED = 'deactivated'
    EXPIRED = 'expired'

class ListerRelationship(Enum):
    OWNER = 'owner'
    MANAGER = 'manager' 
    TENANT = 'tenant'
    ROOMMATE = 'roommate'
    AGENT = 'agent'
    OTHER = 'other'
    
    @classmethod
    def choices(cls):
        return [
            (cls.OWNER.value, 'I own the space'),
            (cls.MANAGER.value, 'I manage the space'),
            (cls.TENANT.value, 'I am the current tenant'),
            (cls.ROOMMATE.value, 'I am a current roommate'),
            (cls.AGENT.value, 'I am a rental agent/broker'),
            (cls.OTHER.value, 'Other')
        ]
    
    @classmethod
    def get_display_text(cls, value):
        """Get the human-readable display text for a relationship value"""
        choices_dict = dict(cls.choices())
        return choices_dict.get(value, value)

class NYCBorough(Enum):
    MANHATTAN = 'Manhattan'
    BROOKLYN = 'Brooklyn' 
    QUEENS = 'Queens'
    BRONX = 'Bronx'
    STATEN_ISLAND = 'Staten Island'
    
    @classmethod
    def choices(cls):
        return [
            (cls.MANHATTAN.value, 'Manhattan'),
            (cls.BROOKLYN.value, 'Brooklyn'),
            (cls.QUEENS.value, 'Queens'),
            (cls.BRONX.value, 'Bronx'),
            (cls.STATEN_ISLAND.value, 'Staten Island')
        ]

class FurnishedStatus(Enum):
    NOT_FURNISHED = 'not_furnished'
    PARTIALLY_FURNISHED = 'partially_furnished'
    FULLY_FURNISHED = 'fully_furnished'
    
    @classmethod
    def choices(cls):
        return [
            (cls.NOT_FURNISHED.value, 'Not furnished'),
            (cls.PARTIALLY_FURNISHED.value, 'Partially furnished'),
            (cls.FULLY_FURNISHED.value, 'Fully furnished')
        ]
    
    @classmethod
    def get_display_text(cls, value):
        """Get the human-readable display text for furnished status"""
        choices_dict = dict(cls.choices())
        return choices_dict.get(value, value)

class VeganHouseholdType(Enum):
    FULLY_VEGAN = 'fully_vegan'
    MIXED_HOUSEHOLD = 'mixed_household'
    
    @classmethod
    def choices(cls):
        return [
            (cls.FULLY_VEGAN.value, 'Fully vegan household'),
            (cls.MIXED_HOUSEHOLD.value, 'Mixed household (some non-vegans)')
        ]
    
    @classmethod
    def get_display_text(cls, value):
        """Get the human-readable display text for vegan household type"""
        choices_dict = dict(cls.choices())
        return choices_dict.get(value, value)

def get_major_cities():
    """Get list of major US cities - starting simple with just 3 cities"""
    major_cities = ['New York', 'Los Angeles', 'Chicago']
    return [(city, city) for city in major_cities]