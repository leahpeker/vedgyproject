---
paths:
  - "**/config/urls.py"
  - "**/config/settings.py"
  - "**/schemas.py"
  - "**/api_config.dart"
  - "**/api_client.dart"
  - "**/models/*.dart"
  - "**/build.yaml"
  - "Dockerfile"
  - "Makefile"
  - "docker-compose.yml"
  - "railway.json"
---

# Django + Flutter Integration Standards

Cross-stack patterns for Django API backend serving a Flutter SPA frontend.

## API Contract

### JSON Field Mapping

Django Ninja outputs snake_case (`start_date`). Flutter Freezed models use camelCase (`startDate`). The bridge is `build.yaml`:

```yaml
# frontend/build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake
          explicit_to_json: true
```

This auto-converts `startDate` <-> `start_date`. Only use `@JsonKey(name: ...)` when the JSON key doesn't follow snake_case convention.

### Type Mapping

| Django | JSON | Dart |
|--------|------|------|
| `UUIDField` | `string` | `String` (not Uuid type) |
| `DateTimeField` | ISO 8601 string | `DateTime` (auto-parsed) |
| `DateField` | ISO 8601 date string | `DateTime` |
| `IntegerField(null=True)` | `int \| null` | `int?` |
| `CharField(choices=...)` | `string` | `String` (match choice values exactly) |
| Nested `Schema` | object | Freezed model |
| `list[Schema]` | array | `List<FreezedModel>` |

### Schema Parity

Django `ListingOut` fields must exactly match Flutter `Listing` factory parameters. When adding a field to a Django schema:
1. Add to Django schema
2. Add to Flutter Freezed model (with same snake_case JSON key)
3. Run `build_runner` codegen
4. Update test fixtures in BOTH stacks

### Choice/Enum Values

Choice values (status, type, category) are shared strings between stacks. When adding or changing a choice value:
1. Update Django model choices
2. Search Flutter for all occurrences of the old value
3. Update dropdown/filter options in Flutter widgets
4. Update test fixtures

There is no compile-time check that choice values match. Be thorough with search.

## SPA Catch-All Route

```python
# config/urls.py — MUST BE LAST in urlpatterns
re_path(
    r"^(?!.*\.(js|css|json|wasm|png|jpg|ico|svg|ttf|otf|woff|woff2|map)$).*$",
    TemplateView.as_view(template_name="flutter/index.html"),
)
```

- Negative lookahead excludes static file extensions
- WhiteNoise serves Flutter assets BEFORE Django routing via `WHITENOISE_ROOT`
- `admin/` and `api/` routes are defined BEFORE the catch-all

### Adding New Static Extensions

If Flutter's build output includes new file types (e.g., `.woff2`, `.wasm`), add them to the catch-all's exclusion list. Otherwise the catch-all returns `index.html` instead of the asset.

## API URL Configuration

### The Rule: Define the API Prefix in ONE Place

Either the Dio baseUrl includes `/api` OR the route strings include `/api/` — never both. Doubling produces `/api/api/listings/`.

**This project's convention:** Route strings include `/api/` (e.g., `/api/auth/login/`). The Dio baseUrl is the origin only (empty in production, `http://localhost:8000` in dev).

### Compile-Time API URL

```dart
// frontend/lib/config/api_config.dart
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
```

Set at build time via `--dart-define=API_URL=`. Production builds use empty string (same-origin). This is the correct approach for Flutter web — `String.fromEnvironment` resolves at compile time.

## Authentication Flow

### End-to-End JWT Flow

```
Flutter Login Screen
  → POST /api/auth/login/ (via plain _authDio, no interceptors)
  → Django returns {"access": "...", "refresh": "..."}
  → Store refresh in FlutterSecureStorage
  → Hold access in memory (AuthState.authenticated)
  → GET /api/auth/me/ (via interceptor-equipped apiClient)
  → Store User in AuthState

Subsequent Requests
  → _AuthInterceptor attaches Bearer header
  → On 401: Completer-based refresh lock, retry once

Session Restore
  → App start: check FlutterSecureStorage for refresh token
  → POST /api/auth/refresh/ → restore session silently
  → Invalid/expired → clear storage → unauthenticated
```

### Auth Dio Separation

Login/signup/refresh requests use a plain Dio instance (`_authDio`) without auth interceptors. This avoids the circular dependency where the interceptor calls auth endpoints that trigger the interceptor.

## Email Deep Links (Password Reset)

### Flow

1. Flutter → `POST /api/auth/password-reset/` → Django sends email
2. Email contains: `{{ protocol }}://{{ domain }}/password-reset-confirm/{{ uid }}/{{ token }}/`
3. URL hits Django → SPA catch-all serves `index.html`
4. GoRouter matches `/password-reset-confirm/:uidb64/:token`
5. Flutter renders form → `POST /api/auth/password-reset-confirm/`

