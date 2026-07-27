FROM python:3.13-slim

ENV FLASK_ENV=production \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

WORKDIR /app

RUN addgroup --system app && adduser --system --ingroup app app

COPY pyproject.toml requirements.lock ./
RUN pip install --no-cache-dir --requirement requirements.lock

COPY app ./app
COPY migrations ./migrations
COPY wsgi.py ./
RUN pip install --no-cache-dir --no-build-isolation --no-deps .

USER app

EXPOSE 8000

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} --workers 2 --threads 4 --timeout 60 wsgi:app"]
