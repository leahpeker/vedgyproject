"""Context processors for templates"""

from django.conf import settings


def photo_url_processor(request):
    """Make photo URL base available in all templates"""
    # Use local media in DEBUG mode (Python 3.13 has SSL issues with B2)
    # In production, use B2
    if settings.DEBUG:
        # Use local media URL in development
        photo_url_base = f"/{settings.MEDIA_URL}" if not settings.MEDIA_URL.startswith("/") else settings.MEDIA_URL
    elif settings.B2_KEY_ID and settings.B2_BUCKET_NAME:
        # Use B2 S3-compatible URL in production
        photo_url_base = (
            f"https://{settings.B2_BUCKET_NAME}.s3.us-east-005.backblazeb2.com/"
        )
    else:
        # Fallback to local media URL
        photo_url_base = settings.MEDIA_URL

    return {"photo_url": photo_url_base}
