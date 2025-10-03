"""Listing CRUD operations routes"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user
from datetime import datetime
from ..models import Listing, ListingStatus, ListingPhoto
from ..models.base import get_major_cities, ListerRelationship, FurnishedStatus, VeganHouseholdType, NYCBorough

# This will be imported from the main app
db = None

def init_listing_management_routes(database):
    """Initialize routes with db instance"""
    global db
    db = database

listing_management_bp = Blueprint('listing_management', __name__)

@listing_management_bp.route('/create', methods=['GET', 'POST'])
@login_required
def create():
    """Create a new listing"""
    from ..services.photo import save_picture

    if request.method == 'POST':
        # Parse dates
        date_available = datetime.strptime(request.form['date_available'], '%Y-%m-%d').date()
        date_until = None
        if request.form.get('date_until'):
            date_until = datetime.strptime(request.form['date_until'], '%Y-%m-%d').date()

        listing = Listing(
            title=request.form['title'],
            description=request.form['description'],
            city=request.form['city'],
            borough=request.form.get('borough', None),  # Only set for NYC
            neighborhood=request.form.get('neighborhood', ''),
            rental_type=request.form['rental_type'],
            room_type=request.form['room_type'],
            price=int(request.form['price']),
            seeking_roommate='seeking_roommate' in request.form,
            date_available=date_available,
            date_until=date_until,
            transportation=request.form.get('transportation', ''),
            size=request.form.get('size', ''),
            furnished=request.form['furnished'],
            vegan_household=request.form['vegan_household'],
            about_lister=request.form['about_lister'],
            lister_relationship=request.form['lister_relationship'],
            rental_requirements=request.form['rental_requirements'],
            pet_policy=request.form['pet_policy'],
            phone_number=request.form.get('phone_number', ''),
            include_phone='include_phone' in request.form,
            user_id=current_user.id
        )

        db.session.add(listing)
        db.session.flush()  # Get the listing ID

        # Handle photo uploads
        photos = request.files.getlist('photos')
        for i, photo in enumerate(photos[:10]):  # Limit to 10 photos
            if photo and photo.filename:
                # Check file size (limit to 10MB)
                photo.seek(0, 2)  # Seek to end
                file_size = photo.tell()
                photo.seek(0)  # Reset to beginning

                if file_size > 10 * 1024 * 1024:  # 10MB limit
                    flash(f'Photo "{photo.filename}" is too large. Please use images under 10MB.', 'warning')
                    continue

                filename = save_picture(photo)
                if filename:  # Only add if save was successful
                    listing_photo = ListingPhoto(
                        filename=filename,
                        listing_id=listing.id,
                        is_primary=(i == 0)  # First photo is primary
                    )
                    db.session.add(listing_photo)

        db.session.commit()
        flash('Your listing draft has been saved!', 'success')
        return redirect(url_for('listing_management.preview', listing_id=listing.id))

    # GET request - show form with empty data
    form_data = {}
    return render_template('create_listing.html',
                         form_data=form_data,
                         major_cities=get_major_cities(),
                         lister_relationships=ListerRelationship.choices(),
                         furnished_options=FurnishedStatus.choices(),
                         vegan_household_options=VeganHouseholdType.choices(),
                         nyc_boroughs=NYCBorough.choices())

@listing_management_bp.route('/edit/<listing_id>', methods=['GET', 'POST'])
@login_required
def edit(listing_id):
    """Edit an existing draft listing"""
    from ..services.photo import save_picture

    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only edit your own listings.', 'danger')
        return redirect(url_for('dashboard.index'))

    # Only allow editing drafts
    if listing.status != ListingStatus.DRAFT.value:
        flash('Only draft listings can be edited.', 'warning')
        return redirect(url_for('dashboard.index'))

    if request.method == 'POST':
        # Parse dates
        date_available = datetime.strptime(request.form['date_available'], '%Y-%m-%d').date()
        date_until = None
        if request.form.get('date_until'):
            date_until = datetime.strptime(request.form['date_until'], '%Y-%m-%d').date()

        # Update all fields
        listing.title = request.form['title']
        listing.description = request.form['description']
        listing.city = request.form['city']
        listing.borough = request.form.get('borough', None)
        listing.neighborhood = request.form.get('neighborhood', '')
        listing.rental_type = request.form['rental_type']
        listing.room_type = request.form['room_type']
        listing.price = int(request.form['price'])
        listing.seeking_roommate = 'seeking_roommate' in request.form
        listing.date_available = date_available
        listing.date_until = date_until
        listing.transportation = request.form.get('transportation', '')
        listing.size = request.form.get('size', '')
        listing.furnished = request.form['furnished']
        listing.vegan_household = request.form['vegan_household']
        listing.about_lister = request.form['about_lister']
        listing.lister_relationship = request.form['lister_relationship']
        listing.rental_requirements = request.form['rental_requirements']
        listing.pet_policy = request.form['pet_policy']
        listing.phone_number = request.form.get('phone_number', '')
        listing.include_phone = 'include_phone' in request.form

        # Handle additional photos
        photos = request.files.getlist('photos')
        for photo in photos[:10-len(listing.photos)]:  # Don't exceed 10 total
            if photo and photo.filename:
                # Check file size (limit to 10MB)
                photo.seek(0, 2)  # Seek to end
                file_size = photo.tell()
                photo.seek(0)  # Reset to beginning

                if file_size > 10 * 1024 * 1024:  # 10MB limit
                    flash(f'Photo "{photo.filename}" is too large. Please use images under 10MB.', 'warning')
                    continue

                filename = save_picture(photo)
                if filename:  # Only add if save was successful
                    listing_photo = ListingPhoto(
                        filename=filename,
                        listing_id=listing.id,
                        is_primary=(len(listing.photos) == 0)
                    )
                    db.session.add(listing_photo)

        db.session.commit()
        flash('Your listing has been updated!', 'success')
        return redirect(url_for('listing_management.preview', listing_id=listing.id))

    # GET request - show form with existing data
    form_data = {
        'title': listing.title,
        'description': listing.description,
        'city': listing.city,
        'borough': listing.borough or '',
        'neighborhood': listing.neighborhood or '',
        'rental_type': listing.rental_type,
        'room_type': listing.room_type,
        'price': listing.price,
        'seeking_roommate': listing.seeking_roommate,
        'date_available': listing.date_available.strftime('%Y-%m-%d') if listing.date_available else '',
        'date_until': listing.date_until.strftime('%Y-%m-%d') if listing.date_until else '',
        'transportation': listing.transportation or '',
        'size': listing.size or '',
        'furnished': listing.furnished,
        'vegan_household': listing.vegan_household,
        'about_lister': listing.about_lister,
        'lister_relationship': listing.lister_relationship,
        'rental_requirements': listing.rental_requirements,
        'pet_policy': listing.pet_policy,
        'phone_number': listing.phone_number or '',
        'include_phone': listing.include_phone
    }
    return render_template('create_listing.html', listing=listing, edit_mode=True, form_data=form_data)

@listing_management_bp.route('/preview/<listing_id>')
@login_required
def preview(listing_id):
    """Preview a draft listing before payment"""
    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only preview your own listings.', 'danger')
        return redirect(url_for('listings.browse'))

    return render_template('preview_listing.html', listing=listing)

@listing_management_bp.route('/pay/<listing_id>')
@login_required
def pay(listing_id):
    """Payment page for a specific listing"""
    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only pay for your own listings.', 'danger')
        return redirect(url_for('listings.browse'))

    # Check if already paid
    if listing.status == ListingStatus.ACTIVE.value:
        flash('This listing is already active!', 'info')
        return redirect(url_for('listings.detail', listing_id=listing.id))

    return render_template('pay_listing.html', listing=listing)

@listing_management_bp.route('/renew/<listing_id>')
@login_required
def renew(listing_id):
    """Renew an expired or deactivated listing - redirect to edit page first"""
    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only renew your own listings.', 'danger')
        return redirect(url_for('dashboard.index'))

    # Check if listing can be renewed (expired or deactivated)
    if listing.status not in [ListingStatus.EXPIRED.value, ListingStatus.DEACTIVATED.value]:
        flash('Only expired or deactivated listings can be renewed.', 'warning')
        return redirect(url_for('dashboard.index'))

    # Convert to draft status so it can be edited
    listing.status = ListingStatus.DRAFT.value
    db.session.commit()

    flash('Listing converted to draft. Please review and update before republishing.', 'info')
    return redirect(url_for('listing_management.edit', listing_id=listing_id))

@listing_management_bp.route('/delete/<listing_id>', methods=['POST'])
@login_required
def delete(listing_id):
    """Delete a draft listing"""
    from ..services.photo import delete_photo_file

    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only delete your own listings.', 'danger')
        return redirect(url_for('dashboard.index'))

    # Only allow deleting drafts, deactivated, and expired listings
    if listing.status not in [ListingStatus.DRAFT.value, ListingStatus.DEACTIVATED.value, ListingStatus.EXPIRED.value]:
        flash('You can only delete draft, deactivated, or expired listings.', 'warning')
        return redirect(url_for('dashboard.index'))

    # Delete associated photos first
    for photo in listing.photos:
        # Delete the actual file from storage (B2 or local)
        delete_photo_file(photo.filename)
        db.session.delete(photo)

    # Delete the listing
    db.session.delete(listing)
    db.session.commit()

    flash('Listing deleted successfully.', 'success')
    return redirect(url_for('dashboard.index'))

@listing_management_bp.route('/deactivate/<listing_id>', methods=['POST'])
@login_required
def deactivate(listing_id):
    """Deactivate an active listing"""
    listing = db.get_or_404(Listing, listing_id)

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only deactivate your own listings.', 'danger')
        return redirect(url_for('dashboard.index'))

    # Only allow deactivating active listings
    if listing.status != ListingStatus.ACTIVE.value:
        flash('Only active listings can be deactivated.', 'warning')
        return redirect(url_for('dashboard.index'))

    # Deactivate the listing
    listing.status = ListingStatus.DEACTIVATED.value
    db.session.commit()

    flash('Listing deactivated successfully.', 'success')
    return redirect(url_for('dashboard.index'))

@listing_management_bp.route('/delete-photo/<photo_id>', methods=['POST'])
@login_required
def delete_photo(photo_id):
    """Delete a photo from a listing"""
    from ..services.photo import delete_photo_file

    photo = db.get_or_404(ListingPhoto, photo_id)
    listing = photo.listing

    # Check if user owns this listing
    if listing.user_id != current_user.id:
        return jsonify({'success': False, 'error': 'Unauthorized'}), 403

    # Only allow deleting photos from draft listings
    if listing.status != ListingStatus.DRAFT.value:
        return jsonify({'success': False, 'error': 'Can only delete photos from draft listings'}), 400

    try:
        # Delete the actual file from storage (B2 or local)
        delete_photo_file(photo.filename)

        # Delete the photo record
        db.session.delete(photo)
        db.session.commit()
        return jsonify({'success': True})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500
