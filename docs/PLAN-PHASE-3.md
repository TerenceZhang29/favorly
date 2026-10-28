# Favorly iOS Prototype — Phase 3 Implementation Plan: Kindness score, profiles, chat and reviews

Oct 9, 2026 · Team 402

## Overview

Phase 1 delivered working flows and Phase 2 made them look good. Phase 3 adds four features on top, still with fake data and a fake location.

**Features, in priority order**

1. **Kindness score.** A helper earns points for completed favors and for the stars in their reviews. Points count toward a gift card.
2. **Profile.** A separate tab showing the user's name, picture, score and past activities. Other users' profiles can be opened from a request.
3. **Chat.** Requester and helper can message each other, only once the request has been picked up.
4. **Reviews.** After a request is completed, the requester gives the helper a star score and a text comment. Reviews show on the helper's profile.

**In scope:** Kindness score with gift-card progress and a fake redeem; a fifth tab, Profile, plus other users' profiles reached from a request; per-request chat between requester and helper; a review form and reviews on profiles; seed history so profiles are not empty; tests and an extended demo script.

**Out of scope:** real gift cards or payments, real photos, push notifications or unread badges, group chat, editing or deleting messages and reviews, the helper reviewing the requester, reporting and blocking, a backend.

**Definition of done:** the extended demo script passes by hand and in `DemoFlowUITests`; `swift test` and `xcodebuild test` pass; the architecture rules in `CLAUDE.md` still hold; the version is `0.3.0` and the commit is tagged `v0.3.0-profiles`.

[PLAN.md](PLAN.md) still governs architecture and the Phase 1 domain model and behavior. [PLAN-PHASE-2.md](PLAN-PHASE-2.md) still governs how the app looks. This file governs what Phase 3 adds; where it changes something in the other two, this file wins.

**Ordering with 2D.** Phase 2D (polish, app icon, tag `v0.2.0-ui`) is still open. Finish it before 3A, because Phase 3 lifts the "looks only" guardrails that 2D's checks assume. If the team wants features first, 2D's consistency pass runs after 3E instead and covers the new screens too.

## Decisions confirmed with the owner (2026-10-09)

| Question | Decision |
| --- | --- |
| How is Kindness score earned? | Points to the helper when a picked-up request is completed, plus a bonus from the review's stars. Only helping earns points |
| What does "score for gift card" mean here? | Progress toward a threshold, plus a fake Redeem that deducts the points and shows a reward code |
| Who writes a review? | The requester reviews the helper, once per completed request |
| What is the profile picture? | An initials avatar drawn in code. No image assets |

## Guardrails

These replace Phase 2's "Functionality guardrails".

- Core, Data and view models may change. Existing behavior, identifiers, visible strings and VoiceOver labels stay as they are unless a feature below needs the change. Log each such change in `docs/PROGRESS.md`.
- Styling still goes only through `Theme` and the shared components. No new palette colors: score, stars and chat bubbles use `brand` and `neutral`, so the contrast tests stay valid.
- `RequestRepository` keeps its current methods. New capabilities are new protocols.
- Existing tests may be edited only where this plan changes what they assert (the seed count, the number of tabs). Everything else in the Phase 1 and 2 suites passes unedited.

## Domain model additions

These types live in `FavorlyCore`. Implement them as written and change them only with a note in `docs/PROGRESS.md`.

**Models** (one per file in `Models/`, each with a `public init`)

```swift
public struct ReviewID: Hashable, Codable, Sendable { public let rawValue: UUID }
public struct RedemptionID: Hashable, Codable, Sendable { public let rawValue: UUID }
public struct MessageID: Hashable, Codable, Sendable { public let rawValue: UUID }

public struct Review: Identifiable, Hashable, Codable, Sendable {
    public let id: ReviewID
    public let requestID: RequestID
    public let reviewerID: UserID       // the requester
    public let revieweeID: UserID       // the helper
    public let rating: Int              // 1...5
    public let comment: String
    public let createdAt: Date
}

public struct NewReviewDraft: Sendable {
    public var rating: Int
    public var comment: String
}

public struct Redemption: Identifiable, Hashable, Codable, Sendable {
    public let id: RedemptionID
    public let userID: UserID
    public let points: Int              // points spent
    public let code: String             // fake reward code, e.g. "FAVORLY-0001"
    public let createdAt: Date
}

public struct KindnessSummary: Hashable, Sendable {
    public let completedFavors: Int
    public let reviewCount: Int
    public let averageRating: Double?   // nil with no reviews
    public let lifetimePoints: Int      // the "Kindness score" everyone sees
    public let redeemedPoints: Int
    public var availablePoints: Int { lifetimePoints - redeemedPoints }
}

public struct ChatMessage: Identifiable, Hashable, Codable, Sendable {
    public let id: MessageID
    public let requestID: RequestID
    public let senderID: UserID
    public let text: String
    public let sentAt: Date
}
```

