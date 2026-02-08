.PHONY: help install run down restart test clean format lint check migrate createsuperuser db-start db-stop

help:
	@echo "Available commands:"
	@echo "  make install          Install dependencies"
	@echo "  make run             Run Django development server"
	@echo "  make down            Stop Django server (kill port 8000)"
	@echo "  make restart         Restart Django server"
	@echo "  make test            Run tests"
	@echo "  make clean           Remove unused imports and variables"
	@echo "  make format          Format code with black"
	@echo "  make lint            Run all linting (clean + format + sort imports)"
	@echo "  make check           Run Django system checks"
	@echo "  make migrate         Run database migrations"
	@echo "  make createsuperuser Create Django superuser"
	@echo "  make db-start        Start local PostgreSQL (Docker)"
	@echo "  make db-stop         Stop local PostgreSQL (Docker)"

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
