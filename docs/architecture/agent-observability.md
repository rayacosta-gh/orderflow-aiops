# Agent-layer observability (forward-looking, decided ahead of Phase 8)

The observability stack (Phase 6) and the MCP-based remediation agent
(Phase 8) are separated by five phases in the build order, but the agent
generates a fundamentally different kind of telemetry than the
application/infra layer, and retrofitting a data model onto it after the
fact would be worse than deciding the shape now. This doc exists so
Phase 6's Prometheus/Grafana/EFK setup doesn't have to be revisited when
Phase 8 arrives — nothing here is built yet.

## Two distinct observability concerns

**Application/infra layer** (Phase 6, as originally scoped): request
latency, error rates, pod health, resource utilization, log aggregation
across `order-api`, `fulfillment-worker`, `notification-service`, via
Prometheus/Grafana and EFK. This is what the [SLOs](../slo/README.md)
are written against.

**Agent layer** (Phase 8, new category — not a subset of the above):

- Token usage and cost per remediation cycle
- Agent reasoning/tool-call loop latency, tracked separately from the
  latency of the remediation action it triggers (an agent that decides
  slowly and a remediation that executes slowly are different problems)
- Tool call success/failure rates — did an MCP tool call execute and
  return the expected result
- A decision audit trail: what the agent observed, decided, recommended
  or executed, and whether a human approved it
- Rate of agent-proposed remediations accepted, rejected, or overridden

## Decisions

**Prometheus scrapes the agent process too, same instance.** One
Prometheus, not two monitoring systems. Agent metrics get a distinguishing
label (`component="agent"`, alongside the existing per-service labels)
rather than living in a separate system a dashboard would have to context-
switch to. This mirrors the project's existing "one system of record"
bias (one Prometheus, one Grafana, one EFK stack for three languages).

**Agent decision/audit records get a dedicated Elasticsearch index,
separate from application logs** (e.g. `agent-audit-*` vs. an
application `logs-*` pattern). Reasons: the audit trail is a structured
decision record (observed/decided/executed/approved), not a free-text
log line, so it's a different schema entirely; audit trails plausibly
need different retention than routine debug logs; and this is the same
distinction already established for restricted-field access logging in
[order-api's SLO doc](../slo/order-api.md#data-access-compliance-not-error-budgeted)
— audit/compliance trails are treated as records to preserve and query
precisely, not as reliability signals to sample or roll up. Same
principle, second application of it.

**Grafana: separate dashboard, not a separate row bolted onto the
existing one.** When Phase 6 builds real dashboards, structure them as
one dashboard (or folder) per concern — e.g. "OrderFlow / Services" now —
rather than one monolithic dashboard. That makes adding an "OrderFlow /
Agent" dashboard in Phase 8 additive instead of a retrofit. Deliberately
*not* building an empty "Agent" row/panel now — an empty panel with no
data source is clutter, not preparation. The preparation is the folder
structure and naming convention, which costs nothing to decide today.

## What this means for Phase 6, concretely

- When metrics are defined for the three services, use a `component`
  or `service` label consistently (not baked into metric names), so
  the agent can later be added as just another labeled source rather
  than requiring new scrape configs or dashboard variables.
- When the EFK index strategy is decided, leave the naming scheme room
  for an `agent-audit-*` pattern alongside whatever the application log
  index pattern ends up being (exact naming TBD in Phase 6).
- Dashboard folder structure should be decided with "one more dashboard
  gets added later" in mind from the start.

No Prometheus scrape config, Elasticsearch index template, or Grafana
dashboard exists yet as of this writing (Phase 4) — this document
constrains Phase 6 decisions, not something to implement now.
