"""Django admin configuration"""

from django.contrib import admin
from django.urls import reverse
from django.utils.html import format_html

from .models import Listing, ListingPhoto, ListingStatus


# User admin is now in users/admin.py


class ListingPhotoInline(admin.TabularInline):
    """Inline admin for listing photos"""

    model = ListingPhoto
    extra = 1
    readonly_fields = ("uploaded_at",)


@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin):
    """Admin interface for Listing model"""

    list_display = (
        "title",
        "user_info",
        "city",
        "price",
        "status",
        "created_at",
        "preview_link",
    )
    list_filter = (
        "status",
        "city",
        "rental_type",
        "room_type",
        "vegan_household",
        "created_at",
    )
    search_fields = (
        "title",
        "description",
        "user__email",
        "user__first_name",
        "user__last_name",
    )
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "user_metadata", "listing_preview")
    inlines = [ListingPhotoInline]

    def user_info(self, obj):
        """Display user with link to their profile"""
        return format_html(
            '<a href="{}">{}</a>',
            reverse("admin:users_user_change", args=[obj.user.id]),
            obj.user.email,
        )

    user_info.short_description = "User"

    def preview_link(self, obj):
        """Link to view listing on site"""
        return format_html(
            '<a href="{}" target="_blank">View on site</a>',
            reverse("listing_detail", args=[obj.id]),
        )

    preview_link.short_description = "Preview"

    def user_metadata(self, obj):
        """Display user metadata"""
        total_listings = obj.user.listings.count()
        active_listings = obj.user.listings.filter(status=ListingStatus.ACTIVE).count()
        return format_html(
            """
            <div style="padding: 15px; border: 1px solid var(--border-color, #ccc); border-radius: 5px; background: var(--body-bg, #fff);">
                <h3 style="margin-top: 0; color: var(--body-fg, #333);">User Information</h3>
                <p style="color: var(--body-fg, #333);"><strong>Name:</strong> {} {}</p>
                <p style="color: var(--body-fg, #333);"><strong>Email:</strong> {}</p>
                <p style="color: var(--body-fg, #333);"><strong>Phone:</strong> {}</p>
                <p style="color: var(--body-fg, #333);"><strong>Total Listings:</strong> {}</p>
                <p style="color: var(--body-fg, #333);"><strong>Active Listings:</strong> {}</p>
                <p style="color: var(--body-fg, #333);"><strong>Member Since:</strong> {}</p>
            </div>
            """,
            obj.user.first_name,
            obj.user.last_name,
            obj.user.email,
            obj.user.phone or "Not provided",
            total_listings,
            active_listings,
            obj.user.created_at.strftime("%B %d, %Y"),
        )

    user_metadata.short_description = "User Metadata"

    def listing_preview(self, obj):
        """Embedded listing preview"""
        if not obj or not obj.id:
            return "No listing data"

        photos_html = ""
        if obj.photos.exists():
            photo = obj.photos.first()
            photos_html = format_html(
                '<img src="{}" style="max-width: 100%; height: auto; border-radius: 8px; margin-bottom: 15px;" />',
                f"/media/{photo.filename}",
            )

        try:
            available_date = (
                obj.date_available.strftime("%B %d, %Y")
                if obj.date_available
                else "Not set"
            )
            location = f"{obj.city}, {obj.borough}" if obj.borough else obj.city
            description = (
                obj.description[:200] + "..."
                if obj.description and len(obj.description) > 200
                else (obj.description or "No description")
            )

            # Format display values (replace underscores and title case)
            rental_type = (
                obj.rental_type.replace("_", " ").title()
                if obj.rental_type
                else "Not set"
            )
            room_type = (
                obj.room_type.replace("_", " ").title() if obj.room_type else "Not set"
            )
            vegan_household = (
                obj.vegan_household.replace("_", " ").title()
                if obj.vegan_household
                else "Not set"
            )

            return format_html(
                """
                <div style="padding: 20px; border: 1px solid var(--border-color, #ddd); border-radius: 8px; background: var(--body-bg, #fff);">
                    <h2 style="margin-top: 0; color: var(--body-fg, #333);">{}</h2>
                    {}
                    <div style="margin: 15px 0;">
                        <span style="background: var(--primary, #417690); color: white; padding: 5px 10px; border-radius: 4px; margin-right: 10px; font-size: 13px;">{}</span>
                        <span style="background: var(--primary, #417690); color: white; padding: 5px 10px; border-radius: 4px; margin-right: 10px; font-size: 13px;">{}</span>
                        <span style="background: var(--primary, #417690); color: white; padding: 5px 10px; border-radius: 4px; font-size: 13px;">{}</span>
                    </div>
                    <p style="color: var(--body-fg, #333);"><strong>Location:</strong> {}</p>
                    <p style="color: var(--body-fg, #333);"><strong>Price:</strong> ${}/mo</p>
                    <p style="color: var(--body-fg, #333);"><strong>Available:</strong> {}</p>
                    <p style="color: var(--body-quiet-color, #666);">{}</p>
                    <a href="{}" target="_blank" class="button" style="display: inline-block; margin-top: 10px;">View Full Listing →</a>
                </div>
                """,
                obj.title or "Untitled",
                photos_html,
                rental_type,
                room_type,
                vegan_household,
                location,
                obj.price or 0,
                available_date,
                description,
                reverse("listing_detail", args=[obj.id]),
            )
        except Exception as e:
            return format_html(
                '<div style="color: red;">Error rendering preview: {}</div>', str(e)
            )

    listing_preview.short_description = "Listing Preview"

    fieldsets = (
        ("User Information", {"fields": ("user", "user_metadata")}),
        ("Listing Preview", {"fields": ("listing_preview",)}),
        ("Basic Info", {"fields": ("title", "description", "status")}),
        ("Location", {"fields": ("city", "borough")}),
        (
            "Rental Details",
            {
                "fields": (
                    "rental_type",
                    "room_type",
                    "price",
                    "date_available",
                    "furnished",
                    "vegan_household",
                )
            },
        ),
        (
            "Lister Info",
            {
                "fields": (
                    "about_lister",
                    "lister_relationship",
                    "rental_requirements",
                    "pet_policy",
                )
            },
        ),
        ("Contact", {"fields": ("phone_number", "include_phone")}),
        ("Metadata", {"fields": ("created_at", "expires_at")}),
    )

    actions = ["approve_listings", "reject_listings", "deactivate_listings"]

    def approve_listings(self, request, queryset):
        """Approve selected listings"""
        count = 0
        for listing in queryset:
            if listing.status == ListingStatus.PAYMENT_SUBMITTED:
                listing.activate_listing()
                count += 1
        self.message_user(request, f"{count} listing(s) approved.")

    approve_listings.short_description = "Approve selected listings"

    def reject_listings(self, request, queryset):
        """Reject selected listings"""
        count = queryset.filter(status=ListingStatus.PAYMENT_SUBMITTED).update(
            status=ListingStatus.DRAFT
        )
        self.message_user(request, f"{count} listing(s) rejected.")

    reject_listings.short_description = "Reject selected listings"

    def deactivate_listings(self, request, queryset):
        """Deactivate selected listings"""
        count = queryset.filter(status=ListingStatus.ACTIVE).update(
            status=ListingStatus.DEACTIVATED
        )
        self.message_user(request, f"{count} listing(s) deactivated.")

    deactivate_listings.short_description = "Deactivate selected listings"


@admin.register(ListingPhoto)
class ListingPhotoAdmin(admin.ModelAdmin):
    """Admin interface for ListingPhoto model"""

    list_display = ("listing", "filename", "uploaded_at")
    list_filter = ("uploaded_at",)
    search_fields = ("listing__title", "filename")
    ordering = ("-uploaded_at",)
    readonly_fields = ("uploaded_at",)
