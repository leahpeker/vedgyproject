---
name: django-flutter-project
description: Scaffold a new Django + Flutter project with Django Ninja API, JWT auth, Riverpod state management, GoRouter routing, Freezed models, uv, Docker, Makefile CI, and Railway deployment. Use when creating a new full-stack project from scratch.
argument-hint: "<project-name> [description]"
---

# Django + Flutter Project Scaffolding

Scaffold a production-ready Django API + Flutter SPA project with all tooling, CI, and deployment configuration.

## When Invoked

1. Parse the project name from args (required) and optional description
2. Confirm the target directory with the user
3. Execute the scaffolding steps below
4. Print a summary of what was created and next steps

## Project Structure to Generate

```
<project-name>/
├── backend/
│   ├── config/
│   │   ├── __init__.py
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── wsgi.py
│   │   └── asgi.py
│   ├── users/
│   │   ├── __init__.py
│   │   ├── models.py          # Custom User with UUID PK, email auth
│   │   ├── api.py             # Auth router: signup, login, refresh, me, password-reset
│   │   ├── admin.py
│   │   └── apps.py
│   ├── templates/
│   │   ├── password_reset_email.html
│   │   └── password_reset_subject.txt
│   ├── tests/
│   │   ├── __init__.py
│   │   └── conftest.py        # Shared fixtures
│   └── manage.py
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── api_config.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   └── auth_tokens.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   ├── services/
│   │   │   ├── api_client.dart
│   │   │   └── secure_storage.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   └── auth/
│   │   │       ├── login_screen.dart
│   │   │       └── signup_screen.dart
│   │   └── widgets/
│   │       └── app_scaffold.dart
│   ├── test/
│   │   └── helpers/
│   │       ├── test_fixtures.dart
│   │       └── fake_secure_storage.dart
│   ├── pubspec.yaml
│   ├── build.yaml
│   └── analysis_options.yaml
├── static/                     # Django static files (if any)
├── .env.example
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── Makefile
├── pyproject.toml
├── railway.json
├── CLAUDE.md
└── README.md
```

## File Templates

### pyproject.toml

```toml
[project]
name = "<project-name>"
version = "0.1.0"
description = "<description>"
requires-python = ">=3.13"
dependencies = [
    "django>=5.2,<6.0",
    "django-ninja>=1.4,<2.0",
    "django-ninja-jwt>=5.3,<6.0",
    "django-cors-headers>=4.6,<5.0",
    "psycopg[binary]>=3.2,<4.0",
    "python-dotenv>=1.1,<2.0",
    "dj-database-url>=3.0,<4.0",
    "whitenoise>=6.11,<7.0",
    "gunicorn>=23.0,<24.0",
    "pillow>=11.0,<12.0",
    "pydantic>=2.12,<3.0",
]

[dependency-groups]
dev = [
    "pytest>=8.4",
    "pytest-django>=4.11",
    "autoflake",
    "black",
    "isort",
]

[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"
addopts = "--verbose --strict-markers --tb=short --reuse-db"
markers = ["django_db: Mark test as requiring database access"]
filterwarnings = [
    "ignore:No directory at.*staticfiles:UserWarning:django.core.handlers.base",
    "ignore:'asyncio.iscoroutinefunction' is deprecated:DeprecationWarning:ninja.signature.utils",
]

[tool.black]
line-length = 100

[tool.isort]
profile = "black"
line_length = 100
```

### Makefile

```makefile
.PHONY: install run test lint check migrate createsuperuser seed db-start db-stop ci dev \
        frontend-install frontend-run frontend-build frontend-codegen frontend-lint \
        frontend-format frontend-test

# Backend
install:
	uv sync
	cd frontend && flutter pub get

run:
	cd backend && uv run python manage.py runserver 0.0.0.0:8000

test:
	cd backend && uv run python -m pytest tests/ -v

clean:
	cd backend && uv run autoflake --remove-all-unused-imports --remove-unused-variables -r --in-place .

format:
	cd backend && uv run black .

sort-imports:
	cd backend && uv run isort .

lint: clean sort-imports format

check:
	cd backend && uv run python manage.py check

migrate:
	cd backend && uv run python manage.py makemigrations && uv run python manage.py migrate

createsuperuser:
	cd backend && uv run python manage.py createsuperuser

# Database
db-start:
	docker compose up -d db

db-stop:
	docker compose down

# Frontend
frontend-install:
	cd frontend && flutter pub get

frontend-run:
	cd frontend && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

frontend-build:
	cd frontend && flutter build web --dart-define=API_URL=$(API_URL)

frontend-codegen:
	cd frontend && dart run build_runner build --delete-conflicting-outputs

frontend-lint:
	cd frontend && dart format --set-exit-if-changed lib/ test/ && dart analyze

frontend-format:
	cd frontend && dart format lib/ test/

frontend-test:
	cd frontend && flutter test

# CI (run before every commit)
ci: lint check test frontend-lint frontend-test

# Dev (concurrent backend + frontend)
dev:
	trap 'kill 0' SIGINT; make run & make frontend-run & wait
```

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: <project-name>
      POSTGRES_USER: <project-name>
      POSTGRES_PASSWORD: <project-name>
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Dockerfile (Multi-Stage)

