"""Public static page routes"""
from flask import Blueprint, render_template

public_bp = Blueprint('public', __name__)

@public_bp.route('/')
def index():
    return render_template('index.html')

@public_bp.route('/terms')
def terms():
    return render_template('terms.html')

@public_bp.route('/privacy')
def privacy():
    return render_template('privacy.html')
