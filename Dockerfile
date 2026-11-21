FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# product photos uploaded by the admin live here: mount a volume on it
VOLUME ["/srv/app/static/uploads"]

EXPOSE 8000

# the container is behind your own proxy, so trust X-Forwarded-For only if you set TRUST_PROXY
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
