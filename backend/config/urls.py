"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
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
    path("admin/", admin.site.urls),  # Django admin panel
    path("api/", api.urls),  # API endpoints
    path("", include("listings.urls")),  # All app routes at root
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
