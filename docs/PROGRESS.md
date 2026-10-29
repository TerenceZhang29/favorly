# Progress

Updated by every coding session. Read this after `docs/PLAN.md`, `docs/PLAN-PHASE-2.md`, `docs/PLAN-PHASE-3.md` and `docs/PLAN-PHASE-4.md`, and continue from the first unchecked item.

**Current phase:** Phase 4. 4A–4F are done: Sign in with Apple on the hosted Supabase project, device location, reporting, blocking and the word filter, and push notifications, tried on the owner's iPhone. Phase 3 (`v0.3.0-profiles` plus 3F), Phase 2 (`v0.2.0-ui`) and Phase 1 (`v0.1.0-prototype`) are complete
**Next task:** 4G (release candidate and beta) on `phase/4g-beta`, starting with the editable location tag on Post

## Phase checklist

- [x] **1A.** Repo scaffold and empty app
- [x] **1B.** Core domain (models, protocols, rules, distance)
- [x] **1C.** Mock data layer (repository, location, session, seed data)
- [x] **1D.** App environment and navigation shell (tabs, Dev Settings)
- [x] **1E.** Browse nearby + request detail + pick up (Flow 2)
- [x] **1F.** Post request + My Activity (Flow 1)
- [x] **1G.** Hardening, UI test, docs, tag `v0.1.0-prototype`

Phase 2, UI refresh ([PLAN-PHASE-2.md](PLAN-PHASE-2.md)):

- [x] **2A.** Theme and shared components, "before" screenshots
- [x] **2B.** Nearby and Request Detail, then the review gate
- [x] **2C.** Post, My Activity and Dev Settings
- [x] **2D.** Polish, app icon, docs, tag `v0.2.0-ui`

Phase 3, Kindness score, profiles, chat and reviews ([PLAN-PHASE-3.md](PLAN-PHASE-3.md)):

