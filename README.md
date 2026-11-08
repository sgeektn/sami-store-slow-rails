# Sami Store: a Rails app that is slow on purpose

A small e-commerce app (products, categories, reviews, orders, customers) with **four performance bugs**, one per endpoint. Traces are sent to [SigNoz](https://signoz.io) with OpenTelemetry, so you can see each bug in a trace, fix it, and measure the difference.

`main` is the slow baseline. Every bug has its own fix branch, and `fixed` has them all.

| # | Endpoint | Bug | What the trace shows | Fix branch |
|---|----------|-----|----------------------|------------|
| 1 | `GET /products` | N+1 queries | About 400 near-identical DB spans under one request | `fix/01-n-plus-one` |
| 2 | `GET /orders?email=` | Missing index | One DB span that scans the whole `orders` table | `fix/02-missing-index` |
| 3 | `GET /api/products` | Heavy serialization | DB time is tiny, Ruby time builds a 2.4 MB JSON | `fix/03-serialization` |
| 4 | `POST /checkout` | Slow work inside the request | Payment and SMTP spans block the response | `fix/04-background-job` |

Each fix branch starts from `main`, so its diff contains only that fix and the test that proves it.

## Requirements

- Ruby 3.3+
- PostgreSQL 16 (a `docker-compose.yml` is included)
- SigNoz, self-hosted or Cloud
- Optional: [k6](https://k6.io) for load tests

## Setup

```bash
docker compose up -d db            # PostgreSQL on localhost:5432
bundle install
bin/rails db:create db:migrate db:seed
```

The seed (about 30 seconds) creates 50k products, 250k reviews and 1M orders. Use `SEED_PRODUCTS`, `SEED_ORDERS` and friends for a smaller dataset. The database settings come from `DB_HOST`, `DB_PORT`, `DB_USER` and `DB_PASSWORD`.

## Send traces to SigNoz

Install SigNoz by following the [official Docker guide](https://signoz.io/docs/install/docker/), or create a SigNoz Cloud account. Then start the app with the OTLP endpoint set:

```bash
# Self-hosted SigNoz (the collector listens for OTLP over HTTP on 4318 by default)
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318 bin/rails server

# SigNoz Cloud
OTEL_EXPORTER_OTLP_ENDPOINT=https://ingest.<region>.signoz.cloud:443 \
OTEL_EXPORTER_OTLP_HEADERS="signoz-ingestion-key=<your-key>" \
bin/rails server
```

Without `OTEL_EXPORTER_OTLP_ENDPOINT` the app runs with tracing off. `OTEL_SERVICE_NAME` defaults to `sami-store`.

## Reproduce the bugs

With the app running on `main`:

```bash
curl localhost:3000/products
curl "localhost:3000/orders?email=customer42@example.com"
curl localhost:3000/api/products > /dev/null
curl -X POST localhost:3000/checkout -d "email=customer42@example.com&product_id=7&quantity=1"
```

Then open the traces in SigNoz and look at the slowest requests for each route.

The checkout latency is simulated: `PAYMENT_LATENCY` (default 0.6 s) and `SMTP_LATENCY` (default 0.4 s).

## Measure before and after

The Ruby runner needs no dependencies. It sends requests one at a time and records p50, p95 and max latency.

```bash
# 1. Baseline, on main
git checkout main && bin/rails server -p 3000
ruby bench/run.rb --label before

# 2. After a fix (or on the fixed branch)
git checkout fixed           # restart the server
ruby bench/run.rb --label after

# 3. Compare
ruby bench/compare.rb before after
```

Run both measurements on the same machine, against the same seeded database, in the same Rails environment. The absolute numbers depend on your hardware, so compare the ratios.

For concurrent load, use the k6 scripts, for example:

```bash
k6 run bench/k6/products.js            # BASE_URL, VUS and DURATION are configurable
```

The k6 scripts are a convenience and are not part of the verified workflow above.

## Tests

```bash
bin/rails db:test:prepare
bin/rails test
```

The smoke tests pass on every branch. Each fix branch adds a test that fails on `main` and passes with the fix.

## The fixes

1. **N+1**: eager load `category`, `inventory` and `reviews` with `includes`, and compute the rating from the loaded reviews.
2. **Missing index**: add a composite index on `orders (customer_email, placed_at)`, which also serves the sort.
3. **Serialization**: select only the columns the client needs, drop the reviews and description from the list, and paginate.
4. **Slow work in the request**: create the order as `pending`, return `202`, and charge and email from a background job.

## Layout

```
app/controllers      one controller per bug
app/services         simulated payment provider and the span helper
config/initializers  OpenTelemetry setup (env vars only)
db/seeds.rb          set-based seed, about 30 s
bench/               Ruby runner, compare script and k6 scripts
```
