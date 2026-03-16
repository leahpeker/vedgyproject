# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vedgy is an open-source vegan housing platform built with Django 5.2 / Python 3.13. It connects vegan renters with vegan-friendly housing. The Django backend is API-only (Django Ninja) + admin panel. The Flutter web frontend (Riverpod + GoRouter + Dio) handles all UI.

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
make ci               # Run all pre-commit checks (lint, check, test, frontend-test)
make seed             # Seed DB with test users + listings (skips existing)
make seed-reset       # Delete and re-create all seed data
```

## Pre-commit Requirement

**Always run `make ci` before committing and fix any failures before proceeding.**

`make ci` runs in sequence: `lint` → `check` → `test` → `frontend-lint` → `frontend-test`. All must pass.

Never run `flutter test` directly — always use `make ci` or `make frontend-test`.

Local dev setup: `cp .env.example .env`, then `make install && make db-start && make migrate && make run`.

### Flutter frontend commands

```bash
make frontend-install   # flutter pub get
make frontend-run       # Run Flutter dev server with hot reload (localhost:3000, any browser)
make frontend-build     # Build Flutter web release (requires API_URL env var)
make frontend-codegen   # Regenerate freezed/riverpod/json code after model changes
make frontend-lint      # Run dart format check + dart analyze
make frontend-format    # Auto-format Dart files
make frontend-fix       # Auto-apply dart fix suggestions
make frontend-test      # Run Flutter test suite
make dev                # Run Django backend + Flutter frontend concurrently
```

Flutter setup: `make frontend-install`, then `API_URL=http://localhost:8000 make frontend-build` or `make frontend-run`.
After editing any `@freezed` or `@riverpod` annotated file, run `make frontend-codegen` to regenerate the `.freezed.dart` and `.g.dart` files.

To run a single test file or test function:
```bash
cd backend && uv run python -m pytest tests/test_api.py
cd backend && uv run python -m pytest tests/test_api.py::TestClassName::test_function_name
```

Pytest config is in `pyproject.toml`. Tests use `reuse-db` and the `django_db` marker for database access.


## Architecture

### Project Layout

```
backend/
├── config/          # Django project settings, urls, wsgi
├── listings/        # Main app: models, API endpoints, utils, schemas
├── users/           # Custom User model (email-based auth, UUID PKs)
├── templates/       # Email-only templates (password reset email)
└── tests/           # API and model tests (conftest.py has shared fixtures)
frontend/
└── lib/             # Flutter web app (Riverpod + GoRouter + Dio)
```

The Django backend is an API-only server (Django Ninja) under `/api/` plus the admin panel. All UI is handled by the Flutter web frontend. In production, Django serves the Flutter SPA via a catch-all route (GoRouter handles client-side routing).

### Key Models

- **User** (`users/models.py`): Custom `AbstractUser` with email as `USERNAME_FIELD`, UUID primary key
- **Listing** (`listings/models.py`): Housing listing with UUID PK, status flow: `draft → payment_submitted → active → expired/deactivated`. Auto-expires after 30 days via `activate_listing()`.
- **ListingPhoto** (`listings/models.py`): FK to Listing, stores filename only (up to 10 per listing)

### Photo Storage

Photos are handled in `listings/utils.py`. They are validated (type, size, PIL verification), resized to 800x600, converted to JPEG (85% quality), and uploaded to Backblaze B2 (with local filesystem fallback). HEIC/HEIF formats are supported.

### URL Routing

`config/urls.py` serves: admin panel (`/admin/`), API (`/api/`), and a Flutter catch-all for everything else. The REST API provides auth endpoints (`/api/auth/`) and listings endpoints (`/api/listings/`).

### Password Reset Flow

1. User requests reset via Flutter → `POST /api/auth/password-reset/` → Django sends email
2. Email contains link to Flutter route `/password-reset-confirm/<uidb64>/<token>/`
3. Flutter renders form, submits to `POST /api/auth/password-reset-confirm/`

## Environment & Deployment

- **Dev database**: SQLite (default via `dj-database-url`)
- **Prod database**: PostgreSQL via `DATABASE_URL`
- **Deployed on**: Railway (`railway.json` runs migrate + collectstatic + gunicorn)
- **Static files**: WhiteNoise
- **Required env vars**: `SECRET_KEY`, `DATABASE_URL`, `B2_KEY_ID`, `B2_APPLICATION_KEY`, `B2_BUCKET_ID`, `B2_BUCKET_NAME` (see `.env.example`)

## Security Considerations

- Path traversal protection in photo deletion
- File upload validation: type checking, size limits (10MB), PIL image verification
- JWT-based authentication for API endpoints
