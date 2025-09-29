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

class SubscriptionStatus(Enum):
    NONE = 'none'
    ACTIVE = 'active' 
    CANCELED = 'canceled'
    EXPIRED = 'expired'

class PaddleEventType(Enum):
    SUBSCRIPTION_CREATED = 'subscription_created'
    SUBSCRIPTION_UPDATED = 'subscription_updated'
    SUBSCRIPTION_CANCELLED = 'subscription_cancelled'
    SUBSCRIPTION_PAYMENT_SUCCESS = 'subscription_payment_success'
    SUBSCRIPTION_PAYMENT_FAILED = 'subscription_payment_failed'

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
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///veglistings.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'your-secret-key-change-this-in-production'
app.config['WTF_CSRF_ENABLED'] = False  # Disable CSRF for development
app.config['UPLOAD_FOLDER'] = 'static/uploads'

# Paddle configuration (use sandbox for development)
app.config['PADDLE_VENDOR_ID'] = 'your-paddle-vendor-id'
app.config['PADDLE_API_KEY'] = 'your-paddle-api-key'  
app.config['PADDLE_WEBHOOK_SECRET'] = 'your-paddle-webhook-secret'
app.config['PADDLE_ENVIRONMENT'] = 'sandbox'  # Change to 'production' later

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
    
    # Paddle subscription fields
    subscription_status = db.Column(db.String(20), default=SubscriptionStatus.NONE.value)
    subscription_start_date = db.Column(db.DateTime)
    subscription_end_date = db.Column(db.DateTime)
    paddle_customer_id = db.Column(db.String(100))
    paddle_subscription_id = db.Column(db.String(100))
    
    listings = db.relationship('Listing', backref='user', lazy=True)
    
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def has_paid_account(self):
        """Check if user has an active paid subscription"""
        if not self.subscription_end_date:
            return False
        
        return (self.subscription_status in [SubscriptionStatus.ACTIVE.value, SubscriptionStatus.CANCELED.value] and 
                self.subscription_end_date > datetime.now())
    
    def subscription_expires_soon(self, days=7):
        """Check if subscription expires within specified days"""
        if not self.subscription_end_date:
            return False
        
        from datetime import timedelta
        warning_date = datetime.now() + timedelta(days=days)
        return self.subscription_end_date <= warning_date

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
    
    # New fields
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

class ListingPhoto(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    filename = db.Column(db.String(100), nullable=False)
    listing_id = db.Column(db.String(36), db.ForeignKey('listing.id'), nullable=False)
    is_primary = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

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

@app.route('/listings')
def listings():
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
    
    # Build query
    query = Listing.query
    
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
    # Check if user has paid account
    if not current_user.has_paid_account():
        flash('You need a paid membership to post listings. Please upgrade your account.', 'warning')
        return redirect(url_for('upgrade', next=url_for('create_listing')))
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
        for i, photo in enumerate(photos[:5]):  # Limit to 5 photos
            if photo and photo.filename:
                filename = save_picture(photo)
                listing_photo = ListingPhoto(
                    filename=filename,
                    listing_id=listing.id,
                    is_primary=(i == 0)  # First photo is primary
                )
                db.session.add(listing_photo)
        
        db.session.commit()
        flash('Your listing has been created!', 'success')
        return redirect(url_for('listings'))
    
    return render_template('create_listing.html')

@app.route('/listing/<int:listing_id>')
def listing_detail(listing_id):
    listing = Listing.query.get_or_404(listing_id)
    return render_template('listing_detail.html', listing=listing)

@app.route('/upgrade')
@login_required
def upgrade():
    """Show upgrade to paid account page with Paddle checkout"""
    # Store the referring page for redirect after upgrade
    next_page = request.args.get('next', request.referrer)
    return render_template('upgrade.html', user=current_user, next_page=next_page)

@app.route('/paddle/checkout')
@login_required
def paddle_checkout():
    """Create Paddle checkout session"""
    # For now, return a simple checkout page
    # In production, you'd create a Paddle checkout session
    return render_template('paddle_checkout.html', user=current_user)

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
    
    if event_type == PaddleEventType.SUBSCRIPTION_CREATED.value:
        handle_subscription_created(data)
    elif event_type == PaddleEventType.SUBSCRIPTION_UPDATED.value:
        handle_subscription_updated(data)
    elif event_type == PaddleEventType.SUBSCRIPTION_CANCELLED.value:
        handle_subscription_cancelled(data)
    elif event_type == PaddleEventType.SUBSCRIPTION_PAYMENT_SUCCESS.value:
        handle_subscription_payment_success(data)
    elif event_type == PaddleEventType.SUBSCRIPTION_PAYMENT_FAILED.value:
        handle_subscription_payment_failed(data)
    
    return jsonify({'status': 'success'}), 200

def handle_subscription_created(data):
    """Handle new subscription creation"""
    customer_email = data.get('customer_email')
    subscription_id = data.get('subscription_id')
    customer_id = data.get('customer_id')
    
    user = User.query.filter_by(email=customer_email).first()
    if user:
        user.subscription_status = SubscriptionStatus.ACTIVE.value
        user.paddle_subscription_id = subscription_id
        user.paddle_customer_id = customer_id
        user.subscription_start_date = datetime.now()
        # Set end date based on subscription plan (monthly)
        from datetime import timedelta
        user.subscription_end_date = datetime.now() + timedelta(days=30)
        db.session.commit()

def handle_subscription_updated(data):
    """Handle subscription updates"""
    subscription_id = data.get('subscription_id')
    status = data.get('status')
    
    user = User.query.filter_by(paddle_subscription_id=subscription_id).first()
    if user:
        # Map Paddle status to our enum values
        if status == 'active':
            user.subscription_status = SubscriptionStatus.ACTIVE.value
            from datetime import timedelta
            user.subscription_end_date = datetime.now() + timedelta(days=30)
        elif status == 'cancelled':
            user.subscription_status = SubscriptionStatus.CANCELED.value
        elif status == 'expired':
            user.subscription_status = SubscriptionStatus.EXPIRED.value
        
        db.session.commit()

def handle_subscription_cancelled(data):
    """Handle subscription cancellation"""
    subscription_id = data.get('subscription_id')
    
    user = User.query.filter_by(paddle_subscription_id=subscription_id).first()
    if user:
        user.subscription_status = SubscriptionStatus.CANCELED.value
        # Keep end_date as is - user retains access until end of billing period
        db.session.commit()

def handle_subscription_payment_success(data):
    """Handle successful subscription payment"""
    subscription_id = data.get('subscription_id')
    
    user = User.query.filter_by(paddle_subscription_id=subscription_id).first()
    if user:
        user.subscription_status = SubscriptionStatus.ACTIVE.value
        # Extend subscription for another month
        from datetime import timedelta
        if user.subscription_end_date and user.subscription_end_date > datetime.now():
            user.subscription_end_date = user.subscription_end_date + timedelta(days=30)
        else:
            user.subscription_end_date = datetime.now() + timedelta(days=30)
        db.session.commit()

def handle_subscription_payment_failed(data):
    """Handle failed subscription payment"""
    subscription_id = data.get('subscription_id')
    
    user = User.query.filter_by(paddle_subscription_id=subscription_id).first()
    if user:
        # Don't immediately expire - Paddle usually retries
        # We might want to send a notification email here
        pass

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, port=8000)