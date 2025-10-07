"""Context processors for templates"""

from django.conf import settings


def photo_url_processor(request):
    """Make photo URL base available in all templates"""
    if settings.B2_KEY_ID and settings.B2_BUCKET_NAME:
        # Use B2 S3-compatible URL
        photo_url_base = (
            f"https://{settings.B2_BUCKET_NAME}.s3.us-east-005.backblazeb2.com/"
        )
    else:
        # Use local media URL
        photo_url_base = settings.MEDIA_URL

    return {"photo_url": photo_url_base}
