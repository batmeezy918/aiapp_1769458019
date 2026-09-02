#!/usr/bin/env bash
set -euo pipefail

# Determinism contract: fail closed on uncontrolled repository, dependency,
# locale, or toolchain inputs. This is a build-governance gate, not a claim
# that Android/Gradle byte-for-byte reproducibility has already been proven.
export LC_ALL=C
export LANG=C
export TZ=UTC

fail() {
  echo "DETERMINISM CONTRACT FAILURE: $1" >&2
  exit 1
}

# The workflow must build the exact commit it was dispatched for.
test -n "${GITHUB_SHA:-}" || fail "GITHUB_SHA is unset"
ACTUAL_COMMIT="$(git rev-parse HEAD)"
test "$ACTUAL_COMMIT" = "$GITHUB_SHA" || fail "checkout is not the requested commit"

# No untracked, ignored, staged, or modified repository content may silently
# participate in a build. Generated outputs are not present at this point.
test -z "$(git status --porcelain=v1 --untracked-files=all)" || fail "working tree is not clean"

# Required inputs must exist and be tracked by Git.
for f in \
  gradlew \
  gradle/wrapper/gradle-wrapper.jar \
  gradle/wrapper/gradle-wrapper.properties \
  settings.gradle.kts \
  app/build.gradle.kts \
  pipeline/schema/object-record.schema.json \
  pipeline/schema/transformation-record.schema.json \
  pipeline/schema/verification-record.schema.json
 do
  test -f "$f" || fail "missing required input: $f"
  git ls-files --error-unmatch "$f" >/dev/null || fail "required input is not tracked: $f"
done

# Reject dependency selectors that can resolve differently without a source
# commit changing. Versions must be explicit; lockfiles can strengthen this
# further later without changing this gate's semantics.
if grep -RInE --exclude-dir=.git --exclude='*.md' \
  '(^|["'"'"'=:[:space:]])([0-9]+\.[0-9]+\.[0-9]+)?[+*]|SNAPSHOT|latest\.release|latest\.integration' \
  build.gradle.kts settings.gradle.kts app/build.gradle.kts gradle pipeline 2>/dev/null; then
  fail "dynamic/SNAPSHOT dependency or version selector detected"
fi

# The wrapper must declare an integrity checksum and a pinned distribution URL.
grep -q '^distributionUrl=https\?://' gradle/wrapper/gradle-wrapper.properties \
  || fail "Gradle distribution URL is missing or not HTTPS"
grep -q '^distributionSha256Sum=[0-9a-f]\{64\}$' gradle/wrapper/gradle-wrapper.properties \
  || fail "Gradle distribution SHA-256 is missing or malformed"

# Canonical build environment is explicit rather than inherited from runner
# locale/timezone state.
printf '%s\n' \
  "commit=$ACTUAL_COMMIT" \
  "locale=$LC_ALL" \
  "timezone=$TZ" \
  "java=${JAVA_VERSION:-unset}" \
  "gradle_wrapper_sha256=$(grep '^distributionSha256Sum=' gradle/wrapper/gradle-wrapper.properties | cut -d= -f2)" \
  "source_date_epoch=$(git show -s --format=%ct "$ACTUAL_COMMIT")" \
  > determinism-contract.txt

# Canonical source-date value is derived from the immutable commit, never wall
# clock time. Consumers may use this value when a reproducible build setting
# supports it.
export SOURCE_DATE_EPOCH="$(git show -s --format=%ct "$ACTUAL_COMMIT")"
echo "Determinism contract: PASS"
