#!/usr/bin/env python3
"""
Script to create an admin user
Run with: python create_admin.py
"""

from app import app, db, Admin

def create_admin():
    with app.app_context():
        # Check if admin already exists
        email = input("Enter admin email: ")
        existing_admin = Admin.query.filter_by(email=email).first()
        
        if existing_admin:
            print(f"Admin with email {email} already exists!")
            return
        
        # Get admin details
        name = input("Enter admin name: ")
        password = input("Enter admin password: ")
        
        # Create admin
        admin = Admin(
            email=email,
            name=name
        )
        admin.set_password(password)
        
        # Save to database
        db.session.add(admin)
        db.session.commit()
        
        print(f"✅ Admin user created successfully!")
        print(f"Email: {email}")
        print(f"Name: {name}")
        print(f"You can now login at /admin/login")

if __name__ == "__main__":
    create_admin()