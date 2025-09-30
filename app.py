from flask import Flask, render_template, request, redirect, url_for, jsonify, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt
from flask_wtf import FlaskForm
from flask_wtf.file import FileField, FileAllowed, MultipleFileField
from wtforms import StringField, PasswordField, SubmitField, ValidationError
from wtforms.validators import DataRequired, Email, Length, EqualTo
import os
import secrets
import hashlib
import requests
import hmac
import json
import uuid
from datetime import datetime
from enum import Enum
from PIL import Image
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class ListingStatus(Enum):
    DRAFT = 'draft'
    ACTIVE = 'active'
    EXPIRED = 'expired'
    
class PaddleEventType(Enum):
    TRANSACTION_COMPLETED = 'transaction.completed'
    TRANSACTION_CREATED = 'transaction.created'
    TRANSACTION_UPDATED = 'transaction.updated'

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
            (cls.MIXED_HOUSEHOLD.value, 'Mixed household')
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

app = Flask(__name__)

# Load configuration from environment variables
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///veglistings.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key-change-this-in-production')
app.config['WTF_CSRF_ENABLED'] = False  # Disable CSRF for development
# Use Railway volume for persistent storage in production
if os.environ.get('RAILWAY_ENVIRONMENT'):
    app.config['UPLOAD_FOLDER'] = '/app/uploads'
else:
    app.config['UPLOAD_FOLDER'] = 'static/uploads'

# Paddle configuration
app.config['PADDLE_CLIENT_TOKEN'] = os.environ.get('PADDLE_CLIENT_TOKEN')
app.config['PADDLE_WEBHOOK_SECRET'] = os.environ.get('PADDLE_WEBHOOK_SECRET')
app.config['PADDLE_ENVIRONMENT'] = os.environ.get('PADDLE_ENVIRONMENT', 'sandbox')

# Paddle Price IDs for different amounts (set in production)
app.config['PADDLE_PRICE_ID_LISTING_BUDGET'] = os.environ.get('PADDLE_PRICE_ID_LISTING_BUDGET')
app.config['PADDLE_PRICE_ID_LISTING_MID'] = os.environ.get('PADDLE_PRICE_ID_LISTING_MID') 
app.config['PADDLE_PRICE_ID_LISTING_SUPPORTER'] = os.environ.get('PADDLE_PRICE_ID_LISTING_SUPPORTER')

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(user_id)

