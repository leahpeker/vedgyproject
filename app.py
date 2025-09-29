from flask import Flask, render_template, request, redirect, url_for, jsonify
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///veglistings.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    listings = db.relationship('Listing', backref='user', lazy=True)

class Listing(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    location = db.Column(db.String(100), nullable=False)
    rental_type = db.Column(db.String(20), nullable=False)  # sublet, new_lease, month_to_month
    room_type = db.Column(db.String(20), nullable=False)    # private_room, shared_room, entire_place
    price = db.Column(db.Integer, nullable=False)  # monthly rent in dollars
    seeking_roommate = db.Column(db.Boolean, default=False, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())

    def __repr__(self):
        return f'<Listing {self.title}>'

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/listings')
def listings():
    # Get filter parameters
    rental_type = request.args.get('rental_type')
    room_type = request.args.get('room_type')
    seeking_roommate = request.args.get('seeking_roommate')
    location_search = request.args.get('location')
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
    if location_search:
        # Improved location search - case insensitive and partial matching
        search_terms = location_search.lower().split()
        for term in search_terms:
            query = query.filter(Listing.location.ilike(f'%{term}%'))
    if min_price:
        query = query.filter(Listing.price >= int(min_price))
    if max_price:
        query = query.filter(Listing.price <= int(max_price))
    
    listings = query.order_by(Listing.created_at.desc()).all()
    
    # If this is an HTMX request, return just the listings container
    if request.headers.get('HX-Request'):
        return render_template('_listings_partial.html', listings=listings)
    
    return render_template('listings.html', listings=listings)

@app.route('/create', methods=['GET', 'POST'])
def create_listing():
    if request.method == 'POST':
        # For now, create a default user if none exists
        user = User.query.first()
        if not user:
            user = User(username='demo_user', email='demo@example.com')
            db.session.add(user)
            db.session.commit()
        
        listing = Listing(
            title=request.form['title'],
            description=request.form['description'],
            location=request.form['location'],
            rental_type=request.form['rental_type'],
            room_type=request.form['room_type'],
            price=int(request.form['price']),  # Store as whole dollars
            seeking_roommate='seeking_roommate' in request.form,
            user_id=user.id
        )
        
        db.session.add(listing)
        db.session.commit()
        
        return redirect(url_for('listings'))
    
    return render_template('create_listing.html')

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True)