"""Listing utility functions"""
from datetime import datetime
from ..models import Listing, ListingStatus
from .. import db

def expire_old_listings():
    """Mark listings as expired if they're past their expiration date"""
    expired_listings = Listing.query.filter(
        Listing.status == ListingStatus.ACTIVE.value,
        Listing.expires_at <= datetime.now()
    ).all()

    for listing in expired_listings:
        listing.status = ListingStatus.EXPIRED.value

    if expired_listings:
        db.session.commit()

    return len(expired_listings)
