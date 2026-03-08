"""Password-reset URL patterns (kept for the email confirm flow in production)."""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.CustomPasswordResetView.as_view(), name="password_reset"),
    path(
        "done/", views.CustomPasswordResetDoneView.as_view(), name="password_reset_done"
    ),
    path(
        "<uidb64>/<token>/",
        views.CustomPasswordResetConfirmView.as_view(),
        name="password_reset_confirm",
    ),
    path(
        "complete/",
        views.CustomPasswordResetCompleteView.as_view(),
        name="password_reset_complete",
    ),
]
