"""Authentication routes"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user, login_required, current_user
from ..models import User, Admin
from ..forms import SignupForm, LoginForm, AdminLoginForm
from ..utils.security import get_safe_redirect
from .. import limiter

# These will be imported from the main app
db = None

def init_auth_routes(database):
    """Initialize routes with db instance"""
    global db
    db = database

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/signup', methods=['GET', 'POST'])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for('public.index'))
    
    form = SignupForm()
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

        # Redirect to safe URL or index
        return redirect(get_safe_redirect(request.args.get('next'), 'public.index'))
    
    return render_template('signup.html', form=form)

@auth_bp.route('/login', methods=['GET', 'POST'])
@limiter.limit("5 per minute")
def login():
    if current_user.is_authenticated:
        return redirect(url_for('public.index'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(form.password.data):
            login_user(user)
            flash(f'Welcome back, {user.first_name}!', 'success')
            return redirect(get_safe_redirect(request.args.get('next'), 'public.index'))
        flash('Invalid email or password', 'danger')
    
    return render_template('login.html', form=form)

@auth_bp.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('public.index'))