"""Admin configuration for users app"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin configuration for User model"""

    list_display = ["email", "first_name", "last_name", "is_staff", "created_at"]
    search_fields = ["email", "first_name", "last_name"]
    ordering = ["-created_at"]
