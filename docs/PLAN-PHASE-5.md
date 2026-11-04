# Favorly — Phase 5 Implementation Plan: Grove UI revamp

Nov 4, 2026 · Team 402

## Overview

Phase 2 gave the app a teal look with system styling. Phase 5 changes the look to **Grove**: olive and lime on a warm off-white (light) or deep moss (dark), the Figtree typeface, soft white cards, lime badges and an olive primary button. The screens, flows and behavior stay the same.

**Reference:** the canvas "Favorly · Grove UI" (https://claude.ai/artifact/MepsaKmAH4rhe43aqw4D4w). It shows Nearby, Request Detail, Post, My Activity, Profile, Chat, Leave a review and Welcome in light and dark. The token values below come from the Grove section of the "Favorly — Look & Feel Options" canvas. Where this file and the mockup disagree, this file wins: the mockup is a drawing, and some of what it shows isn't in the app (see *Mockup reconciliation*).

**In scope:** a new palette, typography, radii, card and shadow tokens in `Theme`; restyled shared components; every screen restyled (the eight above plus Profile setup, Report, Blocked people, Safety tips and Dev Settings); the bundled Figtree font; the app accent color; refreshed screenshots.

**Out of scope:** new features, new screens, new navigation, changed wording (unless the owner accepts a change listed under *Decisions needed*), view model changes, the gift card and Redeem (removed in 4A), a custom tab bar, a Messages tab, custom animations, iPad layouts, a new app icon (separate decision).

**Definition of done:** every screen uses the Grove theme in light and dark mode and at accessibility text sizes. The behavior test suites pass without edits to what they assert. The phase's diff touches no file in `FavorlyCore`, `FavorlyData`, `FavorlyRemote` or any view model. The owner has compared the screenshots with the mockup and approved them.

[PLAN.md](PLAN.md) still governs architecture and behavior, and [PLAN-PHASE-4.md](PLAN-PHASE-4.md) governs release and backend. This file governs how the app looks and replaces the look in [PLAN-PHASE-2.md](PLAN-PHASE-2.md). Phase 2's rules that this file doesn't change still hold.

## Decisions needed from the owner

Each has a default that is used unless `docs/PROGRESS.md` says otherwise.

| # | Decision | Default | Why it matters |
| --- | --- | --- | --- |
| 1 | **When does Phase 5 run?** | After 4H: ship 1.0.0 in the current look, then release Grove as 1.1.0 | Starting before 4H means the App Store screenshots are taken in the new look, but it changes the UI in the middle of the external beta and puts a large diff right before review. Doing it after launch keeps 1.0.0 low-risk |
| 2 | **Bundle Figtree?** | Yes: Figtree (SIL Open Font License 1.1) in `App/Resources/Fonts/`, with its license file | Phase 2 banned custom fonts. Figtree is a big part of the Grove look. It's a font file, not a code dependency. Every use goes through `Theme.Typography`, so switching back to SF Pro is a one-file change |
| 3 | **New headline copy from the mockup?** | No: keep the current titles and strings | The mockup has "Neighbors who could use a hand" on Nearby, "Ask for a favor" on Post and "I can help" on cards. UI tests match strings exactly, and copy changes are product decisions. If accepted, each one is a logged string change, and the UI tests that read it are updated in the same commit |
| 4 | **One tint for all categories?** | Yes: every category icon uses the olive tint, as in the mockup | Phase 2 gave each category its own color. Grove uses one tint, and the symbol plus the category name still tell them apart. The alternative is five earthy category colors, each with a contrast test |
| 5 | **App icon** | Unchanged in this phase | The canvas has logo concepts but none has been chosen. A new icon is its own small task once one is picked |

## Design principles

These replace Phase 2's principles.

1. **System controls, Grove surfaces.** Keep `List`, `Form`, `NavigationStack`, `TabView`, `Picker`, SF Symbols and the system sheets and dialogs. Restyle their backgrounds, rows, fonts and tint. Don't rebuild them. Dynamic Type, VoiceOver, pull to refresh and the iOS 26 floating tab bar keep working for free.
2. **Olive acts, lime celebrates.** Olive (lime in dark mode) marks what the user can act on: the primary button, links, the selected tab. Lime marks good news: the Open status, the Kindness score, "Yours". Every other element is ink, muted ink or a soft tint.
3. **Cards for content, not chrome.** A request, a profile summary or a chat's request is a card. Navigation, section headers and settings rows stay plain.
4. **Color is never the only signal.** This is unchanged from Phase 2. Every colored element also has text or a symbol.
5. **One source of style.** This is unchanged. Screens contain no literal colors, fonts, radii, spacing or shadows.

## Guardrails (do not break)

Checked at the end of every sub-phase.

- No changes under `Sources/FavorlyCore`, `Sources/FavorlyData`, `Sources/FavorlyRemote`, `backend/`, or to any `*ViewModel.swift`. `git diff --stat main -- <paths>` must be empty.
- The package tests keep what they assert, except `ThemeTests`, `RGBColorTests` and `AvatarColorTests`. Those three test the theme itself, so they change with it, and each change is listed in the commit message.
- Every `accessibilityIdentifier` keeps its exact name and stays on an element of the same kind.
- Every visible string and VoiceOver label stays the same, unless decision 3 accepts a change.
- Controls keep their type: menu pickers for category and neighborhood, segmented pickers for radius and the activity segment, a confirmation dialog before Pick up, pull to refresh on Nearby, Apple's own Sign in with Apple button.
- Every UI test class except `ScreenshotUITests` passes unedited. The one exception is a new font-check method added to `LaunchUITests`, with its existing methods left as they are.
- Styling of the Apple sign-in button follows Apple's rules: black in light mode and white in dark mode, as the mockup shows, using `SignInWithAppleButton`'s own styles.
- If a look can't be reached without breaking one of these, don't build it. Write it under "Open questions" in `docs/PROGRESS.md`.

## Theme

All theme code stays in `Sources/FavorlyFeatures/Shared/Theme/`, one type per file.

### Color tokens

All values are opaque hex, so `RGBColor` can test them. The mockup's translucent dark surfaces (white at 6–16%) are pre-blended over the dark background.

| Token | Used for | Light | Dark |
| --- | --- | --- | --- |
| `background` | Screen background behind lists and forms | `#F8FAE6` | `#141A0D` |
| `surface` | Cards, list rows, text fields, the tab bar | `#FFFFFF` | `#22281C` |
| `surfaceBorder` | 1 pt card and field outline | `#E5E9CF` | `#2C3125` |
| `divider` | Row separators | `#E5E9CF` | `#272C20` |
| `ink` | Primary text | `#1D2B12` | `#F1F5E1` |
| `inkMuted` | Secondary text, meta lines, unselected tabs | `#586048` | `#A6AE91` |
| `brand` | Tint: links, selected tab, back buttons, accent words | `#6B6D18` | `#D6EF4F` |
| `onBrand` | Label on a solid `brand` fill | `#FFFFFF` | `#141A0D` |
| `lime` | Open status, score badge, "Yours", profile ring | `#D6EF4F` | `#D6EF4F` |
| `onLime` | Label on `lime` | `#1D2B12` | `#141A0D` |
| `tint` | Soft fill: category tiles, secondary buttons, Claimed status | `#EAF2BF` | `#2D3616` |
| `onTint` | Label and symbol on `tint` | `#45470C` | `#DDF27A` |
| `points` | Point values ("+18") | `#5C5E12` | `#D6EF4F` |
| `segment` | Segmented control track, Completed status, disabled fill | `#ECEFD6` | `#22281C` |
| `spark` | "New" dot and badge, unread markers. Text on it is `ink` (light) or `#141A0D` (dark): white on `#E8701F` is only about 3.1:1 | `#E8701F` | `#FF8A3D` |
| `danger` | Cancel request, Delete account, error text | `#B3261E` | `#FF8A80` |
| `avatar` | Avatar circle | `#ECE9DF` | `#2A321F` |
| `onAvatar` | Avatar initials | `#3A4230` | `#E3E8D0` |
| `ring` | Kindness score ring, progress | `#8DA81A` | `#D6EF4F` |

The dark `surface`, `surfaceBorder`, `divider` and `tint` values are the mockup's white at 6%, 10% and 8%, and lime at 13%, pre-blended over `#141A0D`. These values were checked by calculation (for example white on `#6B6D18` is about 5.5:1, and `#586048` on `#F8FAE6` is about 6.3:1), but not yet on a screen. 5A's contrast tests are the gate. If a pair fails, change the value, keep the test, and log it.

**Removed:** `categoryIngredient`, `categoryMoving`, `categoryCar`, `categoryErrand`, `statusClaimed` and `statusCancelled` as separate hues (decision 4). `RequestCategory+Color` maps every category to `tint`/`onTint`. `RequestStatus+Color` maps Open to `lime`, Claimed to `tint`, Completed to `segment` with `ink` text, and Cancelled to an outline in `inkMuted`.

**Avatars:** one neutral color (`avatar`/`onAvatar`) for everyone, as in the mockup. `Theme.Colors.avatars` and `UserID+AvatarColor` go away, and `AvatarColorTests` is replaced by a test that every avatar uses the token.

### Typography

New type `Theme.Typography`. Each style is `Font.custom("Figtree-…", size:, relativeTo:)` so it scales with Dynamic Type. The weights are Regular, Medium, SemiBold and Bold.

| Style | Size · weight | Relative to | Used for |
| --- | --- | --- | --- |
| `largeTitle` | 34 · Bold, tracking −0.02 em | `.largeTitle` | Root screen titles (through the navigation bar appearance) |
| `title` | 28 · Bold, tracking −0.02 em | `.title` | Request Detail title, profile name |
| `cardTitle` | 19 · Medium | `.title3` | Request title on a card |
| `headline` | 17 · Bold | `.headline` | Section headers ("Past activities"), sheet titles |
| `body` | 15 · Regular | `.subheadline` | Details text, chat bubbles, fields |
| `bodyStrong` | 15 · SemiBold | `.subheadline` | Row titles, names |
| `meta` | 13 · Regular | `.footnote` | Distance · name · time lines |
| `button` | 16 · Bold | `.callout` | Primary and secondary buttons |
| `badge` | 11 · Bold, uppercase, tracking 0.08 em | `.caption2` | Status and "Yours" badges |
| `scoreLarge` | 38 · Bold | `.largeTitle` | Kindness score on Profile |

`project.yml` adds the four font files to the app target's resources and `UIAppFonts` to the Info.plist. A test in `FavorlyFeaturesTests` can't see the app bundle, so the check that the fonts load is a UI-test launch assertion in `LaunchUITests`: a new test method, with the existing ones left alone. If a font fails to load, the system font is used and the app still works.

### Shape, space and depth

| Token | Value |
| --- | --- |
| `Radius.card` | 22 (request cards, profile cards) |
| `Radius.row` | 18 (list rows drawn as cards, chat request card) |
| `Radius.button` | 18 (primary button, 56 pt tall) |
| `Radius.field` | 14 (text fields, search, segmented track) |
| `Radius.tile` | 12 (category tile) |
| `Radius.bubble` | 18, with a 6 pt tail corner |
| `Radius.sheet` | 28 (custom sheet tops, if used) |
| `Spacing.screen` | 20 (horizontal gutter) |
| `Spacing.card` | 16 (card padding) |
| `Shadow.card` | light: `#1D2B12` at 6%, radius 20, y 6; dark: none |
| `Shadow.primary` | light: `#6B6D18` at 30%, radius 26, y 10; dark: `#D6EF4F` at 22% |
| `glow` | Dark mode only: a blurred `#262F0F` circle, 360 pt, behind the top of root screens |

The existing `Spacing` and `IconSize` values stay where they are still used.

### Shared components

| Component | Change |
| --- | --- |
| `GroveBackground` (new) | `background` color, plus the dark-mode glow. Hidden from VoiceOver. Drops the glow when Reduce Transparency is on |
| `Card` (new) | A container view: `surface` fill, `surfaceBorder` outline, `Radius.card`, `Shadow.card`, `Spacing.card` padding |
| `CardRow` modifier (new) | Applied to a `List` row: clear system background, the card drawn as the `listRowBackground`, insets of `Spacing.screen`, hidden separators. Keeps the row a real list row, so tapping, swipe and VoiceOver work as before |
| `CategoryIcon` | `tint` tile, `onTint` symbol, `Radius.tile` |
| `StatusBadge` | Capsule, `badge` font, colors as above |
| `TagBadge` | "Yours" on `lime`; "New" on `spark` with dark text |
| `ScoreLabel` | Star and points in `points`; the large variant becomes the lime "Kindness score" badge over `scoreLarge` in `brand` |
| `PrimaryButtonStyle` | 56 pt, `brand` fill, `onBrand` label, `Radius.button`, `Shadow.primary`; disabled uses `segment` and `inkMuted` |
| `SecondaryButtonStyle` | Capsule, `tint` fill, `onTint` label; the danger variant uses `danger` on a danger tint |
| `AvatarView` | Neutral circle; an optional `ring` progress parameter is left out (it showed gift-card progress, which is gone) |
| `MessageBubble` | Mine: `ink` fill with `background` text; theirs: `surface` with an outline; Grove radii |
| `MessageView`, `InlineMessage`, `ErrorBanner` | Figtree, `inkMuted`/`danger` |
| `SectionHeader` | Sentence case, `headline` style, no uppercase |
| `StarRating`, `StarRatingPicker` | Filled stars in `ring`, empty ones outlined in `inkMuted`; selected picker stars sit on a `tint` tile, 52 pt targets |
| `FactRow` | Leading symbol on a small `tint` tile, as in the mockup's details card |

### App-level touches

- `RootView`: `.tint(Theme.Colors.brand)` and `GroveBackground`. Lists and forms use `.scrollContentBackground(.hidden)`, so the Grove background shows through.
- The navigation bar and tab bar get Figtree titles and the Grove colors through `UINavigationBarAppearance` and `UITabBarAppearance`, set once at launch in the App target. On iOS 26 and later the system's floating tab bar stays. It already looks close to the mockup's floating bar.
- `AccentColor.colorset` takes the `brand` values.
- `MARKETING_VERSION` follows decision 1 (default `1.1.0`).

## Mockup reconciliation

What the mockup shows, and what Phase 5 does with it.

| In the mockup | Decision | Reason |
| --- | --- | --- |
| Cards, palette, type, badges, buttons, bubbles | **Adopt** | This is the look |
| Floating rounded tab bar | **Adapt**: the system `TabView`, tinted | System first. iOS 26 already floats it. On iOS 17–25 it stays the classic bar in Grove colors |
| Segmented radius and activity pickers | **Adapt**: system segmented `Picker` with Grove tint and font | The control type must stay |
| Big two-line headline on Nearby and Post | **Leave out** unless decision 3 accepts it | Changes wording, and the navigation titles are tested |
| Kindness score pill on the Nearby header | **Leave out** | Nearby's view model doesn't load the score. Adding it is a behavior change |
| "I can help" button on Nearby cards | **Leave out** | The whole row already opens Request Detail. A second action would be new behavior |
| Meeting spot on Nearby cards | **Leave out** | 4G decided Nearby rows show the neighborhood only |
| Inline Message, Mark completed and Leave a review buttons on My Activity rows | **Leave out** | These actions live on Request Detail |
| Gift card, Redeem and the progress ring on Profile | **Leave out** | Removed in 4A, "no fake Redeem" |
| Settings button on Profile | **Leave out** | Account rows stay in the Profile list, as built in 4A |
| Chat request card with "Maya marks it done…" | **Adapt**: the existing request title, styled as a card | The note is new copy (decision 3) |
| Points preview on Leave a review | **Leave out** | New copy and logic in the view model |
| Welcome's floating sample cards | **Adopt** as decoration | Hidden from VoiceOver, no data, built from `Card` and `CategoryIcon` with fixed sample text marked as decorative |
| Messages tab (Grove section of the source canvas) | **Leave out** | The app has no inbox. Chat opens from a request |

## Screen by screen

The layout keeps its order and content. The table lists only what changes.

| Screen | Changes |
| --- | --- |
| **Nearby** | Grove background with glow. The location line keeps its `mappin` symbol in `inkMuted`. The radius picker sits under it. The count header uses `headline`. `RequestRow` becomes a `CardRow`: `CategoryIcon`, category name and the distance · name · time line in `meta`, the title in `cardTitle`, the status or "Yours" badge at the top right. Empty, error and loading states use the Grove `MessageView` |
| **Request Detail** | Inline title with an olive back button. The header has the `StatusBadge` and a `meta` line, the title in `title` and the details in `body` `inkMuted`. Facts become one `Card` of `FactRow`s with tinted symbol tiles. The requester and helper rows become cards with an avatar, the name and `ScoreLabel`. Pick up, Mark completed and Leave a review use `PrimaryButtonStyle`. Message is secondary, and Cancel request is the danger secondary. The reason line under Pick up stays |
| **Post** | Form rows become `surface` cards with `Radius.field`. Section headers in `headline` sentence case. The category menu picker shows the category's `CategoryIcon`. The neighborhood picker and meeting spot share one card with the pin symbols in `brand`. The privacy note uses `meta`. Post request uses `PrimaryButtonStyle` in its own section |
| **My Activity** | Segmented picker at the top. `ActivityRow` becomes a `CardRow` with `CategoryIcon`, title, `meta` line and `StatusBadge`. The highlighted new row keeps a stronger tint (`tint` instead of `surface`) |
| **Profile** | `AvatarView` large with the name in `title` and the neighborhood in `meta`. The Kindness score card shows the lime badge, the score in `scoreLarge` and favors · rating on the right. Past activities rows use the "Helped"/"Asked" badges (`tint`/`segment`). Reviews in cards. The Account section stays a plain grouped list on `surface` |
| **Other user's profile** | The same, without the account section, as today |
| **Chat** | The request title shown as a `Card` under the navigation bar. Grove bubbles. The input is a capsule field with a round `brand` Send button. The closed-thread lock note in `inkMuted` |
| **Leave a review** | The system sheet with Grove background. Cancel and Submit in the navigation bar, Submit in `brand` and dimmed until a rating is chosen. Large `StarRatingPicker`. The comment field as a `surface` card with its count |
| **Welcome** | Grove background with the glow. A lime square mark, "Favorly" in `largeTitle`, the existing tagline in `cardTitle`, the decorative sample cards, then Apple's button and the legal links |
| **Profile setup, Report, Blocked people, Safety tips** | Grove background, `surface` rows, Figtree, primary and danger buttons. Same content |
| **Dev Settings** | The plainest screen: Grove colors and font only |

Row views keep `accessibilityElement(children: .ignore)` with the spoken label they have today.

## Implementation phases

Five sequential phases, one session each, on branches named `phase/5a-grove-theme` and so on. No pull requests: fast-forward `main`, push, delete the branch.

### 5A. Theme, font and shared components

- [ ] Before changing anything, run `ScreenshotUITests` and save the current look to `docs/screenshots/phase-4/` as the "before" set
- [ ] Figtree font files and the OFL license under `App/Resources/Fonts/`, `UIAppFonts` in `project.yml`, `xcodegen generate`. Record the font in `docs/PROGRESS.md` (an asset, not a runtime dependency)
- [ ] `Theme.Colors` (Grove tokens), `Theme.Typography`, the new `Radius`, `Spacing` and `Shadow` values; category, status and avatar mappings
- [ ] `GroveBackground`, `Card`, `CardRow`, and every component in the *Shared components* table, each with a light and dark `#Preview`
- [ ] Navigation and tab bar appearance, tint, `AccentColor`
- [ ] Tests: every text-on-fill pair in the token table reaches 4.5:1 (11 pt badge text included); `ink` and `inkMuted` reach 4.5:1 on both `background` and `surface`; `onBrand` on `brand`, `onLime` on `lime` and `onTint` on `tint` reach 4.5:1 in both modes; every category and status maps to a color; a `LaunchUITests` method that checks Figtree is registered

**Done when:** `swift test` and `xcodebuild test` pass. The app runs with the new colors and font on every screen, even though layouts haven't changed yet. The "before" screenshots are committed.

### 5B. Nearby and Request Detail, then the review gate

- [ ] `NearbyView` and `RequestRow` as cards
- [ ] `RequestDetailView`: header, facts card, people cards, buttons
- [ ] Screenshots in light, dark and `accessibility-large`, checked by eye for clipping, truncation and overlap
- [ ] Guardrail checks

**Done when:** `BrowseAndPickUpUITests` and `DemoFlowUITests` pass unedited.

**Review gate.** Stop and show the owner the Nearby and Request Detail screenshots next to the mockup and the Phase 4 ones. Requested changes at this point are edits to `Theme` and the shared components only. Record the outcome in `docs/PROGRESS.md` before 5C.

### 5C. Post, My Activity and Chat

- [ ] `PostRequestView`: card fields, the category and neighborhood pickers, the meeting spot, the primary button
- [ ] `ActivityView` and `ActivityRow` as cards, with the highlighted row
- [ ] `ChatView` and `MessageBubble`: the request card, bubbles, the input bar
- [ ] Screenshots and guardrail checks as in 5B

**Done when:** `PostNeighborhoodUITests`, `KeyboardUITests` and `ChatUITests` pass unedited.

### 5D. Profile, review, onboarding and safety screens

- [ ] `ProfileView`: header, score card, past activities, reviews, the account section
- [ ] `ReviewFormView` and the star picker
- [ ] `WelcomeView` with the decorative cards; `ProfileSetupView`
- [ ] `ReportView`, `BlockedUsersView`, `SafetyTipsView`, `DevSettingsView`
- [ ] Screenshots and guardrail checks as in 5B

**Done when:** `ProfileUITests`, `ReviewUITests`, `OnboardingUITests`, `SafetyUITests` and `DevSettingsUITests` pass unedited, and no screen still uses the Phase 2 look.

### 5E. Polish, accessibility, docs

- [ ] Consistency pass: no literal colors, fonts (`.font(.system`, `.body`, …), radii, padding or shadows in `FavorlyFeatures` outside `Shared/Theme/`
- [ ] Accessibility pass: the largest accessibility text size, Increase Contrast, Reduce Transparency (glow off), Bold Text, VoiceOver labels unchanged
- [ ] Check on a real iPhone in light and dark mode, including the tab bar on the installed iOS version
- [ ] README screenshots (light and one dark), a link to this plan; the "Theme" section of `docs/ARCHITECTURE.md` updated for Grove and Figtree
- [ ] SwiftLint and SwiftFormat clean, no warnings under Swift 6 strict concurrency
- [ ] Version per decision 1; tag `v1.1.0-grove` (or fold into the release tag if Phase 5 runs before 4H)

**Done when:** the *Definition of done* in the Overview is met on a fresh clone.

## Testing and review

- **Automated.** The behavior UI tests and the package tests are the regression net and stay unedited, apart from the three theme test files named in *Guardrails*. New tests cover the Grove tokens' contrast, the mappings and font registration. There are still no pixel snapshot tests.
- **By eye.** `ScreenshotUITests` produces the same set of images each run. Compare each with the mockup's matching artboard after each sub-phase. The owner approves at the 5B gate and at the end of 5E.
- **By hand.** The README demo script, once in light mode and once in dark mode, at the end of 5D, plus one run on a real device in 5E.

## Costs

None. Figtree is free under the OFL. No services, builds or uploads are needed beyond what 4G and 4H already cover. Uploading a 1.1.0 build to TestFlight is a separate, owner-approved step.

## Conventions for coding agents

Everything in `CLAUDE.md` and in the earlier plans' conventions still applies, with these changes for Phase 5:

- Figtree is the one allowed custom font. Use it only through `Theme.Typography`.
- Shadows are allowed only through `Theme.Shadow`, and only on cards and the primary button.
- Components are views without logic, so they need previews, not tests. Anything with logic (contrast, mappings) needs tests in the same phase.
- When the mockup and a guardrail disagree, the guardrail wins. Log the gap in `docs/PROGRESS.md` rather than changing behavior or copy.
- When a look is a judgment call, pick what is closest to the mockup that keeps a system control, and note it in `docs/PROGRESS.md`.
