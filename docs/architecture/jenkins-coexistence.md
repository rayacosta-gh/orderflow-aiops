# Why Jenkins coexists with GitHub Actions (Phase 5)

The original brief for Phase 5 was narrow: run Jenkins/Maven for
`notification-service` alongside GitHub Actions, to demonstrate the
pipeline pattern. Taken literally that's a "look, I can also run
Jenkins" exercise — not a demonstration of judgment. In real
organizations Jenkins and GitHub Actions coexist for specific,
nameable reasons, not out of inertia. This doc ties each of those
reasons to something concretely built in this repo, verified working
end-to-end (`notification-service` build #1, `docker push` to the
internal registry confirmed via its `tags/list` API).

## 1. Migration in progress

`order-api` and `fulfillment-worker` are fully on GitHub Actions + ArgoCD
(Phase 4). `notification-service` alone stays on Jenkins. The asymmetry
*is* the demonstration: a real org migrating off Jenkins doesn't flip
every pipeline at once, it moves service-by-service, and for a while
some services are on the old system for reasons that are organizational
as much as technical. Here that's framed against this project's
existing restricted-data theme — `notification-service` handles
customer-facing communications, treated as "not yet cleared to run on
a third-party SaaS CI" pending its own review, distinct from
`order-api`/`fulfillment-worker` which don't carry that constraint.

## 2. On-prem / regulated / air-gapped

Jenkins runs as a controller + a separate SSH-launched build agent, both
defined in `ci/jenkins/docker-compose.yml`. The chosen posture is
**controlled build, isolated publish** — not full air-gapping. The
agent can still reach Maven Central to build (`ci/jenkins/agent/`
image), but has no path or credential to publish anywhere public. That
boundary isn't enforced by network firewalling; it's enforced by
credential scoping (see #4) — a more realistic and more common control
in practice than blocking egress entirely.

## 3. Different pipeline stages, not duplicated

GitHub Actions keeps owning build, test, dependency/image scanning
(Trivy), and push to the public registry (GHCR) — unchanged from Phase
4, for all three services including `notification-service`. Jenkins
does not repeat any of that. It owns one distinct, additional stage:
package + push to `internal-registry`, a `registry:3.1.1` container
defined in the same compose file, published only to
`127.0.0.1:5050` — a destination GitHub Actions' hosted runners
structurally cannot reach, since it only exists on this local compose
network. Jenkins and GitHub Actions are two pipelines with two
different jobs, not two pipelines doing the same job twice.

## 4. Blast-radius separation

Jenkins holds exactly one credential capable of pushing an image: the
`internal-registry` username/password (`ci/jenkins/controller/jenkins.yaml`),
scoped `GLOBAL` so pipeline steps can use it, and valid only against
the internal registry. It has no GHCR credential and no path to get
one. GitHub Actions' side is symmetric: its `GITHUB_TOKEN` is scoped to
GHCR only, per the existing per-service workflows from Phase 4.
Compromising either CI system does not grant any access via the other
— there is no shared credential to pivot on.

## What's concretely built vs. what's asserted

Built and verified:
- `ci/jenkins/docker-compose.yml` — controller, SSH-launched agent
  (`docker.sock`-mounted, not the controller — least privilege), and
  internal registry, all on an isolated `jenkins-internal` network.
- `ci/jenkins/controller/jenkins.yaml` — JCasC-defined security realm,
  agent node, credentials (scoped as described in #4), and the
  `notification-service` pipeline job itself (Pipeline-from-SCM,
  `apps/notification-service/Jenkinsfile`, triggered by `pollSCM` —
  this Jenkins instance isn't internet-reachable, so a GitHub webhook
  isn't an option here).
- `apps/notification-service/Jenkinsfile` — test → package → docker
  build → push to `localhost:5050` (the registry's host-published
  port; the agent does Docker-outside-of-Docker via the mounted
  socket, so it forwards to the *host* daemon and can't resolve
  compose-network DNS names like `internal-registry`).
- End-to-end run: build #1 succeeded through every stage; the pushed
  image is confirmed present via
  `GET /v2/notification-service/tags/list` against the internal
  registry.

Asserted, not built (and intentionally so — Phase 5 doesn't require
building a second real service migration or a real compliance review):
- The specific claim that `notification-service` is "not yet cleared"
  for SaaS CI (#1) is a narrative frame for the asymmetry, not a
  documented compliance finding.
- No network-level firewalling was attempted or needed for #2 — the
  credential-scoping control is the actual mechanism, and is fully
  built.

## Operational notes

- Admin credentials and the registry password live in `ci/jenkins/.env`
  (gitignored), regenerated fresh on every `docker compose up` since
  Jenkins config is fully JCasC-declarative — nothing is lost by
  tearing the stack down with `-v` between sessions.
- To trigger a build without waiting for `pollSCM`: fetch a CSRF crumb
  and POST to `/job/notification-service/build`, using a shared cookie
  jar between the crumb fetch and the POST (a bare
  `Jenkins-Crumb` header without matching session cookies is
  rejected even with a freshly issued valid crumb).
