#!/bin/sh
# Captures the App Store screenshots on an iPhone simulator, with a clean status bar and no Dev Settings tab,
# into docs/release/screenshots/<size>. Run from the repo root:
#   sh scripts/make-store-screenshots.sh "iPhone 18 Pro Max" 6.9-inch   # 1320 × 2868
#   sh scripts/make-store-screenshots.sh "iPhone 17" 6.3-inch           # 1206 × 2622
set -eu
device="${1:-iPhone 18 Pro Max}"
out="$(pwd)/docs/release/screenshots/${2:-6.9-inch}"
mkdir -p "$out"
rm -f "$out"/*.png
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" >/dev/null
xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
TEST_RUNNER_STORE_SCREENSHOT_DIR="$out" xcodebuild test -project Favorly.xcodeproj -scheme Favorly \
  -destination "platform=iOS Simulator,name=$device" \
  -only-testing:FavorlyUITests/AppStoreScreenshotUITests -parallel-testing-enabled NO -quiet
xcrun simctl status_bar "$device" clear
ls "$out"
