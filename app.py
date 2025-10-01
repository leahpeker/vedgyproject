from flask import Flask, render_template, request, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_bcrypt import Bcrypt
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, ValidationError
from wtforms.validators import DataRequired, Email, Length, EqualTo
import os
import secrets
import hashlib
import uuid
from datetime import datetime
from enum import Enum
from PIL import Image
from dotenv import load_dotenv
import io
from functools import wraps

# Try to import B2 SDK, but don't fail if it's not available
try:
    from b2sdk.v2 import InMemoryAccountInfo, B2Api
    B2_AVAILABLE = True
except ImportError:
    B2_AVAILABLE = False
    print("B2 SDK not available - photo uploads will use local storage")

# Load environment variables from .env file
load_dotenv()

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

# Backblaze B2 configuration
app.config['B2_KEY_ID'] = os.environ.get('B2_KEY_ID')
app.config['B2_APPLICATION_KEY'] = os.environ.get('B2_APPLICATION_KEY')
app.config['B2_BUCKET_ID'] = os.environ.get('B2_BUCKET_ID')
app.config['B2_BUCKET_NAME'] = os.environ.get('B2_BUCKET_NAME')

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message_category = 'info'

# Make get_photo_url available in templates
@app.template_global()
def photo_url(filename):
    return get_photo_url(filename)

# Database will be initialized after all models are defined

# Admin decorator
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated or not isinstance(current_user, Admin):
            return redirect(url_for('admin_login'))
        return f(*args, **kwargs)
    return decorated_function

@login_manager.user_loader
def load_user(user_id):
    # Try loading as user first, then as admin
    user = db.session.get(User, user_id)
    if user:
        return user
    return db.session.get(Admin, user_id)

class User(UserMixin, db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    first_name = db.Column(db.String(50), nullable=False)
    last_name = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    phone = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    listings = db.relationship('Listing', backref='user', lazy=True)
    
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)
    
    def can_create_listing(self):
        """Users can always create listings, payment happens per listing"""
        return True

class Admin(UserMixin, db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)

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

class AdminLoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Admin Sign In')

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
    
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    photos = db.relationship('ListingPhoto', backref='listing', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Listing {self.title}>'
    
    
    def get_lister_relationship_display(self):
        """Get the human-readable display text for lister relationship"""
        return ListerRelationship.get_display_text(self.lister_relationship)
    
    def get_furnished_display(self):
        """Get the human-readable display text for furnished status"""
        return FurnishedStatus.get_display_text(self.furnished)
    
    def get_vegan_household_display(self):
        """Get the human-readable display text for vegan household type"""
        return VeganHouseholdType.get_display_text(self.vegan_household)
    
    def activate_listing(self):
        """Activate listing after successful payment"""
        from datetime import timedelta
        self.status = ListingStatus.ACTIVE.value
        self.paid_at = datetime.now()
        self.expires_at = datetime.now() + timedelta(days=30)

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

def get_b2_api():
    """Initialize Backblaze B2 API connection"""
    if not B2_AVAILABLE:
        return None
        
    if not all([app.config['B2_KEY_ID'], app.config['B2_APPLICATION_KEY'], app.config['B2_BUCKET_ID']]):
        return None
    
    try:
        info = InMemoryAccountInfo()
        b2_api = B2Api(info)
        b2_api.authorize_account("production", app.config['B2_KEY_ID'], app.config['B2_APPLICATION_KEY'])
        return b2_api
    except Exception as e:
        print(f"B2 API initialization error: {e}")
        return None

def save_picture_to_b2(form_picture):
    """Save picture to Backblaze B2 storage"""
    try:
        b2_api = get_b2_api()
        if not b2_api:
            return None
            
        bucket = b2_api.get_bucket_by_id(app.config['B2_BUCKET_ID'])
        
        # Generate unique filename
        random_hex = secrets.token_hex(8)
        picture_fn = f"{random_hex}.jpg"  # Always save as .jpg for smaller files
        
        # Resize and optimize image in memory
        img = Image.open(form_picture)
        
        # Convert to RGB if necessary (for JPEG)
        if img.mode in ('RGBA', 'LA', 'P'):
            img = img.convert('RGB')
            
        # Resize to max 800x600 while maintaining aspect ratio
        img.thumbnail((800, 600), Image.Resampling.LANCZOS)
        
        # Convert to bytes with compression
        img_bytes = io.BytesIO()
        # Save as JPEG with 85% quality for good balance of size/quality
        img.save(img_bytes, format='JPEG', quality=85, optimize=True)
        img_bytes.seek(0)
        
        # Upload to B2
        file_info = bucket.upload_bytes(
            img_bytes.getvalue(),
            picture_fn,
            content_type='image/jpeg'
        )
        
        return picture_fn
    except Exception as e:
        print(f"B2 upload error: {e}")
        return None

def save_picture(form_picture):
    """Save picture to B2 if configured, otherwise save locally"""
    # Try B2 first if configured and available
    if B2_AVAILABLE and app.config['B2_KEY_ID']:
        b2_filename = save_picture_to_b2(form_picture)
        if b2_filename:
            return b2_filename
    
    # Fallback to local storage
    random_hex = secrets.token_hex(8)
    picture_fn = f"{random_hex}.jpg"  # Always save as .jpg for smaller files
    picture_path = os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], picture_fn)
    
    # Create upload directory if it doesn't exist
    os.makedirs(os.path.dirname(picture_path), exist_ok=True)
    
    # Resize and optimize image
    img = Image.open(form_picture)
    
    # Convert to RGB if necessary (for JPEG)
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGB')
        
    # Resize to max 800x600 while maintaining aspect ratio
    img.thumbnail((800, 600), Image.Resampling.LANCZOS)
    
    # Save as optimized JPEG
    img.save(picture_path, format='JPEG', quality=85, optimize=True)
    
    return picture_fn

