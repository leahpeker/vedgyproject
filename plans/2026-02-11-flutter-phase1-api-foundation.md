# Phase 1: API Foundation

## Goal

Stand up the Django Ninja API layer with authentication and read-only listing endpoints. By the end of this phase, you can hit `/api/docs` and interact with every read endpoint using JWT tokens.

## Dependencies to Add

Add to `pyproject.toml`:
- `django-ninja` — API framework
- `django-ninja-jwt` — JWT authentication for Ninja
- `django-cors-headers` — CORS support

## Step 1: Configure django-cors-headers

**File: `config/settings.py`**

Add `corsheaders` to `INSTALLED_APPS`.

Add `corsheaders.middleware.CorsMiddleware` before `django.middleware.common.CommonMiddleware` in `MIDDLEWARE`.

Settings:
```python
# Dev
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
]
CORS_ALLOW_CREDENTIALS = True

# Production: add real domain via environment variable
```

## Step 2: Configure django-ninja-jwt

**File: `config/settings.py`**

Add JWT settings:
```python
NINJA_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "AUTH_HEADER_TYPES": ("Bearer",),
}
```

Short access token lifetime forces regular refresh, limiting exposure if a token is compromised.

## Step 3: Create users/api.py

Auth router with these endpoints:

**POST /api/auth/signup/**
- Input: email, first_name, last_name, password1, password2
- Validate email uniqueness, password strength (reuse Django validators)
- Create user, return JWT pair (access + refresh)
- Rate limit: 5/hour (carry over existing limit)

**POST /api/auth/login/**
- Input: email, password
- Authenticate via Django's `authenticate()`
- Return JWT pair
- Rate limit: 10/hour

**POST /api/auth/refresh/**
- Input: refresh token
- Return new access + refresh tokens
- django-ninja-jwt handles this out of the box

**GET /api/auth/me/**
- Requires valid access token
- Return: id, email, first_name, last_name, phone, created_at

**POST /api/auth/password-reset/**
- Input: email
- Trigger Django's password reset email flow
- Always return 200 (don't leak whether email exists)

## Step 4: Create listings/schemas.py (expanded)

Build on the existing `ListingDraftSchema`:

```python
class UserOut(Schema):
    id: UUID
    first_name: str
    last_name: str

class PhotoOut(Schema):
    id: UUID
    filename: str
    url: str  # computed from photo_url base + filename

class ListingOut(Schema):
    id: UUID
    title: str
    description: str
    city: str
    borough: str | None
    neighborhood: str | None
    price: int
    start_date: date | None
    end_date: date | None
    rental_type: str
    room_type: str
    vegan_household: str
    furnished: str
    lister_relationship: str
    seeking_roommate: bool
    about_lister: str | None
    rental_requirements: str | None
    pet_policy: str | None
    phone_number: str | None
    include_phone: bool
    status: str
    user: UserOut
    photos: list[PhotoOut]
    created_at: datetime
    expires_at: datetime | None

class ListingFilters(Schema):
    city: str | None = None
    borough: str | None = None
    rental_type: str | None = None
    room_type: str | None = None
    vegan_household: str | None = None
    furnished: str | None = None
    seeking_roommate: bool | None = None
    price_min: int | None = None
    price_max: int | None = None

class PaginatedListings(Schema):
    items: list[ListingOut]
    count: int
    page: int
    page_size: int
```

## Step 5: Create listings/api.py (read-only)

Listings router with these endpoints:

**GET /api/listings/**
- Public, no auth required
- Query params matching `ListingFilters`
- Only returns listings with status=ACTIVE
- Paginated (default 20 per page)
- Reuse existing filter logic from `browse_listings` view

**GET /api/listings/{id}/**
- Public for active listings
- Draft/deactivated/expired visible only to owner or staff
- Returns full `ListingOut` with photos and computed photo URLs

**GET /api/listings/dashboard/**
- Requires auth
- Returns current user's listings grouped by status
- Response: `{ drafts: [...], payment_submitted: [...], active: [...], expired: [...], deactivated: [...] }`

## Step 6: Wire routers in config/urls.py

```python
from ninja import NinjaAPI
from users.api import router as auth_router
from listings.api import router as listings_router

api = NinjaAPI(
    title="Vedgy API",
    version="1.0.0",
)

api.add_router("/auth/", auth_router, tags=["auth"])
api.add_router("/listings/", listings_router, tags=["listings"])

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
    # existing template routes remain
    path("", include("listings.urls")),
]
```

## Step 7: Test

- Verify all endpoints via `/api/docs` (Swagger UI)
- Test JWT flow: signup → get tokens → call /me with access token → refresh when expired
- Test listing browse with various filter combinations
- Test permission checks (non-owner can't see draft listings)
- Add API tests in `listings/tests/test_api.py` and `users/tests/test_api.py`

## Acceptance Criteria

- `/api/docs` loads and shows all endpoints
- Can register, login, and refresh tokens
- Can browse listings with filters and get JSON responses
- Photo URLs resolve correctly in listing responses
- Existing template-based routes still work unchanged
- CORS allows requests from `localhost:3000`
