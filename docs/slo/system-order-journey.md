# System SLO: end-to-end order journey

Per-service SLOs ([order-api](order-api.md),
[fulfillment-worker](fulfillment-worker.md),
[notification-service](notification-service.md)) can each be individually
met while the thing a customer actually cares about — *"my order went
through and is on its way"* — still fails, if latency compounds across
the chain or a failure in one service silently strands an order in
another. This system-level SLO is the one that matters most and is the
one the eventual MCP agent layer (Phase 8) should prioritize protecting.

## SLI: Order journey completion latency

**Definition:** proportion of orders that reach `shipped` status within
60 seconds of the initial `POST /orders` request, out of all orders that
are not correctly rejected during validation.

**SLO:** 99% over a rolling 30 days.

**Error budget:** 1% of orders may take longer than 60s to reach
`shipped`, or ~1 in 100 orders.

**Why 60s:** derived from the per-service latency SLOs, not an
independent guess — 300ms (order-api) + 5s (fulfillment-worker,
95th percentile) + 2s (notification-service) leaves enormous headroom
to ~60s, intentionally loose so this budget is consumed mainly by
compounding/cascading effects (a slow fulfillment-worker also delaying
notification-service) and by Phase 7's deliberate incidents, rather than
by simulated per-service latency alone.

## SLI: Order journey completion rate

**Definition:** proportion of orders that eventually reach `shipped`
(no upper time bound), out of all orders not correctly rejected during
validation.

**SLO:** 99.9% over a rolling 30 days.

**Error budget:** 0.1% of valid orders may never reach `shipped` without
manual intervention.

This is deliberately stricter and separate from the latency SLI above:
a slow order is a degraded experience; an order that never ships is a
correctness failure regardless of how long you wait for it.

## Relationship to per-service error budgets

This system SLO's error budget is not simply the sum of the per-service
budgets — a system-level failure can consume this budget while every
individual service technically stays within its own. When both a
per-service SLO and this system SLO are burning budget simultaneously
for the same incident, treat it as one incident with one RCA
(`/docs/incidents/`), not three.
