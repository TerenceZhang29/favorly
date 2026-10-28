# Favorly — Phase 4 Implementation Plan: from prototype to App Store app

Oct 28, 2026 · Team 402

## Overview

Phases 1–3 built a prototype: every flow works, but on fake data, fake users and a fake location that reset on every launch. Phase 4 turns it into an app real neighbors can download from the App Store and use with each other.

**Where things stand (Oct 28, 2026)**

| Area | Today | Needed for the App Store |
| --- | --- | --- |
| Data | `MockRequestRepository`, in memory, seeded, resets on launch | Shared hosted database; requests, chat and reviews visible to everyone nearby |
| Users | Four demo users, switched in Dev Settings | Real accounts (Sign in with Apple), profile setup, sign out, account deletion |
| Location | Preset places in Dev Settings | GPS with permission, coarse and privacy-preserving |
| Rules | Enforced in the app (`RequestRules`, `KindnessRules`, …) | Enforced on the server too, so points and status cannot be faked |
| Kindness gift card | Fake Redeem with a made-up code | Real rewards, or no redeem at all (see decisions) |
| Safety | None | Report, block, content filter, moderation, terms (guideline 1.2) |
| Notifications | None | Push when a request is picked up, a message arrives, or a favor is completed |
| Release | Runs from Xcode on a simulator or a plugged-in phone (free team) | Paid developer account, TestFlight beta, privacy policy, store listing, review |
| Open work | 3E owner review and tag, 3F not started | Both done first |

**In scope:** release configuration with no demo controls; a hosted backend with server-side rules; Sign in with Apple and account deletion; real location; reporting, blocking and moderation; push notifications; a TestFlight beta with real neighbors; the App Store listing and submission; version `1.0.0`.

**Out of scope for 1.0:** payments or in-app purchases, Android or web, iPad layouts, maps, photos in requests, group chat, the helper reviewing the requester, analytics SDKs, launching outside the pilot area's country (US only).

**Definition of done:** Favorly 1.0.0 is approved and live on the App Store in the US; two people on two phones can post, pick up, chat, complete and review a favor with each other; every App Review requirement in the *App Store requirements* table is met; `swift test`, `xcodebuild test` and the backend tests pass; the commit is tagged `v1.0.0`.

[PLAN.md](PLAN.md), [PLAN-PHASE-2.md](PLAN-PHASE-2.md) and [PLAN-PHASE-3.md](PLAN-PHASE-3.md) still govern architecture, looks and existing behavior. This file governs what Phase 4 adds; where it changes something in the others, this file wins.

