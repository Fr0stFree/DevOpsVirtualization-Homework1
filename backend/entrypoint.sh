#!/bin/bash

echo "Collecting static files..."
python manage.py collectstatic --noinput || exit 1

echo "Applying database migrations..."
python manage.py migrate || exit 1

echo "Running the server..."
python manage.py runserver 0.0.0.0:8000