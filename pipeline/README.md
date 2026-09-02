# Deterministic APK Construction Pipeline

This directory is the construction-control boundary for the Android artifact pipeline.

## State discipline

Every material object MUST have an explicit lifecycle state:

`OBSERVED -> IMPORTED -> DERIVED -> PROPOSED -> CREATED -> VERIFIED`

A state transition is valid only when its evidence is recorded. Discussion, hypotheses, and plans are never treated as created implementation.

## Object identity

Material objects are identified by canonical SHA-256 content digests. The canonical representation is UTF-8 with LF line endings for text artifacts. Binary artifacts are hashed byte-for-byte. Manifests use deterministic key ordering and newline termination.

## Transformation identity

Every transformation records:

- parent object IDs and input hashes
- operation ID and operation version
- toolchain identity
- parameter/configuration hash
- output object hashes
- result state
- verification IDs

The ledger is append-only by convention: corrections create new records rather than mutating history.

## Release boundary

An APK may cross the release boundary only after:

1. source/toolchain inputs are identified;
2. construction succeeds;
3. APK bytes exist and are non-empty;
4. APK structure/manifest identity is independently inspected;
5. cryptographic digests are recorded;
6. the construction record is bound to the exact Git commit;
7. all required verification gates pass.

Artifact upload happens only after these gates pass.

## Scope

The scaffold intentionally contains control-plane primitives, evidence schemas, and verification machinery only. EMV implementation features are not silently introduced by the scaffold.
