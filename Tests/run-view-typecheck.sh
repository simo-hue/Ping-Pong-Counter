#!/bin/bash
# Type-checks the pure-SwiftUI screens against the REAL SwiftUI and Charts frameworks.
#
# The app cannot be built here (no Xcode, no iOS SDK), and `swiftc -parse` only checks syntax —
# it would happily accept a Charts modifier with the wrong argument label. The macOS SDK ships
# both SwiftUI and Charts, so the screens that touch no UIKit can be fully type-checked by
# supplying a shim for the iOS-only view model. That catches the class of mistake most likely to
# break the Mac mini build.
#
# A handful of iOS-only view modifiers have no macOS equivalent; they are stripped from a temp
# copy before checking, and listed here so the exclusion stays honest.
#
#   ./Tests/run-view-typecheck.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Modifiers that exist only on iOS and occupy a line of their own; dropping them cannot mask an
# error in the surrounding code.
IOS_ONLY_MODIFIERS='navigationBarTitleDisplayMode|textInputAutocapitalization|scrollContentBackground'

# Inline iOS-only enum cases, rewritten to their macOS equivalents rather than deleted so the
# expression they sit in is still checked.
rewrite_ios_only() {
    sed -E \
        -e 's/\.navigationBarLeading/.cancellationAction/g' \
        -e 's/\.navigationBarTrailing/.confirmationAction/g'
}

VIEWS=(
    AppTheme
    StatsView
    MatchDetailView
    PlayerStatsView
    RosterView
    DoublesSetupView
    DoublesRosterStrip
    ShareCardView
    SettingsView
)

MODELS=(
    MatchRecord
    SetRecord
    RosterPlayer
    MatchClock
    Localized
    DoublesLineup
    StatsAggregates
)

SOURCES=("$ROOT/Tests/ViewChecks/ViewModelShim.swift")

for name in "${VIEWS[@]}"; do
    grep -vE "^[[:space:]]*\.($IOS_ONLY_MODIFIERS)\(" "$ROOT/PingPong/$name.swift" \
        | rewrite_ios_only > "$BUILD_DIR/$name.swift"
    SOURCES+=("$BUILD_DIR/$name.swift")
done

for name in "${MODELS[@]}"; do
    SOURCES+=("$ROOT/PingPong/$name.swift")
done

swiftc -typecheck -target arm64-apple-macos14.0 "${SOURCES[@]}"

echo "View type-check passed (${#VIEWS[@]} screens against real SwiftUI + Charts)"
