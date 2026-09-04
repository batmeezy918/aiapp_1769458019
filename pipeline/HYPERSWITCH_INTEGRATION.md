# HyperSwitch-derived integration boundary

## Purpose

This repository now records the HyperSwitch capability patterns that are useful to the EMV verification system. HyperSwitch is treated as a reference architecture, not as an authority for EMV semantics and not as code to copy wholesale.

## Findings

HyperSwitch separates a Router from a Scheduler (producer/consumer), uses Postgres plus Redis for durable state/cache/queueing, isolates payment data behind a locker/vault boundary, and exposes replaceable observability around metrics, logs, and traces. These are directly relevant to our verification architecture. [Source](https://github.com/juspay/hyperswitch/blob/main/docs/architecture.md)

The repository also contains dedicated card metadata, connector configuration, authentication, blocklist/card-testing controls, account updater, analytics, events, and external-services components. Its public documentation describes configurable routing, fallback behavior, retries, webhooks, disputes, refunds, mandates, reconciliation, and payment-data export. [Repository](https://github.com/juspay/hyperswitch) [Docs](https://github.com/juspay/hyperswitch-docs)

## What we adopt

1. **Router pattern** -> a single deterministic verification command plane.
2. **Scheduler producer/consumer pattern** -> queued verification work with bounded attempts.
3. **Connector abstraction** -> typed EMV/kernel/reference-executor adapters.
4. **Card metadata** -> versioned BIN/card semantic registry.
5. **Routing/fallback** -> capability/evidence-aware executor selection.
6. **Lifecycle events/webhooks** -> immutable verification event ledger and optional signed callbacks.
7. **Idempotency/API locking** -> replay-safe command identity.
8. **Reconciliation** -> source/claim/fixture/execution/reference/replay/certificate consistency checks.
9. **Observability** -> structured metrics, logs, traces and execution-cost accounting.
10. **Authentication/3DS boundary** -> separate deterministic authentication test domain.
11. **Fraud/blocklist/card-testing controls** -> adversarial negative-test domain.
12. **Account updater/config importer** -> versioned transformations requiring re-admission.

## What we deliberately do not adopt yet

- Live payment execution.
- Live PAN or payment credentials.
- Production vault handling.
- Redis as a new dependency before measured need.
- Read replicas before measured database pressure.
- Any assertion of EMVCo/network certification derived from HyperSwitch.

## Resulting control-plane model

`ADMIT -> NORMALIZE -> QUOTIENT -> INSTANTIATE -> QUEUE -> EXECUTE -> COMPARE -> FALSIFY -> REPLAY -> CERTIFY -> EXPORT`

Every stage must retain provenance and hashes. Certification is an evidence state, not a payment approval state. `paymentDecision` remains `NOT_EVALUATED`.

## Immediate implementation sequence

- Repair the existing GitHub determinism gate so the current APK pipeline can reach tests/build.
- Add the orchestration schema and validate it in CI.
- Add deterministic verification lifecycle events and idempotency keys.
- Add executor capability/routing records.
- Add reconciliation and adversarial test matrices to GitHub Actions.
- Use Floot for interactive control, durable evidence, visualization, and replay inspection.
- Use GitHub Actions for compute-heavy deterministic matrices and artifact production.