### Key Points

- Email template links to Flutter route, not Django view
- Always return 200 for password reset request (prevents email enumeration)
- The `domain` in the email comes from the request `Host` header
- Email templates survive SPA migrations (server-side rendering for email)

## Error Handling Chain

### Django → Flutter Error Flow

| Django returns | Flutter _ErrorInterceptor | Screen receives |
|---|---|---|
| `{"detail": "msg"}` | Extracts `detail` → `ApiException(code, "msg")` | `DioException.error` is `ApiException` |
| `[{"msg": "..."}]` (validation) | Falls back to generic message | Screen-level `parseAuthError` handles list format |
| Network error | Passes through as-is | `DioException` with `type: connectionError` |

### Screen-Level Error Handling

```dart
try {
  await ref.read(authProvider.notifier).login(email, password);
} on DioException catch (e) {
  final detail = (e.error is ApiException)
      ? (e.error as ApiException).detail
      : 'Something went wrong';
  showError(detail);
}
```

Always catch `DioException` (not `ApiException`) and unwrap the inner error.

## Deployment (Django Serving Flutter)

### Dockerfile Pattern (Multi-Stage)

```dockerfile
# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:X.XX.X AS flutter-build
WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ ./
RUN flutter build web --release --dart-define=API_URL=

# Stage 2: Django runtime
FROM python:3.13-slim AS runtime
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project
COPY backend/ ./backend/
COPY --from=flutter-build /app/frontend/build/web/ ./backend/staticfiles/flutter/
RUN SECRET_KEY=placeholder uv run python backend/manage.py collectstatic --noinput
CMD ["sh", "-c", "cd backend && uv run python manage.py migrate && uv run gunicorn config.wsgi --bind 0.0.0.0:${PORT:-8000}"]
```

### WhiteNoise Configuration

```python
# Production settings
WHITENOISE_ROOT = STATIC_ROOT / "flutter"  # Serves Flutter files at root paths
TEMPLATES = [{"DIRS": [BASE_DIR / "staticfiles"]}]  # Finds flutter/index.html
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
```

- `WHITENOISE_ROOT` serves Flutter's `main.dart.js`, `flutter.js`, etc. at root URLs (before Django routing)
- Template dirs include `staticfiles/` so the catch-all `TemplateView` finds `flutter/index.html`

### Version Sync

When bumping Flutter SDK in `pubspec.yaml`, immediately update the Dockerfile Flutter image tag. These must match. Consider using a build arg for the Flutter version.

## CORS (Development Only)

```python
if DEBUG:
    CORS_ALLOWED_ORIGINS = ["http://localhost:3000"]  # Flutter dev server
```

Only needed when Flutter dev server (port 3000) and Django (port 8000) run on different ports. Production serves everything from one origin.

## Cross-Origin URL Handling

Local media URLs must be absolute in dev (cross-origin between ports 3000 and 8000). Either:
- Add `SITE_URL` setting that prefixes media paths
- Or always return full URLs from the API

Relative URLs work in production (same origin) but break in dev (different ports).

## Makefile CI Pipeline

```makefile
ci: lint check test frontend-lint frontend-test
```

Both stacks must pass before any commit:
1. `lint` — autoflake + isort + black (Python)
2. `check` — Django system checks
3. `test` — pytest
4. `frontend-lint` — dart format check + dart analyze
5. `frontend-test` — flutter test

Never run `flutter test` directly — always via `make ci` or `make frontend-test`.

## Development Workflow

```bash
make dev    # Runs Django :8000 + Flutter :3000 concurrently
```

- Django serves API at `localhost:8000/api/`
- Flutter dev server at `localhost:3000` with hot reload
- CORS allows cross-origin requests in DEBUG mode
- `API_URL` defaults to `http://localhost:8000` in Flutter dev builds

## Common Integration Bugs

1. **Doubled `/api/api/` paths**: API prefix in both Dio baseUrl AND route strings
2. **SPA catch-all swallows assets**: Missing file extension in negative lookahead regex
3. **Cross-origin media 404s in dev**: Relative media URLs resolve against Flutter's port 3000, not Django's port 8000
4. **Django choice values drift from Flutter**: No compile-time contract — search both stacks when changing choices
5. **Dockerfile Flutter version mismatch**: pubspec.yaml SDK constraint bumped without updating Docker image
6. **Email links to deleted Django views**: Email templates must link to Flutter routes after SPA migration
7. **Truthy .env placeholders**: `B2_BUCKET_NAME=your-bucket` causes URL construction for a non-existent bucket while storage falls back to local
