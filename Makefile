.PHONY: help install run down restart test clean format lint check migrate createsuperuser

PYTHON := backend/venv/bin/python
PYTEST := backend/venv/bin/pytest

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

install:
	cd backend && venv/bin/pip install -r ../requirements.txt

run:
	cd backend && $(PYTHON) manage.py runserver

down:
	@lsof -ti:8000 | xargs kill -9 2>/dev/null || echo "No process running on port 8000"

restart: down
	@sleep 1
	@cd backend && ../$(PYTHON) manage.py runserver

test:
	cd backend && venv/bin/python -m pytest tests/ -v

clean:
	cd backend && ./venv/bin/python -m autoflake --in-place --remove-all-unused-imports --remove-unused-variables --recursive listings/ config/ tests/ || echo "⚠️  autoflake not available, skipping..."

format:
	cd backend && ./venv/bin/python -m black listings/ config/ tests/ || echo "⚠️  black not available, skipping..."

sort-imports:
	cd backend && ./venv/bin/python -m isort listings/ config/ tests/ || echo "⚠️  isort not available, skipping..."

lint: clean sort-imports format
	@echo "✨ Code cleanup complete!"

check:
	cd backend && ../$(PYTHON) manage.py check

migrate:
	cd backend && ../$(PYTHON) manage.py makemigrations
	cd backend && ../$(PYTHON) manage.py migrate

createsuperuser:
	cd backend && ../$(PYTHON) manage.py createsuperuser
