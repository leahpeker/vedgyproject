"""URL patterns for listings app"""

from django.urls import path

from . import views

urlpatterns = [
    # Public pages
    path("", views.index, name="index"),
    path("browse/", views.browse_listings, name="browse"),
    path("listing/<uuid:listing_id>/", views.listing_detail, name="listing_detail"),
    path("privacy/", views.privacy_policy, name="privacy"),
    path("about/", views.about, name="about"),
    path("contact/", views.contact, name="contact"),
    # Auth
    path("signup/", views.signup, name="signup"),
    path("login/", views.user_login, name="login"),
    path("logout/", views.user_logout, name="logout"),
    # Password reset
    path(
        "password-reset/",
        views.CustomPasswordResetView.as_view(),
        name="password_reset",
    ),
    path(
        "password-reset/done/",
        views.CustomPasswordResetDoneView.as_view(),
        name="password_reset_done",
    ),
    path(
        "password-reset/<uidb64>/<token>/",
        views.CustomPasswordResetConfirmView.as_view(),
        name="password_reset_confirm",
    ),
    path(
        "password-reset/complete/",
        views.CustomPasswordResetCompleteView.as_view(),
        name="password_reset_complete",
    ),
    # User dashboard
    path("dashboard/", views.dashboard, name="dashboard"),
    # Listing management
    path("create/", views.create_listing, name="create_listing"),
    path("edit/<uuid:listing_id>/", views.edit_listing, name="edit_listing"),
    path("preview/<uuid:listing_id>/", views.listing_preview, name="listing_preview"),
    path("pay/<uuid:listing_id>/", views.pay_listing, name="pay_listing"),
    path("delete/<uuid:listing_id>/", views.delete_listing, name="delete_listing"),
    path(
        "deactivate/<uuid:listing_id>/",
        views.deactivate_listing,
        name="deactivate_listing",
    ),
    path("photo/delete/<uuid:photo_id>/", views.delete_photo, name="delete_photo"),
    # Admin actions (for staff users)
    path(
        "approve/<uuid:listing_id>/",
        views.admin_approve_listing,
        name="admin_approve",
    ),
    path(
        "reject/<uuid:listing_id>/",
        views.admin_reject_listing,
        name="admin_reject",
    ),
]
