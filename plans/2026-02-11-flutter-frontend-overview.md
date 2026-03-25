# Flutter Frontend for Vedgy — High-Level Design

## Context

Vedgy is a vegan housing platform built as a Django 5.2 server-rendered monolith with HTMX + Alpine.js. This design introduces a Flutter web frontend (with mobile to follow) that replaces the Django templates with a standalone client app backed by a JSON API.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Target platform | Web first, mobile later | Ship web replacement, reuse codebase for mobile |
| API framework | Django Ninja | Already using Pydantic, auto OpenAPI docs, less boilerplate than DRF |
| Authentication | JWT via django-ninja-jwt | Stateless, works identically on web and mobile |
| State management | Riverpod | Handles async/caching well, compile-safe, scales cleanly |
| HTTP client | Dio | Interceptors for JWT attachment, token refresh, error handling |
| Data models | Freezed + json_serializable | Immutability, copyWith, JSON serialization with minimal boilerplate |
| Repo structure | Monorepo | Single repo, frontend/ alongside backend/ |
| Token storage | Access in memory, refresh in flutter_secure_storage | Secure default, refresh recovers access on page reload |

## Architecture

```
vedgyproject/
├── backend/
│   ├── config/
│   │   ├── settings.py       # + django-cors-headers, django-ninja-jwt
│   │   └── urls.py           # wires NinjaAPI with per-app routers at /api/
│   ├── listings/
│   │   ├── models.py         # unchanged
│   │   ├── views.py          # existing template views, kept as-is
│   │   ├── api.py            # Ninja router for listings
│   │   └── schemas.py        # expanded Pydantic schemas
│   └── users/
│       ├── models.py         # unchanged
│       ├── views.py          # existing template views
│       └── api.py            # Ninja router for auth + profile
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── router/           # GoRouter with auth guards
│   │   ├── services/         # Dio client, secure storage
│   │   ├── models/           # Freezed data classes
│   │   ├── providers/        # Riverpod providers
│   │   ├── screens/          # Page-level widgets
│   │   └── widgets/          # Reusable components
│   └── pubspec.yaml
└── Makefile                  # extended with frontend commands
```

## Data Flow

1. Flutter screen triggers a Riverpod provider
2. Provider calls Dio-based API service
3. Dio interceptor attaches JWT access token to request
4. Django Ninja endpoint validates token, queries models, returns JSON
5. Dio response is deserialized into Freezed model
6. Riverpod notifies UI, screen rebuilds with new data

On 401: Dio interceptor calls `/api/auth/refresh/` with refresh token from secure storage, retries original request. If refresh fails, clears tokens, redirects to login.

## API Surface

All endpoints live under `/api/`:

**Auth (`/api/auth/`):**
- `POST /signup/` — register, return JWT pair
- `POST /login/` — email + password, return tokens
- `POST /refresh/` — exchange refresh token for new access token
- `GET /me/` — current user profile
- `POST /password-reset/` — trigger reset email

**Listings (`/api/listings/`):**
- `GET /` — browse with filter query params, paginated
- `GET /{id}/` — single listing with photos
- `POST /` — create draft
- `PATCH /{id}/` — update listing
- `DELETE /{id}/` — delete listing
- `POST /{id}/deactivate/`
- `POST /{id}/photos/` — upload (multipart)
- `DELETE /photos/{photo_id}/`
- `GET /dashboard/` — current user's listings by status
- `POST /{id}/approve/` — staff only
- `POST /{id}/reject/` — staff only

## Routes (Flutter)

```
/                   → HomeScreen          (public)
/browse             → BrowseScreen        (public)
/listing/:id        → ListingDetailScreen (public)
/login              → LoginScreen         (public)
/signup             → SignupScreen        (public)
/password-reset     → PasswordResetScreen (public)
/create             → CreateListingScreen (auth required)
/edit/:id           → EditListingScreen   (auth required, owner only)
/preview/:id        → PreviewScreen       (auth required, owner only)
/pay/:id            → PayScreen           (auth required, owner only)
/dashboard          → DashboardScreen     (auth required)
/about              → AboutScreen         (public)
/privacy            → PrivacyScreen       (public)
/contact            → ContactScreen       (public)
/terms              → TermsScreen         (public)
```

## Local Development

Two processes:
- Django API on `localhost:8000` (`make run`)
- Flutter web on `localhost:3000` (`make frontend-run`)

CORS configured via `django-cors-headers` to allow `localhost:3000` in dev.

## Production Deployment

Single Railway service. Flutter builds to static files, Django serves them via WhiteNoise. API at `/api/`, all other paths fall through to Flutter's `index.html` for client-side routing. Same-origin means no CORS config needed in prod.

## Implementation Phases

1. **API Foundation** — CORS, JWT, auth endpoints, read-only listing endpoints
2. **Flutter Scaffold** — Project init, Dio, Freezed models, auth flow, router, nav shell
3. **Core Screens (Read-Only)** — Home, browse, listing detail, static pages
4. **Listing Management** — Write endpoints, create/edit forms, photo upload, dashboard
5. **Polish & Parity** — Password reset, validation, error states, responsive layout, deploy pipeline
6. **Mobile** — Platform tweaks, simulator testing, app store builds

Each phase has a dedicated design doc with full implementation details.

## Existing Django Templates

Templates remain in the repo and continue to work at their existing routes. They are not modified or deleted. Once Flutter covers all functionality and is deployed, templates can be removed in a future cleanup.
