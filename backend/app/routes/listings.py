"""Listing browsing routes"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import current_user
from ..models import Listing, ListingStatus

# This will be imported from the main app
db = None

def init_listings_routes(database):
    """Initialize routes with db instance"""
    global db
    db = database

listings_bp = Blueprint('listings', __name__)

@listings_bp.route('/listings')
def browse():
    """Browse all active listings with filters"""
    from ..utils.listing_utils import expire_old_listings

    # Expire old listings before showing results
    expire_old_listings()

    # Get filter parameters
    rental_type = request.args.get('rental_type')
    room_type = request.args.get('room_type')
    seeking_roommate = request.args.get('seeking_roommate')
    city_search = request.args.get('city')
    borough_search = request.args.get('borough')
    furnished = request.args.get('furnished')
    vegan_household = request.args.get('vegan_household')
    min_price = request.args.get('min_price')
    max_price = request.args.get('max_price')

    # Build query - only show active listings
    query = Listing.query.filter(Listing.status == ListingStatus.ACTIVE.value)

    if rental_type:
        query = query.filter(Listing.rental_type == rental_type)
    if room_type:
        query = query.filter(Listing.room_type == room_type)
    if seeking_roommate:
        query = query.filter(Listing.seeking_roommate == (seeking_roommate.lower() == 'true'))
    if city_search:
        # City search - exact match or partial
        query = query.filter(Listing.city.ilike(f'%{city_search}%'))
    if borough_search:
        # Borough search - exact match
        query = query.filter(Listing.borough == borough_search)
    if furnished:
        # Furnished status - exact match
        query = query.filter(Listing.furnished == furnished)
    if vegan_household:
        # Vegan household type - exact match
        query = query.filter(Listing.vegan_household == vegan_household)
    if min_price:
        query = query.filter(Listing.price >= int(min_price))
    if max_price:
        query = query.filter(Listing.price <= int(max_price))

    listings = query.order_by(Listing.created_at.desc()).all()

    # If this is an HTMX request, return just the listings container
    if request.headers.get('HX-Request'):
        return render_template('_listings_partial.html', listings=listings)

    return render_template('listings.html', listings=listings)

@listings_bp.route('/listing/<listing_id>')
def detail(listing_id):
    """View individual listing details"""
    listing = db.get_or_404(Listing, listing_id)

    # Handle payment submission confirmation
    if request.args.get('payment') == 'submitted':
        if listing.status == ListingStatus.DRAFT.value and current_user.is_authenticated and listing.user_id == current_user.id:
            listing.status = ListingStatus.PAYMENT_SUBMITTED.value
            db.session.commit()
            flash('Payment confirmation received! We\'ll review and activate your listing within 24 hours.', 'success')
        return redirect(url_for('listings.detail', listing_id=listing_id))

    # Only show active listings to public, or any status to the owner
    if listing.status != ListingStatus.ACTIVE.value:
        if not current_user.is_authenticated or listing.user_id != current_user.id:
            flash('Listing not found or not available.', 'error')
            return redirect(url_for('listings.browse'))

    return render_template('listing_detail.html', listing=listing)
