#!/bin/bash
# Captures one screenshot per Design Tour screen (DEBUG build required).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:-iPhone 17 Dev}"
OUT="$ROOT/.comparison-screenshots/ours"
DERIVED="/tmp/devotionlock-dd"
BUNDLE_ID="com.devotionlock.mobile"

DESTS=(
  authWelcome authSignUp authSignIn
  onboardingEntry onboardingGoal onboardingIntention onboardingVoice onboardingNotifications onboardingRecap
  home conversations insights profile
  journalMood journalMadLibs journalComplete
  paywall devotionComplete splash streak
)

mkdir -p "$OUT"

echo "Building…"
xcodebuild -scheme DevotionLock \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DERIVED" \
  build -quiet

xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
sleep 2

xcrun simctl install "$DEVICE" "$DERIVED/Build/Products/Debug-iphonesimulator/DevotionLock.app"
xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" -design-tour-audit

CONTAINER="$(xcrun simctl get_app_container "$DEVICE" "$BUNDLE_ID" data)"
READY_FILE="$CONTAINER/Documents/design-tour-ready.txt"

wait_for_screen() {
  local dest="$1"
  local attempts=0
  while [ "$attempts" -lt 80 ]; do
    if [ -f "$READY_FILE" ] && [ "$(cat "$READY_FILE")" = "$dest" ]; then
      sleep 1.0
      return 0
    fi
    sleep 0.25
    attempts=$((attempts + 1))
  done
  echo "Warning: timed out waiting for $dest (got: $(cat "$READY_FILE" 2>/dev/null || echo none))"
  sleep 1.0
}

for dest in "${DESTS[@]}"; do
  wait_for_screen "$dest"
  xcrun simctl io "$DEVICE" screenshot "$OUT/$dest.png"
  echo "Captured $dest.png"
done

echo "Done — screenshots in $OUT"
