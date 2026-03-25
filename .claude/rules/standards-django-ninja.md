---
paths:
  - "**/config/settings.py"
  - "**/config/urls.py"
  - "**/models.py"
  - "**/schemas.py"
  - "**/api.py"
  - "**/admin.py"
  - "**/management/**"
  - "**/conftest.py"
  - "**/test_api.py"
  - "**/test_models.py"
---

# Django Ninja API Standards

Standards for Django projects using Django Ninja as the API framework with JWT auth.

## Project Layout

```
backend/
├── config/          # Django project: settings.py, urls.py, wsgi.py
├── <app>/           # Django apps: models, api, schemas, admin
│   ├── models.py
│   ├── api.py       # Django Ninja router endpoints
│   ├── schemas.py   # Pydantic input/output schemas
│   ├── admin.py     # Admin panel configuration
│   ├── utils.py     # Business logic helpers
│   ├── management/commands/   # Management commands
│   └── tests/       # App-specific tests
├── templates/       # Email-only templates (no UI templates)
└── tests/           # Cross-app integration tests
    └── conftest.py  # Shared fixtures (SINGLE source of truth)
```

## Models

### UUID Primary Keys (Always)

```python
import uuid
from django.db import models

class MyModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

Every model gets UUID PK + `created_at`. No auto-increment IDs.

### Status as State Machine

```python
class ListingStatus:
    DRAFT = "draft"
    ACTIVE = "active"
    EXPIRED = "expired"
    CHOICES = [(DRAFT, "Draft"), (ACTIVE, "Active"), (EXPIRED, "Expired")]

class Listing(models.Model):
    status = models.CharField(max_length=20, choices=ListingStatus.CHOICES, default=ListingStatus.DRAFT)

    def activate(self):
        """Status transitions belong in the model, not in API endpoints."""
        with transaction.atomic():
            self.status = ListingStatus.ACTIVE
            self.expires_at = timezone.now() + timedelta(days=30)
            self.save(update_fields=["status", "expires_at"])
```

- Use a status class with constants (not raw strings)
- Status transitions as model methods with `transaction.atomic()`
- Never set `status = "active"` directly in API endpoints

### Field Conventions

- Text fields: default to `""` (empty string), never `null` for text
- Optional fields: use `blank=True, null=True` only for non-text (dates, numbers, FKs)
- FK: always specify `on_delete` explicitly, use `related_name`
- `Meta.ordering = ["-created_at"]` for reverse chronological default

### Custom User Model (Email-Based Auth)

```python
class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    def save(self, *args, **kwargs):
        self.username = self.email  # Sync for Django compat
        super().save(*args, **kwargs)
```

Set `AUTH_USER_MODEL = "users.User"` in settings before first migration.

## API Endpoints (Django Ninja)

### Router Setup

```python
# config/urls.py
from ninja import NinjaAPI

api = NinjaAPI(title="My API", version="1.0.0")
api.add_router("/auth/", auth_router, tags=["auth"])
api.add_router("/listings/", listings_router, tags=["listings"])

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
    # SPA catch-all MUST BE LAST (see integration rules)
]
```

### Response Pattern (Tuple Returns)

```python
from ninja import Router
from ninja_jwt.authentication import JWTAuth

router = Router()

@router.post("/", auth=JWTAuth(), response={201: ListingOut, 400: ErrorOut})
def create_listing(request, data: ListingIn):
    if error:
        return 400, {"detail": "Error message"}
    listing = Listing.objects.create(user=request.auth, **data.dict())
    return 201, ListingOut.from_model(listing)
```

- `response=` declares all possible status codes
- Return tuple: `(status_code, data)`
- `request.auth` is the authenticated User (from JWTAuth)

### Error Schema (Standard)

```python
class ErrorOut(Schema):
    detail: str

class MessageOut(Schema):
    message: str
```

Always use `{"detail": "..."}` for errors, `{"message": "..."}` for success messages.

### Permission Pattern

```python
def _get_owned_resource(request, resource_id: UUID):
    """Reusable ownership check helper."""
    resource = get_object_or_404(MyModel, id=resource_id)
    if resource.user_id != request.auth.id:
        return None, (403, {"detail": "Permission denied"})
    return resource, None
```

### Route Ordering (Critical)

Named routes MUST come before parameterized routes:

```python
@router.get("/dashboard/", ...)     # FIRST: named routes
def dashboard(request): ...

@router.get("/{item_id}/", ...)     # LAST: parameterized routes
def get_item(request, item_id: UUID): ...
```

If `/dashboard/` comes after `/{item_id}/`, Django Ninja will try to parse "dashboard" as a UUID.

### Query Optimization (Always)

```python
listings = (
    Listing.objects
    .filter(status=ListingStatus.ACTIVE)
    .select_related("user")          # FK lookups
    .prefetch_related("photos")      # Reverse relations
)
```

Never return querysets without `select_related`/`prefetch_related` for related objects.

### Manual Pagination

```python
class PaginatedItems(Schema):
    items: list[ItemOut]
    count: int
    page: int
    page_size: int

@router.get("/", response=PaginatedItems)
def list_items(request, page: int = 1, page_size: int = 20):
    qs = Item.objects.all()
    count = qs.count()
    items = qs[(page - 1) * page_size : page * page_size]
    return {"items": [ItemOut.from_model(i) for i in items], "count": count, "page": page, "page_size": page_size}
