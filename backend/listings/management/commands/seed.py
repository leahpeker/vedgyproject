"""
Management command to seed the database with test data.

Data is loaded from backend/fixtures/seed_data.json so it's easy to update.

Usage:
    python manage.py seed             # Create missing records only
    python manage.py seed --reset     # Delete all seed users+listings, then recreate
"""

import json
from pathlib import Path

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.utils import timezone

from listings.models import Listing, ListingStatus

User = get_user_model()

FIXTURES_PATH = Path(__file__).resolve().parents[3] / "fixtures" / "seed_data.json"

# Seed user emails so we can identify and delete them on --reset
SEED_USER_EMAILS = None  # populated from JSON at runtime


class Command(BaseCommand):
    help = "Seed the database with test users and listings"

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete existing seed data before re-creating it",
        )

    def handle(self, *args, **options):
        data = json.loads(FIXTURES_PATH.read_text())
        seed_emails = {u["email"] for u in data["users"]}

        if options["reset"]:
            deleted, _ = User.objects.filter(email__in=seed_emails).delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} seed user(s) and their listings"))

        self._create_users(data["users"])
        self._create_listings(data["listings"])
        self.stdout.write(self.style.SUCCESS("Seeding complete!"))

    def _create_users(self, users_data):
        for u in users_data:
            obj, created = User.objects.get_or_create(
                email=u["email"],
                defaults={
                    "first_name": u.get("first_name", ""),
                    "last_name": u.get("last_name", ""),
                    "username": u["email"],
                },
            )
            if created:
                obj.set_password(u["password"])
                obj.save()
                self.stdout.write(f"  Created user: {u['email']}")
            else:
                self.stdout.write(f"  Skipped (exists): {u['email']}")

    def _create_listings(self, listings_data):
        existing_titles = set(Listing.objects.values_list("title", flat=True))

        for l in listings_data:
            if l["title"] in existing_titles:
                self.stdout.write(f"  Skipped (exists): {l['title'][:60]}")
                continue

            try:
                user = User.objects.get(email=l["user_email"])
            except User.DoesNotExist:
                self.stderr.write(self.style.ERROR(f"  User not found: {l['user_email']} — skipping listing"))
                continue

            Listing.objects.create(
                user=user,
                title=l["title"],
                description=l.get("description", ""),
                city=l.get("city", ""),
                borough=l.get("borough"),
                rental_type=l.get("rental_type", ""),
                room_type=l.get("room_type", ""),
                price=l.get("price"),
                start_date=l.get("start_date"),
                end_date=l.get("end_date"),
                furnished=l.get("furnished", ""),
                vegan_household=l.get("vegan_household", ""),
                about_lister=l.get("about_lister", ""),
                lister_relationship=l.get("lister_relationship", ""),
                seeking_roommate=l.get("seeking_roommate", False),
                rental_requirements=l.get("rental_requirements"),
                pet_policy=l.get("pet_policy"),
                phone_number=l.get("phone_number"),
                include_phone=l.get("include_phone", False),
                status=ListingStatus.ACTIVE,
                expires_at=timezone.now() + timezone.timedelta(days=30),
            )
            self.stdout.write(f"  Created listing: {l['title'][:60]}")
