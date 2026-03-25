# Phase 3: Core Screens (Read-Only)

## Goal

Build the public-facing screens: home, browse with filters, listing detail, and static pages. By the end of this phase, the Flutter web app reaches feature parity with the public, unauthenticated experience.

## Step 1: Flesh Out Listing Models

Complete the Freezed models stubbed in Phase 2:

**lib/models/listing.dart:**
```dart
@freezed
class Listing with _$Listing {
  const factory Listing({
    required String id,
    required String title,
    required String description,
    required String city,
    String? borough,
    String? neighborhood,
    required int price,
    DateTime? startDate,
    DateTime? endDate,
    required String rentalType,
    required String roomType,
    required String veganHousehold,
    required String furnished,
    required String listerRelationship,
    required bool seekingRoommate,
    String? aboutLister,
    String? rentalRequirements,
    String? petPolicy,
    String? phoneNumber,
    required bool includePhone,
    required String status,
    required ListingUser user,
    required List<ListingPhoto> photos,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) =>
      _$ListingFromJson(json);
}

@freezed
class ListingPhoto with _$ListingPhoto {
  const factory ListingPhoto({
    required String id,
    required String filename,
    required String url,
  }) = _ListingPhoto;

  factory ListingPhoto.fromJson(Map<String, dynamic> json) =>
      _$ListingPhotoFromJson(json);
}

@freezed
class ListingUser with _$ListingUser {
  const factory ListingUser({
    required String id,
    required String firstName,
    required String lastName,
  }) = _ListingUser;

  factory ListingUser.fromJson(Map<String, dynamic> json) =>
      _$ListingUserFromJson(json);
}

@freezed
class ListingFilters with _$ListingFilters {
  const factory ListingFilters({
    String? city,
    String? borough,
    String? rentalType,
    String? roomType,
    String? veganHousehold,
    String? furnished,
    bool? seekingRoommate,
    int? priceMin,
    int? priceMax,
    @Default(1) int page,
  }) = _ListingFilters;
}
```

## Step 2: Listings Provider

**lib/providers/listings_provider.dart:**

Two main providers:

**Browse provider:**
- Holds current `ListingFilters` state
- When filters change, calls `GET /api/listings/` with query params
- Returns `AsyncValue<PaginatedListings>` — loading, error, or data
- Pagination: increment page param, append results or replace

**Detail provider:**
- Family provider keyed by listing ID
- Calls `GET /api/listings/{id}/`
- Returns `AsyncValue<Listing>`
- Caches result for the session

## Step 3: HomeScreen

**lib/screens/home_screen.dart:**

Mirrors current `index.html`:
- Hero section with Vedgy branding and tagline
- "Browse Listings" button → navigates to `/browse`
- "Post a Listing" button → navigates to `/create` (auth guard handles redirect)
- Brief description of what Vedgy is

Keep it simple — no API calls on this page.

## Step 4: BrowseScreen

**lib/screens/browse_screen.dart:**

Most interactive screen. Two main sections:

**Filter panel (lib/widgets/filter_panel.dart):**
- Dropdowns for: City, Borough (shown only when city is NYC), Rental Type, Room Type, Vegan Household, Furnished, Seeking Roommate
- Text fields for min/max price with debounce (500ms delay before triggering API call)
- "Clear All" button resets filters to defaults
- Changing any filter updates the `ListingFilters` state in the provider, which triggers a new API call

**Listing grid:**
- Responsive grid: 3 columns on desktop, 2 on tablet, 1 on mobile
- Each card is `ListingCard` widget
- Loading state: skeleton cards
- Empty state: "No listings found" message
- Pagination: "Load More" button or infinite scroll

**lib/widgets/listing_card.dart:**
- Photo thumbnail (first photo, fallback placeholder if none)
- Title, price (bold, green)
- Tags: rental type, room type, furnished, vegan household, seeking roommate
- Location (city + neighborhood)
- Truncated description (150 chars)
- "Posted by" name
- Tap → navigate to `/listing/{id}`

## Step 5: ListingDetailScreen

**lib/screens/listing_detail_screen.dart:**

Full listing view:

**Photo section (lib/widgets/photo_gallery.dart):**
- If multiple photos: horizontal scroll with arrow buttons, thumbnail strip below
- If single photo: display it
- If no photos: placeholder image

**Listing info:**
- Title, price, location
- All detail fields displayed in labeled sections
- Status badges
- Lister info (name, phone if `include_phone` is true)
- "About the lister" section
- Rental requirements, pet policy

**Permission handling:**
- If listing is not active and user is not the owner/staff → show 404 or "listing not available" message
- This check happens in the provider using auth state

## Step 6: Static Pages

**lib/screens/static/about_screen.dart:**
**lib/screens/static/privacy_screen.dart:**
**lib/screens/static/contact_screen.dart:**
**lib/screens/static/terms_screen.dart:**

These are straightforward text content screens. Copy the content from the current Django templates. Wrap in `AppScaffold`. No API calls.

## Step 7: Wire Up Routes

Add all routes to GoRouter:
```dart
GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
GoRoute(path: '/browse', builder: (_, __) => const BrowseScreen()),
GoRoute(path: '/listing/:id', builder: (_, state) =>
    ListingDetailScreen(id: state.pathParameters['id']!)),
GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
GoRoute(path: '/contact', builder: (_, __) => const ContactScreen()),
GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
```

## Acceptance Criteria

- Home page loads with CTAs that navigate correctly
- Browse page shows active listings in a responsive grid
- All 8 filters work and update results dynamically
- Borough dropdown only appears when NYC is selected
- Price range inputs debounce correctly
- Empty filter state shows "No listings found"
- Listing detail page shows all fields and photos
- Non-active listings return appropriate error for non-owners
- Static pages display correct content
- All navigation between screens works via GoRouter
- Loading and error states display appropriately on all screens
