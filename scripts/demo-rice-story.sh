#!/usr/bin/env bash
# Plays the "out of rice" story in the iOS Simulator: Alex runs out of rice, Bea down the hall
# brings a cup, Alex cooks as planned and Bea earns Kindness points.
#
# Usage: scripts/demo-rice-story.sh [--device "iPhone 16 Pro"] [--pace SECONDS] [--record demo.mov]
#   --device  Simulator to use (default: the first available iPhone)
#   --pace    Seconds to hold on each beat (default: 0.5)
#   --record  Also save a screen recording of the run to this file
set -euo pipefail

cd "$(dirname "$0")/.."

device_name=""
pace="0.5"
record=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --device) device_name="$2"; shift 2 ;;
        --pace) pace="$2"; shift 2 ;;
        --record) record="$2"; shift 2 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

command -v xcodegen >/dev/null || { echo "Install XcodeGen first: brew install xcodegen" >&2; exit 1; }

# Pick the Simulator.
if [[ -n "$device_name" ]]; then
    line=$(xcrun simctl list devices available | grep -F "    $device_name (" | head -n 1 || true)
else
    line=$(xcrun simctl list devices available | grep -E '^ +iPhone' | head -n 1 || true)
fi
udid=$(sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' <<<"$line")
if [[ -z "$line" || -z "$udid" ]]; then
    echo "No matching iPhone simulator. See: xcrun simctl list devices available" >&2
    exit 1
fi
echo "Using: $(sed -E 's/^ +//; s/ \(.*//' <<<"$line")"

# Boot it and bring the Simulator window up.
xcrun simctl boot "$udid" 2>/dev/null || true
open_simulator_window() {
    local app
    for app in "$(xcode-select -p)/Applications/Simulator.app" \
        "$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.iphonesimulator'" 2>/dev/null | head -n 1)"; do
        if [[ -n "$app" && -d "$app" ]]; then
            open "$app" --args -CurrentDeviceUDID "$udid" && return 0
        fi
    done
    open -b com.apple.iphonesimulator --args -CurrentDeviceUDID "$udid" 2>/dev/null
}
if ! open_simulator_window; then
    echo "Warning: couldn't open the Simulator window. The demo still runs, and --record still saves a video." >&2
    echo "To watch it live, open Xcode > Open Developer Tool > Simulator, then rerun." >&2
fi
xcrun simctl bootstatus "$udid" -b >/dev/null

# Build first, so a recording starts with the demo and not the build.
xcodegen generate --quiet
derived="build/demo"
echo "Building..."
xcodebuild build-for-testing -project Favorly.xcodeproj -scheme Favorly \
    -destination "id=$udid" -derivedDataPath "$derived" -quiet

# The video is written by the Simulator host; simctl only finishes it when it gets SIGINT. If the
# client dies or is stopped first, the file stays empty and the device refuses new recordings
# ("Host recording is already in progress") until it reboots.
recorder=""
recorder_log=""
stop_recording() {
    if [[ -z "$recorder" ]]; then
        return
    fi
    kill -INT "$recorder" 2>/dev/null || true
    local _
    for _ in {1..30}; do
        kill -0 "$recorder" 2>/dev/null || break
        sleep 0.5
    done
    if kill -0 "$recorder" 2>/dev/null; then
        echo "Warning: the recorder didn't stop; $record may be incomplete." >&2
    else
        wait "$recorder" 2>/dev/null || true
    fi
    recorder=""
    if [[ -s "$record" ]]; then
        echo "Recording saved to $record"
    else
        echo "Recording failed; $record is empty. Recorder output:" >&2
        cat "$recorder_log" >&2
    fi
    rm -f "$recorder_log"
}
trap stop_recording EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if [[ -n "$record" ]]; then
    recorder_log=$(mktemp)
    # Own process group, so Ctrl-C or Ctrl-Z in the terminal reaches only this script, and the
    # EXIT trap stops the recorder exactly once.
    set -m
    xcrun simctl io "$udid" recordVideo --force "$record" >"$recorder_log" 2>&1 &
    recorder=$!
    set +m
    sleep 2
    if ! kill -0 "$recorder" 2>/dev/null; then
        recorder=""
        echo "Couldn't start the screen recording:" >&2
        cat "$recorder_log" >&2
        if grep -q "already in progress" "$recorder_log"; then
            echo "An earlier recording was left running. Reboot the Simulator and rerun:" >&2
            echo "  xcrun simctl shutdown $udid" >&2
        fi
        rm -f "$recorder_log"
        exit 1
    fi
fi

echo "Playing the rice story..."
TEST_RUNNER_FAVORLY_DEMO=1 TEST_RUNNER_DEMO_PACE="$pace" \
    xcodebuild test-without-building -project Favorly.xcodeproj -scheme Favorly \
    -destination "id=$udid" -derivedDataPath "$derived" \
    -only-testing:FavorlyUITests/RiceStoryDemoUITests -quiet
echo "Done."