def delete_photo_from_b2(filename):
    """Delete a photo from Backblaze B2 storage"""
    try:
        b2_api = get_b2_api()
        if not b2_api:
            return False
            
        bucket = b2_api.get_bucket_by_id(app.config['B2_BUCKET_ID'])
        
        # Find and delete the file
        file_versions = bucket.ls(filename)
        for file_version, _ in file_versions:
            if file_version.file_name == filename:
                bucket.delete_file_version(file_version.id_, file_version.file_name)
                print(f"Deleted {filename} from B2")
                return True
        
        print(f"File {filename} not found in B2")
        return False
    except Exception as e:
        print(f"Error deleting {filename} from B2: {e}")
        return False

def delete_photo_file(filename):
    """Delete photo from B2 if configured, otherwise delete locally"""
    if B2_AVAILABLE and app.config['B2_KEY_ID']:
        # Try to delete from B2
        success = delete_photo_from_b2(filename)
        if success:
            return
    
    # Fallback: delete local file
    try:
        photo_path = os.path.join(app.root_path, app.config['UPLOAD_FOLDER'], filename)
        if os.path.exists(photo_path):
            os.remove(photo_path)
            print(f"Deleted local file: {filename}")
    except Exception as e:
        print(f"Error deleting local file {filename}: {e}")

def get_photo_url(filename):
    """Get the URL for a photo (B2 or local)"""
    if app.config['B2_KEY_ID'] and app.config['B2_BUCKET_NAME']:
        # Use S3-compatible URL format which should work better with CORS
        return f"https://{app.config['B2_BUCKET_NAME']}.s3.us-east-005.backblazeb2.com/{filename}"
    else:
        # Return local URL
        return url_for('static', filename=f'uploads/{filename}')

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
        return redirect(url_for('preview_listing', listing_id=listing.id))
    
    form_data = {}
    return render_template('create_listing.html', form_data=form_data)