- [x] **3A.** Kindness score: core and data (rules, repository, seed history)
- [x] **3B.** Profile tab with score and gift card (screenshots not yet checked by eye)
- [x] **3C.** Chat between requester and helper
- [x] **3D.** Reviews
- [x] **3E.** Hardening, demo, docs, tag `v0.3.0-profiles` (owner's review accepted 2026-10-28)
- [x] **3F.** Requester-only completion and auto-complete after 7 days

Phase 4, from prototype to App Store app ([PLAN-PHASE-4.md](PLAN-PHASE-4.md)). The owner accepted every default in "Decisions needed from the owner" on 2026-10-28:

- [x] **4A.** Release groundwork: onboarding and account screens on a mock auth service, Dev Settings Debug-only, no fake Redeem
- [x] **4B.** Backend schema and server rules (local Supabase, database tests, hosted project `favorly`)
- [x] **4C.** Real accounts and shared data (`FavorlyRemote`, Sign in with Apple). The two-phone check moved to 4G
- [x] **4D.** Real location and privacy
- [x] **4E.** Trust and safety: report, block, content filter, moderation, terms
- [x] **4F.** Push notifications
- [ ] **4G.** Release candidate and TestFlight beta
- [ ] **4H.** App Store submission and launch, tag `v1.0.0`

## Needs the owner's review

- **Two-phone check (4G).** Moved from 4C on the owner's decision: done during the internal TestFlight round, when teammates install the app anyway. Steps are in `docs/PLAN-PHASE-4.md`, 4G.

## Owner's review of Phase 3

Accepted by the owner on 2026-10-28: the 3E review items and every judgment call below stand as built. The Phase 3 screenshots were not committed to `docs/screenshots/phase-3/`; regenerate them with the `ScreenshotUITests` command in the README if the team wants them.

**Judgment calls, all confirmed** (each is also in the decision log)

- Gift card above 100 points reads "110 of 100 points" with a full bar, not "100 of 100". Nothing is hidden, but it looks odd.
- The gift card says "Every 100 points earns a $5 gift card." The $5 is the plan's placeholder.
- Avatar colors: Alex blue, Bea indigo, Chen green, Dana pink (from the five colorful palette entries by a fixed hash of the user ID).
- The chat thread stays readable after completion or cancellation, read-only, with a lock note. Sending after completion throws `notAllowed`, not a new error.
- Message and Leave a review buttons: Message is a tinted (secondary) button, Leave a review is a filled (primary) one, both on Request Detail above Mark completed and Cancel.
- Someone's own profile, reached from Request Detail, shows their gift card, the same as the Profile tab.
- The review on Request Detail is shown to everyone who opens the request, titled "Your review" for its author and "Review" for anyone else.
- Profile past activities show completed requests only on every profile, including your own; open and claimed ones stay in My Activity.
- The Request Detail requester and helper rows are now tappable and show the score; VoiceOver still reads "Posted by, Bea" and adds the score as a hint.

## Commit map

One row per commit, oldest first, grouped by phase. Every session adds its commits here before it ends, so this table and `git log` stay in step.

- Each phase ends with a `docs: record phase <id> progress` commit. That commit cannot list its own hash before it exists, so the next commit to touch this file fills it in.
- To undo a whole phase, revert its range, newest phase first: `git revert --no-commit <first>^..<last>`, then commit.
- To undo one change, `git revert <hash>`. Later phases build on earlier ones, so expect conflicts when reverting anything but the newest work.

| Phase | Commit | Change |
| --- | --- | --- |
| Setup | `1ef1310` | docs: add Phase 1 plan, progress log and agent instructions |
| 1A | `d4c4f60` | chore: add gitignore, SwiftLint and SwiftFormat configs |
| 1A | `d72f147` | feat(kit): add FavorlyKit package with Core, Data and Features targets |
| 1A | `44ec3c0` | feat(app): add XcodeGen project, app shell with four tabs and launch UI test |
| 1A | `7436627` | docs: add README and architecture summary, record phase 1A progress |
| 1B | `559f328` | feat(core): add domain models, service protocols and FavorlyError |
| 1B | `b01687f` | feat(core): request status rules |
| 1B | `e937620` | feat(core): draft validation |
| 1B | `17151fe` | feat(core): haversine distance and miles formatting |
| 1B | `921d0c0` | docs: record phase 1B progress |
| 1C | `8de8e95` | feat(data): seed users, requests and location presets |
| 1C | `cd8e865` | feat(data): in-memory request repository with change stream and reset |
| 1C | `551e8d4` | feat(data): mock location provider, location settings and session store |
| 1C | `0f29fb2` | docs: record phase 1C progress |
| 1D | `056aace` | feat(core): require Sendable on SessionStore and LocationSettings |
| 1D | `509edfd` | feat(features): app environment with preview defaults |
| 1D | `bf83caa` | feat(features): navigation shell and dev settings screen |
| 1D | `b75adec` | feat(app): wire the demo environment and add dev settings UI test |
| 1D | `f392175` | docs: record phase 1D progress |
| 1E | `70d387b` | feat(features): display helpers, error messages and radius options |
| 1E | `2739185` | feat(nearby): view model with radius filter and request row |
| 1E | `eedf201` | feat(detail): request detail with pick up, cancel and complete; nearby list screen |
| 1E | `fa48783` | test(ui): browse nearby and pick up flow |
| 1E | `3c6f226` | docs: record phase 1E progress |
| 1F | `4d5b8d1` | refactor(features): share request status text between screens |
| 1F | `db7ef87` | feat(post): post request view model with live validation |
| 1F | `7568bd2` | feat(activity): my activity view model with two segments |
| 1F | `5cc7334` | feat(features): post form, my activity screen and post-then-highlight navigation |
| 1F | `06c1fb0` | test(ui): post and get picked up flow |
| 1F | `d12181c` | docs: record phase 1F progress |
| 1G | `9ae5d2f` | feat(app): add -uiTesting launch argument that removes the mock delay |
| 1G | `81348ff` | feat(features): VoiceOver labels on rows and Dynamic Type layout for facts |
| 1G | `96c6d8b` | test(ui): demo script test, shared UI test base and screenshot capture |
| 1G | `627b80f` | docs: README with demo script and screenshots, expand architecture notes |
| 1G | `3333580` | docs: record phase 1G progress and close out phase 1 (tag `v0.1.0-prototype`) |
| Post-1G | `4adfb3c` | docs: add commit map to progress log and record merge to main |
| Phase 2 plan | `300c7ff` | docs: add Phase 2 UI refresh plan |
| CI | `46d326a` | ci: run package tests and app UI tests on GitHub Actions |
| CI | `e0258b7` | test(ui): longer waits and identifier-wide matching for slower CI simulators |
| CI | `06cd622` | docs: record CI setup in progress log and README |
| 2A | `fdbf4a2` | test(ui): capture every screen in light and dark, save the Phase 1 look |
| 2A | `7897137` | feat(theme): color palette with contrast math, spacing, radii and color mappings |
| 2A | `399751a` | feat(theme): shared components with light and dark previews, optional symbol on FactRow |
| 2A | `495fb90` | feat(app): brand tint on the root view and accent color asset |
| 2A | `dd1906d` | docs: record phase 2A progress |
| 2B | `7ea1afc` | feat(theme): plain list rows, compact section spacing and taller buttons |
| 2B | `6969208` | feat(nearby): restyle the list rows, location line, count and empty and error states |
| 2B | `4dd7dfd` | feat(detail): header with icon and status badge, fact symbols, full-width action buttons |
| 2B | `7ba2098` | test(ui): capture more states and a large text size, add Phase 2 Nearby and Request Detail screenshots |
| 2B | `b5313c6` | docs: record phase 2B progress |
| 2C | `7b94d85` | docs: record the review gate outcome after 2B |
| 2C | `31ed44b` | feat(theme): section header, inline message, highlighted row background and its contrast test |
| 2C | `96f761c` | feat(post): restyle headers, validation messages, location row and the post button |
| 2C | `74d334e` | feat(activity): restyle rows with icon and badges, highlighted new row and empty states |
| 2C | `5675fd9` | feat(dev-settings): red reset button and gray prototype note |
| 2C | `251e302` | test(ui): capture Post, My Activity and Dev Settings states, refresh Phase 2 screenshots |
| 2C | `b1a8422` | docs: record phase 2C progress |
| Phase 3 plan | `0445bd6` | docs: add Phase 3 plan for Kindness score, profiles, chat and reviews |
| 2D | `b5ea2d5` | refactor(theme): move the error banner into a shared component, remove the last style literals |
| 2D | `9b9d3a2` | feat(app): app icon drawn by a script, version 0.2.0 |
| 2D | `d8c5de2` | fix(a11y): keep rows readable at the largest text size |
| 2D | `e060b15` | style: apply SwiftFormat and wrap a long comment |
| 2D | `1d87308` | docs: README with Phase 2 screenshots and a dark one, Theme section in the architecture notes |
| 2D | `5635026` | docs: record phase 2D progress and close out phase 2 |
| 3A | `27f79c5` | feat(core): kindness models, repositories, rules and two new errors |
| 3A | `403bcd9` | feat(data): history seeds 13-17, demo reviews, kindness and review reads in the mock repository |
| 3A | `635a8ce` | feat(features): kindness and review repositories in AppEnvironment, demo wiring and preview stubs |
| 3A | `889569b` | docs: record phase 3A progress |
| CI | `3510875` | ci: manual workflow for SwiftLint, SwiftFormat and screenshots |
| CI | `3165240` | ci: run CI and the lint checks on claude/** branches |
| 3B | `82dfdb3` | feat(profile): profile view model with redeem, kindness scores on request detail |
| 3B | `9f3653b` | feat(theme): avatar, score label and gift card components, avatar colors |
| 3B | `b7dca3d` | feat(profile): profile tab, other users' profiles from request detail |
| 3B | `6963a61` | test(ui): five tabs, profile UI tests and profile screenshots |
| 3C | `8d879e7` | feat(core): chat message model, chat repository and chat rules |
| 3C | `afeebde` | feat(data): chat threads in the mock repository |
| 3C | `ba563e7` | feat(chat): chat view model, chat in AppEnvironment and the message entry point on request detail |
| 3C | `bcb7273` | feat(chat): chat screen, message bubbles and the Message button, chat UI test |
| 3D | `66a3a45` | feat(core): review draft, review rules and submitReview on ReviewRepository |
| 3D | `bb7d005` | feat(data): submit reviews in the mock repository |
| 3D | `b5b0cc7` | feat(review): review form view model, review state on request detail |
| 3D | `7585e31` | feat(review): star rating, review form sheet, review on request detail and reviews on profiles, review UI test |
| 3E | `56059b9` | test(ui): extended demo script, chat and review screenshots |
| 3E | `70ba10a` | chore(app): version 0.3.0 |
| 3E | `b19bc65` | docs: Phase 3 demo script in the README, new protocols and the one mock actor in the architecture notes |
| 3E | `88f2f32` | docs: record phases 3B-3E progress and the owner's review list |
| 3E | `19faa83` | style(detail): keep the person row helper under five parameters |
| CI | `70825b9` | ci: keep the full xcodebuild log and print failing tests |
| 3E | `33485dc` | test(ui): check the new favor before scrolling to the reviews |
| 3E | `9e0d7e8` | fix(chat): close the chat before switching user in the UI test, scroll dismisses the keyboard; apply SwiftFormat rules |
| 3E | `4ddb7e1` | docs: record phase 3 CI results and the commit map [screenshots] |
| 3E | `efac56d` | test(ui): wait for the user row before switching user |
| 3E | `b9a21f4` | docs: record the screenshot run and a one-off UI test flake |
| Polish | `179677c` | feat(features): Done key closes the keyboard on multi-line fields, scrolling dismisses it on Post and Review |
| Demo | `322d024` | test(ui): rice story pitch demo script with screen recording; ignore recordings |
| Demo | `1789989` | docs: README section for the rice story pitch demo |
| Plan | `78d04db` | docs: plan phase 3F, requester-only completion and auto-complete after 7 days |
| Tooling | `e6841f7` | chore(build): local signing file for running on a device, parallel UI tests |
| Tooling | `daf2fce` | docs: README note on the keyboard UI test failing after typing into the simulator |
| Plan | `3c4d547` | docs: plan phase 4, from prototype to App Store app |
| 3E | `4bdb168` | docs: owner accepts the Phase 3 review; 3E done |
| 3F | `33be675` | feat(core): only the requester completes a request; auto-complete after 7 days |
| 3F | `03f6ade` | feat(data): mock repository completes picked-up requests 7 days after pick-up |
| 3F | `76a1009` | fix(features): isReturnKey is nonisolated, clearing actor-isolation warnings in its tests |
| 3F | `7bc820d` | feat(detail): only the requester sees Mark completed; the helper sees when it completes on its own |
| 3F | `5966af0` | test(ui): the helper sees the auto-complete note and the requester completes in the profile test |
| 3F | `0be77da` | docs: requester-only completion and auto-complete in the README demo and architecture notes |
| 3F | `a8fb345` | docs: record phase 3F progress |
| 4A | `1f12138` | feat(core): auth service, sign-in states, profile setup rules; demo user switching leaves SessionStore |
| 4A | `6a764a4` | feat(data): mock auth service; mock session store offers profile lookup and demo controls |
| 4A | `8f03933` | feat(profile): sign out and delete account; remove the gift card and Redeem |
| 4A | `e257684` | feat(onboarding): Welcome and profile setup screens behind a sign-in gate; Dev Settings in Debug builds only |
| 4A | `6b8fbe6` | feat(app): demo or live environment at launch, -demo in the Run scheme, no-encryption Info.plist key |
| 4A | `88f2118` | test(ui): onboarding, sign out and delete account; launch starts at Welcome; gift card steps removed |
| 4A | `a7bdf6d` | docs: sign-in gate, demo and live launches, and the removed gift card in the README and architecture notes; tick 4A |
| 4A | `317e3e8` | docs: record phase 4A progress |
| 4B | `b9f4f48` | chore(backend): local Supabase project, ports moved up by 1000, storage off |
| 4B | `4e93523` | feat(backend): schema for profiles, requests, chat, reviews, reports and blocks; read access by row-level security |
| 4B | `682f9bd` | feat(backend): actions enforcing the app's rules, rate limits, blocks, account deletion; auto-complete job |
| 4B | `d2c79df` | test(backend): pgTAP tests for every action and policy |
| 4B | `bae2f11` | docs(backend): commands, how it works, and the error contract |
| 4B | `f332e21` | docs: record phase 4B progress; hosted project waits on the owner |
| CI | `2318ac2` | ci: run the backend database tests and schema lint on pushes that change backend/ |
| CI | `98cafca` | docs: backend CI in the progress log |
| 4B | `939c0fd` | docs: hosted Supabase project and how to deploy; 4B done |
| 4C | `d2c1f65` | feat(backend): invalid_transition reports the current status; requests, messages and reviews published to realtime |
| 4C | `58ad6d0` | feat(core): notSignedIn, rateLimited, blocked and network errors with their messages |
| 4C | `b41af41` | build(kit): FavorlyRemote target on supabase-swift 2.55.5 |
| 4C | `26d69f8` | feat(remote): configuration, server rows mapped to the domain model, server errors mapped to FavorlyError |
| 4C | `18c722c` | feat(remote): repository, profiles, session and auth against Supabase, with realtime changes |
| 4C | `bcf145c` | test(remote): contract tests run against the mock always and the local backend on request |
| 4C | `3a7b6cc` | feat(app): -remote Debug launches use the Supabase backend from Local.xcconfig, with email sign-in for development |
| 4C | `56ff948` | docs: running against the backend; 4C progress, decisions and the supabase-swift dependency |
| 4C | `333ab18` | docs: hosted deploys use --linked and the CLI login; migration 0005 deployed |
| 4C | `7648e4f` | feat(onboarding): Sign in with Apple button with a hashed nonce on the backend; the demo keeps its plain button |
| 4C | `b8ce42a` | feat(app): normal launches use the hosted backend; Sign in with Apple entitlement |
| 4C | `f521dd1` | docs: hosted auth settings and the Sign in with Apple decisions |
| 4C | `1c519e1` | docs: 4C done but the two-phone check; running against the hosted or local backend |
| 4D | `0cad4c3` | feat(core): locationPermissionDenied, and snapping locations to about 100 m |
| 4D | `d1b153e` | feat(device): device location provider with permission, snapping and neighborhood names, on CoreLocation |
| 4D | `513a5af` | feat(features): Nearby names the neighborhood; Open Settings when location is off; presets only in demo launches |
| 4D | `343a77f` | feat(app): the backend launch uses the device's location; location permission text |
| 4D | `d8a0d10` | docs: device location in the README; 4D progress and decisions; two-phone check moved to 4G |
| 4E | `00a35c9` | feat(core): report targets and reasons, moderation repository, content filter in every validator |
| 4E | `356d2bb` | feat(backend): offensive-word triggers with the app's list, and blocked_profiles for the Blocked people list |
| 4E | `1f353e2` | feat(data): reports and blocks in the mock repository; blocks stop pick-ups and messages |
| 4E | `8984734` | feat(remote): reporting and blocking against the server; contract tests for reports, blocks and the word filter |
| 4E | `c2d07ef` | feat(features): moderation in AppEnvironment |
| 4E | `b5b1163` | feat(safety): report requests, messages and people; block from Request Detail and profiles; Blocked people, Safety tips, terms and support on Profile |
| 4E | `8443ae8` | fix(safety): Unblock keeps its own accessibility identifier |
| 4E | `dcdb2ba` | test(ui): report a request, block and unblock someone, open safety tips |
| 4E | `59859c4` | docs: moderation routine and dashboard queries |
| 4E | `50ce8d5` | docs: record phase 4E progress |
| 4E | `61ee4d5` | docs: safety migration deployed to the hosted project |
| 4F | `1487abb` | feat(backend): device tokens, a push outbox filled by triggers with each notification's text, sending through pg_net |
| 4F | `d0c8824` | feat(backend): push Edge Function sends the outbox to APNs with an ES256 provider token |
| 4F | `9e321d4` | feat(core): push registrar and notification service protocols, with mocks |
| 4F | `4c4983d` | feat(remote,device): register device tokens on the server; system notification permission |
| 4F | `48883ef` | feat(features): ask for notifications after the first post or pick-up, unregister at sign-out, open tapped notifications in My Activity |
| 4F | `6811fe1` | feat(app): app delegate for device tokens and notification taps; push entitlement |
| 4F | `f73e542` | docs: push setup in the backend README; 4F progress and decisions |
| 4F | `c6a4dcc` | docs: push migration and function deployed to the hosted project |
| 4D | `60ab8a8` | docs: plan an editable location tag on Post, after checking what the geocoder returns in New York |
| 4F | `983a2b5` | fix(app): a notification tapped before the environment exists still opens its request; early device tokens are kept |
| 4F | `d2589f4` | fix(app): notification delegate methods use completion handlers; the async forms crashed when a notification was tapped |

## Confirmed decisions

Defaults from the plan's Preparation section. Change here if the team decides otherwise.

- Bundle identifier: `edu.cornelltech.team402.favorly`
- Minimum iOS: 17
- Default fake location: Cornell Tech, Roosevelt Island (40.7553, -73.9562)
- Categories: Ingredient, Moving help, Car help, Errand, Other
- Units: miles in the UI, meters internally

## Decisions made during implementation

Add entries as `YYYY-MM-DD · phase · decision · reason`.

- 2026-10-07 · 1A · The `Favorly` scheme's test action lists the three package test targets and `FavorlyUITests` directly, with no `.xctestplan` file · a test plan file refers to project targets by generated IDs, which would be hand-maintained against a git-ignored project; the scheme runs the same tests
- 2026-10-07 · 1A · Optional GitHub Actions CI left out · it could not be verified from this machine, and the hosted runner's Xcode and simulator names are unknown; add it once someone can watch a run
- 2026-10-07 · 1A · `FavorlyCoreModule` and `FavorlyDataModule` are placeholder types so the targets compile and have one trivial test each · delete them in 1B and 1C when real types land
- 2026-10-07 · 1A · Only folders that hold a file exist so far (`Root/` in Features) · git does not track empty folders; each later phase creates the plan's folders as it fills them
- 2026-10-07 · 1A · SwiftFormat rule `wrapPropertyBodies` disabled · the plan's own code uses one-line computed properties (`var id: RequestID { request.id }`)
- 2026-10-07 · 1A · SwiftLint `trailing_comma` set to mandatory · otherwise it conflicts with SwiftFormat, which adds trailing commas
- 2026-10-07 · 1A · UI test target has `LaunchUITests` (app shows four tabs) · the target needs a source file; `DemoFlowUITests` arrives in 1G
- 2026-10-07 · 1B · Every public model has an explicit `public init`; `HelpRequest`'s defaults `helperID` and `claimedAt` to `nil` and `status` to `.open` · Swift's memberwise initializers are internal, so other modules could not build the types otherwise
- 2026-10-07 · 1B · `DraftValidator.validate(_:)` returns the draft with title and details trimmed (`@discardableResult`), where the plan shows no return value · the repository must store the trimmed title, and this keeps the trimming in one place
- 2026-10-07 · 1B · Details are trimmed before the 500-character check, like the title · the plan only says "0–500 characters"; trailing whitespace should not use up the limit
- 2026-10-07 · 1B · `validateClaim` checks "own request" before status, so a requester claiming their own already-claimed request gets `cannotClaimOwnRequest` · the plan does not order the two checks
- 2026-10-07 · 1B · `DistanceFormatter.miles` shows "< 0.1 mi" for anything under 0.1 mi, including 0.05–0.1 mi that would round up to "0.1 mi" · the plan's wording allows either; this one never overstates a short distance
- 2026-10-07 · 1B · Added `Distance.metersPerMile`, `Distance.meters(fromMiles:)`, `DraftValidator.titleLengthRange` and `DraftValidator.maxDetailsLength` · the UI needs the same constants for the radius picker and form hints
- 2026-10-07 · 1B · SwiftLint `identifier_name` allows `to` · the plan names the parameter in `canTransition(from:to:)`
- 2026-10-07 · 1C · `LocationSettings` is a `@MainActor` protocol in Core, with `LocationPreset` as a Core model; the `@Observable` class is `MockLocationSettings` in Data · the plan puts `LocationSettings` in Data but has `AppEnvironment` (Features) hold it, and Features must not import Data. This mirrors `SessionStore` / `MockSessionStore`
- 2026-10-07 · 1C · Seed data is `DemoRequests.all(now:)`, a function, where the plan writes `DemoRequests.all` · timestamps are relative to launch time, and tests need a fixed clock
- 2026-10-07 · 1C · `MockRequestRepository.init` takes `seed`, `artificialDelay` and `now` closures/values, all defaulted · tests run with zero delay and a fixed clock; 1G's `-uiTesting` launch argument will pass zero delay
- 2026-10-07 · 1C · `reset()` skips the artificial delay and emits on `changes()` · it is a dev-settings action, and open screens must refresh after it
- 2026-10-07 · 1C · `requests(claimedBy:)` returns every request whose helper is the user, whatever its status, newest claim first · "Picked up by me" should keep showing completed and cancelled pick-ups
- 2026-10-07 · 1C · `changes()` streams buffer one pending signal · the signal has no payload, so a slow subscriber needs only one refresh
- 2026-10-07 · 1C · `FavorlyData` imports `os` (for `OSAllocatedUnfairLock` in `ChangeBroadcaster`) and `Observation` · `changes()` is not `async`, so the actor needs a lock-protected subscriber list; both are system frameworks
- 2026-10-07 · 1C · Seed has 12 requests: from Cornell Tech, 3 open within 0.25 mi, 7 within 1 mi, 8 within 3 mi · matches the plan's "about 8" for the demo and makes each radius step visibly change the list
- 2026-10-07 · 1D · `SessionStore` and `LocationSettings` now also require `Sendable` · `AppEnvironment` must be `Sendable` to be an environment default and to be captured by view-model tasks; `@MainActor` classes already are, so conformers need no change
- 2026-10-07 · 1D · The environment value uses SwiftUI's `@Entry` macro (`EnvironmentValues.appEnvironment`), where the plan says `EnvironmentKey` · `@Entry` generates the same key; SwiftFormat rewrites a hand-written key to it
- 2026-10-07 · 1D · `AppEnvironment.preview()` is built from small read-only stubs inside Features (`PreviewRequestRepository`, `PreviewLocationProvider`, `PreviewSessionStore`, `PreviewLocationSettings`) · Features cannot import Data, and previews and the environment default still need something to run on
- 2026-10-07 · 1D · A view with no injected environment gets `AppEnvironment.sharedPreview` through `MainActor.assumeIsolated` · the default must be produced from a nonisolated context; SwiftUI reads environment values on the main actor. The app always injects `AppEnvironment.demo()`
- 2026-10-07 · 1D · `FavorlyFeaturesTests` depends on `FavorlyData` · the plan calls for view model tests against the mocks; only the Features sources are barred from importing Data
- 2026-10-07 · 1D · Dev Settings lists users and locations as rows of buttons with a checkmark, not `Picker`s · each row gets a stable `accessibilityIdentifier` the UI tests can tap
- 2026-10-07 · 1D · No Dev Settings view model · the screen only forwards taps to the session, location settings and repository, and holds no logic to test; `DevSettingsUITests` covers it end to end
- 2026-10-07 · 1D · "Reset demo data" restores requests only, not the current user or location · the plan lists it under data controls
- 2026-10-07 · 1D · The debug line reads "Alex @ Cornell Tech, Roosevelt Island", using the full location label, where the plan's example shows "Alex @ Cornell Tech" · the label is the plan's own preset name
- 2026-10-07 · 1E · View models take the `AppEnvironment` in `init`; `RootView` reads it from the SwiftUI environment and passes it down · a view model has to exist before the view body runs, so it cannot read `@Environment` itself
- 2026-10-07 · 1E · Location and radius changes reload through `.task(id: viewModel.reloadKey)` in the view; repository writes reload through `viewModel.observeChanges()` · the plan says the view model "observes" both; this keeps the view model free of observation plumbing and easy to test
- 2026-10-07 · 1E · A list already on screen stays visible while it reloads; only the first load and a retry after an error show the spinner · avoids a flicker on every radius tap and every write
- 2026-10-07 · 1E · Nearby keeps the debug line ("Alex @ Cornell Tech, Roosevelt Island") as its location header, and shows a count ("7 requests") above the list · on one laptop the demo needs to show who is signed in; the count makes radius changes obvious and gives UI tests something stable to read
- 2026-10-07 · 1E · The detail status row reads "Claimed by Bea" while claimed, with a separate Helper row for claimed and completed requests · matches the demo script's wording
- 2026-10-07 · 1E · Only Pick up asks for confirmation; Cancel request and Mark completed act at once · the plan asks for a dialog before Pick up only
- 2026-10-07 · 1E · When an action fails, the detail screen shows the message and reloads the request · after `alreadyClaimed` the user should see who claimed it
- 2026-10-07 · 1E · Added `BrowseAndPickUpUITests` (Flow 2, own request has no Pick up, empty and error states) · the plan checks Flow 2 by hand; an agent cannot, so the flow is automated
- 2026-10-07 · 1F · `RootView` owns the tab selection and the just-posted request ID; `PostRequestView` reports a post through an `onPosted` closure · switching tabs and highlighting are navigation concerns, so the Post view model stays unaware of other tabs
- 2026-10-07 · 1F · The new request is highlighted in My Activity (tinted row and a "New" badge) until the user leaves that tab · the plan says "highlight" without saying for how long
- 2026-10-07 · 1F · The Post form's category defaults to Other · none of the five is an obvious default, and the demo picks Ingredient explicitly
- 2026-10-07 · 1F · The title message appears only once the user has typed something; the Post button is disabled either way · an empty form should not open with an error
- 2026-10-07 · 1F · My Activity rows show the status ("Claimed by Bea"), plus "Posted by Dana" for requests picked up from someone else · the plan lists "status and helper" for My requests and nothing for Picked up by me
- 2026-10-07 · 1F · `statusText(for:)` moved to a `SessionStore` extension shared by Request Detail and My Activity · both screens need the same "Claimed by Bea" wording
- 2026-10-07 · 1F · Added `PostAndGetPickedUpUITests` (Flow 1 end to end, and the two empty states) · the plan checks Flow 1 by hand; 1G turns this into `DemoFlowUITests`
- 2026-10-07 · 1G · `-uiTesting` only sets the mock delay to zero · the plan also says it "resets data", but data is in memory and every launch already starts from the seed
- 2026-10-07 · 1G · `DemoFlowUITests` runs the whole seven-step demo script, which contains Flow 1; it replaces 1F's `PostAndGetPickedUpUITests` · one test that mirrors the README script is easier to keep in step with it
- 2026-10-07 · 1G · UI tests share a `UITestCase` base class (launch, lookup by identifier, wait, scroll-then-tap) · removes the duplicated helpers noted in 1F
- 2026-10-07 · 1G · List rows speak one sentence to VoiceOver ("Need 2 eggs for a cake, Ingredient, less than 0.1 miles away, posted 12 minutes ago by Chen"); detail rows read as label plus value · the default reading split each row into fragments and read "<" literally. Added `DistanceFormatter.spokenMiles` in Core for this
- 2026-10-07 · 1G · Detail rows stack the value under the label at accessibility text sizes, and row icons scale with the text · side-by-side text was cramped at large sizes
- 2026-10-07 · 1G · Dev Settings rows use primary text color, not the button tint · every row looked like a link
- 2026-10-07 · 1G · `ScreenshotUITests` regenerates the README screenshots and is skipped unless `TEST_RUNNER_SCREENSHOT_DIR` is set · an agent cannot tap through the Simulator by hand to capture them
- 2026-10-07 · 1G · Tag `v0.1.0-prototype` points at the tip of `phase/1g-hardening`, because the phase pull requests were not merged yet · if the pull requests are squash-merged, move the tag to the resulting commit on `main`
- 2026-10-07 · post-1G · No pull requests: `main` was fast-forwarded to `phase/1g-hardening`, keeping every commit · the owner decided no review step is needed; the tag `v0.1.0-prototype` stays valid because no commit was rewritten
- 2026-10-07 · post-1G · Added the "Commit map" section, one row per commit · the owner wants the progress file and the commit history to match, so changes are easy to trace and revert
- 2026-10-07 · Phase 2 plan · The Phase 2 plan is its own file, `docs/PLAN-PHASE-2.md`; `docs/PLAN.md` stays the source of truth for architecture and behavior · the Phase 1 plan is a finished record, and Phase 2 changes looks only
- 2026-10-07 · Phase 2 plan · Phase 2 keeps one branch per phase but has no pull requests: fast-forward `main` at the end of each phase, then delete the branch · follows the owner's decision for Phase 1
- 2026-10-07 · Phase 2 plan · "Functionality unchanged" is defined as: no edits to Core, Data, view models, identifiers, visible strings, control types, or the four behavior UI test classes · gives each phase something concrete to check
- 2026-10-07 · Phase 2 plan · Theme colors are light and dark hex pairs in code, not an asset catalog in the package or system colors · they can be unit tested for contrast, and `swift test` on macOS does not compile asset catalogs
- 2026-10-07 · Phase 2 plan · Brand color defaults to teal (`#0A6B67` light, `#4FD1C5` dark); the owner has not confirmed it · it can be changed in one place before or at the 2B review gate
- 2026-10-08 · CI · Added `.github/workflows/ci.yml`: `swift test` and the full `xcodebuild test` on every push to `main`, `phase/**` and `ci/**` · the owner asked for the full test run; the repo is public, so standard macOS runners are free
- 2026-10-08 · CI · CI runs on `macos-26` with its default Xcode (26.6, iOS 26.5 simulator), while local development uses Xcode 27 and iOS 27 · the `xcode-27` runner label is still in public preview; the code builds and passes on both, so CI also guards against relying on the newest SDK
- 2026-10-08 · CI · The workflow picks the first iPhone on the newest installed iOS runtime, not a named device · simulator names differ between runner images
- 2026-10-08 · CI · UI test waits went from 5 s to a shared 20 s (`UITestCase.waitTimeout`), and `waitFor` now accepts any element with the identifier · the hosted runner is several times slower, and on iOS 26.5 a `Label`'s icon and text share one identifier, so the first match was the icon. No assertion changed
- 2026-10-08 · 2A · `ScreenshotUITests` has one test per appearance and writes `<screen>-light.png` and `<screen>-dark.png` for the five screens and the Nearby empty state; it switches appearance with `XCUIDevice.shared.appearance` and sets it back to light afterwards · no app code is needed to force a color scheme
- 2026-10-08 · 2A · The "before" set is in `docs/screenshots/phase-1/` (12 images, iPhone 17, iOS 27.0); the three README images in `docs/screenshots/` are untouched until 2D · take the Phase 2 screenshots on the same simulator so they compare side by side
- 2026-10-08 · 2A · Added `Theme.Colors.onBrand` (white in light mode, black in dark mode) for the primary button label · the component table says "white label", but the 2A test list asks for black on the dark brand color, and white on `#4FD1C5` would not be readable
- 2026-10-08 · 2A · Added `Theme.IconSize` (`row` 36, `large` 56), `Theme.pressedOpacity` (0.7) and `Theme.disabledOpacity` (0.4), and `Theme.Colors.palette` listing the nine tokens · components need these numbers and no literal should live outside `Theme`; the contrast test loops over `palette`
- 2026-10-08 · 2A · `RGBColor` has `blended(over:opacity:)`, and `AdaptiveColor` has `rgb(for:)` · the contrast test needs the color of a 14% tint on a background, without SwiftUI
- 2026-10-08 · 2A · `StatusBadge` and `TagBadge` are rounded rectangles with `Theme.Radius.badge`, not true capsules · the plan says "capsule" but also defines a badge radius of 6; a rounded rectangle still looks right when "Claimed by Bea" wraps at accessibility text sizes. Change at the review gate if a pill is preferred
- 2026-10-08 · 2A · `MessageView` takes the accessibility identifiers for its message and Retry button as parameters, and Retry uses the system `.bordered` style · `nearby.empty`, `nearby.error` and `nearby.retry` must stay on the same kind of element
- 2026-10-08 · 2A · Fact symbols in `FactRow` are gray, not brand colored · the brand color marks what the user can act on, and facts are not tappable
- 2026-10-08 · 2A · Shared components live in `Shared/Components/`, with a `LightAndDarkPreview` helper that shows preview content in both modes · keeps each component's `#Preview` to one block
- 2026-10-08 · 2A · Tests that import SwiftUI refer to `FavorlyFeatures.RGBColor` through a type alias · macOS has an old system type also named `RGBColor`
- 2026-10-08 · 2B · Each Request Detail action is its own list section with compact spacing, and the buttons have 16 pt vertical padding · on iOS 26 a list section clips its rows to the card shape; a shorter button, or two buttons in one row, came out with uneven corners. This way every button has the same corners as the cards above it, and `Theme.Radius.button` only shows outside a list
- 2026-10-08 · 2B · Added `plainListRow()` (no card, no insets, no separator) and `compactSectionSpacing()` (iOS only) as shared view helpers · screens need them for full-width buttons and centered messages, and the clear color and the `#if os(iOS)` should not live in screen files
- 2026-10-08 · 2B · Empty, error and loading states on Nearby and Request Detail sit on the page background, not in a card · matches the system's own empty states
- 2026-10-08 · 2B · The status badge in the Request Detail header is hidden from VoiceOver · the Status row below already speaks the same text, and spoken output must not change
- 2026-10-08 · 2B · The Request Detail load error also uses `MessageView` (`exclamationmark.triangle`) · the plan lists symbols only for Nearby; same treatment keeps the two screens consistent
- 2026-10-08 · 2B · Request Detail uses `toolbarTitleDisplayMode(.inline)` · it exists on macOS too, so `swift test` still builds the package
- 2026-10-08 · 2B · `ScreenshotUITests` has a third test at the `accessibility-large` text size (launch argument `-UIPreferredContentSizeCategoryName`), and also captures Nearby with a "Yours" row, the Nearby error state, and Request Detail with Pick up and with the requester's two buttons · the plan asks for a by-eye check at that size and those states were not in the first set
- 2026-10-08 · 2B · Phase 2 screenshots are in `docs/screenshots/phase-2/` (21 images for Nearby and Request Detail) · next to `phase-1/` for the review gate
- 2026-10-08 · 2C · The highlighted new row uses `Theme.highlightOpacity` (0.08), not the 0.14 tint, drawn by `HighlightedRowBackground` over the plain background · at 0.14 the "Open" and "New" badges on top of it fell to about 4.2:1; at 0.08 every palette color stays above 4.5:1, and a test checks it. In dark mode the highlighted row is a little darker than a normal row, because the shared background style is black there
- 2026-10-08 · 2C · `ActivityRow` splits the view model's subtitle ("Claimed by Bea · Posted by Dana") at " · " to show the status as a badge and the rest as gray text · the view model must not change in Phase 2. The spoken label is built from the unsplit subtitle, as before
- 2026-10-08 · 2C · In `ActivityRow` the badge and "Posted by" text sit side by side when they fit and stack when they do not (`ViewThatFits`) · they overflow at accessibility text sizes
- 2026-10-08 · 2C · Added `SectionHeader` (Post headers and the Nearby count) and `InlineMessage` (red text with a warning symbol, for validation, submit and location errors on Post) as shared components · the same styling was needed in several places
- 2026-10-08 · 2C · The Post submit error is its own section above the button, and the Category section has no header · the button row has no card, so the error needs one; adding a "Category" header would add a visible string
- 2026-10-08 · 2C · Dev Settings keeps the system section headers and its footer; only the checkmarks (brand color, semibold) and the Reset button changed · the plan asks for it to stay the plainest screen
- 2026-10-08 · 2C · `docs/screenshots/phase-2/` now holds the full set: 16 captures in light, dark and `accessibility-large` (48 images, 11 MB) · replaces the 2B subset
- 2026-10-09 · 2D · Consistency pass: the Request Detail error banner became the shared `ErrorBanner`, `FactRow`'s stacked spacing uses `Theme.Spacing.small` (4, was a literal 2), and the icon's symbol size uses the new `Theme.IconSize.symbolScale` (0.5) · no screen file now holds a shape, a color or a number for style. System colors (`.primary`, `.secondary`) stay, as the plan allows
- 2026-10-09 · 2D · `CategoryIcon` grows with text size only up to `Theme.IconSize.maxScale` (2×) · at the largest accessibility size the icon took so much of the row that titles broke one word per line. The `accessibility-large` look is unchanged, since it is just under the cap
- 2026-10-09 · 2D · At accessibility text sizes the "Yours" and "New" badges sit under the row's text, not beside it, and My Activity always stacks its status line · beside the text they squeezed the title into mid-word breaks ("Nee/d a"). Spoken labels and identifiers are unchanged
- 2026-10-09 · 2D · `StatusBadge` text always wraps and is never cut off · "Claimed by Bea" was truncated to "Claime…" at the largest text size
- 2026-10-09 · 2D · `ScreenshotUITests` has a fourth test at the largest text size (`accessibility-largest`, `AccessibilityXXXL`); it scrolls to rows that are off screen at that size and no longer requires elements that sit below the fold · the plan asks for every screen at the largest size. Those 16 images were checked by eye and are not committed, to keep the repo small
- 2026-10-09 · 2D · Increase Contrast and Reduce Transparency were checked by running the light screenshot test with the simulator setting on (`xcrun simctl ui <device> increase_contrast enabled`; `defaults write com.apple.Accessibility EnhancedBackgroundContrastEnabled` inside the simulator) · nothing clipped, overlapped or lost its meaning. Theme colors do not change with Increase Contrast; they already pass 4.5:1, and system text and bars adapt on their own
- 2026-10-09 · 2D · The app icon is `hand.raised.fill` in white, 56% of the icon's height, on the light brand color, drawn by `scripts/make-app-icon.swift` with AppKit; one 1024×1024 image with no transparency, no separate dark or tinted variants · the plan asks for a script so it can be redrawn; the system derives the other appearances
- 2026-10-09 · 2D · The README shows three light screenshots and one dark (Nearby), copied from `docs/screenshots/phase-2/`, which was regenerated at the end of 2D · the plan asks for light screenshots and one dark
- 2026-10-09 · Phase 3 plan · The Phase 3 plan is its own file, `docs/PLAN-PHASE-3.md`, with five phases 3A–3E; Kindness score and Profile come first (3A, 3B), then chat and reviews · the owner set those two as priorities 1 and 2
- 2026-10-09 · Phase 3 plan · Kindness score: 10 points to the helper per completed request plus 2 per review star; only helping earns points · owner's choice
- 2026-10-09 · Phase 3 plan · Gift card: progress toward 100 points plus a fake Redeem that deducts the points and shows a reward code; the lifetime score never drops · owner's choice
- 2026-10-09 · Phase 3 plan · Reviews: the requester reviews the helper, once per completed request · owner's choice
- 2026-10-09 · Phase 3 plan · Profile picture: an initials avatar drawn in code, no image assets · owner's choice; keeps Phase 2's no-image-assets rule
- 2026-10-09 · Phase 3 plan · New capabilities are three new Core protocols (`KindnessRepository`, `ReviewRepository`, `ChatRepository`), all implemented by the one `MockRequestRepository` actor · `RequestRepository` stays as it is, and one actor keeps cross-cutting rules atomic with one `changes()` stream and one `reset()`
- 2026-10-09 · Phase 3 plan · Five completed seed requests and seed reviews are added so Bea starts at 90 points; none involve Alex · profiles need history and the demo must reach a gift card in one favor, without changing Alex's empty states or any Nearby count
- 2026-10-09 · 3A · 3A adds only what its task list names: `Review`, `Redemption`, `KindnessSummary`, `ReviewID`, `RedemptionID`, `KindnessRepository`, and `ReviewRepository` with its two reads. `NewReviewDraft` and `submitReview` wait for 3D, `ChatMessage`, `MessageID` and `ChatRepository` for 3C · the plan splits them that way
- 2026-10-09 · 3A · `KindnessRules` has `pointsPerFavor` (10), `pointsPerStar` (2), `giftCardCost` (100), `summary(completedAsHelper:reviews:redemptions:)`, `validateRedeem(_:)` and `rewardCode(number:)` · the plan wants the values defined once; redeem validation and the code format are rules too, so they live beside them
- 2026-10-09 · 3A · `summary` counts stars only from reviews of requests it counts as completed favors · a review can only exist for a completed request, but the pure function should not trust its input; it also makes a stray review in a test seed harmless
- 2026-10-09 · 3A · Reward codes count up across all users, not per user (Bea's first is `FAVORLY-0001`, the next anyone redeems is `FAVORLY-0002`), and `reset()` starts them over · a gift card code should be unique; the demo script only needs Bea's to be `FAVORLY-0001`
- 2026-10-09 · 3A · `review(for:)` throws `notFound` for an unknown request and returns `nil` for a known request with no review · matches `request(id:)`
- 2026-10-09 · 3A · `redemptions(by:)` is newest first by the order of redeeming, not by `createdAt` · tests use a fixed clock, so two redemptions share a time
- 2026-10-09 · 3A · `MockRequestRepository`'s shared state (`requests`, `reviews`, `redemptions`, `now`, `broadcaster`, `simulateLatency()`) is internal instead of private · the plan puts each conformance in its own file, and Swift's `private` does not reach across files. It is still actor-isolated and not public
- 2026-10-09 · 3A · `MockRequestRepository.init` gains `reviewSeed` (defaults to `DemoReviews.all()`), and `reset()` restores reviews and clears redemptions · tests pass a fixed clock to both seeds, as they do for requests
- 2026-10-09 · 3A · Added `DemoRequests.id(_:)` for the fixed seed IDs · `DemoReviews` needs the history requests' IDs, and tests can use it instead of building UUIDs by hand
- 2026-10-09 · 3A · History seeds 13–17 were posted 3, 4, 5, 6 and 2 days ago in the requester's own neighborhood; like every seed, they were claimed halfway between posting and now, and each review comes a few hours after its claim · "several days old" in the plan; the neighborhoods keep them believable on a profile. They are completed, so no Nearby count changes
- 2026-10-09 · 3A · `AppEnvironment` gains `kindness` and `reviews` in this phase; `chat` comes with `ChatRepository` in 3C. `AppEnvironment.demo()`, `TestWorld` and `AppEnvironmentTests` pass the one `MockRequestRepository` to all three. `PreviewRequestRepository` gains `reviews` (empty by default) and read-only conformances; its redeem throws `notAllowed` · the plan's wiring, limited to the protocols that exist so far
- 2026-10-09 · 3A · Phase 1 and 2 tests edited only for the larger seed: `DemoRequestsTests` (17 requests; the distance spread and status mix are checked on the first twelve, the Phase 1 set), `MockRequestRepositoryTests` (Chen posted 6, Chen picked up a claimed and a completed one, Bea picked up five completed ones) and `ActivityViewModelTests` (the same counts through the view model, and Bea's "Picked up by me" holds 6 after picking up the eggs). `DisplayTests` gets two new rows for the new error messages, and `AppEnvironmentTests` builds the environment with the new members · the guardrails allow edits where the plan changes what a test asserts
- 2026-10-09 · 3A · New error messages: `alreadyReviewed` → "You already reviewed this favor.", `notEnoughPoints` → "You need 100 points to redeem a gift card." (the number comes from `KindnessRules.giftCardCost`) · plain wording in the style of the existing messages
- 2026-10-09 · 3A · Worked on the session branch `claude/brave-cray-shr7y8`, not `phase/3a-kindness-core`, and did not fast-forward or push `main` · this session ran in a cloud container that may push only its assigned branch. The phase is one linear set of commits on top of `main`, so `git merge --ff-only claude/brave-cray-shr7y8` on `main` brings it in
- 2026-10-09 · 3A–3E · Phases 3B to 3E were done back to back in the same cloud session as 3A, at the owner's request ("go straight through to 3E"), instead of one phase per session · the owner was away and asked for as much as possible without waiting on review. Each phase still has its own commits and its own entries here
- 2026-10-09 · CI · `ci.yml` also runs on pushes to `claude/**` branches, and a new `manual-checks.yml` runs SwiftLint and SwiftFormat on those pushes (or by hand), plus `ScreenshotUITests` with an uploaded artifact when the commit message contains `[screenshots]` or it is run by hand with the box ticked · a cloud session has no Xcode, and GitHub only allows running a workflow by hand once it is on `main`, so pushes are how such a session builds the app and lints
- 2026-10-09 · 3B · `ProfileViewModel(userID:environment:)` serves both the tab (`userID` nil, follows the signed-in user, reloads on a switch through `reloadKey`) and a pushed profile (fixed user). `isOwn` compares with the signed-in user, so your own profile opened from a request also shows the gift card · one view model and one view, as the plan's table lists
- 2026-10-09 · 3B · Past activities are completed requests only, on every profile, labeled "Helped" or "Asked", newest pick-up first · the screen table says "completed requests"; rule 14 then holds for other people's profiles without a second code path
- 2026-10-09 · 3B · Profile loads reviews and lists them from 3D on; in 3B the Kindness section already shows "5.0 average from 4 reviews" · the summary has the average anyway
- 2026-10-09 · 3B · Gift-card progress text is "\(available) of 100 points" even above 100 ("110 of 100 points"), and the bar is capped at full · hiding points would be wrong, and the demo script's "10 of 100 points" after redeeming from 110 needs the true number. Listed for review
- 2026-10-09 · 3B · `GiftCardCard` shows the code just redeemed in a tinted box ("Your reward code"), and earlier codes under "Past reward codes"; the explanation line reads "Every 100 points earns a $5 gift card." · the plan names a "$5" card as a placeholder. Listed for review
- 2026-10-09 · 3B · Added `Theme.IconSize.avatar` (64) and `Theme.Colors.avatars` (brand and the four category colors). `UserID.avatarColor` picks one with a ×33 string hash of the raw ID, since Swift's `hashValue` changes between launches; the four demo users get four different colors (Alex blue, Bea indigo, Chen green, Dana pink), and `AvatarColorTests` checks it · the plan says "picked from the existing palette by a stable hash"; gray and the status colors would read as a state
- 2026-10-09 · 3B · `AvatarView`, `ScoreLabel` and `GiftCardCard` live in `Shared/Components/`; `ProfileActivityRow` in `Profile/` · as the plan's table. `ScoreLabel` reads "Kindness score, 90 points" to VoiceOver, so UI tests read `profile.score` as "90 points"
- 2026-10-09 · 3B · Navigation destinations moved out of `NearbyView` and `ActivityView` into one `AppDestinations` modifier that `RootView` applies to the root of each tab's stack: `RequestID` → Request Detail, `UserID` → profile · Request Detail now pushes profiles and Profile pushes Request Detail; registering each destination once avoids SwiftUI's duplicate-destination warnings deeper in a stack
- 2026-10-09 · 3B · Request Detail's "Posted by" and "Helper" rows are `NavigationLink`s to that user's profile, with a `ScoreLabel` beside the name. The rows keep their identifiers (`detail.requester`, `detail.helper`), their label and their value ("Bea", "Bea (you)"), so `BrowseAndPickUpUITests` passes unedited; the score is spoken as the hint · the plan asks for tappable names and a score beside them, and existing identifiers and spoken text must not change
- 2026-10-09 · 3B · `RequestDetailViewModel` gains `requesterScore` and `helperScore`, loaded with the request and after each action; a failed lookup leaves the score out rather than failing the screen · the score is extra information
- 2026-10-09 · 3B · `RootTabTests` and `LaunchUITests` now expect five tabs (`testLaunchShowsFourTabs` became `testLaunchShowsFiveTabs`) · the plan changes the tab count
- 2026-10-09 · 3B · `ScreenshotUITests` also captures `profile-empty` (Alex), `profile` (Bea) and `profile-other` (Bea's profile from Alex's request) · the plan asks for profile screenshots; they have not been looked at yet
- 2026-10-09 · 3C · `ChatRules` has `validateRead`, `validateSend`, `canRead`, `canSend`, `validateText` and `messageLengthRange` (1...500). Sending on a completed or cancelled request throws `notAllowed`, and so does reading a request with no helper · the plan names `notAllowed` for non-participants; a new error just for "closed" would need a new message for a state the UI never offers
- 2026-10-09 · 3C · A cancelled request that had a helper keeps its thread readable, like a completed one · rule 13 says the thread is read-only "after completion or cancellation"
- 2026-10-09 · 3C · The seed has no messages, and `reset()` removes every message · "restores messages to the seed"; an empty thread also shows the "Say hello" state in the demo
- 2026-10-09 · 3C · Chat opens from a "Message <name>" button (tinted, `SecondaryButtonStyle`) in its own section above Mark completed; it is shown to the requester and the helper whenever the request has a helper, so a finished thread can still be read. It pushes `ChatView` with `navigationDestination(isPresented:)` · a plain `NavigationLink` inside a list row draws a disclosure row, not a full-width button
- 2026-10-09 · 3C · `ChatView` is a plain list of `MessageBubble`s with the composer (`TextField` and a `.borderedProminent` Send button in the brand tint) pinned under it with `safeAreaInset`; it scrolls to the newest message. The composer is hidden once the thread is read-only, and a gray lock note says why. An empty closed thread says "No messages" instead of "Say hello" · the plan's states
- 2026-10-09 · 3C · `MessageBubble`: your messages on the right on a brand tint, the other person's on the left on a gray (`neutral`) tint, both in primary text, with "You · 9:41 PM" or "Bea · 9:41 PM" under them; VoiceOver reads "Bea said: On my way, at 9:41 PM". Added `Theme.Radius.bubble` (18) and `Theme.Spacing.bubbleInset` (48, the space kept free on the far side) · the plan asks for brand and neutral only; primary text on a 14% tint is at least as readable as the tested colored text
- 2026-10-09 · 3C · The composer shows a count ("9 / 500") once you type, and an inline message only when the text is too long; an empty or whitespace-only message just disables Send · same pattern as the Post form
- 2026-10-09 · 3D · `ReviewRules` has `validateReviewer(request:by:existing:)`, `canReview`, `validate(_:)` (returns the draft with the comment trimmed), `ratingRange` (1...5) and `maxCommentLength` (300). Messages: "Choose a rating from 1 to 5 stars." and "Comment must be 300 characters or fewer." · rule 12; the rating message only shows if something submits without one, since the form disables Submit
- 2026-10-09 · 3D · The review form is a sheet with its own navigation bar (Cancel on the left), a five-star picker where each star is a button (`review.star.1`…`5`), an optional comment with a count in the footer, and a full-width Submit · the plan's screen table
- 2026-10-09 · 3D · Request Detail shows the review in its own section, headed "Your review" for its author and "Review" for anyone else who opens the request; "Leave a review" is a filled button shown to the requester of a completed, unreviewed request · the plan names "Your review"; the helper and other people can already read reviews on the profile, so hiding it here would be inconsistent. Listed for review
- 2026-10-09 · 3D · The profile's Reviews section lists every review newest first with stars, comment, "Dana · Oct 9"; with none it says "No reviews yet" · plan
- 2026-10-09 · 3E · `DemoFlowUITests` keeps the Phase 1 script as it was and adds `testExtendedDemoScript` for the six Phase 3 steps; step 6 opens Bea's profile from Chen's "Water my plants for the weekend" (seed 13), a request she helped with · "extended" read as adding to it; the Phase 1 test still guards the original flow
- 2026-10-09 · 3E · Spoken sentences: activity rows "Need a pinch of saffron, Ingredient, Helped, Downtown Brooklyn"; review rows "5 out of 5 stars from Dana, Oct 9: Fast and friendly"; message bubbles "Bea said: On my way, at 9:41 PM" · the 3E accessibility task
- 2026-10-09 · 3E · `ScreenshotUITests` also captures the chat (empty and with a message), the review form (empty and filled), Request Detail with a review, and the profile's reviews: 25 captures per appearance · so the new screens can be checked by eye
- 2026-10-09 · 3E · `MARKETING_VERSION` is `0.3.0`. The tag `v0.3.0-profiles` was not created · the tag should mark a commit a person has checked by hand; see "Needs the owner's review"
- 2026-10-13 · Phase 3 plan · Added phase 3F to `docs/PLAN-PHASE-3.md`: only the requester can mark a request completed, and a claimed request completes on its own 7 days after pick-up (rule 15, replacing Phase 1 rule 4) · owner's decision during the Phase 3 review; it stops a helper from awarding themselves points, and the 7-day limit stops a requester from withholding them
- 2026-10-26 · tooling · Signing settings come from `Config/Signing.xcconfig`, which includes an optional, git-ignored `Config/Local.xcconfig` for `DEVELOPMENT_TEAM` and an optional `FAVORLY_BUNDLE_ID` · lets each person run on their own iPhone with a free Personal Team without committing their team ID; simulator builds are unchanged
- 2026-10-26 · tooling · `FavorlyUITests` is parallelizable in the scheme, and the full UI suite runs only before a push; `swift test` covers day-to-day checks · the serial UI suite took over 10 minutes on a laptop
- 2026-10-28 · 3E · The owner accepted the Phase 3 review and every listed judgment call as built; tagged `v0.3.0-profiles` · owner's decision
- 2026-10-28 · Phase 4 plan · The developer account is an Individual enrollment (the App Store shows that person's legal name as the seller), and every other default in `docs/PLAN-PHASE-4.md` stands · owner's decision; an Organization account needs a registered company and a D-U-N-S number
- 2026-10-28 · 3F · `RequestRules.autoCompleteDate(of:)` added beside the plan's `autoCompleteInterval` and `isAutoCompleteDue(_:now:)` · the helper's note needs the date, and both rules then share one definition
- 2026-10-28 · 3F · `MockRequestRepository.simulateLatency()` became `beginOperation()`: it waits out the delay and then completes due requests, emitting on `changes()` when any changed · every read and write already called it, so auto-complete runs before each one with no timer, as the plan asks
- 2026-10-28 · 3F · The helper's note is a gray footnote with a clock symbol where Mark completed would be, built by `RequestDetailViewModel.autoCompleteNote` like the chat's `closedText` · matches the chat's read-only note
- 2026-10-28 · 3F · `ProfileUITests.testOneMoreFavorLetsBeaRedeemAGiftCard` now checks Bea's note and missing button, then switches to Chen to complete; `ScreenshotUITests` waits for the note instead of Mark completed · the only UI tests that completed as the helper
- 2026-10-28 · 3F · `DoneKeyModifier.isReturnKey` is `nonisolated` · its tests raised Swift 6 actor-isolation warnings, and it is a pure function
- 2026-10-28 · 4A · `AuthState` has no payload (`.signedOut`, `.needsProfile`, `.signedIn`) instead of the plan's `.signedIn(UserProfile)` · the signed-in user lives in `SessionStore`, so one source of truth; a payload went stale when Dev Settings switched users
- 2026-10-28 · 4A · `AuthService.completeProfile` takes a `ProfileSetupDraft` (name, adult, accepted terms) instead of three parameters; `ProfileSetupRules.termsVersion` (1) is the version accepted · matches `NewRequestDraft` and `NewReviewDraft`, and the server records the version in 4B
- 2026-10-28 · 4A · `SessionStore` is now `currentUser` plus `profile(for:)`; `availableUsers` and `switchUser(to:)` moved to `DemoSessionControls`, adopted by the mock and preview sessions only. Dev Settings casts to it · change to a Phase 1 protocol, as the plan says; a real session cannot list every user
- 2026-10-28 · 4A · The gift card section, Redeem and reward codes are removed from the Profile tab rather than turned into points progress with no reward · progress toward nothing has no meaning; the plainer option. `KindnessRepository` keeps its redeem methods for the mock, unused by any screen
- 2026-10-28 · 4A · Supabase URL and key plumbing is deferred to 4C · nothing reads them until `FavorlyRemote` exists, and an unused key in the Info.plist is dead config
- 2026-10-28 · 4A · The Welcome button is a styled "Continue with Apple" button driving the mock; Apple's `SignInWithAppleButton` arrives in 4C · the real button needs the Sign in with Apple capability, which needs the paid account
- 2026-10-28 · 4A · The Run scheme passes `-demo`; UI tests pass `-uiTesting`, plus `-signedOut` to start at Welcome; any other launch uses `AppEnvironment.live()`, which until 4C is the demo wiring starting signed out · Xcode's Run keeps the old demo, and a Release build starts where a downloaded app will
- 2026-10-28 · 4A · `MockAuthService.deleteAccount` forgets the user in the session and signs out; their requests, messages and reviews stay in the mock repository. The confirmation text describes the plan's server behavior · real deletion is a server function (4B) wired in 4C
- 2026-10-28 · 4A · Terms and Privacy links point at GitHub Pages paths (`terencezhang29.github.io/favorly/terms`, `/privacy`) that go live in 4G · the links need a stable address now; the pages are 4G's work
- 2026-10-28 · 4A · Dev Settings is left out of non-Debug builds through `RootTab.visible` (`#if DEBUG`); tests cover `RootTab.tabs(showingDevSettings:)` · a unit test cannot build Release, so the switch is a tested pure function
- 2026-10-28 · 4A · Profile setup uses two toggles (18 or older; accept the terms) with separate links to read each document · a link inside a toggle's label toggles the switch instead of opening the link
- 2026-10-28 · 4B · The server's content filter moved from 4B to 4E · the app has no `ContentFilter` yet, and both must share one word list; building them together keeps them the same
- 2026-10-28 · 4B · No `redemptions` or `device_tokens` tables · the gift card is gone (4A), and push tokens arrive with 4F
- 2026-10-28 · 4B · Writes go only through `security definer` functions; tables are read-only for signed-in users and closed to the anonymous key · one place enforces each rule, and a client cannot write a row the rules would refuse
- 2026-10-28 · 4B · Row-level security shows another person's requests unless cancelled or blocked, so claimed and completed ones are readable · Request Detail and profiles need them, as in the mock; open-only reading is `nearby_requests`
- 2026-10-28 · 4B · `nearby_requests` includes the caller's own open requests · matches `MockRequestRepository.nearby`, where Alex sees his own rice request
- 2026-10-28 · 4B · Picking up across a block fails with `blocked` in both directions · one code for one rule; the app can say "You can't interact with this person"
- 2026-10-28 · 4B · New server-only texts: "This request is missing its location." and "Note must be 500 characters or fewer." · the app never sends such input, but the server must still refuse it
- 2026-10-28 · 4B · `complete_profile` also changes the name of an existing profile · a later "edit name" needs no new function
- 2026-10-28 · 4B · `delete_my_account` deletes the `auth.users` row in SQL, cascading to the profile · no edge function needed; reviews about the deleted user go too, since their score goes with them
- 2026-10-28 · 4B · Errors are SQLSTATE `P0001` with a fixed message, and validation text in DETAIL (contract in `backend/README.md`) · 4C maps them to `FavorlyError`, adding `.notSignedIn`, `.rateLimited` and `.blocked`
- 2026-10-28 · 4B · Local Supabase ports are 55321–55329, not the default 54321–54329 · another local Supabase project (hackamatch) uses the defaults on this Mac
- 2026-10-28 · 4B · Backend tests and the schema lint also run on GitHub Actions (`.github/workflows/backend.yml`), on pushes that change `backend/`, starting only the database (about 2 minutes) · the repo is public, so the minutes are free; owner asked for CI before the hosted project
- 2026-10-28 · 4B · Hosted Supabase project `favorly` (ref `dkerjrnwjvrvsuldtqwe`), US East, free tier, in the owner's existing organization; the four migrations deployed with `supabase db push`, and `supabase db diff --linked` finds no differences · owner created it and set the password in their own Terminal. The organization now has 2 of 2 free active projects (hackamatch, favorly)
- 2026-10-29 · 4C · Third-party runtime dependency: `supabase-swift` 2.55.5 (MIT), pinned exactly in `Package.swift` because `Package.resolved` is git-ignored; only `FavorlyRemote` imports it · the plan's backend choice; its Swift client covers auth, PostgREST and realtime
- 2026-10-29 · 4C · One `RemoteRepository` actor implements all four repository protocols, mirroring `MockRequestRepository`; the `user` parameters of writes are not sent, since the server acts as the session's user · same shape as the mock, so `AppEnvironment` wiring is identical
- 2026-10-29 · 4C · RPC parameters are `[String: AnyJSON]` dictionaries with the server's snake_case names · structs with snake_case fields broke SwiftLint's `identifier_name`, and the dictionary shows the server's names exactly
- 2026-10-29 · 4C · `RemoteSessionStore` reads names from `RemoteProfileDirectory`, which the repository fills after every read that names people; a deleted person's side of a favor reads "A neighbor" (`UserID.deletedUser`) · `SessionStore.profile(for:)` is synchronous, so names must be loaded before a screen shows them
- 2026-10-29 · 4C · New `FavorlyError` cases `.notSignedIn`, `.rateLimited`, `.blocked`, `.network` with user messages; server error codes map one to one (`RemoteErrors`) · the error contract in `backend/README.md`
- 2026-10-29 · 4C · Migration `20261029000005_app_support.sql` replaces the claim, cancel and complete functions so `invalid_transition` carries the current status in DETAIL, and publishes requests, messages and reviews to realtime · `FavorlyError.invalidTransition(from:to:)` needs the from-status; deployed migrations are never edited
- 2026-10-29 · 4C · Contract tests (`FavorlyRemoteTests`) run the same 8 checks against the mock always and the local backend with `FAVORLY_REMOTE_TESTS=1` plus the URL and key; each test signs up its own users at a random spot, so data left by earlier runs never interferes · the plan's "mock and server behave the same"
- 2026-10-29 · 4C · `RemoteAuthService.signIn(email:password:createAccount:)` exists for development and the contract tests; Debug `-remote` launches with `-devEmail`/`-devPassword` sign in by email · Sign in with Apple needs the paid account; email sign-in must stay off on the hosted project
- 2026-10-29 · 4C · `-remote` is Debug-only; `AppEnvironment.live()` stays on demo data until Sign in with Apple works · a Release build without a way to sign in would be unusable
- 2026-10-29 · 4C · Backend settings live in `Config/Backend.xcconfig` (empty by default), included by `Signing.xcconfig`; `project.yml` now generates `App/Info.plist` with the two keys, the version build settings, and `NSAllowsLocalNetworking` for the local backend · XcodeGen's `info` is the only way to add custom Info.plist keys; its default hardcoded version 1.0, so the version keys point at the build settings
- 2026-10-29 · 4C · Mock and server differ in two known ways the contract tests avoid: the server snaps locations to about 100 m, and the server returns an empty thread to a stranger where the mock throws `notAllowed` · both are deliberate on the server; the app never shows a stranger's thread
- 2026-10-29 · 4C · Migration `20261029000005_app_support.sql` deployed to the hosted project after the full test suite and backend CI passed on `main`; `supabase db diff --linked` finds no differences · owner approved. `supabase db push` works with the CLI login, no database password, so deploys can run from here with the owner's approval
- 2026-10-29 · 4C · Hosted auth: Apple provider on with Client ID `edu.cornelltech.team402.favorly` and no OAuth secret key; Email provider off; project-wide sign-ups stay on. Checked through the public `/auth/v1/settings` endpoint, and an email sign-up is refused (400) · native Sign in with Apple only needs the bundle ID; the OAuth secret is for web redirects and expires every 6 months; email accounts would bypass Apple sign-in
- 2026-10-29 · 4C · Sign in with Apple asks for no name or email (`requestedScopes = []`); profile setup asks for the name · less personal data, and the App Privacy answers stay small
- 2026-10-29 · 4C · `Config/Backend.xcconfig` holds the hosted project's URL and public anon key, committed; `Local.xcconfig` may override them with the local backend · the anon key is public by design; normal launches need it to reach the backend
- 2026-10-29 · 4C · With an Individual enrollment the paid team keeps the Personal Team's ID (`5B89U2CMF9`); Xcode needed the account removed and re-added before it allowed the Sign in with Apple capability · Apple upgrades the team in place
- 2026-10-29 · 4C · Sign in with Apple tried by the owner on an iPhone against the hosted project: sign-in, profile setup and the tabs work, and the hosted project has the one profile · the plan's 4C sign-in check
- 2026-10-29 · 4D · Device location lives in a new `FavorlyDevice` module: `DeviceLocationProvider` holds the rules (ask once, `.locationPermissionDenied` when refused, snap, name, cache the name per 100 m square) behind two seams, `LocationSource` and `NeighborhoodNamer`, so tests use fakes; `CoreLocationSource` and `GeocoderNeighborhoodNamer` are thin adapters checked in the simulator · CoreLocation cannot be driven from unit tests
- 2026-10-29 · 4D · `LocationPrivacy.snapped` rounds to 3 decimal places on the device, the same as the server · the exact position never leaves the phone
- 2026-10-29 · 4D · `CLGeocoder` for neighborhood names (`subLocality`, else `locality`, else "Your neighborhood") · its iOS 26 deprecation does not warn with an iOS 17 deployment target; `MKReverseGeocodingRequest` can replace it when the target moves to 26
- 2026-10-29 · 4D · `AppEnvironment.locationSettings` is optional: demo launches pass the presets, backend launches pass nil and Dev Settings hides its location section · the plan's "presets only in Debug and -demo"
- 2026-10-29 · 4D · The Nearby header shows "Near <neighborhood>" from the last fix ("Location is off" when denied) instead of the debug line "Alex @ preset"; its identifier is now `nearby.location`. Dev Settings keeps the debug line · the user name next to a place was debug information
- 2026-10-29 · 4D · Permission is asked the first time Nearby or Post needs a location; if refused, both show the reason and an Open Settings button instead of Retry · the plan's permission flow; Retry cannot help until Settings changes
- 2026-10-29 · 4D · `MessageView` takes an `actionTitle` (default "Retry") · Open Settings reuses the same component
- 2026-10-29 · 4E · `ModerationRepository` (report, block, unblock, blocked users) with `ReportTarget` and `ReportReason`; writes take `by user` like the other repositories · same shape as the rest; the server ignores it and uses the session
- 2026-10-29 · 4E · `ContentFilter` is part of every validator that checks text other people read: `DraftValidator`, `ChatRules.validateText`, `ReviewRules.validate` and `ProfileSetupRules` (names too, which the plan did not list) · one place per kind of text; names are shown to everyone
- 2026-10-29 · 4E · The filter matches whole words, lowercased, letters only, also with the endings s, es, ed, er, ers, ing and y; it misses run-together or misspelled words and blocks a few innocent uses (the name "Dick") · a plain list is predictable and the same on both sides; reports catch the rest
- 2026-10-29 · 4E · The server applies the list with `before insert or update` triggers on requests, messages, reviews and profiles, raising the app's validation text, instead of editing the action functions again · no deployed function needs replacing; direct inserts are covered too
- 2026-10-29 · 4E · `ContentFilterTests.theServerHasTheSameList` reads the safety migration and compares its `array[...]` with `ContentFilter.words` · the plan's "one shared word list" without generated code
- 2026-10-29 · 4E · `public.blocked_profiles()` returns the names of the people the caller blocked · row-level security hides a blocked person's profile from both sides, so the Blocked people list could not otherwise name them
- 2026-10-29 · 4E · The mock refuses pick-ups and messages across a block, like the server, but its reads cannot hide blocked people, since they do not know who is asking; `NearbyViewModel` filters out requests from people the user blocked, which also covers the server's few seconds of realtime lag · keeps the demo honest at the cost of one extra call per Nearby load
- 2026-10-29 · 4E · The report and block menu is one modifier, `SafetyActions`, on Request Detail and on other people's profiles; a successful block closes the screen · its content is hidden from then on; the shared modifier also kept `RequestDetailView` under SwiftLint's length limit
- 2026-10-29 · 4E · Report a message by long-pressing someone else's bubble (`contextMenu`) · keeps the chat uncluttered
- 2026-10-29 · 4E · Support is a web page (`LegalLinks.support`) rather than an email address · no personal address in the app; the page goes up with the privacy policy in 4G
- 2026-10-29 · 4E · Moderation happens in the Supabase dashboard with the queries in `backend/moderation/queries.sql`, following `docs/MODERATION.md`; banning uses the dashboard's Ban user · no admin screens to build or secure in the app
- 2026-10-29 · 4E · Migration `20261029000006_safety.sql` deployed to the hosted project after the full suite and backend CI passed on `main`; all six migrations recorded there and `supabase db diff --linked` finds no differences · owner approved
- 2026-10-29 · 4F · Notifications go through an outbox: database triggers write each notification with its final text to `push_outbox`, and the `push` Edge Function sends what is unsent · the texts are tested in pgTAP like every other rule, nothing is lost when Apple or the function is down, and a cron job retries every 5 minutes, up to 5 attempts
- 2026-10-29 · 4F · The outbox calls the function through `pg_net` with a shared secret (`X-Push-Secret`) kept in Vault and in the function's secrets; the function runs with `verify_jwt = false` · the database has no user JWT; the shared secret is the authentication, and without it the function answers 403
- 2026-10-29 · 4F · APNs is called directly from the function with an ES256 provider token from the team's `.p8` key, using Web Crypto and `fetch`, no push service or SDK · free, no third-party data processor, and the app needs no Firebase
- 2026-10-29 · 4F · Texts: "Request picked up" / "Bea picked up \"<title>\"."; "New message from Bea" / the message, cut at 120 characters; "Favor completed" / "Alex marked \"<title>\" completed." or "\"<title>\" completed automatically after 7 days."; "New review" / "Alex left you a 5-star review." Nobody is notified across a block, or about their own action · the plan's four events
- 2026-10-29 · 4F · Message notifications show the start of the message on the lock screen · the usual chat behavior; iOS lets people hide previews in Settings
- 2026-10-29 · 4F · Device tokens are registered as lowercase hex with an environment (`sandbox` in Debug, `production` in Release), move to whoever signed in on the device last, and are removed at sign-out; Apple's `410`/`BadDeviceToken` deletes them · TestFlight and App Store builds are Release
- 2026-10-29 · 4F · Permission is asked after the first successful post or pick-up (`NotificationService.requestPermissionIfNeeded`), never at launch; at each sign-in the app registers again if allowed · the plan's timing; refreshed tokens reach the server
- 2026-10-29 · 4F · A tapped notification switches to My Activity and pushes the request, plus its chat for a message (`NotificationRouter`, `ChatDestination`, a path for the My Activity stack) · one place to open from, with Back leading to the request
- 2026-10-29 · 4F · `AppEnvironment.init` is `@MainActor` · it creates the `NotificationRouter`, a main-actor object; every caller already ran on the main actor
- 2026-10-29 · 4F · The Edge Function has no Deno unit tests (Deno is not installed); it was checked locally with `supabase functions serve` and a throwaway P-256 key: without the secret it answers 403, and with it Apple's sandbox answered `InvalidProviderToken`, so the token signing, the HTTP/2 call and the retry count work · delivery to a phone needs the real key
- 2026-10-29 · 4F · Migration `20261029000007_push.sql` and the `push` function deployed to the hosted project after the full suite and backend CI passed on `main`; seven migrations recorded, `db diff --linked` finds no differences, and the live function answers 403 without the secret · owner approved
- 2026-10-29 · 4D follow-up · Requesters will be able to edit the location tag on Post (owner's choice of three options), planned in 4G · Apple's geocoder gives only the borough in New York: `subLocality` is "Manhattan" for Roosevelt Island and the Upper West Side, `areasOfInterest` is "Roosevelt Island" there but "Long Island" for Brooklyn and Queens, and `name` is a street address. Checked with `CLGeocoder` on 2026-10-29
- 2026-10-29 · 4F · The owner created the APNs key and set the five function secrets and the two Vault entries; a notification queued from the SQL Editor arrived on the owner's iPhone and, when tapped, opened the request with the app closed, in the background and open · the plan's "Done when" for one phone; the two-phone check is in 4G
- 2026-10-29 · 4F · The notification router is a static on `AppDelegate`, created at launch and passed to every environment, and a device token that arrives before the environment is held until it exists · a notification tapped while the app was not running reached the delegate before SwiftUI had built the environment, and was dropped
- 2026-10-29 · 4F · `UNUserNotificationCenterDelegate` methods use the completion-handler forms, not `async` · the `async` forms returned on a background thread and UIKit aborted the app (`_performBlockAfterCATransactionCommitSynchronizes`), seen in a crash log copied from the owner's iPhone with `xcrun devicectl device copy from --domain-type systemCrashLogs`; no automated test can tap a real notification, so the code says why
- 2026-10-07 · 1A · Tab bar buttons are found by label in UI tests (`app.tabBars.buttons["Nearby"]`) · SwiftUI does not reliably pass a tab item's `accessibilityIdentifier` to the tab bar button

## Known issues

- Last CI result on the session branch (commit `9e0d7e8`): `swift test` and `xcodebuild test` (iOS simulator on `macos-26`, all UI tests including `ProfileUITests`, `ChatUITests`, `ReviewUITests` and `DemoFlowUITests.testExtendedDemoScript`) pass, and SwiftLint `--strict` and `swiftformat --lint` are clean. The first runs failed on one SwiftLint rule (`function_parameter_count`), two SwiftFormat rules (`hoistTry`, `wrapIfExpressionBodies`), the chat UI test switching user while the keyboard covered the tab bar, and the extended demo test checking a row it had scrolled past; all fixed
- Screenshots: the "Manual checks" run for `4ddb7e1` uploaded a `screenshots` artifact with 92 images. The light pass completed; two of the four `ScreenshotUITests` passes failed partway (most likely the two accessibility text sizes, where new Phase 3 elements sit below the fold), so those sets are incomplete. The waits in the new capture steps may need the same "scroll first" treatment 2D gave the old ones
- `BrowseAndPickUpUITests` failed once on CI at its first user switch right after launch, and passed on the re-run of the same commit; `switchUser` now waits for the user row before tapping
- Phase 3 was built in a Linux container with no Xcode. `swift test` ran there (Swift 6.1.3) over Core, Data and every Features file and test that does not import SwiftUI, including every view model. All SwiftUI code (views, components, `Theme`) and the UI tests were compiled and run only by GitHub Actions on `macos-26`, through pushes to the session branch; SwiftLint and SwiftFormat ran there too (`manual-checks.yml`). No screen of Phase 3 has been looked at by a person
- Not seen on screen by anyone: the profile, the gift card before and after redeeming, the chat, the review sheet, the review on Request Detail, the avatars in light and dark, and every new screen at the largest text sizes
- The chat composer and the review sheet have not been tried with the keyboard on a real device; UI tests type into them on the simulator
- Not yet checked by a person: the demo script has only been run by `DemoFlowUITests`, and VoiceOver labels were set in code and read back through UI tests, not listened to with VoiceOver on.
- The segmented radius and activity pickers do not grow with Dynamic Type. That is how the system control behaves; everything else was checked at the `accessibility-large` text size.
- The red error banner on Request Detail (shown when an action fails) has not been seen on screen; no test flow makes an action fail.
- On Request Detail the Location value wraps to two lines now that the row has a leading symbol.
- The plan asks for the demo script to be run by hand in light and dark at the end of 2C. An agent cannot; `DemoFlowUITests` ran it in light mode, and the screenshot test walks most of it in dark mode.
- At accessibility text sizes the Post location text wraps under its pin icon. That is how the system lays out a `Label` in a list at those sizes.
- Not seen on screen, because no test flow produces them: the Post submit error, the Post location error, and the My Activity load error.
- At the largest accessibility text size the Post title field cuts a long title with "…" while it is not being edited, and the tab bar labels stay small. Both are how the system controls behave.
- The app icon has only been seen as the generated image and through a successful build, not on a Home Screen.
- Increase Contrast and Reduce Transparency were checked in light mode only.
- `ScreenshotUITests` takes about four minutes for its four passes. It is skipped in CI and in normal runs, where no screenshot folder is set.
- In `ScreenshotUITests`, wait for something near the top of the screen before a capture: at the large text size, rows below the fold do not exist yet and a wait on them fails.
- If dark-mode screenshots come out light, the simulator is stuck: `xcrun simctl shutdown` and `boot` it. This happened once on the iPhone 17 simulator, where even Settings stayed light.
- CI does not run SwiftLint or SwiftFormat; run them locally before pushing.
- A CI run takes about 12 minutes, nearly all of it the UI tests on the hosted simulator.
- The UI test suite takes a little over three minutes, mostly app launches and typing.
- If a UI test fails, `xcodebuild` can sit for several minutes collecting diagnostics before it exits. Pass `-collect-test-diagnostics never` to skip that.
- Crash logs from a connected iPhone: `xcrun devicectl device info files --device <udid> --domain-type systemCrashLogs` lists them, and `xcrun devicectl device copy from ... --source <file>` copies one.
- Notification taps cannot be automated: `xcrun simctl push` can deliver one to a simulator, but nothing can tap it. Check taps by hand on a phone after changing `AppDelegate`.
- A new test file is not in the Xcode project until `xcodegen generate` runs again; until then `-only-testing` silently skips it.
- Demo launches (`-demo`, UI tests) still use the mock sign-in: Continue with Apple goes straight to profile setup, every sign-up is a new user, and deleting an account only forgets the user in the session. Normal launches sign in with Apple.
- The Supabase session is kept in the keychain, which survives deleting the app, on a simulator as on a phone. Reinstalling therefore restores the last account; sign out, or run `xcrun simctl keychain <device> reset` on a simulator, to start at Welcome.
- `xcodegen generate` ticks `-demo` in the Run scheme again; untick it to run against the backend.
- Apple's geocoder names Roosevelt Island "Manhattan" (its borough, as `subLocality`), so the Nearby header reads "Near Manhattan" there. Coarser than the plan's example, but accurate and private.
- `xcodebuild` prints `appintentsmetadataprocessor ... Metadata extraction skipped` warnings. They come from an Xcode build tool, not the Swift compiler, and need no action.

## Open questions

- Phase 3: the helper can mark a request completed (Phase 1 rule 4), so a helper can award themselves 10 points. Resolved 2026-10-13: only the requester can mark completed, and a claimed request auto-completes 7 days after pick-up; planned as phase 3F.
- Phase 3F: how is auto-complete shown in a demo, when 7 days never pass? Resolved 2026-10-28: tests only, with a fixed clock, as the plan's default.
- Phase 3: are 10 points per favor, 2 per star and 100 points for a "$5" gift card the right values? Default: yes, as placeholders in `KindnessRules`.
- Phase 3: should chat stay open for sending after a request is completed? Default: no, the thread becomes read-only.
- Phase 3: what does someone else's profile show? Default: completed requests only, never gift-card progress or reward codes.
- Should 2D finish before 3A? Resolved 2026-10-09: yes, 2D was done first.
- Review gate after 2B. Resolved 2026-10-08: the repo owner looked at the Nearby and Request Detail screenshots and approved them as they are (teal brand, rounded-rectangle badges, pill-shaped action buttons). No palette or component changes were requested.
- Phase 2: is teal the right brand color, and who approves the look at the review gate after 2B? Defaults: teal, and the repo owner.
- 1B through 1G were each branched from the previous phase branch because the earlier pull requests were not merged yet. Resolved: no pull requests; `main` was fast-forwarded to the last phase branch, which contains the earlier ones.
- The plan's 1A says "first commit pushed to `main`", while `CLAUDE.md` says one branch per phase. Resolved as: the pre-existing docs were committed straight to `main`, and the 1A work is on `phase/1a-scaffold` for a pull request.

## Session log

Newest first, one line per session: `YYYY-MM-DD · phase · what was done · next step`.

- 2026-10-29 · 4F · Push deployed and set up on the hosted project; notification arrived on the owner's iPhone; fixed a dropped tap at cold launch and a crash from the `async` delegate methods (crash log from the device); all three tap cases work; 4F done · start 4G on `phase/4g-beta` with the editable location tag
- 2026-10-29 · 4F (code) · Push outbox, triggers and tests (153 database tests); `push` Edge Function, checked locally against Apple's sandbox with a throwaway key; device registration, permission after the first post or pick-up, unregister at sign-out, notification taps open My Activity; push entitlement; 386 package tests · owner: APNs key and secrets; deploy migration 0007 and the function; test on a phone
- 2026-10-29 · 4E · Report (request, message, person), block and unblock, Blocked people, Safety tips, terms, privacy and support links; offensive-word filter in the app and as server triggers, with a test that the lists match; `blocked_profiles`; mock and remote moderation with contract tests on both; `SafetyUITests`; `docs/MODERATION.md` and dashboard queries. 380 package tests, 133 database tests · deploy migration 0006 with the owner's approval, then 4F on `phase/4f-push`
- 2026-10-29 · 4D · `FavorlyDevice` (permission, 100 m snapping, neighborhood names), Nearby header from the real fix, Open Settings when denied, presets only in demo launches, location permission text; 361 package tests; checked in the simulator against the local backend ("Near Manhattan", then denied with Open Settings); two-phone check moved to 4G · start 4E on `phase/4e-safety`
- 2026-10-29 · 4C · Sign in with Apple (Apple's button, hashed nonce, no scopes); normal launches on the hosted project; Apple provider on and Email off on the hosted project; owner signed in on an iPhone and the profile exists on the hosted project; 4C done but the owner's two-phone check · start 4D on `phase/4d-location`
- 2026-10-29 · 4C (part) · Migration 0005 (transition status, realtime); four new `FavorlyError` cases; `FavorlyRemote` on supabase-swift (rows, errors, repository with realtime, profiles, session, auth); 22 remote tests, contract tests pass on mock and local backend; `-remote` Debug launches with email sign-in, checked end to end in the simulator · owner deploys migration 0005 and enrolls in the Apple Developer Program, then Sign in with Apple and the live wiring
- 2026-10-28 · 4B · Backend CI on GitHub Actions (first run green, 104 s); owner logged in to Supabase and created the hosted project `favorly`; migrations deployed and checked (`migration list --linked`, `db diff --linked`); 4B done · 4C after the owner enrolls in the Apple Developer Program
- 2026-10-28 · 4B · Supabase CLI installed; `backend/supabase` with four migrations (schema, row-level security, actions with the app's rules, rate limits, blocks, account deletion, `pg_cron` auto-complete); 116 pgTAP tests pass; lint clean; `backend/README.md` with the error contract. App unchanged · owner approves the hosted Supabase project (free tier), then deploy; then 4C
- 2026-10-28 · 4A · `AuthService`, `AuthState`, `ProfileSetupRules`, `DemoSessionControls`; `MockAuthService`; Welcome and profile setup behind a sign-in gate; Sign out and Delete account on the Profile tab; gift card and Redeem removed; Dev Settings Debug-only; `-demo`, `-signedOut` and `AppEnvironment.live()`; no-encryption key; 307 package tests and the changed UI test classes pass · start 4B on `phase/4b-backend` after the owner installs Docker and the Supabase CLI
- 2026-10-28 · 3F · Requester-only completion, auto-complete 7 days after pick-up in rules and the mock repository, the helper's auto-complete note on Request Detail, tests (279 package tests, profile UI tests), docs; also accepted the Phase 3 review, tagged `v0.3.0-profiles`, wrote the Phase 4 plan · start 4A on `phase/4a-release-groundwork`
- 2026-10-09 · 3B–3E · Profile tab and other users' profiles with score, gift card and redeem; scores and tappable names on Request Detail; chat (rules, mock, screen, Message button); reviews (rules, submit, star picker, review sheet, review on Request Detail and on profiles); `ProfileUITests`, `ChatUITests`, `ReviewUITests`, `DemoFlowUITests.testExtendedDemoScript`, new screenshot captures; version 0.3.0, README and architecture notes; CI on `claude/**` branches and a lint and screenshot workflow. View models and rules pass on Linux; the app, the UI tests and lint ran on GitHub Actions (results in the commit map rows and below) · the owner's review list at the top of this file
- 2026-10-09 · 3A · `Review`, `Redemption`, `KindnessSummary` and their IDs, `KindnessRepository`, `ReviewRepository` (reads), `KindnessRules`, `alreadyReviewed` and `notEnoughPoints` with messages; seeds 13–17 and `DemoReviews` (Bea 90, Chen 18, Dana 0, Alex 0); kindness and review conformances on `MockRequestRepository`; `kindness` and `reviews` in `AppEnvironment`, demo wiring, preview stubs and `TestWorld`. 154 tests pass on Linux; app build, UI tests and lint left to CI and a Mac · confirm CI, fast-forward `main`, start 3B on `phase/3b-profile`
- 2026-10-09 · 2D · Consistency pass (no style literals left outside `Theme`), accessibility pass at the largest text size, with Increase Contrast and with Reduce Transparency (three row layout fixes), app icon and its script, version `0.2.0`, README and architecture docs, refreshed screenshots; 138 package tests and 12 UI tests pass, the four behavior classes unedited; Core, Data, view model and existing test diff is empty; SwiftLint and SwiftFormat clean; tagged `v0.2.0-ui` · start 3A on `phase/3a-kindness-core`
- 2026-10-09 · Phase 3 plan · Wrote `docs/PLAN-PHASE-3.md` (Kindness score, profiles, chat and reviews in five phases, 3A–3E), added the Phase 3 checklist, decisions and open questions here, updated `CLAUDE.md` and the README to point at it; no code changed · finish 2D on `phase/2d-polish`, then start 3A on `phase/3a-kindness-core`
- 2026-10-08 · 2C · Review gate passed with no changes. `PostRequestView`, `ActivityRow`, `ActivityView` and `DevSettingsView` restyled; every screen now uses the theme; screenshots in light, dark and `accessibility-large` checked by eye; 138 package tests (1 new) and the four behavior UI test classes pass unedited; Core, Data and view model diff is empty · start 2D on `phase/2d-polish`
- 2026-10-08 · 2B · `RequestRow`, `NearbyView` and `RequestDetailView` restyled; screenshots in light, dark and `accessibility-large` checked by eye; 137 package tests and the four behavior UI test classes pass unedited; Core, Data and view model diff is empty · hold the review gate, then start 2C
- 2026-10-08 · 2A · "Before" screenshots (12, light and dark), `RGBColor`, `AdaptiveColor`, `Theme`, category and status colors, six shared components plus the optional `FactRow` symbol, brand tint and accent color; 137 package tests (12 new) and all UI tests pass unedited; Core, Data and view model diff is empty · start 2B on `phase/2b-nearby-detail`
- 2026-10-08 · CI · GitHub Actions workflow added and green on its second run (run 37726152972); first run exposed four UI test waits that were too tight for the runner · start 2A on `phase/2a-theme`
- 2026-10-07 · Phase 2 plan · Wrote `docs/PLAN-PHASE-2.md` (UI refresh in four phases, 2A–2D), added the Phase 2 checklist here, updated `CLAUDE.md` and the README to point at it; no code changed · start 2A on `phase/2a-theme`
- 2026-10-07 · post-1G · Added the commit map to this file and fast-forwarded `main` to the Phase 1 work, with no pull requests · run the demo by hand
- 2026-10-07 · 1G · `-uiTesting` flag, `DemoFlowUITests`, accessibility pass, README with demo script and screenshots, architecture notes; a fresh clone generates, lints and passes `swift test` and `xcodebuild test`; tagged `v0.1.0-prototype` · merge the pull requests, run the demo by hand
- 2026-10-07 · 1F · `PostRequestViewModel`, `PostRequestView`, `ActivityViewModel`, `ActivityView`, `ActivityRow`, `ActivitySegment`, post-then-highlight navigation; 56 Features tests and Flow 1 UI tests; `swift test` and `xcodebuild test` pass · start 1G on `phase/1g-hardening`
- 2026-10-07 · 1E · `NearbyViewModel`, `NearbyView`, `RequestRow`, `RadiusOption`, `RequestDetailViewModel`, `RequestDetailView`, shared display helpers; 38 Features tests and Flow 2 UI tests; `swift test` and `xcodebuild test` pass · start 1F on `phase/1f-post-activity`
- 2026-10-07 · 1D · `AppEnvironment` with preview stubs and environment value, `AppEnvironment.demo()` in the App target, four tabs each in a `NavigationStack`, working Dev Settings, `DevSettingsUITests`; `swift test` and `xcodebuild test` pass · start 1E on `phase/1e-nearby-detail`
- 2026-10-07 · 1C · Seed fixtures (`LocationPresets`, `DemoUsers`, `DemoRequests`), `MockRequestRepository`, `MockLocationProvider`, `MockLocationSettings`, `MockSessionStore` with 40 tests; `swift test` and `xcodebuild test` pass · start 1D on `phase/1d-app-shell`
- 2026-10-07 · 1B · Models, service protocols, `FavorlyError`, `RequestRules`, `DraftValidator`, `Distance`, `DistanceFormatter` in `FavorlyCore` with 28 tests; Core imports only Foundation; `swift test` and `xcodebuild test` pass · start 1C on `phase/1c-mock-data`
- 2026-10-07 · 1A · Package with three library and three test targets, `project.yml`, app with four empty tabs, launch UI test, lint/format configs, README, ARCHITECTURE; `swift test` and `xcodebuild test` (iPhone 17, iOS 27.0) pass · start 1B on `phase/1b-core-domain`