`UserProfile` is unchanged. The avatar is derived from `displayName` and `id`. A `photoURL` field is the later seam for real pictures.

**Service protocols** (in `Services/`)

```swift
public protocol KindnessRepository: Sendable {
    func kindnessSummary(for user: UserID) async throws -> KindnessSummary
    func redemptions(by user: UserID) async throws -> [Redemption]      // newest first
    func redeemGiftCard(by user: UserID) async throws -> Redemption
}

public protocol ReviewRepository: Sendable {
    func reviews(about user: UserID) async throws -> [Review]           // newest first
    func review(for request: RequestID) async throws -> Review?
    func submitReview(_ draft: NewReviewDraft, for request: RequestID, by user: UserID) async throws -> Review
}

public protocol ChatRepository: Sendable {
    func messages(for request: RequestID, as user: UserID) async throws -> [ChatMessage]   // oldest first
    func send(_ text: String, in request: RequestID, by user: UserID) async throws -> ChatMessage
}
```

Every write emits on the existing `RequestRepository.changes()`, and `reset()` restores reviews, redemptions and messages to the seed along with requests. Open screens and Dev Settings keep working with no new plumbing.

**Errors.** `FavorlyError` gains `alreadyReviewed` and `notEnoughPoints`. `ErrorMessage.text(for:)` gains a message for each.

## Business rules

Implement in `Rules/`, enforce in the repository, cover with tests. Numbering continues from the nine rules in [PLAN.md](PLAN.md).

