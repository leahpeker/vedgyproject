from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, re_path
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

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
    # Flutter catch-all — must be last. GoRouter handles client-side routing,
    # so any path that Django doesn't own serves index.html.
    # Exclude static asset extensions so WhiteNoise can serve Flutter build files.
    re_path(
        r"^(?!.*\.(js|css|json|wasm|png|jpg|ico|svg|ttf|otf|woff|woff2|map)$).*$",
        TemplateView.as_view(template_name="flutter/index.html"),
    ),
]

# Serve media files in development (photos still need to load locally).
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
