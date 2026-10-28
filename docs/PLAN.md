# Favorly iOS Prototype — Phase 1 Implementation Plan

Oct 7, 2026 · Team 402

Phase 1 is complete. The next phase, a UI refresh, is planned in [PLAN-PHASE-2.md](PLAN-PHASE-2.md).

## Overview

Phase 1 delivers a SwiftUI prototype that runs in the iOS Simulator on a Mac and demonstrates two flows end to end, using fake data and a fake location. Visuals stay minimal; the investment goes into a clean, modular codebase that later phases can extend with a real backend and real GPS without rewrites.

**The two flows this phase must showcase**

1. **Post and get picked up.** User A posts a help request (title, details, category) tagged with a location. User B later finds it and picks it up. User A sees that it was claimed and by whom.
2. **Browse nearby and pick up.** A user sees all open requests within a radius of their current location, sorted by distance, opens one and picks it up.

**In scope:** request posting, nearby browsing with a radius filter, request detail, pick-up (claim), a My Activity view, an in-app user switcher so one person can play both roles on one laptop, a fake location picker, seeded demo data, unit tests and one UI test of the demo flow.

**Out of scope for this phase:** real accounts and sign-in, a server or database, real GPS, maps, push notifications, chat between users, ratings and trust/safety features, payments, App Store submission and TestFlight.

**Definition of done:** a fresh clone of the GitHub repo builds with the documented commands, the app launches in the iOS Simulator, the demo script in *Testing, build and demo* passes by hand, and `swift test` plus the Xcode test plan pass with no failures.

## Preparation work (you, before coding starts)

A Mac is a hard requirement: iOS apps can only be built and run in the Simulator with Xcode on macOS. Everything else on this list is free for Phase 1.

**Machine and tools**

- [ ] A Mac running a current macOS that supports the latest Xcode (Apple Silicon recommended; plan for 40+ GB free disk for Xcode and simulators)
- [ ] Install the latest stable Xcode from the Mac App Store, open it once, accept the license and let it install components
- [ ] Install at least one iOS Simulator runtime (Xcode → Settings → Components) and confirm an iPhone simulator boots
- [ ] Run `xcode-select --install` and `sudo xcode-select -s /Applications/Xcode.app` so command-line builds use the right Xcode
- [ ] Install Homebrew, then `brew install xcodegen swiftlint swiftformat`
- [ ] Confirm `git --version`, `swift --version` and `xcodebuild -version` all work in Terminal

**Accounts and repo**

