# Phase 5: Polish & Parity

## Goal

Complete remaining features (password reset, form validation), add error handling and loading states everywhere, make the layout responsive, and set up the production build pipeline. By the end of this phase, the Flutter web app is ready to deploy and fully replaces the Django template frontend.

## Step 1: Password Reset Flow

**Screens:**
- `PasswordResetScreen` — email input, calls `POST /api/auth/password-reset/`
- Success message: "If an account with that email exists, we've sent a reset link"

The actual reset link in the email still points to the Django template-based reset form (`/password-reset/<uidb64>/<token>/`). This is fine — the email flow is server-side and the reset form can remain a Django template page. Users complete the reset there and then return to the Flutter app to log in.

Alternative: build Flutter screens for the token-based reset confirm flow and point the email link to the Flutter app. Only worth doing if you want to eliminate all Django template usage.

## Step 2: Form Validation

**Client-side validation across all forms:**

Login:
- Email format check
- Password not empty

Signup:
- Email format check
- First name, last name required
- Password minimum 8 characters
- Password confirmation matches
- Show Django's password validation errors from API (common password, too similar to email, etc.)

Create/Edit Listing:
- Title required (on submit, not during auto-save)
- Price must be positive integer
- Start date before end date (if both provided)
- City required
- At least one photo recommended (warning, not blocking)

**Server-side error display:**
- Map Django Ninja validation error responses to inline field errors
- Format: API returns `{ "detail": [{ "loc": ["body", "field_name"], "msg": "error" }] }`
- Parse `loc` to match error to form field, display below the field

## Step 3: Loading & Error States

**Every screen that fetches data needs three states:**

Loading:
- Skeleton placeholders matching the layout (not a spinner)
- BrowseScreen: skeleton listing cards in grid
- ListingDetailScreen: skeleton blocks for photo area, title, fields
- DashboardScreen: skeleton cards per section

Error:
- Network error: "Unable to connect. Check your connection and try again." + retry button
- 404: "Listing not found" with link back to browse
- 403: "You don't have permission to view this" with link to home
- Generic: "Something went wrong" + retry button

Empty:
- Browse with no results: "No listings match your filters. Try adjusting your search."
- Dashboard empty section: "No [status] listings yet"

## Step 4: Responsive Layout

**Breakpoints:**
- Desktop: > 1024px — full layout, side-by-side panels
- Tablet: 768–1024px — adjusted grid, stacked where needed
- Mobile: < 768px — single column, hamburger nav

**Screen-specific adjustments:**

BrowseScreen:
- Desktop: filter panel on left (sidebar), listing grid on right
- Tablet: filters in a collapsible top bar, 2-column grid
- Mobile: filters behind a "Filters" button/drawer, single column cards

ListingDetailScreen:
- Desktop: photo gallery on left, details on right
- Mobile: photo gallery full-width on top, details below

Create/Edit forms:
- Desktop: two-column field layout where appropriate
- Mobile: single-column stack

Nav bar:
- Desktop: full horizontal links
- Mobile: hamburger menu with slide-out drawer

## Step 5: Snackbar / Toast Notifications

Replace Django's message framework with Flutter snackbars for:
- "Listing saved as draft"
- "Listing submitted for review"
- "Listing deactivated"
- "Listing deleted"
- "Photo uploaded" / "Photo deleted"
- Error messages from failed operations

Use a Riverpod provider to manage notification state so any screen can trigger a message.

## Step 6: Production Build Pipeline

**Update `railway.json`:**

Build command:
```bash
cd frontend && flutter build web --release && \
cp -r build/web/ ../backend/staticfiles/flutter/ && \
cd ../backend && \
python manage.py collectstatic --noinput && \
python manage.py migrate
```

**Django catch-all route:**

Add a catch-all view at the end of `config/urls.py` that serves `flutter/index.html` for any path not matched by `/api/` or `/admin/`. This lets GoRouter handle client-side routing.

```python
from django.views.generic import TemplateView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
    # Password reset templates (kept for email flow)
    path("password-reset/", include("listings.urls_password_reset")),
    # Flutter app catch-all (must be last)
    re_path(r"^.*$", TemplateView.as_view(template_name="flutter/index.html")),
]
```

**CORS in production:**
Not needed — same origin. Remove dev CORS origins or gate behind `DEBUG` setting.

**Environment config in Flutter:**
Base API URL switches between `localhost:8000` (dev) and relative `/api/` (prod, same origin). Use `--dart-define` or a config file.

## Step 7: Smoke Test Deployed App

- Verify Flutter app loads at root URL
- Verify `/api/docs` still accessible
- Verify client-side routing works (navigate to `/browse`, refresh page — still works)
- Verify auth flow end to end in production
- Verify photo URLs resolve from B2

## Acceptance Criteria

- Password reset email flow works
- All forms show validation errors inline
- Every data-fetching screen has loading skeletons, error states, and empty states
- App looks good and is usable at desktop, tablet, and mobile widths
- Nav collapses to hamburger menu on mobile
- Snackbar notifications for all user actions
- Production build serves Flutter from Django via WhiteNoise
- Client-side routing works on page refresh (catch-all serves index.html)
- `/api/` and `/admin/` still route to Django
- No CORS issues in production
