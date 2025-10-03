"""Flask application factory"""
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize extensions
db = SQLAlchemy()
bcrypt = Bcrypt()
login_manager = LoginManager()

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
    
    # Initialize extensions with app
    db.init_app(app)
    bcrypt.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message_category = 'info'
    
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
    
    # Initialize database tables on startup
    with app.app_context():
        db.create_all()
        # Create default admin if none exists (only in non-testing mode)
        if not app.config.get('TESTING'):
            from .utils.admin_utils import create_default_admin
            create_default_admin()

    return app