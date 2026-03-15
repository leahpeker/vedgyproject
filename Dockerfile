# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.41.4 AS flutter-build

WORKDIR /app/frontend
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY frontend/ ./
RUN flutter build web --release --dart-define=API_URL=/api


# Stage 2: Python / Django runtime
FROM python:3.13-slim AS runtime

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Install Python dependencies (cached layer)
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

# Copy backend source
COPY backend/ ./backend/
COPY static/ ./static/

# Copy Flutter build output into Django staticfiles
COPY --from=flutter-build /app/frontend/build/web/ ./backend/staticfiles/flutter/

# Collect static files (Flutter assets + Django static)
RUN DJANGO_SETTINGS_MODULE=config.settings \
    SECRET_KEY=collectstatic-placeholder \
    uv run python backend/manage.py collectstatic --noinput

EXPOSE ${PORT:-8000}

CMD ["sh", "-c", "cd backend && uv run python manage.py migrate && uv run gunicorn config.wsgi --bind 0.0.0.0:${PORT:-8000}"]
