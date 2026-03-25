# Phase 4: Listing Management

## Goal

Build the authenticated listing CRUD flows: create, edit, auto-save, photo upload/delete, preview, pay, dashboard, deactivate, and admin actions. By the end of this phase, the Flutter app has full feature parity with the existing Django template frontend.

## Step 1: Write Endpoints in listings/api.py

Add to the existing listings router:

**POST /api/listings/**
- Requires auth
- Input: `ListingIn` schema (all fields optional for draft creation)
- Creates listing with status=DRAFT, user=request.user
- Returns `ListingOut`

**PATCH /api/listings/{id}/**
- Requires auth, owner only
- Input: partial `ListingIn` (all fields optional)
- Updates provided fields only
- Used for both explicit saves and auto-save
- Returns `ListingOut`

**DELETE /api/listings/{id}/**
- Requires auth, owner only
- Deletes listing and all associated photos (B2 + DB)
- Returns 204

**POST /api/listings/{id}/deactivate/**
- Requires auth, owner only
- Sets status to DEACTIVATED
- Returns `ListingOut`

**POST /api/listings/{id}/photos/**
- Requires auth, owner only
- Multipart file upload
- Validates: file type, size (10MB), max 10 photos per listing
- Processes via existing `utils.py` pipeline (resize, JPEG, B2 upload)
- Returns `PhotoOut`

**DELETE /api/listings/photos/{photo_id}/**
- Requires auth, listing owner only
- Deletes from B2 + DB
- Returns 204

**POST /api/listings/{id}/approve/**
- Requires staff
- Calls `activate_listing()` (sets ACTIVE, 30-day expiration)
- Returns `ListingOut`

**POST /api/listings/{id}/reject/**
- Requires staff
- Sets status back to DRAFT
- Returns `ListingOut`

Add schema:
```python
class ListingIn(Schema):
    title: str | None = None
    description: str | None = None
    city: str | None = None
    borough: str | None = None
    neighborhood: str | None = None
    price: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    rental_type: str | None = None
    room_type: str | None = None
    vegan_household: str | None = None
    furnished: str | None = None
    lister_relationship: str | None = None
    seeking_roommate: bool = False
    about_lister: str | None = None
    rental_requirements: str | None = None
    pet_policy: str | None = None
    phone_number: str | None = None
    include_phone: bool = False
```

## Step 2: Dashboard Provider

**lib/providers/dashboard_provider.dart:**

- Calls `GET /api/listings/dashboard/`
- Returns grouped listings by status
- Refreshes on listing create/edit/delete/deactivate actions

## Step 3: Photo Provider

**lib/providers/photo_provider.dart:**

- `uploadPhotos(String listingId, List<File> files)` — multipart upload via Dio
- `deletePhoto(String photoId)` — DELETE call
- Tracks upload progress per file (Dio supports progress callbacks)
- After upload/delete, invalidates the listing detail cache

## Step 4: DashboardScreen

**lib/screens/dashboard_screen.dart:**

- Sections or tabs for each status group: Draft, Payment Submitted, Active, Expired, Deactivated
- Each listing card shows: title, status badge, created date, price, city
- Action buttons per status:
  - Draft: Edit, Delete
  - Payment Submitted: (view only, waiting for admin)
  - Active: View, Deactivate
  - Expired: Edit (creates new draft? or re-submit flow)
  - Deactivated: Edit, Delete
- Empty state per section: "No [status] listings"
- Tap listing title → navigate to listing detail

## Step 5: CreateListingScreen

**lib/screens/create_listing_screen.dart:**

Multi-section form matching current `create_listing.html`:

**Form sections:**
1. Basic info: title, description
2. Location: city dropdown, borough (conditional on NYC), neighborhood
3. Details: price, start/end dates, rental type, room type
4. Living situation: vegan household, furnished, seeking roommate
5. Lister info: lister relationship, about lister, phone, include phone toggle
6. Requirements: rental requirements, pet policy
7. Photos: upload area, thumbnail previews, delete per photo

**Auto-save behavior:**
- On first meaningful input, `POST /api/listings/` to create draft and get listing ID
- Subsequent changes debounced (2 seconds), `PATCH /api/listings/{id}/` with changed fields only
- Visual indicator: "Saving..." / "Saved" / "Save failed"
- Photos uploaded immediately on selection (not debounced)

**Form validation:**
- Client-side: required fields before submission, price must be positive, valid dates
- Server-side errors displayed inline next to relevant fields

**Submit flow:**
- "Preview" button → navigate to `/preview/{id}`

## Step 6: EditListingScreen

**lib/screens/edit_listing_screen.dart:**

Same form component as CreateListingScreen but pre-populated with existing data. Fetches listing on mount via detail provider. Same auto-save behavior. Owner-only access enforced by router guard + API permission check.

Consider extracting a shared `ListingForm` widget used by both Create and Edit screens, parameterized by initial data and listing ID.

## Step 7: PreviewScreen

**lib/screens/preview_screen.dart:**

Read-only view of the listing (reuse `ListingDetailScreen` layout in read-only mode). Shows how the listing will appear to browsers.

Action button: "Submit for Review" → navigates to `/pay/{id}`.

## Step 8: PayScreen

**lib/screens/pay_screen.dart:**

Payment page matching current `pay_listing.html`. On "Submit Payment" action, sets listing status to `payment_submitted` via API. No actual payment integration in this phase (matches current behavior).

After submission: redirect to dashboard with success message.

## Step 9: API Tests

**backend/listings/tests/test_api.py (expanded):**
- Test create, update, delete listing
- Test photo upload (valid file, invalid file, too many photos)
- Test photo delete
- Test deactivate
- Test approve/reject (staff only, non-staff gets 403)
- Test owner-only access (other users get 403)

**backend/users/tests/test_api.py:**
- Test signup with duplicate email
- Test login with wrong password
- Test token refresh with expired/invalid token

## Acceptance Criteria

- Can create a new listing draft from the Flutter app
- Auto-save works on field changes with visual feedback
- Can upload up to 10 photos with progress indicators
- Can delete individual photos
- Can preview listing before submitting
- Dashboard shows listings grouped by status with correct actions
- Can deactivate active listings
- Can delete draft/deactivated listings
- Staff can approve/reject listings via API
- All write operations require authentication
- Owner-only operations reject other users
- Existing template-based CRUD still works unchanged
