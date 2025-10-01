"""Test admin authentication"""
import pytest
from app import db, Admin, Listing, ListingStatus

class TestAdminAuth:
    """Test admin authentication"""
    
    def test_admin_login_valid_credentials(self, client, test_admin):
        """Test admin login with valid credentials"""
        response = client.post('/admin/login', data={
            'email': 'admin@example.com',
            'password': 'adminpass123'
        })
        
        # Should redirect after successful login
        assert response.status_code == 302
    
    def test_admin_login_invalid_credentials(self, client, test_admin):
        """Test admin login with invalid credentials"""
        response = client.post('/admin/login', data={
            'email': 'admin@example.com',
            'password': 'wrongpassword'
        })
        
        # Should show login form again (not redirect)
        assert response.status_code == 200
    
    def test_admin_login_nonexistent_admin(self, client):
        """Test admin login with nonexistent admin"""
        response = client.post('/admin/login', data={
            'email': 'fake@example.com',
            'password': 'password123'
        })
        
        # Should show login form again (not redirect)
        assert response.status_code == 200
    
    def test_admin_dashboard_requires_auth(self, client):
        """Test admin dashboard requires authentication"""
        response = client.get('/admin/dashboard')
        
        # Should redirect to admin login
        assert response.status_code == 302
        assert '/admin/login' in response.headers['Location']
    
    def test_admin_dashboard_access(self, client, logged_in_admin):
        """Test admin can access dashboard"""
        response = client.get('/admin/dashboard')
        
        # Should show dashboard
        assert response.status_code == 200
        assert b'Admin Dashboard' in response.data
    
    def test_regular_user_cannot_access_admin(self, client, logged_in_user):
        """Test regular user cannot access admin routes"""
        response = client.get('/admin/dashboard')
        
        # Should redirect to admin login
        assert response.status_code == 302
        assert '/admin/login' in response.headers['Location']
    
    def test_admin_approve_listing(self, client, logged_in_admin, payment_submitted_listing):
        """Test admin can approve listings"""
        response = client.post(f'/admin/approve/{payment_submitted_listing.id}')
        
        # Should redirect after approval
        assert response.status_code == 302
        
        # Listing should be activated
        from app import ListingStatus
        updated_listing = db.session.get(Listing, payment_submitted_listing.id)
        assert updated_listing.status == ListingStatus.ACTIVE.value
    
    def test_admin_reject_listing(self, client, logged_in_admin, payment_submitted_listing):
        """Test admin can reject listings"""
        response = client.post(f'/admin/reject/{payment_submitted_listing.id}')
        
        # Should redirect after rejection
        assert response.status_code == 302
        
        # Listing should be returned to draft status
        updated_listing = db.session.get(Listing, payment_submitted_listing.id)
        assert updated_listing.status == ListingStatus.DRAFT.value