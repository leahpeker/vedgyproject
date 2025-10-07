#!/usr/bin/env python
"""Django development server entry point"""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

    # Add backend to Python path
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc

    # Run development server
    execute_from_command_line(['manage.py', 'runserver', '0.0.0.0:8000'])
