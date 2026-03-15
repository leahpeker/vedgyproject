import os

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.generic import TemplateView
from ninja import NinjaAPI

from listings.api import router as listings_router
from users.api import router as auth_router

api = NinjaAPI(
    title="Vedgy API",
    version="1.0.0",
)

api.add_router("/auth/", auth_router, tags=["auth"])
api.add_router("/listings/", listings_router, tags=["listings"])

# Use the Flutter catch-all only on Railway (RAILWAY_ENVIRONMENT is set by the
# platform). Locally — including during tests — keep the legacy Django views so
# test_views.py continues to exercise the server-rendered templates.
_on_railway = bool(os.environ.get("RAILWAY_ENVIRONMENT"))

if _on_railway:
    # Production: Flutter SPA handles all UI. Django serves only the API, admin,
    # and the password-reset confirm flow (email links still point here).
    urlpatterns = [
        path("admin/", admin.site.urls),
        path("api/", api.urls),
        # Password-reset templates kept for the email confirm link flow.
        path("password-reset/", include("listings.urls_password_reset")),
        # Flutter catch-all — must be last. GoRouter handles client-side routing,
        # so any path that Django doesn't own serves index.html.
        # Exclude static asset extensions so WhiteNoise can serve Flutter build files.
        re_path(
            r"^(?!.*\.(js|css|json|wasm|png|jpg|ico|svg|ttf|otf|woff|woff2|map)$).*$",
            TemplateView.as_view(template_name="flutter/index.html"),
        ),
    ]
else:
    # Development / CI: serve the legacy server-rendered Django views and media.
    urlpatterns = [
        path("admin/", admin.site.urls),
        path("api/", api.urls),
        path("", include("listings.urls")),
    ]
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