```

## Schemas (Pydantic)

### Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Input | `XyzIn` | `ListingIn`, `LoginIn` |
| Output | `XyzOut` | `ListingOut`, `UserOut` |
| Filters | `XyzFilters` | `ListingFilters` |
| Paginated | `PaginatedXyz` | `PaginatedListings` |

### Factory Methods (ORM to Schema)

```python
class ListingOut(Schema):
    id: str
    title: str
    user: UserOut
    photos: list[PhotoOut]

    @staticmethod
    def from_model(listing) -> "ListingOut":
        return ListingOut(
            id=str(listing.id),
            title=listing.title,
            user=UserOut.from_model(listing.user),
            photos=[PhotoOut.from_model(p) for p in listing.photos.all()],
        )
```

### PATCH with Optional Fields

```python
class ListingIn(Schema):
    title: str | None = None
    description: str | None = None

@router.patch("/{listing_id}/", ...)
def update_listing(request, listing_id: UUID, data: ListingIn):
    updates = data.dict(exclude_unset=True)
    for key, value in updates.items():
        setattr(listing, key, value)
    listing.save(update_fields=list(updates.keys()))
```

Use `exclude_unset=True` so absent fields are not set to `None`.

## Settings

### Environment Detection

```python
IS_PRODUCTION = os.environ.get("RAILWAY_ENVIRONMENT") is not None

# Define ONCE at the top, use everywhere
SECRET_KEY = os.environ.get("SECRET_KEY")
if not SECRET_KEY:
    if IS_PRODUCTION:
        raise ValueError("SECRET_KEY must be set in production")
    SECRET_KEY = "django-insecure-development-key-only"
```

- Define `IS_PRODUCTION` exactly ONCE
- Fail-fast in production for missing required vars
- Provide dev-friendly defaults only outside production

### Database

```python
DATABASES = {"default": dj_database_url.config(default="sqlite:///db.sqlite3", conn_max_age=600)}
```

SQLite for local dev, PostgreSQL via `DATABASE_URL` in production.

### JWT Configuration

```python
NINJA_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "AUTH_HEADER_TYPES": ("Bearer",),
}
```

### .env.example Rules

- Optional services MUST have empty placeholder values: `B2_KEY_ID=` (not `B2_KEY_ID=your-key-here`)
- Truthy placeholder strings cause silent misconfigurations where code falls back incorrectly

## Testing

### Fixture Pattern

```python
# tests/conftest.py — SINGLE source of truth for ALL test fixtures
@pytest.fixture
def test_user(db):
    return User.objects.create_user(email="test@example.com", password="testpass123", first_name="Test", last_name="User")

@pytest.fixture
def auth_headers(test_user):
    refresh = RefreshToken.for_user(test_user)
    return {"HTTP_AUTHORIZATION": f"Bearer {refresh.access_token}"}

@pytest.fixture
def draft_listing(test_user):
    return Listing.objects.create(status=ListingStatus.DRAFT, user=test_user, title="Test Listing")
```

- ONE conftest.py with shared fixtures (never duplicate across apps)
- Auth fixtures generate JWT headers as dicts: `client.get(url, **auth_headers)`
- Create `other_user` + `other_auth_headers` fixtures for permission tests
- `@pytest.fixture(autouse=True)` for test environment setup (e.g., swapping staticfiles storage)

### Test Organization

```python
@pytest.mark.django_db
class TestCreateListing:
    def test_create_listing_success(self, api_client, auth_headers):
        response = api_client.post("/api/listings/", data, content_type="application/json", **auth_headers)
        assert response.status_code == 201

    def test_create_listing_unauthenticated(self, api_client):
        response = api_client.post("/api/listings/", data, content_type="application/json")
        assert response.status_code == 401
```

- Class per endpoint or feature
- `test_<action>_<scenario>` naming
- Assert status code FIRST, then response data
- Happy path first, then error cases

### Image Test Helper

```python
def _make_test_image(fmt="JPEG", size=(20, 20)):
    buf = io.BytesIO()
    Image.new("RGB", size).save(buf, format=fmt)
    buf.seek(0)
    return SimpleUploadedFile("test.jpg", buf.read(), content_type="image/jpeg")
```

## Admin

- Use `format_html()` for any HTML in admin display (never raw HTML strings)
- Inline models for related objects (`TabularInline`)
- List filters for status, date, category fields
- After migration to SPA: replace all `reverse("view_name", ...)` with direct SPA URLs

## Management Commands

- Seed commands: idempotent (skip existing), support `--reset` flag
- Expiration/cleanup commands: use `.update()` for bulk status transitions, not per-object loops
- Load fixture data from JSON files (not hardcoded in command)

## Common Bugs to Avoid

1. **Doubled API prefix**: If Dio baseUrl is `/api` AND route strings include `/api/`, requests go to `/api/api/`. One must be empty.
2. **SPA catch-all eating static assets**: Always exclude file extensions from the catch-all regex.
3. **Conditional URL configs**: Never serve different URL patterns in dev vs prod. Same routes everywhere.
4. **Truthy .env placeholders**: `B2_KEY_ID=your-key-here` is truthy, causing code to attempt B2 upload then fall back silently.
5. **Admin `reverse()` after migration**: When views are deleted, `reverse()` calls in admin break at runtime.
6. **Route order**: Named routes must precede parameterized routes (`/dashboard/` before `/{id}/`).
