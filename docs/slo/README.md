# SLOs and Error Budgets

This directory defines Service Level Indicators (SLIs), Service Level
Objectives (SLOs), and error budgets for OrderFlow, written **before** the
observability stack (Prometheus/Grafana, EFK) is built. The intent is that
Phase 6 (dashboards) instruments and visualizes exactly the SLIs defined
here, rather than the other way around — dashboards built to justify
whatever metrics happen to be easy to scrape.

## Concepts, briefly

- **SLI (indicator):** a precise, measurable ratio — good events / total
  events — that reflects whether a service is doing its job (e.g.
  non-5xx responses / all responses).
- **SLO (objective):** a target value for an SLI over a rolling window
  (e.g. 99.9% over 30 days). It's a promise to ourselves, not a contract.
- **Error budget:** `1 - SLO`, converted into an absolute allowance
  (minutes of downtime, or a count/proportion of bad events) for the
  window. Spending the whole budget is expected and fine; the budget
  exists to be spent on risk (deploys, experiments, deliberate incidents).
  Exceeding it is the signal that should change behavior.

All SLOs here use a **rolling 30-day window** (43,200 minutes) unless
stated otherwise, for consistency across services and because it's the
window the Google SRE workbook's multi-window burn-rate math assumes.

## Error budget policy

When a service's error budget is exhausted before the window resets:

1. New non-critical changes to that service are paused (this applies to
   Phase 4+ GitOps deploys — reliability fixes and rollbacks are exempt).
2. The next deliberate-incident exercise (Phase 7) targets a *different*
   service until the exhausted one recovers, so we aren't compounding
   failures on top of a service already known to be unhealthy.
3. An RCA is written even if no real user-facing incident triggered it —
   budget exhaustion itself is the trigger.

Burn-rate alerting (once Prometheus/Alertmanager exist in Phase 6) will
use two windows per the Google SRE workbook approach, so a brief severe
spike and a long mild leak both get caught without noisy single-window
alerts:

| Severity | Burn rate | Long window | Short window | Budget consumed |
|---|---|---|---|---|
| Page (fast burn) | 14.4x | 1h | 5m | 2% in 1 hour |
| Ticket (slow burn) | 6x | 6h | 30m | 5% in 6 hours |

This table is a forward-looking spec for Phase 6 alerting rules, not
something enforced yet — no metrics pipeline exists at this point in the
project.

## Summary

| Service | Primary SLI | SLO | Error budget / 30d |
|---|---|---|---|
| [order-api](order-api.md) | Availability (non-5xx) | 99.9% | 43.2 min |
| [order-api](order-api.md) | Latency (`POST /orders` < 300ms) | 99% | 432 min-equivalent (1% of requests) |
| [fulfillment-worker](fulfillment-worker.md) | Event processing success (reaches `fulfilled`) | 99.5% | 216 min-equivalent (0.5% of events) |
| [fulfillment-worker](fulfillment-worker.md) | Processing latency (`received`→`fulfilled` < 5s) | 95% | 5% of events |
| [notification-service](notification-service.md) | Notification delivery success | 99.9% | 0.1% of events |
| [system](system-order-journey.md) | End-to-end order journey (`received`→`shipped` < 60s) | 99% | 1% of orders |

Restricted-field access logging (audit completeness for `name`,
`address`, `phone`) is treated as a **hard invariant, not an
error-budgeted SLO** — see [order-api.md](order-api.md#data-access-compliance-not-error-budgeted)
for why that distinction matters.
