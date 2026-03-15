"""Management command to expire active listings past their expires_at date."""

from django.core.management.base import BaseCommand
from django.utils import timezone

from listings.models import Listing, ListingStatus


class Command(BaseCommand):
    help = "Transition active listings past their expires_at to expired status."

    def handle(self, *args, **options):
        count = Listing.objects.filter(
            status=ListingStatus.ACTIVE,
            expires_at__lte=timezone.now(),
        ).update(status=ListingStatus.EXPIRED)

        self.stdout.write(f"Expired {count} listing(s).")