10. **Kindness points (`KindnessRules`).** The helper earns 10 points per completed request and 2 points per star of that request's review, so one favor is worth 10 to 20 points. Requests that are open, claimed or cancelled earn nothing. The score is derived by one pure function, `summary(completedAsHelper:reviews:redemptions:)`; nothing stores a running total.
11. **Gift card.** `lifetimePoints` never decreases and is the Kindness score shown to everyone. `availablePoints = lifetimePoints − redeemedPoints` drives gift-card progress, which only the owner sees. One gift card costs 100 available points; redeeming with fewer throws `notEnoughPoints`. A redemption records 100 points and a code that counts up (`FAVORLY-0001`, `FAVORLY-0002`), so tests are deterministic.
12. **Reviews (`ReviewRules`).** Only the requester can review, only when the request is `completed` and has a helper (`notAllowed` otherwise), and only once per request (`alreadyReviewed`). The rating is 1 to 5. The comment is trimmed and 0 to 300 characters. Bad input throws `validation("…")` with a readable message.
13. **Chat (`ChatRules`).** A request's thread exists once it has a helper. Only the requester and the helper can read it (`notAllowed` otherwise). Sending is allowed only while the request is `claimed`; after completion or cancellation the thread is read-only. Message text is trimmed and 1 to 500 characters.
14. **Privacy.** Rule 9 extends to profiles: past activities show the location label only. Someone else's profile shows completed requests only, and never their gift-card progress or reward codes.
15. **Completion (`RequestRules`, added 2026-10-13, replaces Phase 1's rule 4).** Only the requester can mark a claimed request completed; anyone else, the helper included, gets `notAllowed`. A claimed request that the requester has not completed or cancelled completes on its own 7 days after `claimedAt` (`RequestRules.autoCompleteInterval`). An auto-completed request is an ordinary completed request: the helper earns the points, and the requester can still review it.

## Data layer

**One mock actor.** `MockRequestRepository` stays the single in-memory actor and also conforms to the three new protocols, one conformance per file: `MockRequestRepository+Kindness.swift`, `MockRequestRepository+Reviews.swift`, `MockRequestRepository+Chat.swift`. It holds `reviews`, `redemptions` and `messages` beside `requests`. One actor keeps rules that span requests and reviews atomic, and keeps one `changes()` stream and one `reset()`.

**Environment.** `AppEnvironment` gains `kindness`, `reviews` and `chat`. `AppEnvironment.demo()` passes the same actor to all four members. `PreviewRequestRepository` gets matching read-only conformances, and `TestWorld` is updated the same way.

**Seed history.** Profiles need content and the gift card must be reachable in a five-minute demo. Add five completed requests (seed IDs 13–17, several days old) and a `DemoReviews` fixture. None involve Alex, so Alex's empty states and every Nearby count stay as they are.

| Seed | Requester → helper | Review |
| --- | --- | --- |
| 12 (existing saffron request) | Dana → Bea | None yet; Dana can leave one |
| 13–16 (new) | Chen or Dana → Bea | 5 stars each, with short comments |
| 17 (new) | Bea → Chen | 4 stars |

**Starting scores**

| User | Completed favors | Review stars | Score |
| --- | --- | --- | --- |
| Bea | 5 | 20 | 90 |
| Chen | 1 | 4 | 18 |
| Dana | 0 | 0 | 0 |
| Alex | 0 | 0 | 0 |

One more completed favor takes Bea to 100, which is what the demo does.

## Screens

Five tabs: Nearby, Post, My Activity, Profile, Dev Settings.

| Screen | What it shows | Actions |
| --- | --- | --- |
| **Profile** (new tab, `person.crop.circle`) | Avatar, name, neighborhood. Kindness score with favors completed and average rating. Gift-card card with a progress bar ("90 of 100 points"), a Redeem button and past reward codes. Past activities: completed requests, labeled "Helped" or "Asked". Reviews received | **Redeem** (enabled at 100 points); tap an activity to open Request Detail |
| **Other user's profile** (pushed) | The same view for another user, without the gift-card card | Reached by tapping "Posted by" or "Helper" on Request Detail |
| **Request Detail** (changed) | Score beside the requester's and helper's names; a "Your review" row once reviewed | **Message Bea** (participants, once picked up); **Leave a review** (requester, when completed and not yet reviewed) |
| **Chat** (pushed from Request Detail) | Request title, messages as bubbles with sender and time, a read-only note when the thread is closed | Text field and **Send** |
| **Review form** (sheet) | Star picker, comment field with a character count | **Submit**, **Cancel** |

Key states: Profile has loading, loaded, an empty history ("No activity yet") and an error with Retry. Chat has an empty thread ("Say hello") and a closed thread. The review form disables Submit until a rating is chosen.

**New Features code.** Each screen follows the existing pattern: a view, an `@Observable` view model that takes `AppEnvironment` in `init`, and a reload on `repository.changes()`.

| Folder | Types |
| --- | --- |
| `Profile/` | `ProfileView`, `ProfileViewModel` (state enum like `ActivityViewModel`; `reloadKey` for user switches), `ProfileActivityRow`, `ReviewRow`, `GiftCardCard` |
| `Chat/` | `ChatView`, `ChatViewModel`, `MessageBubble` |
| `Review/` | `ReviewFormView`, `ReviewFormViewModel` (live validation like `PostRequestViewModel`) |
| `Shared/Components/` | `AvatarView` (initial on a tinted circle; color picked from the existing palette by a stable hash of the user ID), `ScoreLabel`, `StarRating` (read-only), `StarRatingPicker` |

**Changed:** `RootTab` and `RootView` (fifth tab), `RequestDetailViewModel` and `RequestDetailView` (chat and review entry points, tappable names), `Theme` (`Radius.bubble`, `IconSize.avatar`).

**Reused as they are:** `CategoryIcon`, `StatusBadge`, `FactRow`, `MessageView`, `InlineMessage`, `SectionHeader`, `PrimaryButtonStyle`, `SecondaryButtonStyle`, `plainListRow()`, `SessionStore.displayName(for:)`, `SessionStore.statusText(for:)`.

Every interactive element gets an `accessibilityIdentifier`: `profile.*`, `chat.*`, `review.*`, `detail.message`, `detail.review`.

## Implementation phases

Six sequential phases (3F was added on 2026-10-13), each sized for one agent session. Each ends with green tests, an updated `docs/PROGRESS.md` including the commit map, and a build that can be demoed.

No pull requests. Work on a branch `phase/<id>-<short-name>`; when the phase is done, fast-forward `main` to it, push `main`, and delete the branch.

### 3A. Kindness score: core and data

- [ ] `Review`, `Redemption`, `KindnessSummary` and their ID types; `KindnessRepository`; `ReviewRepository` with its two read methods; `KindnessRules`; the two new errors and their messages
- [ ] `MockRequestRepository` conformances for the summary, redemptions, redeem and review reads; seeds 13–17 and `DemoReviews`
- [ ] `AppEnvironment` members, `AppEnvironment.demo()` wiring, preview stubs, `TestWorld`
- [ ] Tests: points per favor and per star; only completed requests count; lifetime versus available; redeem at 99 and at 100; two redemptions in a row; deterministic codes; seed scores (Bea 90, Chen 18, Dana 0, Alex 0); `reset()` clears redemptions; `changes()` emits on redeem
- [ ] Update the Phase 1 tests that assert a seed count of 12

**Done when:** `swift test` passes and every demo user's score is available through `AppEnvironment`. The app looks the same as before.

### 3B. Profile tab with score and gift card

- [ ] `AvatarView`, `ScoreLabel`, `GiftCardCard`, `ProfileActivityRow`, each with a light and dark `#Preview`
- [ ] `ProfileViewModel` and `ProfileView`; the fifth tab in `RootTab` and `RootView`
- [ ] Other users' profiles from Request Detail; score beside the names there
- [ ] Tests: view model states; own versus other profile (no gift card on others); redeem updates the summary; a user switch reloads; `RootTabTests` and `LaunchUITests` for five tabs; new `ProfileUITests` (Bea's profile shows 90, Alex's shows the empty state)
- [ ] Screenshots in light, dark and at `accessibility-large`, checked by eye

**Done when:** by hand, Bea completes one favor, her profile reaches 100, Redeem shows a code, and progress returns to "0 of 100 points".

### 3C. Chat

- [ ] `ChatMessage`, `MessageID`, `ChatRepository`, `ChatRules`; the mock conformance
- [ ] `ChatViewModel`, `ChatView`, `MessageBubble`; the "Message …" button on Request Detail
- [ ] Tests: no thread before pick-up; a non-participant gets `notAllowed`; sending only while claimed; text limits; oldest-first ordering; refresh on `changes()`
- [ ] UI test: Bea sends a message, the user is switched, Alex sees it and replies

**Done when:** two demo users can hold a conversation on one laptop through the user switcher, and the button is absent on open requests.

### 3D. Reviews

- [ ] `NewReviewDraft`, `ReviewRules`, `submitReview` in the mock
- [ ] `StarRating`, `StarRatingPicker`, `ReviewFormViewModel`, `ReviewFormView`
- [ ] "Leave a review" and "Your review" on Request Detail; `ReviewRow` and the Reviews section on Profile
- [ ] Tests: every `ReviewRules` branch; the star bonus reaches the helper's score; a second review throws `alreadyReviewed`; form validation
- [ ] UI test: submit a review, then see it on the helper's profile

**Done when:** Alex reviews Bea with 5 stars, Bea's score rises by 10, and the review shows on her profile.

### 3E. Hardening, demo, docs

- [ ] `DemoFlowUITests` extended to the demo script below
- [ ] Accessibility pass on the new screens: Dynamic Type, and one spoken sentence each for message, review and activity rows
- [ ] Search the new files for literal colors, radii and padding; SwiftLint and SwiftFormat clean; no compiler warnings
- [ ] README demo script and screenshots; `docs/ARCHITECTURE.md` (the new protocols, one mock actor)
- [ ] `MARKETING_VERSION` `0.3.0`; tag `v0.3.0-profiles`

**Done when:** the *Definition of done* in the Overview is met on a fresh clone.

### 3F. Requester-only completion and auto-complete

Decided by the owner on 2026-10-13, after reviewing 3A–3E. It closes the "Self-awarded points" open question: a helper can no longer complete a request, so they cannot award themselves points, and a requester who never confirms cannot hold the helper's points back for more than 7 days. Branch `phase/3f-completion`.

- [x] `RequestRules.validateComplete`: only the requester passes; the helper gets `notAllowed`. Update the status-rules text in `docs/PLAN.md` (rule 4 and the Request Detail row) to match
- [x] `RequestRules.autoCompleteInterval` (7 days) and `RequestRules.isAutoCompleteDue(_:now:)`: true for a claimed request whose `claimedAt` is 7 days or more before `now`
- [x] `MockRequestRepository`: before every read and write, complete each claimed request that is due, and emit on `changes()` when any changed. No timer; the repository's `now` closure decides, so tests use a fixed clock
- [x] `RequestDetailViewModel`: `canComplete` is true for the requester only. For the helper of a claimed request, expose the auto-complete date
- [x] `RequestDetailView`: the helper sees no Mark completed button, and a gray note in its place: "Completes automatically on Oct 20 if Alex doesn't confirm." (`detail.autoCompleteNote`)
- [x] Tests: the helper cannot complete; the requester can; not due at 7 days minus one second, due at exactly 7 days; an auto-completed request gives the helper 10 points and can be reviewed; a cancelled or open request never auto-completes; `reset()` is unaffected; the view model hides the action from the helper
- [x] UI tests: the helper's Request Detail has no Mark completed button and shows the note. Edit any existing test that completes a request as the helper
- [x] README demo script and `docs/ARCHITECTURE.md` if either mentions the helper completing

**Done when:** as Bea, a picked-up request shows the note and no Mark completed button; as Alex, Mark completed still works; a test with the clock moved 7 days forward shows the request completed and Bea's score 10 higher.

## Testing and demo

Commands are unchanged from [PLAN.md](PLAN.md).

**Coverage expectations**

- Rules 10–13: every branch.
- Repository: every new protocol method, including error paths and `reset()`.
- View models: state transitions, and what each user can see and do.
- UI: the extended demo flow, plus one focused test each for Profile, Chat and Reviews.

**Extended demo script** (the acceptance test for this phase)

1. Alex's Profile shows a score of 0 and "No activity yet".
2. Alex posts "Need a cup of rice". Switch to Bea; her Profile shows 90 points and "90 of 100 points".
3. Bea picks up the request, opens the chat and sends "On my way". Switch to Alex, reply, then tap Mark completed.
4. Alex taps Leave a review: 5 stars, "Fast and friendly".
5. Switch to Bea. Profile shows 110 points, the new review, and the favor under Past activities. Tap Redeem: the code `FAVORLY-0001` appears and progress reads "10 of 100 points".
6. Switch to Chen and open Bea's profile from a request. Score and reviews are visible; the gift-card card is not.

## Open questions

Each has a default the plan assumes. Change them in `docs/PROGRESS.md` if the team decides otherwise.

- **Self-awarded points.** Resolved 2026-10-13: only the requester can mark a request completed, and a claimed request completes on its own after 7 days. See rule 15 and phase 3F.
- **Showing auto-complete in the demo.** Data is in memory and resets on launch, so 7 days never pass in a demo. Default: tests only, with a fixed clock; no seed request and no Dev Settings control to move time.
- **Point values.** 10 per favor, 2 per star, and 100 points for a "$5" gift card are placeholders, defined once in `KindnessRules`.
- **Chat after completion.** Sending closes when the request is completed. Reopening it is a one-line change in `ChatRules`.
- **What others see.** Someone else's profile shows completed requests only. Open and cancelled requests stay private to their owner.

## Conventions for coding agents

Everything in [PLAN.md](PLAN.md)'s conventions, [PLAN-PHASE-2.md](PLAN-PHASE-2.md)'s styling rules and `CLAUDE.md` still applies, with these changes for Phase 3:

- Phase 2's "looks only" guardrails are replaced by the *Guardrails* section above.
- Every new rule, repository method and view model ships with tests in the same phase. New components are views with no logic and need previews, not tests.
- No third-party dependencies and no image assets.
- When behavior is a judgment call, pick the plainer option and note it in `docs/PROGRESS.md`.