class User(UserMixin, db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    phone = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    # Paddle customer info for future transactions
    paddle_customer_id = db.Column(db.String(100))
    
    listings = db.relationship('Listing', backref='user', lazy=True)
    
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def can_create_listing(self):
        """Users can always create listings, payment happens per listing"""
        return True

class RegistrationForm(FlaskForm):
    first_name = StringField('First Name', validators=[DataRequired(), Length(min=1, max=50)])
    last_name = StringField('Last Name', validators=[DataRequired(), Length(min=1, max=50)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    password_confirm = PasswordField('Confirm Password', validators=[
        DataRequired(), EqualTo('password', message='Passwords must match')
    ])
    submit = SubmitField('Sign Up')
    
    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user:
            raise ValidationError('Email already registered. Choose a different one.')

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Sign In')

class Listing(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    city = db.Column(db.String(100), nullable=False)
    borough = db.Column(db.String(50), nullable=True)  # For NYC: Manhattan, Brooklyn, etc.
    neighborhood = db.Column(db.String(100), nullable=True)
    rental_type = db.Column(db.String(20), nullable=False)  # sublet, new_lease, month_to_month
    room_type = db.Column(db.String(20), nullable=False)    # private_room, shared_room, entire_place
    price = db.Column(db.Integer, nullable=False)  # monthly rent in dollars
    seeking_roommate = db.Column(db.Boolean, default=False, nullable=False)
    date_available = db.Column(db.Date, nullable=False)
    date_until = db.Column(db.Date, nullable=True)  # Optional end date for sublets
    transportation = db.Column(db.Text, nullable=True)  # Transportation options/details
    size = db.Column(db.String(50), nullable=True)  # Room/space size
    furnished = db.Column(db.String(30), nullable=False)  # not_furnished, partially_furnished, fully_furnished
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
    paddle_transaction_id = db.Column(db.String(100), nullable=True)
    
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    photos = db.relationship('ListingPhoto', backref='listing', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Listing {self.title}>'
    
    def get_masked_email(self):
        """Generate a masked email address for this listing"""
        listing_hash = hashlib.md5(f"listing_{self.id}_{self.created_at}".encode()).hexdigest()[:8]
        return f"listing-{listing_hash}@veglistings.com"
    
    def get_lister_relationship_display(self):
        """Get the human-readable display text for lister relationship"""
        return ListerRelationship.get_display_text(self.lister_relationship)
    
    def get_furnished_display(self):
        """Get the human-readable display text for furnished status"""
        return FurnishedStatus.get_display_text(self.furnished)
    
    def get_vegan_household_display(self):
        """Get the human-readable display text for vegan household type"""
        return VeganHouseholdType.get_display_text(self.vegan_household)
    
    def activate_listing(self, transaction_id):
        """Activate listing after successful payment"""
        from datetime import timedelta
        self.status = ListingStatus.ACTIVE.value
        self.paid_at = datetime.now()
        self.expires_at = datetime.now() + timedelta(days=30)
        self.paddle_transaction_id = transaction_id

class ListingPhoto(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = db.Column(db.String(100), nullable=False)
    listing_id = db.Column(db.String(36), db.ForeignKey('listing.id'), nullable=False)
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

def expire_old_listings():
    """Mark listings as expired if they're past their expiration date"""
    from datetime import datetime
    expired_listings = Listing.query.filter(
        Listing.status == ListingStatus.ACTIVE.value,
        Listing.expires_at <= datetime.now()
    ).all()
    
    for listing in expired_listings:
        listing.status = ListingStatus.EXPIRED.value
    
    if expired_listings:
        db.session.commit()
    
    return len(expired_listings)

def save_picture(form_picture):
    random_hex = secrets.token_hex(8)
    _, f_ext = os.path.splitext(form_picture.filename)
    picture_fn = random_hex + f_ext
    picture_path = os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], picture_fn)
    
    # Create upload directory if it doesn't exist
    os.makedirs(os.path.dirname(picture_path), exist_ok=True)
    
    # Resize image
    output_size = (800, 600)
    img = Image.open(form_picture)
    img.thumbnail(output_size)
    img.save(picture_path)
    
    return picture_fn

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/terms')
def terms():
    return render_template('terms.html')

@app.route('/privacy')
def privacy():
    return render_template('privacy.html')

@app.route('/listings')
def listings():
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

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(
            first_name=form.first_name.data, 
            last_name=form.last_name.data,
            email=form.email.data
        )
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        
        # Automatically log in the user after signup
        login_user(user)
        flash(f'Welcome to VegListings, {user.first_name}!', 'success')
        
        # Redirect to next page or index
        next_page = request.args.get('next')
        return redirect(next_page) if next_page else redirect(url_for('index'))
    
    return render_template('signup.html', form=form)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(form.password.data):
            login_user(user)
            next_page = request.args.get('next')
            flash(f'Welcome back, {user.first_name}!', 'success')
            return redirect(next_page) if next_page else redirect(url_for('index'))
        flash('Invalid email or password', 'danger')
    
    return render_template('login.html', form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('index'))

@app.route('/create', methods=['GET', 'POST'])
@login_required
def create_listing():
    if request.method == 'POST':
        from datetime import datetime
        
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
                filename = save_picture(photo)
                listing_photo = ListingPhoto(
                    filename=filename,
                    listing_id=listing.id,
                    is_primary=(i == 0)  # First photo is primary
                )
                db.session.add(listing_photo)
        
        db.session.commit()
        flash('Your listing draft has been saved!', 'success')
        return redirect(url_for('preview_listing', listing_id=listing.id))
    
    return render_template('create_listing.html')

@app.route('/listing/<listing_id>')
def listing_detail(listing_id):
    listing = Listing.query.get_or_404(listing_id)
    return render_template('listing_detail.html', listing=listing)

@app.route('/preview/<listing_id>')
@login_required
def preview_listing(listing_id):
    """Preview a draft listing before payment"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only preview your own listings.', 'danger')
        return redirect(url_for('listings'))
    
    return render_template('preview_listing.html', listing=listing)

@app.route('/dashboard')
@login_required
def dashboard():
    """User dashboard to manage their listings"""
    # Get all user's listings
    user_listings = Listing.query.filter_by(user_id=current_user.id).order_by(Listing.created_at.desc()).all()
    
    # Expire old listings before showing dashboard
    expire_old_listings()
    
    # Categorize listings
    active_listings = [l for l in user_listings if l.status == ListingStatus.ACTIVE.value]
    draft_listings = [l for l in user_listings if l.status == ListingStatus.DRAFT.value]
    expired_listings = [l for l in user_listings if l.status == ListingStatus.EXPIRED.value]
    
    return render_template('dashboard.html', 
                         active_listings=active_listings,
                         draft_listings=draft_listings,
                         expired_listings=expired_listings)

@app.route('/pay/<listing_id>')
@login_required
def pay_for_listing(listing_id):
    """Payment page for a specific listing"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only pay for your own listings.', 'danger')
        return redirect(url_for('listings'))
    
    # Check if already paid
    if listing.status == ListingStatus.ACTIVE.value:
        flash('This listing is already active!', 'info')
        return redirect(url_for('listing_detail', listing_id=listing.id))
    
    # No need to change status - draft stays draft until paid
    
    return render_template('pay_listing.html', listing=listing)

@app.route('/renew/<listing_id>')
@login_required
def renew_listing(listing_id):
    """Renew an expired listing"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only renew your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Check if listing can be renewed (expired or active)
    if listing.status not in [ListingStatus.EXPIRED.value, ListingStatus.ACTIVE.value]:
        flash('This listing cannot be renewed.', 'warning')
        return redirect(url_for('dashboard'))
    
    return render_template('renew_listing.html', listing=listing)

@app.route('/delete/<listing_id>', methods=['POST'])
@login_required
def delete_listing(listing_id):
    """Delete a draft listing"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only delete your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Only allow deleting drafts
    if listing.status != ListingStatus.DRAFT.value:
        flash('You can only delete draft listings.', 'warning')
        return redirect(url_for('dashboard'))
    
    # Delete associated photos first
    for photo in listing.photos:
        # Delete the actual file
        photo_path = os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], photo.filename)
        if os.path.exists(photo_path):
            os.remove(photo_path)
        db.session.delete(photo)
    
    # Delete the listing
    db.session.delete(listing)
    db.session.commit()
    
    flash('Draft listing deleted successfully.', 'success')
    return redirect(url_for('dashboard'))

@app.route('/upgrade')
@login_required
def upgrade():
    """Show upgrade to paid account page with Paddle checkout"""
    # Store the referring page for redirect after upgrade
    next_page = request.args.get('next', request.referrer)
    return render_template('upgrade.html', user=current_user, next_page=next_page)

@app.route('/paddle/checkout/listing/<int:amount>/<listing_id>')
@login_required
def paddle_checkout_listing(amount, listing_id):
    """Create Paddle checkout session for listing payment"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only pay for your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # In production, create a real Paddle checkout session
    checkout_data = {
        'amount': amount,
        'listing_id': listing_id,
        'listing_title': listing.title,
        'user_email': current_user.email,
        'type': 'listing'
    }
    
    return render_template('paddle_checkout.html', **checkout_data)

@app.route('/paddle/checkout/renewal/<int:amount>/<listing_id>')
@login_required
def paddle_checkout_renewal(amount, listing_id):
    """Create Paddle checkout session for listing renewal"""
    listing = Listing.query.get_or_404(listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only renew your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # In production, create a real Paddle checkout session
    checkout_data = {
        'amount': amount,
        'listing_id': listing_id,
        'listing_title': listing.title,
        'user_email': current_user.email,
        'type': 'renewal'
    }
    
    return render_template('paddle_checkout.html', **checkout_data)

@app.route('/paddle/webhook', methods=['POST'])
def paddle_webhook():
    """Handle Paddle webhook notifications"""
    # Verify webhook signature
    signature = request.headers.get('paddle-signature')
    webhook_secret = app.config['PADDLE_WEBHOOK_SECRET']
    
    # In production, verify the webhook signature
    # payload = request.get_data()
    # expected_signature = hmac.new(
    #     webhook_secret.encode(), payload, hashlib.sha256
    # ).hexdigest()
    
    data = request.get_json()
    event_type = data.get('event_type')
    
    if event_type == PaddleEventType.TRANSACTION_COMPLETED.value:
        handle_transaction_completed(data)
    elif event_type == PaddleEventType.TRANSACTION_CREATED.value:
        handle_transaction_created(data)
    elif event_type == PaddleEventType.TRANSACTION_UPDATED.value:
        handle_transaction_updated(data)
    
    return jsonify({'status': 'success'}), 200

def handle_transaction_completed(data):
    """Handle completed listing payment or renewal"""
    transaction_id = data.get('transaction_id')
    customer_email = data.get('customer_email')
    custom_data = data.get('custom_data', {})
    listing_id = custom_data.get('listing_id')
    is_renewal = custom_data.get('renewal', False)
    
    if listing_id:
        listing = Listing.query.get(listing_id)
        if listing:
            if is_renewal:
                # Handle renewal - extend expiration date
                from datetime import timedelta
                if listing.status == ListingStatus.EXPIRED.value or listing.status == ListingStatus.ACTIVE.value:
                    listing.status = ListingStatus.ACTIVE.value
                    listing.paddle_transaction_id = transaction_id
                    
                    # If expired, start from now. If active, extend from current expiration
                    if listing.status == ListingStatus.EXPIRED.value or not listing.expires_at:
                        listing.paid_at = datetime.now()
                        listing.expires_at = datetime.now() + timedelta(days=30)
                    else:
                        # Extend from current expiration date
                        listing.expires_at = listing.expires_at + timedelta(days=30)
                    
                    db.session.commit()
            else:
                # Handle new listing payment
                if listing.status == ListingStatus.DRAFT.value:
                    listing.activate_listing(transaction_id)
                    db.session.commit()

def handle_transaction_created(data):
    """Handle transaction creation - not much to do here"""
    pass

def handle_transaction_updated(data):
    """Handle transaction updates"""
    # Could handle status changes here if needed
    pass


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    
    # Use Railway's PORT environment variable or default to 8000
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)