```dockerfile
# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.41.4 AS flutter-build

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY frontend/ ./
RUN flutter build web --release --dart-define=API_URL=

# Stage 2: Python/Django runtime
FROM python:3.13-slim AS runtime

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY backend/ ./backend/
COPY static/ ./static/

COPY --from=flutter-build /app/frontend/build/web/ ./backend/staticfiles/flutter/

RUN DJANGO_SETTINGS_MODULE=config.settings \
    SECRET_KEY=collectstatic-placeholder \
    uv run python backend/manage.py collectstatic --noinput

EXPOSE ${PORT:-8000}

CMD ["sh", "-c", "cd backend && uv run python manage.py migrate && uv run gunicorn config.wsgi --bind 0.0.0.0:${PORT:-8000}"]
```

### railway.json

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### .env.example

```bash
# Database (dev: SQLite by default, prod: PostgreSQL)
DATABASE_URL=postgresql://<project-name>:<project-name>@localhost:5432/<project-name>

# Django
DEBUG=True
SECRET_KEY=

# Email (optional)
EMAIL_HOST=
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=

# File storage (optional — leave empty for local storage)
B2_KEY_ID=
B2_APPLICATION_KEY=
B2_BUCKET_ID=
B2_BUCKET_NAME=
```

All optional services use empty placeholder values (never truthy placeholder strings).

### .gitignore

```gitignore
# Python
__pycache__/
*.pyc
*.egg-info/
venv/
.venv/
*.db
*.sqlite3

# Environment
.env

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Uploads
media/
static/uploads/

# Flutter generated
frontend/.dart_tool/
frontend/build/
frontend/ios/
frontend/android/
frontend/.flutter-plugins
frontend/.flutter-plugins-dependencies
*.freezed.dart
*.g.dart

# Claude Code
.claude/
```

### backend/config/settings.py

Key sections to include:

```python
import os
from datetime import timedelta
from pathlib import Path

import dj_database_url
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR.parent / ".env")

# Environment detection (define ONCE)
IS_PRODUCTION = os.environ.get("RAILWAY_ENVIRONMENT") is not None

SECRET_KEY = os.environ.get("SECRET_KEY")
if not SECRET_KEY:
    if IS_PRODUCTION:
        raise ValueError("SECRET_KEY must be set in production")
    SECRET_KEY = "django-insecure-development-key-only"

DEBUG = os.environ.get("DEBUG", "False") == "True"

ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "ninja_jwt",
    "users",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    # ... rest of default middleware
]

AUTH_USER_MODEL = "users.User"

DATABASES = {"default": dj_database_url.config(default="sqlite:///db.sqlite3", conn_max_age=600)}

NINJA_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=15),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "AUTH_HEADER_TYPES": ("Bearer",),
}

# Static files
STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

if IS_PRODUCTION:
    WHITENOISE_ROOT = STATIC_ROOT / "flutter"
    STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

# CORS (dev only)
if DEBUG:
    CORS_ALLOWED_ORIGINS = ["http://localhost:3000"]

# Email
if IS_PRODUCTION:
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
else:
    EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
```

### backend/config/urls.py

```python
from django.contrib import admin
from django.urls import path, re_path
from django.views.generic import TemplateView
from ninja import NinjaAPI

from users.api import router as auth_router

api = NinjaAPI(title="<Project Name> API", version="1.0.0")
api.add_router("/auth/", auth_router, tags=["auth"])

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", api.urls),
    # Flutter SPA catch-all (MUST BE LAST)
    re_path(
        r"^(?!.*\.(js|css|json|wasm|png|jpg|ico|svg|ttf|otf|woff|woff2|map)$).*$",
        TemplateView.as_view(template_name="flutter/index.html"),
    ),
]
```

