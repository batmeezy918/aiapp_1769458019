# Determinism + SIM2XR Foundation

## Purpose

This document defines the governance boundary for the deterministic APK
construction pipeline. It does not assert byte-for-byte reproducibility until
that property is empirically demonstrated by repeated independent builds.

## SIM2XR interpretation

SIM2XR is used here as a **state-projection and admissibility discipline**,
not as a substitute for a build proof.

The pipeline state is treated as:

`Psi = (source, toolchain, dependencies, configuration, environment, artifacts, evidence)`

A canonical projection retains acceptance-relevant observables:

`Pi(Psi) = (commit, wrapper integrity, dependency policy, canonical environment, artifact identity, verification state)`

A transformation is admissible only when its declared inputs and outputs are
bound to explicit identities and the required gates pass. The projection is
therefore a control boundary: it prevents irrelevant implementation detail
from being mistaken for verified build identity, while retaining the
observables needed to establish provenance and release eligibility.

## State machine

`OBSERVED -> IMPORTED -> DERIVED -> PROPOSED -> CREATED -> VERIFIED`

The following transitions are distinct:

- **CREATED:** required artifact bytes exist and have a cryptographic identity.
- **VERIFIED:** defined verification gates passed for those exact bytes.
- **RELEASE:** promotion is permitted only after the verification record binds
  the artifact to the exact construction context.

No state transition may be inferred merely from discussion, source presence,
or a successful earlier run.

## Determinism hazards addressed at the foundation

1. **Wrong source revision** — exact `GITHUB_SHA` must equal `HEAD`.
2. **Hidden working-tree mutation** — dirty/untracked repository state fails.
3. **Dependency drift** — dynamic selectors and `SNAPSHOT` inputs fail.
4. **Toolchain drift** — the Gradle distribution URL and SHA-256 are pinned.
5. **Locale/time-zone drift** — build governance fixes `LC_ALL=C`, `LANG=C`,
   and `TZ=UTC`.
6. **Wall-clock provenance ambiguity** — `SOURCE_DATE_EPOCH` is derived from
   the immutable commit timestamp rather than the runner clock.
7. **Unbound transformations** — object/transformation/verification schemas
   provide explicit identity and lineage records.
8. **Premature promotion** — artifact upload occurs after certification.

## Remaining empirical proof obligations

These are intentionally **not** declared solved by this scaffold:

- repeated clean builds produce identical APK SHA-256 values;
- Android/Gradle archive timestamps and ordering are fully normalized;
- dependency resolution is byte-for-byte reproducible across fresh runners;
- every generated artifact is derivable solely from declared inputs;
- release signing configuration is deterministic and appropriately isolated;
- external services or network-fetched resources cannot alter build output;
- the complete construction context can be reconstructed from the ledger.

These become explicit verification targets rather than hidden assumptions.

## Governing invariant

`RELEASE_ELIGIBLE(A) => exists C,V: BIND(C,A) and PASS(V,A,C)`

where `A` is the exact artifact byte object, `C` is its construction context,
and `V` is a verification record. The invariant is a governance target; each
concrete implication must be backed by executable evidence.
