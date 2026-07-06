# fulfillment-worker SLOs

`fulfillment-worker` consumes `order created` events, simulates inventory
check, payment authorization, and shipping trigger, and advances each
order through its state machine: `received` → `validated` → `fulfilled`
→ `shipped`. Unlike `order-api`, nothing calls it synchronously — its
reliability shows up as orders silently stuck partway through the state
machine rather than as failed HTTP requests, so its SLIs are event-based
rather than request-based.

## SLI: Event processing success rate

**Definition:** proportion of `order created` events that reach
`fulfilled` status without requiring manual intervention or retry
exhaustion, out of all `order created` events consumed.

- Excludes: orders that are correctly rejected during validation (e.g.
  simulated inventory-unavailable) — that's a valid terminal state, not
  a processing failure.
- Includes: events dropped, poison-pilled (repeatedly failing and
  exhausting retries), or left stuck due to worker crash/restart without
  resuming.

**SLO:** 99.5% over a rolling 30 days.

**Error budget:** 0.5% → up to 1 in 200 events may fail to reach
`fulfilled`. Looser than `order-api`'s availability target because this
service does more (three simulated downstream calls per order) and a
stuck order is recoverable via reprocessing, whereas a dropped HTTP
request is not.

## SLI: Processing latency

**Definition:** proportion of events where the time from `received` to
`fulfilled` is under 5 seconds.

**SLO:** 95% over a rolling 30 days.

**Error budget:** 5% of orders may take longer than 5s to fulfill.

**Why 5s and looser than order-api's 99%:** the simulated inventory
check, payment authorization, and shipping trigger are three sequential
steps; 5s is generous for three simulated calls but leaves room for
Phase 7's deliberate incidents (e.g. simulated downstream slowness)
to actually threaten this budget rather than being unaffected by them.

## SLI: Consumer lag (freshness)

**Definition:** proportion of 1-minute windows where consumer lag
(events published but not yet consumed) stays under 30 seconds.

**SLO:** 99% over a rolling 30 days.

**Error budget:** 1% of minutes may see lag exceed 30s.

**Why this SLI exists separately from processing latency:** processing
latency measures *individual* event handling time; lag measures whether
the worker is keeping up with the *rate* of incoming events. A worker
could process every event in under 5s individually while still falling
behind if events arrive faster than one-at-a-time processing — this is
exactly the kind of thing Phase 7 (killing pods, exhausting resources)
should be able to break on purpose.

## Future measurement (Phase 6)

Backed by: a state-transition counter per status
(`order_status_transitions_total{status="fulfilled"}`), a histogram of
transition duration, and consumer-lag gauge from the message broker
(exact broker TBD — Kafka or RabbitMQ — chosen when event infrastructure
is wired up, not yet decided as of Phase 1/2).