### backend/users/models.py

```python
import uuid
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, username=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]
    objects = UserManager()

    def save(self, *args, **kwargs):
        self.username = self.email
        super().save(*args, **kwargs)
```

### backend/users/api.py

Include endpoints:
- `POST /signup/` — Create user, return JWT tokens
- `POST /login/` — Authenticate, return JWT tokens
- `POST /refresh/` — Refresh access token
- `GET /me/` — Return current user (auth required)
- `POST /password-reset/` — Send reset email (always 200)
- `POST /password-reset-confirm/` — Validate token, set new password

Use error response pattern: `response={200: UserOut, 400: ErrorOut}`

### backend/tests/conftest.py

Include fixtures:
- `use_plain_staticfiles` (autouse) — Swap to plain StaticFilesStorage
- `api_client` — Django test client
- `test_user` — Standard user with JWT auth headers
- `auth_headers` — JWT Bearer token dict
- `other_user` + `other_auth_headers` — For permission tests

### frontend/pubspec.yaml

```yaml
name: <project_name>
description: <description>
version: 1.0.0+1

environment:
  sdk: ^3.11.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^4.0.2
  go_router: ^17.1.0
  dio: ^5.9.1
  flutter_secure_storage: ^10.0.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.11.0
  logging: ^1.3.0
  url_launcher: ^6.3.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.11.1
  freezed: ^3.2.5
  json_serializable: ^6.13.0
  riverpod_generator: ^4.0.3
  riverpod_lint: ^3.1.3
  mocktail: ^1.0.4
  network_image_mock: ^2.1.1

flutter:
  uses-material-design: true
```

### frontend/build.yaml

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake
          explicit_to_json: true
```

### frontend/analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: ^3.1.3

analyzer:
  errors:
    invalid_annotation_target: ignore
    non_abstract_class_inherits_abstract_member: ignore

linter:
  rules:
    avoid_unnecessary_containers: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_single_quotes: true
    require_trailing_commas: true
    sized_box_for_whitespace: true
    use_colored_box: true
```

### CLAUDE.md Template

Generate a project-specific CLAUDE.md with:
- Project overview (name, description, tech stack)
- All make commands
- Architecture section (project layout, key models, URL routing)
- Environment variables and deployment info
- Reference to `~/.claude/rules/standards-django-ninja.md`, `standards-flutter-riverpod.md`, `standards-django-flutter-integration.md`

## Scaffolding Steps

1. Create the directory structure
2. Write all configuration files (pyproject.toml, Makefile, docker-compose.yml, Dockerfile, railway.json, .env.example, .gitignore)
3. Write Django config (settings.py, urls.py, wsgi.py, asgi.py)
4. Write Users app (models.py, api.py, admin.py, apps.py)
5. Write email templates
6. Write test conftest.py
7. Run `flutter create --project-name=<name> frontend` to generate Flutter scaffolding
8. Replace generated Flutter files with the template files above
9. Run `cd frontend && flutter pub get`
10. Run `cd frontend && dart run build_runner build --delete-conflicting-outputs`
11. Run `uv sync`
12. Run `make db-start && make migrate`
13. Initialize git: `git init && git add -A && git commit -m "feat: scaffold <project-name> with Django + Flutter"`
14. Write CLAUDE.md and README.md
15. Print next steps:
    ```
    Project scaffolded! Next steps:
    1. cp .env.example .env
    2. make db-start && make migrate
    3. make createsuperuser
    4. make dev  (runs Django :8000 + Flutter :3000)
    5. make ci   (run before every commit)
    ```

## Key Decisions Baked In

- **UUID PKs everywhere** — Better for distributed systems, no sequential ID enumeration
- **Email-based auth** — No username field exposed to users
- **JWT with short-lived access tokens** — 15min access, 7-day refresh
- **Django Ninja over DRF** — Pydantic schemas, type-safe, auto OpenAPI docs
- **Riverpod over BLoC/Provider** — Code generation, auto-dispose, type-safe
- **GoRouter over Navigator 2.0** — Declarative routing with guards, deep links
- **Freezed for all models** — Immutable, `copyWith`, union types, JSON codegen
- **Mocktail over Mockito** — No code generation needed for mocks
- **uv over pip** — Fast, reliable, automatic venv management
- **Single `make ci`** — Both stacks must pass before any commit
- **Railway deployment** — Single Dockerfile, auto-deploy from git push
- **WhiteNoise** — Efficient static file serving without nginx/CDN in simple deployments