**Before 4A.** Finish 3E (the owner's by-hand review and the `v0.3.0-profiles` tag) and 3F (requester-only completion and auto-complete). 3F's rule is one the server must enforce in 4B, so it has to exist first.

## Decisions needed from the owner

Each has a default the plan assumes. Record the answer in `docs/PROGRESS.md`; items marked **$** need cost approval before anyone acts on them.

| Question | Default | Why it matters |
| --- | --- | --- |
| **$** Who holds the Apple Developer account? | One team member enrolls as an Individual ($99/year). The App Store shows that person's legal name as the seller | An Organization account shows "Team 402"-style names but needs a legal entity and a D-U-N-S number (weeks) |
| **$** Which backend? | Supabase: Postgres with PostGIS for "requests within 1 mile", row-level security, realtime for chat, Sign in with Apple built in | Firebase has no native radius query and needs paid Cloud Functions for server rules. CloudKit public data cannot enforce rules like "only the requester completes" |
| **$** Hosting plan | Free tier for development and internal TestFlight; Pro ($25/month) from the external beta on | Free projects pause after a week without traffic and have no backups; a paused backend means a dead app |
| Gift cards | No real gift cards in 1.0. Kindness score, progress and reviews stay; Redeem is removed | A fake reward code violates guideline 2.3 (accurate behavior). Real cards cost money, need fraud checks and a fulfillment process |
| Who can sign up? | 18 and over, confirmed at sign-up; age rating 18+ | Strangers chat and meet in person |
| Launch area | US only; the beta and first marketing focus on Roosevelt Island | A hyperlocal app with an empty map in every other city feels broken; one dense area avoids that |
| Sign-in methods | Sign in with Apple only | Satisfies guideline 4.8 with one method, and hides users' emails |
| How exact is location? | Requests store a point snapped to about 100 m, and show the neighborhood name, never an address | Safety: nobody can find where a requester lives from the app |
| What happens on account deletion? | Profile, open requests, messages and reviews they wrote are deleted; their completed favors stay, shown as "Deleted user", so the other person's history and points survive | Guideline 5.1.1(v) requires deletion in the app |
| Who moderates? | The owner checks the report queue daily during beta and launch, in the Supabase dashboard | Guideline 1.2 expects reports to be acted on promptly (Apple's guidance is 24 hours) |
| Legal | Terms of Use and Privacy Policy written from a template; ask Cornell Tech's legal resources to look them over before 4H | The app arranges in-person favors between strangers |

## Costs

Nothing below is spent without the owner's approval (see `CLAUDE.md` and the global cost rule).

| Item | When | Cost | Free alternative until then |
| --- | --- | --- | --- |
| Apple Developer Program | Before 4C (Sign in with Apple and push both need it) | $99/year | Free Personal Team for 4A–4B on a plugged-in phone |
| Supabase hosted project | End of 4B | Free tier | Local Supabase in Docker for all of 4B and most of 4C |
| Supabase Pro | Start of the external beta (4G) | $25/month | Stay on free tier for internal testers only |
| Website for privacy policy, terms and support | 4G | Free (GitHub Pages) | — |
| Custom domain | Optional | About $10–15/year | `<user>.github.io/favorly` |
| Apple Push Notification service | 4F | Free | — |
| Docker Desktop | 4B | Free for personal and education use | — |
| GitHub Actions minutes | 4B onward (backend tests) | Free for public repos; private repos get a monthly free allowance, macOS minutes count 10× | Run backend tests locally only |
| Legal review | Before 4H | Unknown | Cornell Tech clinic or faculty, if available |

**Running total for launch:** $99 once a year plus $25/month from the external beta. About $250 for the first year if the beta starts two months before launch.

## Guardrails

These replace Phase 3's guardrails.

- The architecture rules in `CLAUDE.md` still hold. The backend arrives as a new target, `FavorlyRemote`, a sibling of `FavorlyData` (see [ARCHITECTURE.md](ARCHITECTURE.md)). `FavorlyFeatures` never imports it.
- `FavorlyData` stays. Mocks keep powering unit tests, UI tests, SwiftUI previews and the `-uiTesting` and `-demo` launch modes, so the UI suite never touches the network.
- Every rule enforced in the app (`RequestRules`, `ChatRules`, `ReviewRules`, `KindnessRules`) is also enforced on the server. The app's copy is for showing the right buttons; the server's copy is the truth.
- No secrets in the app or the repo. The app holds only the Supabase URL and the public anon key, which is safe with row-level security on every table. The service-role key lives only in the Supabase dashboard and in server functions.
- Existing identifiers, visible strings and VoiceOver labels stay unless a feature below needs the change. Log each change in `docs/PROGRESS.md`.
- Third-party runtime dependency: the Supabase Swift SDK (`supabase-swift`), in `FavorlyRemote` only. Record it in `docs/PROGRESS.md` as `CLAUDE.md` requires. No other new dependencies without a note.
- Styling still goes only through `Theme` and the shared components.

## App Store requirements

Requirements from the App Review Guidelines that Favorly 1.0 must meet, and the phase that meets each. Re-read the current guidelines at the start of 4H; they change.

| Guideline | Requirement | Phase |
| --- | --- | --- |
| 2.2 Beta testing | No demos or test controls in the store build: no Dev Settings tab, no user switching, no fake data | 4A |
| 2.3 Accurate metadata | The app does what it shows; no fake reward codes | 4A |
| 4.2 Minimum functionality | Real shared data, so neighbors actually see each other | 4B, 4C |
| 4.8 Login services | Sign in with Apple offered | 4C |
| 5.1.1(v) Account deletion | Delete the account from inside the app | 4A (screen), 4C (server) |
| 5.1.5 Location services | Ask only when needed, explain why, work (with a message) if denied | 4D |
| 1.2 User-generated content | Report content, block users, filter objectionable content, act on reports, publish contact info, users agree to terms | 4E |
| 4.5.4 Push notifications | Optional, not required to use the app, no marketing | 4F |
| 5.1.1(i), 5.1.2 Privacy | Privacy policy in the app and the listing; App Privacy answers match what is collected | 4G |
| 2.1 App completeness | Reviewer can use every feature; review notes explain the two-person flow | 4H |

## Architecture and domain model changes

**New target**

- `FavorlyRemote` (package target) → `FavorlyCore` + `supabase-swift`. Implements every repository protocol, plus `AuthService`, against Supabase. One type per file, like `FavorlyData`.
- The App target gets `AppEnvironment.live()` next to `AppEnvironment.demo()`. `FavorlyApp` picks `demo()` when launched with `-uiTesting` or `-demo`, and `live()` otherwise.
- Backend code lives in the repo under `backend/supabase/` (Supabase CLI layout): `migrations/` (SQL schema, policies, functions), `functions/` (edge functions in TypeScript), `tests/` (pgTAP database tests), `seed.sql` (local development only).

**Core additions** (record any further change in `docs/PROGRESS.md`)

- `AuthService` protocol, `@MainActor`: `state: AuthState`, `signInWithApple(identityToken:nonce:) async throws`, `completeProfile(displayName:confirmedAdult:acceptedTermsVersion:) async throws`, `signOut() async`, `deleteAccount() async throws`.
- `AuthState` enum: `.signedOut`, `.needsProfile`, `.signedIn(UserProfile)`.
- `SessionStore` keeps `currentUser` for signed-in screens. `availableUsers` and `switchUser(to:)` move to a new `DemoSessionControls` protocol that only the mock implements and only Debug builds show. This is a change to a Phase 1 protocol; record it.
- `ModerationRepository` protocol: `report(_ target: ReportTarget, reason: ReportReason, note: String) async throws`, `block(_ user: UserID) async throws`, `unblock(_:)`, `blockedUsers() async throws -> [UserProfile]`.
- `ReportTarget` (`.request`, `.message`, `.user`) and `ReportReason` (`.spam`, `.inappropriate`, `.unsafe`, `.other`).
- `PushRegistrar` protocol: `register(deviceToken: Data) async throws`, `unregister() async`.
- `FavorlyError` gains `.notSignedIn`, `.network`, `.rateLimited`, `.blocked`, `.locationPermissionDenied`, each with a user message.
- `ContentFilter` rule (Core): rejects titles, details, messages and review comments containing words from a bundled list, with a user message. The server runs the same check.
- `KindnessRepository.redeemGiftCard` and `redemptions` stay in the protocol for the mock, but 1.0 shows no Redeem (see decisions).
- IDs: the server uses UUIDs. `RequestID`, `UserID` and the other ID types keep their `String` raw values and hold UUID strings.

**Server design (Supabase)**

- Tables: `profiles` (id = auth user, display name, neighborhood, adult confirmed, terms version, created), `requests` (location as PostGIS `geography(Point)`, snapped to about 100 m), `messages`, `reviews`, `reports`, `blocks`, `device_tokens`.
- Kindness score is a database view computed from completed requests and reviews, never a stored number the app can write.
- Row-level security on every table. Clients read through policies and change state only through SQL functions (RPCs) that check the rules: `nearby_requests(lat, lng, radius_m)`, `create_request`, `claim_request`, `cancel_request`, `complete_request` (requester only, rule 15), `send_message`, `submit_review`, `report`, `block`, `delete_my_account`.
- Blocks hide content both ways: a blocked user's requests, messages and profile disappear for the blocker, and the blocked user cannot claim the blocker's requests or message them.
- Rate limits in the RPCs: at most 5 open requests per user, 20 new requests per day, 30 messages per minute.
- Auto-complete (rule 15): `pg_cron` runs every 15 minutes and completes claimed requests 7 days after pick-up.
- Push: a database webhook calls an edge function that sends APNs notifications. The APNs key is stored as a Supabase secret.

## Implementation phases

One phase per session, on `phase/4x-<short-name>` branches, as in `CLAUDE.md`. Owner tasks (enrolling, approving costs, creating hosted resources, inviting testers) are marked **Owner**; an agent pauses at them and logs them in `PENDING_APPROVALS.md`.

### 4A. Release groundwork (no backend, no cost)

Everything the store build needs that does not depend on a server, built against mocks.

- [x] `AuthService`, `AuthState`, `DemoSessionControls` in Core; `MockAuthService` in Data (starts signed out in live-like mode, signed in as Alex in `-uiTesting` and `-demo`)
- [x] Onboarding: Welcome screen with Sign in with Apple button (wired to the mock for now), profile setup (display name, "I'm 18 or older", accept Terms of Use and Privacy Policy with links)
- [x] Profile tab: Sign out, Delete account (with a confirmation that explains what is deleted)
- [x] Dev Settings tab and user switching compiled only in Debug builds (`#if DEBUG`); Release shows four tabs
- [x] Remove the Redeem button and reward codes from the UI; gift-card progress becomes "Kindness score" progress with no money amount (per decisions). Done by removing the gift card section entirely; see `docs/PROGRESS.md`
- [x] `AppEnvironment.live()` stub and the `-demo` launch argument; `FavorlyApp` chooses the environment
- [x] Config plumbing (encryption key done; the Supabase keys moved to 4C, see `docs/PROGRESS.md`): `FAVORLY_SUPABASE_URL` and `FAVORLY_SUPABASE_ANON_KEY` from `Config/Signing.xcconfig` / `Local.xcconfig` into the Info.plist; `ITSAppUsesNonExemptEncryption = NO`
- [x] Tests: auth state transitions, onboarding validation (empty name, unticked boxes), delete-account confirmation, Release build has no Dev Settings (a build-setting test or a UI test on a Release-config scheme)
- [x] Update UI tests and the demo script for the onboarding step (skipped under `-uiTesting`)

**Done when:** a Release build launches to the Welcome screen with no Dev Settings tab; a Debug `-demo` launch behaves exactly as 0.3.0 did; `swift test` and `xcodebuild test` pass.

### 4B. Backend schema and server rules (local only, no cost)

- [x] **Owner:** install Docker Desktop and the Supabase CLI
- [x] `backend/supabase/` project: migrations for every table, PostGIS, row-level security policies, the RPCs and the kindness view described above
- [x] Server versions of rules 1–15 in the RPCs (the content filter moved to 4E, see `docs/PROGRESS.md`)
- [x] `pg_cron` auto-complete job; rate limits; block rules
- [x] `delete_my_account` function implementing the deletion decision
- [x] pgTAP tests for every RPC and policy: allowed and refused for requester, helper, stranger and blocked user; nearby radius edges; auto-complete at 7 days minus 1 second and at 7 days; kindness totals; deletion leaves "Deleted user" on completed favors
- [x] `backend/README.md`: start, reset, test and deploy commands
- [ ] **Owner, $ (free tier):** create the hosted Supabase project, then deploy the migrations to it

**Done when:** `supabase test db` passes locally; every rule in `docs/PLAN.md` and Phase 3 has a server test; nothing in the app changed.

### 4C. Real accounts and shared data

- [ ] **Owner, $99:** Apple Developer Program enrolled; App ID with Sign in with Apple; Supabase Apple provider configured
- [ ] `FavorlyRemote` target with `supabase-swift`; dependency recorded in `docs/PROGRESS.md`
- [ ] `RemoteAuthService`: Sign in with Apple through Supabase auth, profile completion, sign out, account deletion, session restore on launch
- [ ] `RemoteRequestRepository`, `RemoteChatRepository`, `RemoteReviewRepository`, `RemoteKindnessRepository`; `changes()` backed by Supabase realtime; chat updates live
- [ ] Error mapping: server errors to `FavorlyError` (`.network`, `.notAllowed`, `.rateLimited`, …); offline shows a retryable error, never a crash
- [ ] Contract tests: one shared test suite run against `MockRequestRepository` always, and against local Supabase when `FAVORLY_REMOTE_TESTS=1`, so mock and server behave the same
- [ ] `FAVORLY_SUPABASE_URL` and `FAVORLY_SUPABASE_ANON_KEY` from `Config/Signing.xcconfig` / `Local.xcconfig` into the Info.plist (moved from 4A)
- [ ] Replace the Welcome screen's mock button with Apple's `SignInWithAppleButton`
- [ ] `AppEnvironment.live()` wired; Release builds use it

**Done when:** two phones signed in with two Apple IDs (simulator plus a device is fine) can post, pick up, chat, complete and review a favor with each other, against the hosted project; deleting an account on one phone updates the other; contract tests pass against both implementations.

### 4D. Real location and privacy

- [ ] `CoreLocationProvider` implementing `LocationProvider`: when-in-use permission, reduced accuracy is enough, one fix per request
- [ ] Neighborhood name from reverse geocoding (`CLGeocoder`), shown instead of the preset label
- [ ] Location snapped to about 100 m before upload; distances shown rounded
- [ ] Permission flow: ask when Nearby or Post first needs it, with the reason; if denied, an explanation and a button to Settings; `.locationPermissionDenied` error
- [ ] `NSLocationWhenInUseUsageDescription` in `project.yml`
- [ ] `LocationSettings` and presets only in Debug and `-demo`
- [ ] Tests: snapping, rounding, permission states in the view models (with a fake provider)

**Done when:** on a phone, Nearby shows real requests around the real location; denying permission shows the explanation and the Settings button; no screen shows a location more exact than the neighborhood and a rounded distance.

### 4E. Trust and safety

- [ ] Report a request, a message or a user (menu on Request Detail, long-press on a message, menu on a profile); reason and an optional note
- [ ] Block and unblock a user; Blocked users list in Profile; blocked content disappears at once
- [ ] Content filter on post, message and review, in the app and on the server (one shared word list; moved here from 4B)
- [ ] Terms of Use shown and accepted at sign-up (version stored); link in Profile; Safety tips screen (meet in public places, don't share your address, report anything unsafe)
- [ ] Contact support link (email or website) in Profile
- [ ] Moderation: `reports` queue readable in the Supabase dashboard; a saved query listing open reports; **Owner:** a written moderation routine in `docs/MODERATION.md` (check daily, remove content, ban accounts)
- [ ] Tests: report and block RPCs (4B covers the server), view models, blocked content hidden, filter messages

**Done when:** a user can report and block from every place content appears; a blocked user's content is gone for the blocker on both phones; offensive words are refused with a clear message.

### 4F. Push notifications

- [ ] **Owner:** create an APNs key in the developer account; store it as a Supabase secret
- [ ] Push capability and entitlement in `project.yml`
- [ ] Ask for notification permission after the user's first post or first pick-up, not at launch
- [ ] Device token registered through `PushRegistrar`; removed on sign-out and account deletion
- [ ] Edge function sends: "Bea picked up your request", "New message from Bea", "Alex marked your favor completed", "Alex left you a review"
- [ ] Tapping a notification opens the right request or chat
- [ ] Profile: notification settings link
- [ ] Tests: registration and routing logic; the edge function's message text

**Done when:** on two phones, each of the four events shows a notification on the other phone, and tapping it opens the right screen.

### 4G. Release candidate and beta

- [ ] **Owner, $25/month:** upgrade Supabase to Pro before external testers join
- [ ] Website (GitHub Pages): Privacy Policy, Terms of Use, Support page with contact email. Linked in the app and the listing
- [ ] App Privacy answers drafted in `docs/release/app-privacy.md` (contact info: name; location: coarse; user content: messages, requests, reviews; identifiers: user ID; none used for tracking)
- [ ] Version `1.0.0` (build numbers count up per upload); archive a Release build
- [ ] **Owner:** App Store Connect app record; internal TestFlight for the team
- [ ] Internal round: the team uses it for a week on Roosevelt Island; fix crashes (Xcode Organizer) and blockers
- [ ] **Owner:** external TestFlight group (Beta App Review, about a day), 20–50 neighbors, two weeks; "What to Test" notes; feedback through TestFlight
- [ ] Triage list in `docs/PROGRESS.md`; fix everything marked "launch blocker"
- [ ] Cold-start plan: team members post real requests in the pilot area so the first users see activity

**Done when:** the external beta ran for two weeks with no open launch blockers and no crash affecting more than one tester; the privacy policy, terms and support pages are live.

### 4H. App Store submission and launch

- [ ] Store listing: name, subtitle, description, keywords, category (Lifestyle or Social Networking), support and privacy URLs, age rating questionnaire (18+)
- [ ] Screenshots for the required iPhone sizes, captured with `ScreenshotUITests` under `-demo` at the required size, with realistic Roosevelt Island content
- [ ] Review notes: what the app does; that it needs two people, with a short screen recording of the full two-phone flow; that the reviewer can post a request and see it on Nearby; where report and block are; moderation contact
- [ ] Re-read the App Review Guidelines and tick every row of *App Store requirements*
- [ ] **Owner:** submit for review; answer any rejection, fix, resubmit
- [ ] **Owner:** release with phased release on; tag `v1.0.0`
- [ ] Post-launch watch for the first two weeks: crashes, reports queue daily, Supabase usage against plan limits

**Done when:** Favorly 1.0.0 is live in the US App Store and tagged `v1.0.0`.

## Rough timeline

Estimates, not commitments. Code phases assume one or two working sessions each; waits are outside the team's control.

| Weeks | Work | Waits |
| --- | --- | --- |
| 0 | 3E review, 3F | — |
| 1 | 4A, 4B | — |
| 2 | 4C | Developer Program approval (1–2 days) |
| 3 | 4D, 4E | — |
| 4 | 4F, 4G internal round | — |
| 5–6 | External beta | Beta App Review (about a day) |
| 7 | 4H | App Review (usually 1–2 days; each rejection adds 1–3) |

About seven to eight weeks from now to launch, if decisions come quickly and the beta finds nothing large.

## Testing

Commands from [PLAN.md](PLAN.md) still apply, plus:

```bash
supabase start                 # local backend in Docker
supabase test db               # database tests (pgTAP)
FAVORLY_REMOTE_TESTS=1 swift test --package-path Packages/FavorlyKit   # contract tests against local Supabase
```

- Unit and UI tests keep using mocks, so they need no network and stay as fast as now.
- Contract tests prove the mock and the server agree; when they disagree, the server is right and the mock is fixed.
- Before each TestFlight upload: the full UI suite, the backend tests, and the two-phone flow by hand.

## Open questions

Defaults are in *Decisions needed from the owner*. Also:

- **Empty area at review time.** Apple reviewers are not on Roosevelt Island, so Nearby will be empty for them. Default: the review notes and screen recording explain this, and the reviewer can post a request and see it. If rejected under 2.1, add a review account with a few requests near the reviewer's location.
- **Neighborhood names.** Reverse geocoding gives names like "Roosevelt Island" or "Midtown East". Default: use the system's `subLocality`, falling back to the city.
- **Profile names.** Display names are self-chosen. Default: first name or nickname, 2–30 characters, through the content filter. No verification in 1.0.
- **Notifications for new nearby requests.** Not in 1.0; it needs a server-side geo fan-out and a way to avoid spamming. Revisit after launch.

## Conventions for coding agents

Everything in `CLAUDE.md`, [PLAN.md](PLAN.md)'s conventions and Phase 3's conventions still applies, with these changes:

- Phase 3's guardrails are replaced by the *Guardrails* section above.
- Every new rule, repository method, view model and server function ships with tests in the same phase.
- Never create, upgrade or deploy hosted resources, enroll in programs or upload builds without the owner's approval. In unattended sessions, log the step in `PENDING_APPROVALS.md` and continue with work that does not depend on it.
- Work against local Supabase (`supabase start`) by default; only 4C's two-phone check and later need the hosted project.
- When behavior is a judgment call, pick the plainer, more private option and note it in `docs/PROGRESS.md`.
