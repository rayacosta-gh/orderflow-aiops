# notification-service SLOs

`notification-service` consumes order status-change events and sends
mock (log-based) notifications. It's the lowest-stakes service in the
system — a missed or late notification doesn't affect whether an order
actually ships — so its SLOs are intentionally the loosest, and it's the
best candidate for early deliberate-incident exercises (Phase 7) since
breaking it has the smallest blast radius.

## SLI: Notification delivery success rate

**Definition:** proportion of status-change events that result in a
corresponding logged notification, out of all status-change events
consumed.

**SLO:** 99.9% over a rolling 30 days.

**Error budget:** 0.1% of status-change events may fail to produce a
notification log entry.

**Why the highest availability target despite being lowest-stakes:**
the operation itself is trivial (consume event, log a line) with no
simulated external dependency, so there's no principled reason to
tolerate more failure than that — the low stakes justify it being the
*first* service sacrificed under the error-budget policy's "pause
non-critical changes" rule, not a looser target.

## SLI: Notification latency

**Definition:** proportion of notifications logged within 2 seconds of
the triggering status-change event.

**SLO:** 95% over a rolling 30 days.

**Error budget:** 5% of notifications may take longer than 2s.

## Future measurement (Phase 6)

Backed by a counter of consumed events vs. emitted log lines
(`notifications_sent_total`) and a duration histogram
(`notification_latency_seconds`), scraped once Prometheus exists.
