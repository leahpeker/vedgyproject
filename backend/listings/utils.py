"""Photo upload and management utilities"""

import io
import os
import secrets

from django.conf import settings
from django.core.exceptions import ValidationError
from PIL import Image
from pillow_heif import register_heif_opener

# Enable HEIC support
register_heif_opener()

# File upload security settings
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif', 'heic', 'heif'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

# Try to import B2 SDK
try:
    from b2sdk.v2 import B2Api, InMemoryAccountInfo

    B2_AVAILABLE = True
except ImportError:
    B2_AVAILABLE = False


def validate_image_file(file):
    """Validate uploaded image file for security"""
    # Check file size
    if file.size > MAX_FILE_SIZE:
        raise ValidationError("File too large. Maximum size is 10MB.")

    # Check file extension
    file_ext = file.name.lower().split('.')[-1]
    if file_ext not in ALLOWED_EXTENSIONS:
        raise ValidationError(
            f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    # Verify the file is actually an image by trying to open it with PIL
    # Note: We just try to open it, not verify(), since verify() consumes the file
    # and makes it unusable for subsequent operations
    try:
        file.seek(0)
        img = Image.open(file)
        img.load()  # Force loading to check if it's a valid image
        file.seek(0)  # Reset for subsequent use
    except Exception as e:
        raise ValidationError(f"File is not a valid image: {str(e)}")

    return True


def get_photo_url(filename):
    """Get the URL for a photo (B2 or local)"""
    if settings.B2_KEY_ID and settings.B2_BUCKET_NAME:
        # Use S3-compatible URL format which should work better with CORS
        return f"https://{settings.B2_BUCKET_NAME}.s3.us-east-005.backblazeb2.com/{filename}"
    else:
        # Return local URL
        return f"{settings.MEDIA_URL}{filename}"


def get_b2_api():
    """Initialize Backblaze B2 API connection"""
    if not B2_AVAILABLE:
        return None

    if not all(
        [settings.B2_KEY_ID, settings.B2_APPLICATION_KEY, settings.B2_BUCKET_ID]
    ):
        return None

    try:
        info = InMemoryAccountInfo()
        b2_api = B2Api(info)
        b2_api.authorize_account(
            "production", settings.B2_KEY_ID, settings.B2_APPLICATION_KEY
        )
        return b2_api
    except Exception as e:
        print(f"B2 API initialization error: {e}")
        return None


def save_picture_to_b2(form_picture):
    """Save picture to Backblaze B2 storage"""
    try:
        # Validate file first
        validate_image_file(form_picture)

        b2_api = get_b2_api()
        if not b2_api:
            return None

        bucket = b2_api.get_bucket_by_id(settings.B2_BUCKET_ID)

        # Generate unique filename
        random_hex = secrets.token_hex(8)
        picture_fn = f"{random_hex}.jpg"  # Always save as .jpg for smaller files

        # Resize and optimize image in memory
        img = Image.open(form_picture)

        # Apply EXIF orientation to prevent rotation issues
        try:
            from PIL import ImageOps
            img = ImageOps.exif_transpose(img)
        except Exception:
            pass  # If EXIF orientation fails, continue without it

        # Convert to RGB if necessary (for JPEG)
        if img.mode in ("RGBA", "LA", "P"):
            img = img.convert("RGB")

        # Resize to max 800x600 while maintaining aspect ratio
        img.thumbnail((800, 600), Image.Resampling.LANCZOS)

        # Convert to bytes with compression
        img_bytes = io.BytesIO()
        # Save as JPEG with 85% quality for good balance of size/quality
        img.save(img_bytes, format="JPEG", quality=85, optimize=True)
        img_bytes.seek(0)

        # Upload to B2
        file_info = bucket.upload_bytes(
            img_bytes.getvalue(), picture_fn, content_type="image/jpeg"
        )

        return picture_fn
    except ValidationError as e:
        print(f"File validation error: {e}")
        return None
    except Exception as e:
        print(f"B2 upload error: {type(e).__name__}")
        return None


def save_picture(form_picture):
    """Save picture to B2 if configured, otherwise save locally"""
    # Validate file first
    try:
        validate_image_file(form_picture)
    except ValidationError as e:
        print(f"File validation error: {e}")
        return None

    # Try B2 first if configured and available
    if B2_AVAILABLE and settings.B2_KEY_ID:
        b2_filename = save_picture_to_b2(form_picture)
        if b2_filename:
            return b2_filename

    # Fallback to local storage
    random_hex = secrets.token_hex(8)
    picture_fn = f"{random_hex}.jpg"  # Always save as .jpg for smaller files
    picture_path = os.path.join(settings.MEDIA_ROOT, picture_fn)

    # Create upload directory if it doesn't exist
    os.makedirs(os.path.dirname(picture_path), exist_ok=True)

    # Resize and optimize image
    img = Image.open(form_picture)

    # Apply EXIF orientation to prevent rotation issues
    try:
        from PIL import ImageOps
        img = ImageOps.exif_transpose(img)
    except Exception:
        pass  # If EXIF orientation fails, continue without it

    # Convert to RGB if necessary (for JPEG)
    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGB")

    # Resize to max 800x600 while maintaining aspect ratio
    img.thumbnail((800, 600), Image.Resampling.LANCZOS)

    # Save as optimized JPEG
    img.save(picture_path, format="JPEG", quality=85, optimize=True)

    return picture_fn


def delete_photo_from_b2(filename):
    """Delete a photo from Backblaze B2 storage"""
    try:
        b2_api = get_b2_api()
        if not b2_api:
            return False

        bucket = b2_api.get_bucket_by_id(settings.B2_BUCKET_ID)

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
    # Validate filename doesn't contain path traversal
    if '..' in filename or filename.startswith('/'):
        print(f"Invalid filename detected: {filename}")
        return

    if B2_AVAILABLE and settings.B2_KEY_ID:
        # Try to delete from B2
        success = delete_photo_from_b2(filename)
        if success:
            return

    # Fallback: delete local file
    try:
        # Use basename to ensure no directory traversal
        safe_filename = os.path.basename(filename)
        photo_path = os.path.join(settings.MEDIA_ROOT, safe_filename)

        # Ensure the resolved path is within MEDIA_ROOT
        real_path = os.path.realpath(photo_path)
        real_media_root = os.path.realpath(settings.MEDIA_ROOT)

        if not real_path.startswith(real_media_root):
            print(f"Path traversal detected: {filename}")
            return

        if os.path.exists(photo_path):
            os.remove(photo_path)
            print(f"Deleted local file: {filename}")
        else:
            print(f"Local file not found: {filename}")
    except Exception as e:
        print(f"Error deleting local file {filename}: {e}")
