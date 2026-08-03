#!/bin/bash
# Model-level regression checks for the scoring engine.
#
# These compile against the real PingPong/SetRecord.swift with a scripted stand-in for the parts
# of ScoreViewModel that cannot build outside iOS (it imports WatchConnectivity). They need only
# the Swift toolchain from the Command Line Tools — no Xcode, no simulator — so they can run
# anywhere, including in CI or before a build.
#
#   ./Tests/run-model-checks.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

swiftc -module-name PingPongTest -o "$BUILD_DIR/model-checks" \
    "$ROOT/Tests/ModelChecks/main.swift" \
    "$ROOT/PingPong/SetRecord.swift"

"$BUILD_DIR/model-checks"
