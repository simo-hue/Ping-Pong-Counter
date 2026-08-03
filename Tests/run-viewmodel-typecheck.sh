#!/bin/bash
# Type-checks ScoreViewModel.swift — the largest and most-edited file in the app — on macOS.
#
# It cannot be compiled directly because it imports WatchConnectivity and leans on UIKit-,
# AudioToolbox- and ActivityKit-backed managers, none of which exist here. Stripping the import and
# supplying shape-only stubs makes the whole file type-check, which catches the errors `swiftc
# -parse` cannot see: a call to a property that does not exist in the enclosing type, a memberwise
# initialiser invoked with the wrong number of arguments, a renamed method, a wrong argument label.
#
# Those are precisely the mistakes that otherwise surface as a failed build on the Mac mini.
#
#   ./Tests/run-viewmodel-typecheck.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Drop the iOS-only import and the platform-gated WCSessionDelegate methods; the stubs stand in for
# both. Everything else in the file is checked as written.
sed -e 's/^@preconcurrency import WatchConnectivity$//' \
    -e 's/^import Combine$//' \
    "$ROOT/PingPong/ScoreViewModel.swift" > "$BUILD_DIR/ScoreViewModel.swift"

# `#if os(iOS)` blocks are skipped by the compiler on a macOS target, so they need no handling —
# but assert they are still gated, in case one is ever un-gated by accident.
if grep -q "sessionDidBecomeInactive" "$BUILD_DIR/ScoreViewModel.swift" && ! grep -q "#if os(iOS)" "$BUILD_DIR/ScoreViewModel.swift"; then
    echo "error: WCSessionDelegate iOS-only methods are no longer behind #if os(iOS)" >&2
    exit 1
fi

swiftc -typecheck -target arm64-apple-macos14.0 \
    "$BUILD_DIR/ScoreViewModel.swift" \
    "$ROOT/Tests/ViewChecks/PlatformStubs.swift" \
    "$ROOT/PingPong/MatchRecord.swift" \
    "$ROOT/PingPong/SetRecord.swift" \
    "$ROOT/PingPong/RosterPlayer.swift" \
    "$ROOT/PingPong/MatchClock.swift" \
    "$ROOT/PingPong/DoublesLineup.swift" \
    "$ROOT/PingPong/StatsAggregates.swift" \
    "$ROOT/PingPong/Localized.swift"

echo "View model type-check passed (ScoreViewModel against stubbed platform frameworks)"