- [ ] A GitHub account for each teammate; create an empty repo named `favorly-ios` (no README, so the agent's first commit is clean) and add teammates as collaborators
- [ ] Set up SSH or `gh auth login` on the Mac so the agent can push
- [ ] Sign in to Xcode with an Apple ID (Xcode → Settings → Accounts). A free account is enough for the Simulator
- [ ] Not needed yet, but budget for later: Apple Developer Program ($99/year) for TestFlight and the US App Store

**Decisions to confirm (defaults the plan assumes)**

- [ ] Bundle identifier: `edu.cornelltech.team402.favorly` (change if the team prefers another reverse-domain)
- [ ] Minimum iOS version: iOS 17 (needed for the `@Observable` macro)
- [ ] Default fake location: Cornell Tech, Roosevelt Island (40.7553, -73.9562)
- [ ] Request categories: Ingredient, Moving help, Car help, Errand, Other
- [ ] Distance units: miles in the UI (US launch), meters internally

**Agent setup**

- [ ] Give the coding agent (e.g. Claude Code) access to the cloned repo on the Mac, so it can run `xcodebuild` and the Simulator
- [ ] Copy this plan into the repo as `docs/PLAN.md` so every agent session can read it

## Tech stack and key decisions

The stack is native Swift with no third-party runtime dependencies, so the prototype stays small and every layer can be swapped behind a protocol later.

| Area | Choice | Why |
| --- | --- | --- |
| Language | Swift 6, strict concurrency on | Catches data races early; models are `Sendable` |
| UI | SwiftUI, iOS 17+ | Fastest path to simple screens; `@Observable` view models |
| Architecture | MVVM + protocol-based services + manual dependency injection | Views stay dumb; fakes swap for real services in later phases |
| Modules | One local Swift package `FavorlyKit` with three library targets | Core logic tests run with `swift test`, no Simulator needed |
| Project file | XcodeGen (`project.yml`) generates `Favorly.xcodeproj` | No `.pbxproj` merge conflicts; agents can edit YAML safely |
| Data | In-memory `actor` repository seeded from Swift fixtures | Fake data requirement; thread-safe; reset any time |
| Location | `LocationProvider` protocol, mock returns a chosen preset | Fake geo-tag requirement; real CoreLocation drops in later |
| Distance | Haversine formula in pure Swift | No framework dependency; easy to unit test |
| Tests | Swift Testing (`@Test`) for packages, XCUITest for the demo flow | Built into Xcode; no extra tooling |
| Lint/format | SwiftLint + SwiftFormat, configs committed | Consistent style across agents and teammates |
| CI (optional) | GitHub Actions on `macos-latest`: build + test | Keeps `main` green as more people contribute |

**Deliberate non-choices:** no Firebase, Supabase or other backend SDK yet; no Combine (use async/await and `@Observable`); no SwiftData or Core Data (data resets on launch by design); no MapKit (list UI only).

## Architecture and repo structure

Dependencies point inward to Core: Features → Core, Data → Core, and the App target imports both. Core has no imports beyond Foundation. Features depend only on Core protocols, never on the mock types. The App target is the only place that picks concrete implementations.

```
                 ┌──────────────────────────────┐
                 │      App target (Favorly)     │
                 │   FavorlyApp + demo wiring   │
                 └───────┬──────────────┬───────┘
          shows screens  │              │  wires in mocks
                         ▼              ▼
        ┌──────────────────┐    ┌──────────────────┐
        │  FavorlyFeatures │    │   FavorlyData    │
        │ views + view     │    │ Mock repository, │
        │ models           │    │ location, session│
        └────────┬─────────┘    └────────┬─────────┘
   codes against │                       │ implements
       protocols ▼                       ▼ protocols
        ┌────────────────────────────────────────────┐
        │        FavorlyCore (Foundation only)        │
        │        Models · Protocols · Rules          │
        └────────────────────────────────────────────┘
```

Swapping mocks for real services later means adding a new sibling of FavorlyData and changing one line in the App target.

**Package targets (`Packages/FavorlyKit`)**

- **FavorlyCore**: models, service protocols, errors, business rules (status transitions, validation, distance). Pure Swift, fully unit tested.
- **FavorlyData**: in-memory `MockRequestRepository`, `MockLocationProvider`, `MockSessionStore`, seed fixtures. Implements Core protocols. Phase 2 adds a sibling target (e.g. `FavorlyRemote`) instead of editing this one.
- **FavorlyFeatures**: SwiftUI screens and their `@Observable` view models, grouped by feature folder. Receives services through an `AppEnvironment` value.

**Repository layout**

```
favorly-ios/
├── README.md                  # setup, build, demo script
├── CLAUDE.md                  # instructions for coding agents
├── project.yml                # XcodeGen spec (source of truth for the Xcode project)
├── .gitignore                 # Swift/Xcode template + Favorly.xcodeproj/
├── .swiftlint.yml
├── .swiftformat
├── .github/workflows/ci.yml   # optional: build + test
├── docs/
│   ├── PLAN.md                # this plan
│   ├── ARCHITECTURE.md        # short summary of layers and rules
│   └── PROGRESS.md            # phase checklist, updated by every agent session
├── App/
│   ├── FavorlyApp.swift       # @main, builds AppEnvironment, shows RootView
│   ├── AppEnvironment+Demo.swift  # wires mock services + seed data
│   └── Resources/Assets.xcassets
├── AppUITests/
│   └── DemoFlowUITests.swift
└── Packages/FavorlyKit/
    ├── Package.swift
    ├── Sources/
    │   ├── FavorlyCore/
    │   │   ├── Models/        # HelpRequest, UserProfile, GeoPoint, enums
    │   │   ├── Services/      # RequestRepository, LocationProvider, SessionStore
    │   │   ├── Rules/         # RequestRules, Distance, Validation
    │   │   └── Errors/        # FavorlyError
    │   ├── FavorlyData/
    │   │   ├── MockRequestRepository.swift
    │   │   ├── MockLocationProvider.swift
    │   │   ├── MockSessionStore.swift
    │   │   └── Seed/          # DemoUsers, DemoRequests, LocationPresets
    │   └── FavorlyFeatures/
    │       ├── Environment/   # AppEnvironment + SwiftUI EnvironmentKey
    │       ├── Root/          # RootView (TabView)
    │       ├── Nearby/        # NearbyView, NearbyViewModel, RequestRow
    │       ├── RequestDetail/ # RequestDetailView, RequestDetailViewModel
    │       ├── PostRequest/   # PostRequestView, PostRequestViewModel
    │       ├── Activity/      # ActivityView, ActivityViewModel
    │       ├── DevSettings/   # user switcher, location picker, reset
    │       └── Shared/        # formatters, small reusable views
    └── Tests/
        ├── FavorlyCoreTests/
        ├── FavorlyDataTests/
        └── FavorlyFeaturesTests/   # view model tests against mocks
```

The generated `Favorly.xcodeproj` is git-ignored; anyone runs `xcodegen generate` after cloning.

## Domain model, interfaces and business rules

These types live in `FavorlyCore` and are the contract every other layer codes against. Agents should implement them as written and change them only with a note in `docs/PROGRESS.md`.

**Models**

```swift
public struct UserID: Hashable, Codable, Sendable { public let rawValue: String }
public struct RequestID: Hashable, Codable, Sendable { public let rawValue: UUID }

public struct GeoPoint: Hashable, Codable, Sendable {
    public let latitude: Double   // degrees, -90...90
    public let longitude: Double  // degrees, -180...180
}

public struct TaggedLocation: Hashable, Codable, Sendable {
    public let point: GeoPoint
    public let label: String      // e.g. "Roosevelt Island" (never a full street address)
}

public enum RequestCategory: String, CaseIterable, Codable, Sendable {
    case ingredient, movingHelp, carHelp, errand, other
}

public enum RequestStatus: String, Codable, Sendable {
    case open, claimed, completed, cancelled
}

public struct UserProfile: Identifiable, Hashable, Codable, Sendable {
    public let id: UserID
    public var displayName: String
    public var neighborhood: String
}

public struct HelpRequest: Identifiable, Hashable, Codable, Sendable {
    public let id: RequestID
    public var title: String
    public var details: String
    public var category: RequestCategory
    public var location: TaggedLocation
    public let requesterID: UserID
    public var helperID: UserID?        // set when claimed
    public var status: RequestStatus
    public let createdAt: Date
    public var claimedAt: Date?
}

public struct NewRequestDraft: Sendable {
    public var title: String
    public var details: String
    public var category: RequestCategory
    public var location: TaggedLocation
}

public struct NearbyRequest: Identifiable, Hashable, Sendable {
    public let request: HelpRequest
    public let distanceMeters: Double
    public var id: RequestID { request.id }
}
```

**Service protocols**

```swift
public protocol RequestRepository: Sendable {
    func nearby(around point: GeoPoint, radiusMeters: Double) async throws -> [NearbyRequest]
    func request(id: RequestID) async throws -> HelpRequest
    func requests(postedBy user: UserID) async throws -> [HelpRequest]
    func requests(claimedBy user: UserID) async throws -> [HelpRequest]
    func create(_ draft: NewRequestDraft, by user: UserID) async throws -> HelpRequest
    func claim(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    func cancel(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    func complete(_ id: RequestID, by user: UserID) async throws -> HelpRequest
    func changes() -> AsyncStream<Void>      // emits after any write, so open screens refresh
    func reset() async                       // restore seed data (dev settings)
}

public protocol LocationProvider: Sendable {
    func currentLocation() async throws -> TaggedLocation
}

@MainActor
public protocol SessionStore: AnyObject {
    var currentUser: UserProfile { get }
    var availableUsers: [UserProfile] { get }
    func switchUser(to id: UserID)
}

public enum FavorlyError: Error, Equatable, Sendable {
    case notFound
    case alreadyClaimed
    case cannotClaimOwnRequest
    case notAllowed                 // e.g. cancelling someone else's request
    case invalidTransition(from: RequestStatus, to: RequestStatus)
    case validation(String)         // user-facing message
    case locationUnavailable
}
```

**Business rules (implement in `Rules/`, enforce in the repository, cover with tests)**

1. Status moves only `open → claimed → completed`, plus `open → cancelled` and `claimed → cancelled`. Anything else throws `invalidTransition`.
2. Only an `open` request can be claimed. A second claim throws `alreadyClaimed`.
3. A user cannot claim their own request (`cannotClaimOwnRequest`).
4. Only the requester can cancel; only the requester can mark it completed. A picked-up request completes on its own 7 days after pick-up (Phase 3 rule 15, which replaced "requester or helper" on 2026-10-13).
5. Validation on create: title trimmed, 3–80 characters; details 0–500 characters; otherwise `validation("…")` with a readable message.
6. Nearby returns only `open` requests within the radius, sorted by distance ascending, ties broken by newest first. The current user's own open requests are included and flagged "Yours" in the UI, with no Pick up button.
7. Radius options: 0.25, 0.5, 1 and 3 miles; default 1 mile. Convert to meters at the UI boundary (1 mi = 1609.344 m).
8. Distance uses the haversine formula with Earth radius 6,371,000 m. Display rounds to 0.1 mi, or "< 0.1 mi".
9. Privacy rule to keep from day one: show only the location label and rounded distance to other users, never raw coordinates.

## Fake data and fake geolocation

All data lives in memory and resets on every launch, so every demo starts from the same known state. A dev settings screen lets one person switch between demo users and move their fake location, which is how both sides of a pick-up get shown on a single laptop.

**MockRequestRepository**

- An `actor` holding `[RequestID: HelpRequest]`, initialized from `DemoRequests.all`.
- Every write enforces the Core rules, then yields to an `AsyncStream` continuation so `changes()` subscribers refresh.
- Optional `artificialDelay: Duration` (default 300 ms) so loading states are visible and real network latency is mimicked.
- `reset()` restores the seed set.

**MockLocationProvider**

- Returns the currently selected `LocationPreset`. Selection is held in a small `@MainActor @Observable` `LocationSettings` object the dev settings screen edits.
- Can be configured to throw `locationUnavailable`, so the error state can be tested.

**Location presets** (coordinates rounded, fine for a fake)

| Preset | Latitude | Longitude | Purpose |
| --- | --- | --- | --- |
| Cornell Tech, Roosevelt Island (default) | 40.7553 | -73.9562 | Most seed requests are near here |
| Roosevelt Island north (Lighthouse Park) | 40.7720 | -73.9406 | About 1.4 mi away; tests the radius filter |
| Long Island City | 40.7447 | -73.9485 | Across the river; mix of near and far |
| Midtown East | 40.7549 | -73.9680 | About 0.6 mi west of Cornell Tech |
| Ithaca, NY | 42.4440 | -76.5019 | Far away; shows the empty state |

**Demo users** (`DemoUsers`)

| Display name | ID | Neighborhood | Role in the demo |
| --- | --- | --- | --- |
| Alex | `user-alex` | Roosevelt Island | Default signed-in user; posts a request |
| Bea | `user-bea` | Roosevelt Island | Picks up Alex's request |
| Chen | `user-chen` | Long Island City | Owns some seed requests |
| Dana | `user-dana` | Midtown East | Owns some seed requests |

**Seed requests** (`DemoRequests`): about 12, built in code with fixed UUIDs and timestamps relative to launch time. Cover every category, three statuses (mostly `open`, one `claimed`, one `completed`), and a spread of distances: six within 0.5 mi of Cornell Tech, three at 0.5–1.5 mi, three over 3 mi. Examples: "Need 2 eggs for a cake", "Help carrying a couch up 3 floors", "Jump start for a dead battery", "Borrow a cup of rice", "Pick up a prescription bag from the pharmacy counter" (errand). None belong to Alex, so Alex's Nearby list starts full of other people's requests.

**Session**: `MockSessionStore` is `@MainActor @Observable`, starts as Alex, and `switchUser(to:)` changes `currentUser`. All view models read the user from the session at action time, so switching users updates every tab.

## Screens and user flows

Four tabs, plain system styling (default fonts, `List`, `Form`, SF Symbols). Every interactive element gets an `accessibilityIdentifier` so the UI test can drive it.

| Tab / screen | What it shows | Actions | Key states |
| --- | --- | --- | --- |
| **Nearby** | Header with current location label and a radius picker; list of open requests: category icon, title, distance, posted time, requester name, "Yours" badge | Pull to refresh; tap a row opens Request Detail | Loading, empty ("No requests within 1 mi"), error with Retry |
| **Request Detail** | Title, details, category, location label, distance, requester, status, helper name once claimed | **Pick up** (others' open requests); **Cancel** (own open/claimed); **Mark completed** (requester only, when claimed; the helper sees when it completes on its own) | Confirm dialog before Pick up; inline error for `alreadyClaimed` etc. |
| **Post** | Form: title, details, category picker, location row prefilled from `LocationProvider` ("Tagged at Cornell Tech, Roosevelt Island") | **Post request**; button disabled until valid | Validation messages; success returns to My Activity and highlights the new item |
| **My Activity** | Segmented control: *My requests* (with status and helper) and *Picked up by me* | Tap opens Request Detail | Empty states per segment |
| **Dev Settings** (4th tab, gear icon) | Current user, fake location, data controls | Switch user (Alex/Bea/Chen/Dana); choose location preset; toggle "Simulate location error"; **Reset demo data** | Labeled "Prototype only" |

**Flow 1, post and get picked up:** Alex → Post → fills the form → Post request → appears in My Activity as *Open* → switch to Bea → Nearby shows it at top ("< 0.1 mi") → Detail → Pick up → status *Claimed* → switch to Alex → My Activity shows *Claimed by Bea*.

**Flow 2, browse nearby and pick up:** Bea → Nearby (1 mi) shows about 8 requests sorted by distance → change radius to 0.25 mi and the list shrinks → change radius to 3 mi and it grows → open "Need 2 eggs for a cake" → Pick up → it leaves Nearby and appears under *Picked up by me*.

Screens refresh from `repository.changes()`, so a claim made on one tab is reflected on the others without manual refresh.

## Implementation phases

Seven sequential phases, each sized for one agent session and one pull request. Each ends with green tests, an updated `docs/PROGRESS.md`, and a demoable state. Phases 1A–1C need no Simulator; 1D onward does.

### 1A. Repo scaffold and empty app

- [ ] Create the folder layout from *Architecture and repo structure*, with placeholder files where needed so targets compile
- [ ] `Packages/FavorlyKit/Package.swift`: tools version 6.0, platforms `.iOS(.v17)` and `.macOS(.v14)` (macOS lets `swift test` run on the laptop), three library targets and three test targets with dependencies Features → Core and Data → Core (Features never imports Data)
- [ ] `project.yml`: app target `Favorly` (iOS 17, bundle ID from Preparation), depends on the local package products; UI test target `FavorlyUITests`; scheme `Favorly` with a test plan running package tests and UI tests
- [ ] `App/FavorlyApp.swift` showing a `RootView` with four empty tabs
- [ ] `.gitignore` (Xcode/Swift template, plus `Favorly.xcodeproj/`, `DerivedData/`, `.build/`), `.swiftlint.yml`, `.swiftformat`, `README.md` with setup steps, `docs/ARCHITECTURE.md` (`docs/PLAN.md`, `docs/PROGRESS.md` and `CLAUDE.md` already exist)
- [ ] Optional: `.github/workflows/ci.yml` running `swift test` and `xcodebuild test`

**Done when:** `xcodegen generate` succeeds; the app launches in the Simulator showing four tabs; `swift test` passes (one trivial test per target); first commit pushed to `main`.

### 1B. Core domain

- [ ] Models, enums, `FavorlyError` and service protocols exactly as in *Domain model*
- [ ] `RequestRules`: `canTransition(from:to:)`, `validateClaim(request:by:)`, `validateCancel`, `validateComplete`
- [ ] `DraftValidator.validate(_:) throws` for title and details limits
- [ ] `Distance.meters(from:to:)` (haversine) and `DistanceFormatter.miles(_:)` → "0.4 mi" / "< 0.1 mi"
- [ ] Tests: every allowed and disallowed transition; claim own request; validation edges (2, 3, 80, 81 characters; whitespace-only); distance against two known pairs within 1% (e.g. Cornell Tech to Midtown East ≈ 1.0 km)

**Done when:** `swift test --filter FavorlyCoreTests` passes, and Core imports nothing but Foundation.

### 1C. Mock data layer

- [ ] `LocationPreset` list and `DemoUsers`, `DemoRequests` seed fixtures as in *Fake data*
- [ ] `MockRequestRepository` actor implementing every protocol method, using Core rules, with `changes()` stream and `reset()`
- [ ] `MockLocationProvider` + `LocationSettings`; `MockSessionStore`
- [ ] Tests: nearby filters by radius and status and sorts by distance; create assigns requester, `open` status and current time; claim sets helper, `claimedAt` and `claimed`; double claim throws `alreadyClaimed`; `changes()` emits after a write; `reset()` restores the seed count

**Done when:** `swift test` passes for Core and Data.

### 1D. App environment and navigation shell

- [ ] `AppEnvironment` struct in Features holding `repository`, `locationProvider`, `session`, `locationSettings`; a SwiftUI `EnvironmentKey` to inject it
- [ ] `AppEnvironment.demo()` in the App target wires the mocks; `AppEnvironment.preview()` for SwiftUI previews
- [ ] `RootView` TabView: Nearby, Post, My Activity, Dev Settings, each wrapped in a `NavigationStack`
- [ ] Dev Settings screen fully working: user picker, location preset picker, error toggle, Reset demo data

**Done when:** switching user and location in Dev Settings updates a debug line ("Alex @ Cornell Tech") shown on the Nearby tab.

### 1E. Browse nearby + request detail + pick up (Flow 2)

- [ ] `NearbyViewModel` (`@MainActor @Observable`): `state` enum (`loading`, `loaded([NearbyRequest])`, `empty`, `failed(String)`), `radius`, `load()`, observes `changes()` and location changes
- [ ] `NearbyView` + `RequestRow`, radius `Picker`, pull to refresh, empty and error states
- [ ] `RequestDetailViewModel`: loads by ID, computes which actions are available for the current user, `pickUp()`, `cancel()`, `complete()`, maps `FavorlyError` to messages
- [ ] `RequestDetailView` with confirmation dialog before Pick up
- [ ] View model tests against mocks: radius change re-filters; own requests show no Pick up; pick up changes status and shows the helper name

**Done when:** Flow 2 from *Screens and user flows* works by hand in the Simulator.

### 1F. Post request + My Activity (Flow 1)

- [ ] `PostRequestViewModel`: form fields, live validation, loads the tagged location, `submit()`; resets the form after success
- [ ] `PostRequestView` with location row and disabled-until-valid Post button
- [ ] `ActivityViewModel` + `ActivityView`: two segments from `requests(postedBy:)` and `requests(claimedBy:)`, refresh on `changes()` and user switch
- [ ] After posting, switch to the My Activity tab and highlight the new request
- [ ] View model tests: invalid title blocks submit; successful submit creates a request at the current preset; Activity segments list the right items per user

**Done when:** Flow 1 works by hand, including switching to Bea and back to Alex.

### 1G. Hardening, UI test, docs

- [ ] `DemoFlowUITests`: launch with argument `-uiTesting` (resets data, zero artificial delay), run Flow 1 end to end using accessibility identifiers
- [ ] Accessibility pass: Dynamic Type works on all screens, VoiceOver labels on rows and buttons
- [ ] SwiftLint and SwiftFormat clean; no compiler warnings under Swift 6 strict concurrency
- [ ] README: prerequisites, setup, run, test, demo script, architecture link; add 2–3 Simulator screenshots in `docs/screenshots/`
- [ ] Tag the commit `v0.1.0-prototype`

**Done when:** the full *Definition of done* in the Overview is met on a fresh clone.

## Testing, build and demo

Core and data logic is tested with `swift test` on macOS; screens are tested through view model tests and one UI test in the Simulator.

**Commands (run from the repo root)**

```bash
# one-time after clone, and after editing project.yml
xcodegen generate

# fast logic tests, no Simulator
swift test --package-path Packages/FavorlyKit

# list simulators, then pick an available iPhone name
xcrun simctl list devices available

# build and run all tests on a simulator
xcodebuild test -project Favorly.xcodeproj -scheme Favorly \
  -destination 'platform=iOS Simulator,name=<iPhone model from the list>'

# run the app: open in Xcode and press Run
open Favorly.xcodeproj
```

**Test coverage expectations**

- Core rules and distance: every branch covered
- Repository: every protocol method, including error paths
- View models: state transitions and available actions per user
- UI: one end-to-end test of Flow 1; no screenshot or pixel tests

**Demo script (5 minutes, the acceptance test for this phase)**

1. Launch the app. Dev Settings shows *Alex @ Cornell Tech*.
2. Nearby: open requests within 1 mi, closest first. Change the radius to 0.25 mi, then to 3 mi, and watch the list change.
3. Post tab: "Need a cup of rice", category Ingredient, location tagged Cornell Tech. Post. My Activity shows it as *Open*.
4. Dev Settings: switch to Bea. Nearby: Alex's rice request is at the top at "< 0.1 mi".
5. Open it, tap Pick up, confirm. Status becomes *Claimed by Bea*; it disappears from Nearby and appears under *Picked up by me*.
6. Switch back to Alex. My Activity shows the rice request *Claimed by Bea*. Tap Mark completed.
7. Dev Settings: move to Ithaca, NY. Nearby shows the empty state. Reset demo data to finish.

## Conventions for coding agents and future phases

Any agent picking up this work starts by reading `docs/PLAN.md` and `docs/PROGRESS.md`, then continues from the first unchecked phase.

**Working rules**

- One phase per branch (`phase/1c-mock-data`) and per pull request into `main`; commit messages follow Conventional Commits (`feat(nearby): radius picker`)
- At the end of a session, update `docs/PROGRESS.md`: tick finished tasks, list decisions made, known issues, and the next task to pick up
- Never import `FavorlyData` from `FavorlyFeatures`; views get services only through `AppEnvironment`
- One type per file; file name matches the type; `public` only for what other modules need
- Every new view model or rule ships with tests in the same PR
- No new third-party dependencies without noting the reason in `docs/PROGRESS.md`
- Keep the UI plain; no custom design system in this phase
- Do not edit the generated `.xcodeproj`; change `project.yml` and regenerate

**What later phases will plug in (no work now, but don't block it)**

| Later phase | Change | Where it plugs in |
| --- | --- | --- |
| Real backend | Hosted database with geo queries (e.g. Firebase or Supabase/Postgres + PostGIS) | New `FavorlyRemote` target implementing `RequestRepository` |
| Accounts | Sign in with Apple, real profiles | New `AuthService`; `SessionStore` backed by it |
| Real location | CoreLocation with when-in-use permission, coarse location for privacy | `CoreLocationProvider` implementing `LocationProvider` |
| Notifications | Push when a request is picked up | New service; triggered from the backend |
| Trust and safety | Reporting, blocking, request moderation, verified neighbors | Core rules + new features |
| App Store | Developer Program, privacy policy, App Privacy labels, TestFlight beta | Release checklist; location usage strings in `project.yml` |

The protocols in *Domain model* are the seams for every row above, so Features and Core should not need rewrites when real services arrive.
