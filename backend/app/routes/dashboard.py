"""User dashboard routes"""
from flask import Blueprint, render_template
from flask_login import login_required, current_user
from ..models import Listing, ListingStatus

# This will be imported from the main app
db = None

def init_dashboard_routes(database):
    """Initialize routes with db instance"""
    global db
    db = database

dashboard_bp = Blueprint('dashboard', __name__)

@dashboard_bp.route('/dashboard')
@login_required
def index():
    """User dashboard to manage their listings"""
    from ..utils.listing_utils import expire_old_listings

    # Expire old listings before showing dashboard
    expire_old_listings()

    # Get all user's listings
    user_listings = Listing.query.filter_by(user_id=current_user.id).order_by(Listing.created_at.desc()).all()

    # Categorize listings by status
    active_listings = [l for l in user_listings if l.status == ListingStatus.ACTIVE.value]
    draft_listings = [l for l in user_listings if l.status == ListingStatus.DRAFT.value]
    payment_submitted_listings = [l for l in user_listings if l.status == ListingStatus.PAYMENT_SUBMITTED.value]
    deactivated_listings = [l for l in user_listings if l.status == ListingStatus.DEACTIVATED.value]
    expired_listings = [l for l in user_listings if l.status == ListingStatus.EXPIRED.value]

    return render_template('dashboard.html',
                         active_listings=active_listings,
                         draft_listings=draft_listings,
                         payment_submitted_listings=payment_submitted_listings,
                         deactivated_listings=deactivated_listings,
                         expired_listings=expired_listings)
