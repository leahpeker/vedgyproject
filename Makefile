.PHONY: help install run down restart test clean format lint check migrate createsuperuser

PYTHON := venv/bin/python

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
	pip3 install -r requirements.txt

run:
	$(PYTHON) run-django.py

down:
	@lsof -ti:8000 | xargs kill -9 2>/dev/null || echo "No process running on port 8000"

restart: down
	@sleep 1
	@$(PYTHON) run-django.py

test:
	cd backend && pytest

clean:
	autoflake --in-place --remove-all-unused-imports --remove-unused-variables --recursive backend/listings/ backend/veglistings_project/ backend/tests/

format:
	black backend/listings/ backend/veglistings_project/ backend/tests/

isort:
	isort backend/listings/ backend/veglistings_project/ backend/tests/

lint: clean isort format
	@echo "✨ Code cleanup complete!"

check:
	cd backend && ../$(PYTHON) manage.py check

migrate:
	cd backend && ../$(PYTHON) manage.py makemigrations
	cd backend && ../$(PYTHON) manage.py migrate

createsuperuser:
	cd backend && ../$(PYTHON) manage.py createsuperuser
