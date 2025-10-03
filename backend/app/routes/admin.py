"""Admin routes"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, current_user
from ..models import Admin, Listing, ListingStatus
from ..forms import AdminLoginForm
from ..utils.decorators import admin_required

# These will be imported from the main app
db = None

def init_admin_routes(database):
    """Initialize routes with db instance"""
    global db
    db = database

admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

@admin_bp.route('/login', methods=['GET', 'POST'])
def admin_login():
    """Admin login page"""
    if current_user.is_authenticated and isinstance(current_user, Admin):
        return redirect(url_for('admin.admin_dashboard'))
    
    form = AdminLoginForm()
    if form.validate_on_submit():
        admin = Admin.query.filter_by(email=form.email.data).first()
        if admin and admin.check_password(form.password.data):
            login_user(admin)
            flash('Admin login successful!', 'success')
            return redirect(url_for('admin.admin_dashboard'))
        flash('Invalid admin credentials', 'danger')
    
    return render_template('admin_login.html', form=form)

@admin_bp.route('/dashboard')
@admin_required
def admin_dashboard():
    """Admin dashboard showing pending listings"""
    # Get all listings that need approval
    pending_listings = Listing.query.filter_by(status=ListingStatus.PAYMENT_SUBMITTED.value).order_by(Listing.created_at.desc()).all()
    
    return render_template('admin_dashboard.html', pending_listings=pending_listings)

@admin_bp.route('/listing/<listing_id>')
@admin_required
def admin_review_listing(listing_id):
    """Admin review individual listing"""
    listing = db.get_or_404(Listing, listing_id)
    return render_template('admin_review_listing.html', listing=listing)

@admin_bp.route('/approve/<listing_id>', methods=['POST'])
@admin_required
def admin_approve_listing(listing_id):
    """Approve a listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    if listing.status == ListingStatus.PAYMENT_SUBMITTED.value:
        listing.activate_listing()  # Sets to ACTIVE and sets expiration
        db.session.commit()
        flash(f'Listing "{listing.title}" approved and activated!', 'success')
    else:
        flash('Listing cannot be approved in its current status.', 'warning')
    
    return redirect(url_for('admin.admin_dashboard'))

@admin_bp.route('/reject/<listing_id>', methods=['POST'])
@admin_required
def admin_reject_listing(listing_id):
    """Reject a listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    if listing.status == ListingStatus.PAYMENT_SUBMITTED.value:
        listing.status = ListingStatus.DRAFT.value
        db.session.commit()
        flash(f'Listing "{listing.title}" rejected and returned to draft.', 'info')
    else:
        flash('Listing cannot be rejected in its current status.', 'warning')
    
    return redirect(url_for('admin.admin_dashboard'))