"""Security utility functions"""
from urllib.parse import urlparse, urljoin
from flask import request

def is_safe_url(target):
    """Check if a redirect URL is safe (same domain)"""
    if not target:
        return False

    ref_url = urlparse(request.host_url)
    test_url = urlparse(urljoin(request.host_url, target))

    # Must have same scheme and netloc (domain)
    return test_url.scheme in ('http', 'https') and ref_url.netloc == test_url.netloc

def get_safe_redirect(next_param, default_endpoint):
    """Get a safe redirect URL or return default"""
    from flask import url_for

    if next_param and is_safe_url(next_param):
        return next_param
    return url_for(default_endpoint)
