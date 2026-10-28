# Favorly iOS prototype

Favorly is a hyperlocal iOS app that lets neighbors post small help requests and pick them up. This repo holds the prototype: SwiftUI, fake data and a fake location, run in the iOS Simulator. Phase 1 (working flows) is done; Phase 2 is a UI refresh that changes looks only; Phase 3 adds the Kindness score, profiles, chat and reviews; Phase 4 turns the prototype into an App Store app with a real backend.

## Start of every session

1. Read `docs/PLAN.md`. It is the source of truth for architecture, interfaces and behavior.
2. Read `docs/PLAN-PHASE-2.md`. It is the source of truth for how the app looks, and for the scope of phases 2A–2D.
3. Read `docs/PLAN-PHASE-3.md`. It is the source of truth for the scope, rules and acceptance criteria of phases 3A–3F.
4. Read `docs/PLAN-PHASE-4.md`. It is the source of truth for the scope, decisions, costs and acceptance criteria of phases 4A–4H.
5. Read `docs/PROGRESS.md` and continue from the first unchecked phase or task.
6. If the plan is ambiguous or seems wrong, write the question in `docs/PROGRESS.md` under "Open questions" and pick the most reasonable option. Don't silently diverge from the plan.

## How to work

- Do one phase (2A → 2D, then 3A → 3F, then 4A → 4H) per session, on a branch named `phase/<id>-<short-name>` (e.g. `phase/2a-theme`).
- No pull requests. When a phase is done, fast-forward `main` to the branch, push `main`, and delete the branch.
- Commit in small steps using Conventional Commits (`feat(core): request status rules`).
- Implement the types and protocols in the plan's "Domain model" section as written. If you must change one, record why in `docs/PROGRESS.md`.
- Every new rule, repository method or view model ships with tests in the same phase.

## Architecture rules (do not break)

- Dependencies: `FavorlyFeatures → FavorlyCore` and `FavorlyData → FavorlyCore`, and from 4C `FavorlyRemote → FavorlyCore`. The App target imports them all.
- `FavorlyCore` imports only Foundation.
- `FavorlyFeatures` never imports `FavorlyData`. Views get services only through `AppEnvironment`.
- One type per file; the file name matches the type; `public` only for what other modules need.
- No third-party runtime dependencies without a note in `docs/PROGRESS.md`.
- Build the UI from system SwiftUI controls, styled only through `Theme` and the shared components; no literal colors or sizes in screen files. Add an `accessibilityIdentifier` to every interactive element.
- Follow the guardrails of the phase you are in: "Functionality guardrails" in `docs/PLAN-PHASE-2.md` for 2A–2D (looks only), "Guardrails" in `docs/PLAN-PHASE-3.md` for 3A–3F, "Guardrails" in `docs/PLAN-PHASE-4.md` for 4A–4H.

## Project file

- `project.yml` (XcodeGen) is the source of truth. Never hand-edit `Favorly.xcodeproj`; it is git-ignored.
- After changing `project.yml`, run `xcodegen generate`.

## Commands

```bash
xcodegen generate
swift test --package-path Packages/FavorlyKit
xcrun simctl list devices available
xcodebuild test -project Favorly.xcodeproj -scheme Favorly \
  -destination 'platform=iOS Simulator,name=<available iPhone>'
```

## Before ending a phase

1. `swift test` passes, and `xcodebuild test` passes once the app target exists (1A onward).
2. No compiler warnings under Swift 6 strict concurrency; SwiftLint is clean.
3. The phase's "Done when" criteria in its plan file are met.
4. `docs/PROGRESS.md` is updated: tick tasks, log decisions and known issues, add the phase's commits to the commit map, and name the next task.
5. Commit, fast-forward `main`, push, and summarize the changes.
