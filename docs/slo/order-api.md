# order-api SLOs

`order-api` is the system's entry point: it accepts order submissions over
REST, validates them, writes to the database, and emits an `order created`
event. It's the only service a client talks to directly, so its
availability and latency set the floor for how the whole system feels.

## SLI: Availability

**Definition:** proportion of requests to `order-api` that return a
non-5xx response, over all requests, measured at the load balancer /
ingress edge (once one exists) or at the service itself in the interim.

- Excludes: requests rejected with 4xx due to caller error (bad input,
  missing auth) — those are correct behavior, not unavailability.
- Includes: 5xx from the service itself, timeouts, and connection
  failures.

**SLO:** 99.9% over a rolling 30 days.

**Error budget:** 0.1% → **43.2 minutes/month** of full-outage-equivalent
downtime (or a proportionally larger number of partial-failure requests —
e.g. 4,320 failed requests out of 4.32M).

**Why 99.9% and not higher:** this is a portfolio project simulating
real traffic, not a paid service with contractual uptime — three nines
is strict enough to make burn-rate alerting and error-budget policy
meaningful (Phase 6/7) without demanding infrastructure (multi-region,
active-active) that's out of scope for a single local cluster.

## SLI: Latency

**Definition:** proportion of `POST /orders` requests that complete in
under 300ms, measured server-side from request received to response
written.

**SLO:** 99% over a rolling 30 days.

**Error budget:** 1% of requests may exceed 300ms.

**Why 300ms:** `order-api` only validates and writes to a database and
publishes an event — no synchronous calls to `fulfillment-worker` or
`notification-service` — so 300ms is generous headroom over expected
p50, reserved for GC pauses, connection pool contention, and noisy-
neighbor effects on a shared minikube node.

## Future measurement (Phase 6)

Once Prometheus exists, these will be backed by a histogram metric
(e.g. `http_request_duration_seconds{handler="POST /orders"}`) and a
counter (`http_requests_total{code=~"5.."}`), which is why the SLIs
above are already phrased as ratios of countable events rather than
anything requiring a specific backend.

## Data access compliance (not error-budgeted)

Every field on the order model is tagged `public`, `internal`, or
`restricted` (`name`, `address`, `phone` are `restricted`). The API
layer must check the caller's role against field sensitivity before
including restricted fields in a response, and log every access to a
restricted field for audit purposes.

This is intentionally **not** expressed as an SLO with an error budget.
An error budget says "some amount of failure is acceptable and even
expected — spend it on risk." Unlogged access to a customer's name,
address, or phone number is never acceptable at any rate; it's a
correctness bug / compliance defect, not a reliability statistic to be
budgeted against. It gets tracked as a pass/fail invariant (covered by
tests) and, once logging pipelines exist, as an audit-completeness
check in Phase 6 — not as an SLI here.
