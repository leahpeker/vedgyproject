"""Flask application factory"""
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_bcrypt import Bcrypt
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
bcrypt = Bcrypt()
login_manager = LoginManager()
limiter = Limiter(
    get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri="memory://"
)

def create_app():
    """Create and configure Flask application"""
    # Point Flask to templates and static folders in root directory
    app = Flask(__name__, 
                template_folder='../../templates',
                static_folder='../../static')
    
    # Configuration
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///veglistings.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key-change-this-in-production')
    app.config['WTF_CSRF_ENABLED'] = True  # Enable CSRF protection

    # Session Security
    app.config['SESSION_COOKIE_SECURE'] = os.environ.get('RAILWAY_ENVIRONMENT') is not None  # HTTPS only in prod
    app.config['SESSION_COOKIE_HTTPONLY'] = True  # Prevent JavaScript access
    app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'  # CSRF protection
    app.config['PERMANENT_SESSION_LIFETIME'] = 604800  # 7 days in seconds
    
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
    
    # Initialize extensions with app
    db.init_app(app)
    bcrypt.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message_category = 'info'
    limiter.init_app(app)
    
    # Initialize routes with database instance
    from .routes.auth import init_auth_routes
    from .routes.admin import init_admin_routes
    from .routes.listings import init_listings_routes
    from .routes.listing_management import init_listing_management_routes
    from .routes.dashboard import init_dashboard_routes
    init_auth_routes(db)
    init_admin_routes(db)
    init_listings_routes(db)
    init_listing_management_routes(db)
    init_dashboard_routes(db)

    # Import models for login_manager
    from .models import User, Admin

    @login_manager.user_loader
    def load_user(user_id):
        # Try loading as user first, then as admin
        user = db.session.get(User, user_id)
        if user:
            return user
        return db.session.get(Admin, user_id)

    # Register blueprints
    from .routes import auth_bp, admin_bp, public_bp, listings_bp, listing_management_bp, dashboard_bp
    app.register_blueprint(public_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(listings_bp)
    app.register_blueprint(listing_management_bp)
    app.register_blueprint(dashboard_bp)
    
    # Make get_photo_url available in templates
    from .services.photo import get_photo_url
    @app.template_global()
    def photo_url(filename):
        return get_photo_url(filename)

    # Make csrf_token available in all templates
    from flask_wtf.csrf import generate_csrf
    @app.context_processor
    def inject_csrf_token():
        return dict(csrf_token=generate_csrf)

    # Add security headers
    @app.after_request
    def add_security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'SAMEORIGIN'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        # CSP - allow Tailwind CDN, Alpine.js, Backblaze B2 for images, and payment providers
        response.headers['Content-Security-Policy'] = "default-src 'self'; img-src 'self' https://*.backblazeb2.com data:; style-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com https://cdn.jsdelivr.net; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdn.jsdelivr.net https://js.stripe.com; frame-src https://js.stripe.com; font-src 'self' https://cdn.jsdelivr.net;"
        return response
    
    # Initialize database tables on startup
    with app.app_context():
        db.create_all()
        # Create default admin if none exists (only in non-testing mode)
        if not app.config.get('TESTING'):
            from .utils.admin_utils import create_default_admin
            create_default_admin()

    return app