# Architecture

A short summary of the layers and rules. [PLAN.md](PLAN.md) has the full detail, and [PROGRESS.md](PROGRESS.md) logs every place the code departs from it.

## Layers

```
App target (Favorly)  ──►  FavorlyFeatures  ──►  FavorlyCore
        │                                           ▲
        └──────────────►  FavorlyData  ─────────────┘
```

| Module | Holds | May import |
| --- | --- | --- |
| `FavorlyCore` | Models, service protocols, errors, business rules | Foundation only |
| `FavorlyData` | In-memory mock services and seed data | `FavorlyCore`, system frameworks |
| `FavorlyFeatures` | SwiftUI screens and `@Observable` view models | `FavorlyCore`, SwiftUI |
| App target | `@main`, and the choice of concrete services | all three |

The three modules are library targets of one local package, `Packages/FavorlyKit`.

## Rules

- `FavorlyFeatures` never imports `FavorlyData`. Views get services only through `AppEnvironment`.
- The App target is the only place that picks concrete implementations: `AppEnvironment.demo()` for `-demo` and `-uiTesting` launches, `AppEnvironment.live()` otherwise. Until phase 4C, `live()` is the demo wiring starting signed out.
- A real backend arrives as a new sibling of `FavorlyData`, not as edits to it.
- One type per file; the file name matches the type; `public` only for what other modules need.
- No third-party runtime dependencies without a note in [PROGRESS.md](PROGRESS.md).

## How a screen is put together

- `AppEnvironment` holds eight services, all protocols in Core: `RequestRepository`, `KindnessRepository`, `ReviewRepository`, `ChatRepository`, `LocationProvider`, `SessionStore`, `AuthService` and `LocationSettings`.
- `RootView` shows Welcome, profile setup or the tabs (`MainTabView`), following `AuthService.state`. `SessionStore` holds the signed-in user and looks up other users' profiles. Switching between demo users is a separate protocol, `DemoSessionControls`, that only the mock and preview sessions adopt; Dev Settings uses it, and Dev Settings exists only in Debug builds (`RootTab.visible`).
- One mock actor, `MockRequestRepository`, implements all four repository protocols, one conformance per file (`MockRequestRepository+Kindness.swift`, `+Reviews.swift`, `+Chat.swift`). `AppEnvironment.demo()` passes the same instance to each. One actor keeps rules that span requests and reviews atomic, and keeps one `changes()` stream and one `reset()` for everything. A real backend can split them later without touching Features.
- Only the requester marks a request completed. A picked-up request completes on its own 7 days after pick-up: `MockRequestRepository` completes every due request at the start of each read and write, using its `now` clock, with no timer. A real backend does the same on the server (see `docs/PLAN-PHASE-4.md`).
- The Kindness score is never stored. `KindnessRules.summary` derives it from completed requests, reviews and redemptions each time it is asked for.
- `MainTabView` reads the environment once and hands it to each screen's initializer. The screen creates its view model from it.
- Each tab's `NavigationStack` registers its destinations once, through `appDestinations(_:)`: a `RequestID` opens Request Detail and a `UserID` opens that user's profile. Chat is pushed and the review form is a sheet, both from Request Detail.
- View models are `@MainActor @Observable` classes. They expose a `state` enum and async methods such as `load()`, and hold no SwiftUI types.
- Screens refresh in two ways. `observeChanges()` reloads after any repository write. A `reloadKey` on the view model, used with `.task(id:)`, reloads when the user, location or radius changes.
- Business rules live in Core (`RequestRules`, `DraftValidator`, `Distance`, `KindnessRules`, `ReviewRules`, `ChatRules`). The repository enforces them; view models use the same rules to decide which buttons to show.
- Other users see only a location label and a rounded distance, never coordinates. Someone else's profile shows completed requests only. The gift card and Redeem were removed in 4A; `KindnessRepository` still has the redeem methods, unused by any screen.

## Theme

How the app looks is decided in one place. [PLAN-PHASE-5.md](PLAN-PHASE-5.md) has the Grove look and the reasons behind it; it replaced the teal look of [PLAN-PHASE-2.md](PLAN-PHASE-2.md).

- **One source of style.** Screen files never contain a literal color, font, corner radius, spacing number or shadow. They use `Theme`, `TextStyle` and the shared components.
- `Shared/Theme/` holds `Theme` (Grove colors, spacing, radii, icon sizes, shadows), `TextStyle` (the Figtree type scale, each style relative to a system text style so it follows Dynamic Type), `GroveFonts` (registers the bundled Figtree files), `GroveAppearance` (navigation bar, tab bar and segmented picker fonts and colors, applied once from `RootView`), `BadgeColors` and `RequestStatus+Color`, `AdaptiveColor` (a light and a dark value) and `RGBColor` (plain numbers, so contrast can be unit tested).
- `Shared/Components/` holds the building blocks: `GroveBackground`, `CardBackground` and `cardRow()` (a list row drawn as its own card), `groveListBackground()` and `groveRows()` for lists and forms, `CategoryIcon`, `StatusBadge`, `TagBadge`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `MessageView`, `SectionHeader`, `InlineMessage`, `ErrorBanner`, `AvatarView`, `ScoreLabel`, `StarRating`, `StarRatingPicker` and `textStyle(_:)`. They take plain values, never a view model, and each has a light and dark preview.
- Figtree (SIL Open Font License 1.1) ships as a resource of `FavorlyFeatures` in `Resources/Fonts/`, with its license. If it ever fails to load, SwiftUI falls back to the system font.
- System controls stay system controls: `List`, `Form`, `TabView`, segmented and menu pickers, sheets, dialogs and Apple's sign-in button are restyled, not rebuilt.
- `ThemeTests` checks every text-on-fill pairing the screens use, and every badge, for 4.5:1 contrast in both modes, and that the fonts register. A new pairing goes into `ThemeTests.pairs`.
- The app icon is drawn by `scripts/make-app-icon.swift`. It still uses the Phase 2 teal; a Grove icon is a separate decision.

## Project file

`project.yml` (XcodeGen) is the source of truth. `Favorly.xcodeproj` is generated and git-ignored.

## Tests

- Package tests use Swift Testing and run on macOS with `swift test`, without a Simulator. View model tests run against the real mocks from `FavorlyData` with no artificial delay.
- The `Favorly` scheme runs the same package tests plus the UI tests on an iOS Simulator.
- UI tests find elements by `accessibilityIdentifier` and subclass `UITestCase`, which launches the app with `-uiTesting`.
