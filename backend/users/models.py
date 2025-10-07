"""User models for VedgyProject"""

import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user model"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    # Django requires username field, we'll use email
    username = models.CharField(max_length=150, unique=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    def save(self, *args, **kwargs):
        """Auto-set username to email"""
        if not self.username:
            self.username = self.email
        super().save(*args, **kwargs)

    def can_create_listing(self):
        """Users can always create listings"""
        return True

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