@app.route('/edit/<listing_id>', methods=['GET', 'POST'])
@login_required
def edit_listing(listing_id):
    """Edit an existing draft listing using the create form"""
    listing = db.get_or_404(Listing, listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only edit your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Only allow editing drafts
    if listing.status != ListingStatus.DRAFT.value:
        flash('Only draft listings can be edited.', 'warning')
        return redirect(url_for('dashboard'))
    
    if request.method == 'POST':
        # Update existing listing with form data (same logic as create)
        from datetime import datetime
        
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
        return redirect(url_for('preview_listing', listing_id=listing.id))
    
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

@app.route('/listing/<listing_id>')
def listing_detail(listing_id):
    listing = db.get_or_404(Listing, listing_id)
    
    # Handle payment submission confirmation
    if request.args.get('payment') == 'submitted':
        if listing.status == ListingStatus.DRAFT.value and listing.user_id == current_user.id:
            listing.status = ListingStatus.PAYMENT_SUBMITTED.value
            db.session.commit()
            flash('Payment confirmation received! We\'ll review and activate your listing within 24 hours.', 'success')
        return redirect(url_for('listing_detail', listing_id=listing_id))
    
    return render_template('listing_detail.html', listing=listing)

@app.route('/preview/<listing_id>')
@login_required
def preview_listing(listing_id):
    """Preview a draft listing before payment"""
    listing = db.get_or_404(Listing, listing_id)
    
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
    payment_submitted_listings = [l for l in user_listings if l.status == ListingStatus.PAYMENT_SUBMITTED.value]
    deactivated_listings = [l for l in user_listings if l.status == ListingStatus.DEACTIVATED.value]
    expired_listings = [l for l in user_listings if l.status == ListingStatus.EXPIRED.value]
    
    return render_template('dashboard.html', 
                         active_listings=active_listings,
                         draft_listings=draft_listings,
                         payment_submitted_listings=payment_submitted_listings,
                         deactivated_listings=deactivated_listings,
                         expired_listings=expired_listings)

@app.route('/pay/<listing_id>')
@login_required
def pay_for_listing(listing_id):
    """Payment page for a specific listing"""
    listing = db.get_or_404(Listing, listing_id)
    
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
    """Renew an expired or deactivated listing - redirect to edit page first"""
    listing = db.get_or_404(Listing, listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only renew your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Check if listing can be renewed (expired or deactivated)
    if listing.status not in [ListingStatus.EXPIRED.value, ListingStatus.DEACTIVATED.value]:
        flash('Only expired or deactivated listings can be renewed.', 'warning')
        return redirect(url_for('dashboard'))
    
    # Convert to draft status so it can be edited
    listing.status = ListingStatus.DRAFT.value
    db.session.commit()
    
    flash('Listing converted to draft. Please review and update before republishing.', 'info')
    # Redirect to edit page (we need to create this route)
    return redirect(url_for('edit_listing', listing_id=listing_id))

@app.route('/delete/<listing_id>', methods=['POST'])
@login_required
def delete_listing(listing_id):
    """Delete a draft listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only delete your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Only allow deleting drafts, deactivated, and expired listings
    if listing.status not in [ListingStatus.DRAFT.value, ListingStatus.DEACTIVATED.value, ListingStatus.EXPIRED.value]:
        flash('You can only delete draft, deactivated, or expired listings.', 'warning')
        return redirect(url_for('dashboard'))
    
    # Delete associated photos first
    for photo in listing.photos:
        # Delete the actual file from storage (B2 or local)
        delete_photo_file(photo.filename)
        db.session.delete(photo)
    
    # Delete the listing
    db.session.delete(listing)
    db.session.commit()
    
    flash('Listing deleted successfully.', 'success')
    return redirect(url_for('dashboard'))

@app.route('/deactivate/<listing_id>', methods=['POST'])
@login_required
def deactivate_listing(listing_id):
    """Deactivate an active listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    # Check if user owns this listing
    if listing.user_id != current_user.id:
        flash('You can only deactivate your own listings.', 'danger')
        return redirect(url_for('dashboard'))
    
    # Only allow deactivating active listings
    if listing.status != ListingStatus.ACTIVE.value:
        flash('Only active listings can be deactivated.', 'warning')
        return redirect(url_for('dashboard'))
    
    # Deactivate the listing
    listing.status = ListingStatus.DEACTIVATED.value
    db.session.commit()
    
    flash('Listing deactivated successfully.', 'success')
    return redirect(url_for('dashboard'))

@app.route('/delete-photo/<photo_id>', methods=['POST'])
@login_required
def delete_photo(photo_id):
    """Delete a photo from a listing"""
    from flask import jsonify
    
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

# Admin Routes
@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    """Admin login page"""
    if current_user.is_authenticated and isinstance(current_user, Admin):
        return redirect(url_for('admin_dashboard'))
    
    form = AdminLoginForm()
    if form.validate_on_submit():
        admin = Admin.query.filter_by(email=form.email.data).first()
        if admin and admin.check_password(form.password.data):
            login_user(admin)
            flash('Admin login successful!', 'success')
            return redirect(url_for('admin_dashboard'))
        flash('Invalid admin credentials', 'danger')
    
    return render_template('admin_login.html', form=form)

@app.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    """Admin dashboard showing pending listings"""
    # Get all listings that need approval
    pending_listings = Listing.query.filter_by(status=ListingStatus.PAYMENT_SUBMITTED.value).order_by(Listing.created_at.desc()).all()
    
    return render_template('admin_dashboard.html', pending_listings=pending_listings)

@app.route('/admin/listing/<listing_id>')
@admin_required
def admin_review_listing(listing_id):
    """Admin page to review individual listing"""
    listing = db.get_or_404(Listing, listing_id)
    return render_template('admin_review_listing.html', listing=listing)

@app.route('/admin/approve/<listing_id>', methods=['POST'])
@admin_required
def admin_approve_listing(listing_id):
    """Approve a listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    if listing.status == ListingStatus.PAYMENT_SUBMITTED.value:
        listing.activate_listing()  # Sets to ACTIVE and sets expiration
        db.session.commit()
        flash(f'Listing "{listing.title}" approved and activated!', 'success')
    else:
        flash('Listing cannot be approved in its current state.', 'warning')
    
    return redirect(url_for('admin_dashboard'))

@app.route('/admin/reject/<listing_id>', methods=['POST'])
@admin_required
def admin_reject_listing(listing_id):
    """Reject a listing"""
    listing = db.get_or_404(Listing, listing_id)
    
    if listing.status == ListingStatus.PAYMENT_SUBMITTED.value:
        listing.status = ListingStatus.DRAFT.value
        db.session.commit()
        flash(f'Listing "{listing.title}" rejected and returned to draft.', 'info')
    else:
        flash('Listing cannot be rejected in its current state.', 'warning')
    
    return redirect(url_for('admin_dashboard'))

def create_default_admin():
    """Create default admin if none exists"""
    if Admin.query.first() is None:
        admin_email = os.environ.get('ADMIN_EMAIL')
        admin_password = os.environ.get('ADMIN_PASSWORD')
        admin_name = os.environ.get('ADMIN_NAME', 'Admin')
        
        if admin_email and admin_password:
            admin = Admin(
                email=admin_email,
                name=admin_name
            )
            admin.set_password(admin_password)
            db.session.add(admin)
            db.session.commit()
            print(f"✅ Default admin created: {admin_email}")

# Initialize database and create admin on startup (for production)
with app.app_context():
    db.create_all()
    create_default_admin()

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        create_default_admin()
    
    # Use Railway's PORT environment variable or default to 8000
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)