# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vedgy is an open-source vegan housing platform built with Django 5.2 / Python 3.13. It connects vegan renters with vegan-friendly housing. Server-side rendered with HTMX + Alpine.js for interactivity, styled with Tailwind CSS (via CDN).

## Development Commands

All commands use the Makefile and [uv](https://docs.astral.sh/uv/) for dependency management:

```bash
make db-start         # Start local PostgreSQL via Docker
make db-stop          # Stop local PostgreSQL
make install          # Install dependencies via uv sync
make run              # Run dev server on localhost:8000
make test             # Run pytest
make lint             # Run autoflake + isort + black (clean, sort-imports, format)
make migrate          # makemigrations + migrate
make createsuperuser  # Create Django admin user
make check            # Django system checks
```

Local dev setup: `cp .env.example .env`, then `make install && make db-start && make migrate && make run`.

### Flutter frontend commands

```bash
make frontend-install   # flutter pub get
make frontend-run       # Run Flutter dev server with hot reload (localhost:3000, any browser)
make frontend-build     # Build Flutter web release (requires API_URL env var)
make frontend-codegen   # Regenerate freezed/riverpod/json code after model changes
make frontend-test      # Run Flutter test suite
make dev                # Run Django backend + Flutter frontend concurrently
```

Flutter setup: `make frontend-install`, then `API_URL=http://localhost:8000 make frontend-build` or `make frontend-run`.
After editing any `@freezed` or `@riverpod` annotated file, run `make frontend-codegen` to regenerate the `.freezed.dart` and `.g.dart` files.

To run a single test file or test function:
```bash
cd backend && uv run python -m pytest tests/test_views.py
cd backend && uv run python -m pytest tests/test_views.py::TestClassName::test_function_name
```

Pytest config is in `pyproject.toml`. Tests use `reuse-db` and the `django_db` marker for database access.

## Architecture

### Django Project Layout

```
backend/
├── config/          # Django project settings, urls, wsgi
├── listings/        # Main app: models, views, forms, utils, schemas
├── users/           # Custom User model (email-based auth, UUID PKs)
├── templates/       # All HTML templates (Django template engine)
└── tests/           # Integration tests (conftest.py has shared fixtures)
```

The Django backend is both a server-rendered app and a REST API. The REST API (Django Ninja) lives under `/api/` and provides auth and listings endpoints consumed by the Flutter web frontend. The legacy HTMX/server-rendered views are still active under the root URL patterns. The only non-API JSON endpoint is the draft auto-save (`/listings/save-draft/`), which uses Pydantic for partial validation.

### Key Models

- **User** (`users/models.py`): Custom `AbstractUser` with email as `USERNAME_FIELD`, UUID primary key
- **Listing** (`listings/models.py`): Housing listing with UUID PK, status flow: `draft → payment_submitted → active → expired/deactivated`. Auto-expires after 30 days via `activate_listing()`.
- **ListingPhoto** (`listings/models.py`): FK to Listing, stores filename only (up to 10 per listing)

### Photo Storage

Photos are handled in `listings/utils.py`. They are validated (type, size, PIL verification), resized to 800x600, converted to JPEG (85% quality), and uploaded to Backblaze B2 (with local filesystem fallback). The `context_processors.py` provides the photo URL base to templates. HEIC/HEIF formats are supported.

### Frontend Patterns

- **Base template** (`templates/base.html`): nav, footer, Django messages
- **HTMX**: Used for listing filter/browse (`_listings_partial.html` is the partial)
- **Alpine.js**: Used for interactive UI components
- **Forms**: Django ModelForms with Tailwind CSS widget classes applied in `forms.py`

### URL Routing

Django server-rendered routes live at the root level. `config/urls.py` includes `listings/urls.py` which defines: `/`, `/browse/`, `/listing/<id>/`, `/create/`, `/edit/<id>/`, `/dashboard/`, auth routes, etc. The REST API routes are mounted under `/api/` via Django Ninja (see the architecture description above).

## Environment & Deployment

- **Dev database**: SQLite (default via `dj-database-url`)
- **Prod database**: PostgreSQL via `DATABASE_URL`
- **Deployed on**: Railway (`railway.json` runs migrate + collectstatic + gunicorn)
- **Static files**: WhiteNoise
- **Required env vars**: `SECRET_KEY`, `DATABASE_URL`, `B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_BUCKET_ID`, `B2_BUCKET_NAME` (see `.env.example`)

## Security Considerations

- Rate limiting on auth endpoints (django-ratelimit): signup 5/hr, login 10/hr
- Open redirect prevention in login/signup views
- Path traversal protection in photo deletion
- File upload validation: type checking, size limits (10MB), PIL image verification
Use 'bd' for task tracking
