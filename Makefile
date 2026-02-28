.PHONY: help install run down restart test clean format lint check migrate createsuperuser db-start db-stop \
        frontend-install frontend-run frontend-build frontend-codegen frontend-test dev

help:
	@echo "Backend commands:"
	@echo "  make install          Install Python dependencies (uv)"
	@echo "  make run              Run Django development server (localhost:8000)"
	@echo "  make down             Stop Django server (kill port 8000)"
	@echo "  make restart          Restart Django server"
	@echo "  make test             Run Django pytest suite"
	@echo "  make lint             Run autoflake + isort + black"
	@echo "  make check            Run Django system checks"
	@echo "  make migrate          makemigrations + migrate"
	@echo "  make createsuperuser  Create Django admin user"
	@echo "  make db-start         Start local PostgreSQL (Docker)"
	@echo "  make db-stop          Stop local PostgreSQL (Docker)"
	@echo ""
	@echo "Frontend commands:"
	@echo "  make frontend-install   flutter pub get"
	@echo "  make frontend-run       Run Flutter web server (localhost:3000)"
	@echo "  make frontend-build     Build Flutter web release"
	@echo "  make frontend-codegen   Regenerate freezed/riverpod/json code"
	@echo "  make frontend-test      Run Flutter test suite"
	@echo ""
	@echo "  make dev                Run Django + Flutter concurrently"

install:
	uv sync

run:
	cd backend && uv run python manage.py runserver

down:
	@lsof -ti:8000 | xargs kill -9 2>/dev/null || echo "No process running on port 8000"

restart: down
	@sleep 1
	@cd backend && uv run python manage.py runserver

test:
	cd backend && uv run python -m pytest tests/ -v

clean:
	cd backend && uv run python -m autoflake --in-place --remove-all-unused-imports --remove-unused-variables --recursive listings/ config/ tests/ || echo "autoflake not available, skipping..."

format:
	cd backend && uv run python -m black listings/ config/ tests/ || echo "black not available, skipping..."

sort-imports:
	cd backend && uv run python -m isort listings/ config/ tests/ || echo "isort not available, skipping..."

lint: clean sort-imports format
	@echo "Code cleanup complete!"

check:
	cd backend && uv run python manage.py check

migrate:
	cd backend && uv run python manage.py makemigrations
	cd backend && uv run python manage.py migrate

createsuperuser:
	cd backend && uv run python manage.py createsuperuser

db-start:
	docker compose up -d db
	@echo "PostgreSQL running on localhost:5432 (vedgy/vedgy)"

db-stop:
	docker compose down

# ---------------------------------------------------------------------------
# Flutter frontend
# ---------------------------------------------------------------------------

frontend-install:
	cd frontend && flutter pub get

frontend-run:
	cd frontend && flutter run -d web-server --web-port 3000

frontend-build:
	cd frontend && flutter build web --dart-define=API_URL=$$API_URL

frontend-codegen:
	cd frontend && dart run build_runner build --delete-conflicting-outputs

frontend-test:
	cd frontend && flutter test

# Run Django backend and Flutter web app concurrently.
# Ctrl-C stops both.
dev:
	@trap 'kill 0' INT; \
	  (make run) & \
	  (sleep 2 && make frontend-run) & \
	  wait
