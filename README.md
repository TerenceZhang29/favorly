# Favorly iOS

[![CI](https://github.com/TerenceZhang29/favorly/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/TerenceZhang29/favorly/actions/workflows/ci.yml)

Favorly is a hyperlocal iOS app that lets neighbors post small help requests and pick them up. This repo holds the prototype (version 0.3.0): SwiftUI, fake data and a fake location, run in the iOS Simulator. Phase 1 built the flows, Phase 2 gave them their look, and Phase 3 added the Kindness score, profiles, chat and reviews.

| Nearby | Request detail | My Activity | Dark mode |
| --- | --- | --- | --- |
| ![Nearby list with a radius picker](docs/screenshots/nearby.png) | ![Request detail after a pick up](docs/screenshots/request-detail.png) | ![My Activity showing a claimed request](docs/screenshots/my-activity.png) | ![Nearby list in dark mode](docs/screenshots/nearby-dark.png) |

The Phase 1 plan is in [docs/PLAN.md](docs/PLAN.md), the Phase 2 (UI refresh) plan in [docs/PLAN-PHASE-2.md](docs/PLAN-PHASE-2.md), the Phase 3 (Kindness score, profiles, chat and reviews) plan in [docs/PLAN-PHASE-3.md](docs/PLAN-PHASE-3.md), the Phase 4 (App Store release with a real backend) plan in [docs/PLAN-PHASE-4.md](docs/PLAN-PHASE-4.md), the layering rules in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and the status and decision log in [docs/PROGRESS.md](docs/PROGRESS.md).

## Prerequisites

- A Mac with the latest stable Xcode and at least one iOS Simulator runtime (iOS 17 or later)
- Command-line builds pointed at Xcode: `sudo xcode-select -s /Applications/Xcode.app`
- Homebrew tools: `brew install xcodegen swiftlint swiftformat`

## Setup

The Xcode project is generated from `project.yml` and is not checked in.

```bash
git clone git@github.com:TerenceZhang29/favorly.git
cd favorly
xcodegen generate
```

Run `xcodegen generate` again after any change to `project.yml`.

## Run

```bash
open Favorly.xcodeproj
```

Pick an iPhone simulator and press Run. All data is in memory and resets on every launch.

The Run scheme passes `-demo`, so the app starts signed in as Alex with demo data and a Dev Settings tab. To try sign-up, untick `-demo` in Product → Scheme → Edit Scheme → Run → Arguments: the app then starts at the Welcome screen, as a downloaded app will. Until phase 4C the sign-in is a mock: Continue with Apple goes straight to profile setup, and every sign-up is a new user. Release builds have no Dev Settings tab.

### Run against the backend

Without `-demo`, the app runs as a downloaded app does: it signs in with Apple and uses the hosted Supabase project in `Config/Backend.xcconfig`. To try it, untick `-demo` in Product → Scheme → Edit Scheme → Run → Arguments (`xcodegen generate` ticks it again). Sign in with Apple needs a device, or a simulator signed in to an Apple ID, and the team in `Config/Local.xcconfig`.

To develop against the local backend instead:

1. In `backend/`, run `supabase start`, then `supabase status` for the API URL and anon key.
2. Put them in `Config/Local.xcconfig` (see `Config/Local.xcconfig.example`; write the URL as `http:/$()/127.0.0.1:55321`), and run `xcodegen generate`.
3. Sign in with Apple is not set up on the local backend, so add `-devEmail you@dev.local -devPassword any-password` to the Run arguments (Debug builds only). The first launch creates that account and asks for a profile.

Two simulators with two different `-devEmail` values see each other's requests, chat and reviews. Launches against a backend use the device's own location, asking for permission the first time; on a simulator, set it in the Simulator app under Features → Location (or `xcrun simctl location <device> set 40.762,-73.950`). Dev Settings location presets exist only in `-demo` launches. The session lives in the keychain, which survives deleting the app; sign out from the Profile tab to start again at Welcome.

### Run on your iPhone

This uses a free Apple ID; no paid developer account is needed. Your iPhone needs iOS 17 or later.

1. In Xcode → Settings → Accounts, add your Apple ID. This creates a free Personal Team.
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set `DEVELOPMENT_TEAM` to your team ID. The file is git-ignored, so your team ID stays on your Mac. If Xcode says the bundle identifier is not available, also set `FAVORLY_BUNDLE_ID` to something of your own.
3. Run `xcodegen generate`.
4. Plug in the iPhone, tap Trust This Computer, and turn on Settings → Privacy & Security → Developer Mode.
5. Pick the iPhone as the run destination and press Run. On the first launch, iOS asks you to trust the developer in Settings → General → VPN & Device Management.

With a free team the app stops opening after 7 days; press Run again to renew it.

## Test

```bash
# fast logic tests, no Simulator
swift test --package-path Packages/FavorlyKit

# list simulators, then pick an available iPhone name
xcrun simctl list devices available

# build and run all tests on a simulator
xcodebuild test -project Favorly.xcodeproj -scheme Favorly \
  -destination 'platform=iOS Simulator,name=<iPhone model from the list>'
```

The second command runs the package tests again on iOS, plus the UI tests. Each UI test class runs on its own clone of the simulator at the same time. The UI tests take minutes, so use `swift test` while working and run the full suite before pushing. `DemoFlowUITests` walks through the demo script below. UI tests launch the app with `-uiTesting`, which removes the 300 ms delay the mock data layer adds to mimic a network.

If `KeyboardUITests` fails because the Done key is "not visible", the simulator thinks a hardware keyboard is attached, which happens after you type into it from the Mac keyboard, and keeps the on-screen keyboard below the screen. Erase that simulator (`xcrun simctl erase <device id>`) and run the tests again.

Every push to `main` and to `phase/**`, `ci/**` and `claude/**` branches runs both commands on GitHub Actions (`.github/workflows/ci.yml`). A second workflow, `.github/workflows/manual-checks.yml`, runs SwiftLint and SwiftFormat on `claude/**` branches (agent sessions without Xcode) or by hand from the Actions tab, and can capture the screenshots and upload them as an artifact.

## Lint and format

```bash
swiftlint --strict
swiftformat --lint .   # drop --lint to apply the fixes
```

## Demo script

One person plays both sides by switching users in the Dev Settings tab. It takes about five minutes.

1. Launch the app. Dev Settings shows *Alex @ Cornell Tech, Roosevelt Island*.
2. Nearby: 7 open requests within 1 mi, closest first. Change the radius to 0.25 mi (3 requests), then to 3 mi (8 requests), then back to 1 mi.
3. Post tab: title "Need a cup of rice", category Ingredient, location tagged at Cornell Tech. Tap Post request. My Activity opens and shows it as *Open*.
4. Dev Settings: switch to Bea. Nearby: Alex's rice request is at the top at "< 0.1 mi".
5. Open it, tap Pick up and confirm. The status becomes *Claimed by Bea*. It leaves Nearby and appears in My Activity under *Picked up by me*.
6. Dev Settings: switch back to Alex. My Activity shows the rice request as *Claimed by Bea*. Open it and tap Mark completed.
7. Dev Settings: choose Ithaca, NY. Nearby shows "No requests within 1 mi". Tap Reset demo data to finish.

### Phase 3: Kindness score, profiles, chat and reviews

Start from a fresh launch (or Reset demo data, and switch back to Alex and Cornell Tech). `DemoFlowUITests.testExtendedDemoScript` runs the same steps.

1. Profile tab: Alex has a score of 0 and "No activity yet".
2. Post "Need a cup of rice" as Alex. Switch to Bea: her Profile shows 90 points.
3. As Bea, open the rice request in Nearby and Pick up. Bea has no Mark completed button; a note says the favor completes automatically in 7 days if Alex doesn't confirm. Tap Message Alex and send "On my way". Switch to Alex, open the request from My Activity, tap Message Bea, reply, go back and tap Mark completed.
4. Still as Alex, tap Leave a review: 5 stars, "Fast and friendly", Submit.
5. Switch to Bea. Profile shows 110 points, the new review and the favor under Past activities.
6. Switch to Chen. In My Activity open "Water my plants for the weekend" and tap the Helper row: Bea's profile shows her score and reviews, but no Account section.

## Pitch demo: the rice story

`scripts/demo-rice-story.sh` boots an iPhone simulator, opens the Simulator window and plays the story from the pitch slide on its own, paced for narration (under two minutes):

1. Alex planned to cook, but the rice ran out and the store is closed. Alex posts "Need a cup of rice".
2. Bea, down the hall, sees it at the top of Nearby, picks it up and messages "On my way with a cup of rice!".
3. Alex replies, marks the favor completed and leaves Bea a 5-star review.
4. Bea's Profile shows 110 Kindness points.

```bash
scripts/demo-rice-story.sh                            # first available iPhone, 0.5 s per beat
scripts/demo-rice-story.sh --device "iPhone 16 Pro"   # a specific simulator
scripts/demo-rice-story.sh --pace 2                   # slower, for narrating live
scripts/demo-rice-story.sh --record rice-demo.mov     # also save a screen recording
```

The steps are `RiceStoryDemoUITests`, which is skipped in the normal test run unless `TEST_RUNNER_FAVORLY_DEMO=1` is set.

## Updating the screenshots

`ScreenshotUITests` is skipped unless it is given a folder to write to:

```bash
TEST_RUNNER_SCREENSHOT_DIR=/tmp/favorly-shots xcodebuild test \
  -project Favorly.xcodeproj -scheme Favorly \
  -destination 'platform=iOS Simulator,name=<iPhone model>' \
  -only-testing:FavorlyUITests/ScreenshotUITests
```

It writes each screen and its main states (25 captures) four times: `<name>-light.png`, `<name>-dark.png`, `<name>-accessibility-large.png` and `<name>-accessibility-largest.png`. The Phase 2 set is kept in `docs/screenshots/phase-2/`, and the four images above are copies from it. The Phase 1 look is kept in `docs/screenshots/phase-1/`. The Phase 3 screens (profile, chat, review form) are captured too but not yet committed; see `docs/PROGRESS.md`.

## App icon

The icon is drawn by a script, so it can be redrawn if the brand color changes:

```bash
swift scripts/make-app-icon.swift
```
