"""Photo upload and management services"""
import os
import io
import secrets
from flask import current_app, url_for
from PIL import Image

# Try to import B2 SDK
try:
    from b2sdk.v2 import InMemoryAccountInfo, B2Api
    B2_AVAILABLE = True
except ImportError:
    B2_AVAILABLE = False

def get_photo_url(filename):
    """Get the URL for a photo (B2 or local)"""
    if current_app.config['B2_KEY_ID'] and current_app.config['B2_BUCKET_NAME']:
        # Use S3-compatible URL format which should work better with CORS
        return f"https://{current_app.config['B2_BUCKET_NAME']}.s3.us-east-005.backblazeb2.com/{filename}"
    else:
        # Return local URL
        return url_for('static', filename=f'uploads/{filename}')

def get_b2_api():
    """Initialize Backblaze B2 API connection"""
    if not B2_AVAILABLE:
        return None
        
    if not all([current_app.config['B2_KEY_ID'], current_app.config['B2_APPLICATION_KEY'], current_app.config['B2_BUCKET_ID']]):
        return None
    
    try:
        info = InMemoryAccountInfo()
        b2_api = B2Api(info)
        b2_api.authorize_account("production", current_app.config['B2_KEY_ID'], current_app.config['B2_APPLICATION_KEY'])
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
            
        bucket = b2_api.get_bucket_by_id(current_app.config['B2_BUCKET_ID'])
        
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
    if B2_AVAILABLE and current_app.config['B2_KEY_ID']:
        b2_filename = save_picture_to_b2(form_picture)
        if b2_filename:
            return b2_filename
    
    # Fallback to local storage
    random_hex = secrets.token_hex(8)
    picture_fn = f"{random_hex}.jpg"  # Always save as .jpg for smaller files
    picture_path = os.path.join(current_app.root_path, current_app.config['UPLOAD_FOLDER'], picture_fn)
    
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
            
        bucket = b2_api.get_bucket_by_id(current_app.config['B2_BUCKET_ID'])
        
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
    if B2_AVAILABLE and current_app.config['B2_KEY_ID']:
        # Try to delete from B2
        success = delete_photo_from_b2(filename)
        if success:
            return
    
    # Fallback: delete local file
    try:
        photo_path = os.path.join(current_app.root_path, current_app.config['UPLOAD_FOLDER'], filename)
        if os.path.exists(photo_path):
            os.remove(photo_path)
            print(f"Deleted local file: {filename}")
        else:
            print(f"Local file not found: {filename}")
    except Exception as e:
        print(f"Error deleting local file {filename}: {e}")