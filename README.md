# Smart Delivery System

A multi-category online store (food, groceries, books, sports, gadgets, fashion, home, beauty) with a
shopping cart, checkout (Cash on Delivery + Razorpay), order tracking, customer accounts and an admin panel.

Built with FastAPI, SQLAlchemy, MySQL and plain HTML/CSS/JS (no build step).

## Features

**Store**
- Category sidebar, live search (every word must match), sort, sizes with prices, "from" prices
- Cart drawer (prices always calculated by the server), coupons, delivery fee, pincode check with delivery estimate
- Checkout as guest or logged-in customer, saved addresses, Cash on Delivery or online payment
- Order tracking by order number + mobile (`/track`), status timeline, cancel while pending
- Customer accounts (`/account`): My orders, addresses, profile, password
- Wishlist, related products, customer reviews (only after delivery), photo gallery, stock labels
- Phone bottom navigation bar

**Admin** (`/admin`)
- Orders: search, status / payment filters, detail window, status history, Excel export,
  automatic new-order alert (sound + toast) and optional Telegram / email alerts
- Products: add / edit, photo upload or free-photo finder, sizes, stock, extra photos
- Categories and coupons

## Run it locally

```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env      # then edit DATABASE_URL, ADMIN_PASSWORD, SESSION_SECRET_KEY
uvicorn app.main:app --reload
```

Open http://127.0.0.1:8000 (store) and http://127.0.0.1:8000/admin (admin).

## Upgrading an existing database (your product photos are safe)

On start the app only **adds** missing tables and columns. It never changes, drops or re-seeds existing
rows, so `products.image_url` and the files in `app/static/uploads/products/` stay exactly as they are
(this is covered by `tests/test_photo_safety.py`). The starter catalogue is loaded only when the
database has no categories at all.

Still, **take a backup before the first run of a new version**:

```powershell
mysqldump -u USER -p DATABASE_NAME > backup.sql
```

Also copy the `app/static/uploads` folder.

## Tests

```powershell
pip install -r requirements-dev.txt
python -m pytest
```

The tests use their own temporary SQLite database; your MySQL data and photos are not touched.

## Configuration

All settings are environment variables, see [.env.example](.env.example).

| Setting | Meaning |
| --- | --- |
| `COOKIE_SECURE` | `true` when served over HTTPS |
| `TRUST_PROXY` | `true` only behind your own proxy (real IP for rate limits) |
| `DELIVERY_FEE`, `DELIVERY_FREE_ABOVE` | Delivery charge and the order value above which it is free |
| `STORE_PINCODE`, `SERVICEABLE_PREFIXES` | Delivery estimate and optional serviceable areas |
| `RAZORPAY_*` | Online payments (off while the keys are empty) |
| `TELEGRAM_*`, `SMTP_*`, `ALERT_EMAIL_*` | Optional new-order alerts |

### Razorpay

1. Put `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` (use **test** keys first) in `.env`.
2. In the Razorpay dashboard add the webhook `https://YOUR-SITE/api/payments/webhook`
   with events `payment.captured` and `order.paid`, and copy its secret to `RAZORPAY_WEBHOOK_SECRET`.
3. The amount is always taken from the saved order, the payment signature is verified on the server and the
   webhook makes sure a payment is recorded even if the customer closes the tab.

## Deploy with Docker

```powershell
docker compose up --build -d
```

Put a reverse proxy (Caddy / Nginx) with HTTPS in front of port 8000, then set
`COOKIE_SECURE=true` and `TRUST_PROXY=true`. The `uploads` volume keeps product photos; back it up with the database.

## How safe is it?

- Prices, names and totals are computed on the server; the browser only sends product ids, sizes, quantities.
- Stock, coupon use and order creation happen in one database transaction with row locks.
- Passwords use PBKDF2-SHA256 (600,000 rounds); login, registration, checkout, tracking and payment calls are rate limited.
- Tracking needs the order number **and** the phone number; the phone is never put in a URL.
- Excel export neutralises spreadsheet formulas typed by customers.

## Known limits

- Rate limiting keeps counters in memory (one server). Use Redis if you run several.
- Schema upgrades are additive only (new tables / columns). Renaming or dropping columns would need Alembic migrations.
- Razorpay live payments, Telegram/email alerts and the Docker build were not run end-to-end in development.
