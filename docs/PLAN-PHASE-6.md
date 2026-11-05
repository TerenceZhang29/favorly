# Favorly — Phase 6 Plan: TestFlight beta

Nov 4, 2026 · Team 402

## Overview

Phase 6 runs the beta that 4G prepared. The release candidate is version 1.0.0 with the Grove look (Phase 5), from build 3 on. These items moved here from 4G in [PLAN-PHASE-4.md](PLAN-PHASE-4.md) on 2026-11-04, when the owner closed 4G after the two-phone check. App Store submission (4H) follows this phase.

[PLAN-PHASE-4.md](PLAN-PHASE-4.md) still governs costs, guardrails, the App Store requirements and 4H. [PLAN-PHASE-5.md](PLAN-PHASE-5.md) still governs how the app looks.

**Guardrails.** Fixes found in the beta keep Phase 4's guardrails and Phase 5's look. Every new build raises `CURRENT_PROJECT_VERSION` in `project.yml` and keeps `MARKETING_VERSION` at `1.0.0` unless the owner decides otherwise. Uploads and anything that costs money need the owner's approval, as `CLAUDE.md` says.

## Phases

### 6A. Internal round

- [ ] **Owner:** internal TestFlight group for the team, on build 3 or later
- [ ] The team uses it for a week on Roosevelt Island
- [ ] Fix crashes (Xcode Organizer) and blockers; each fix ships as a new build
- [ ] Cold-start plan: team members post real requests in the pilot area so the first users see activity

**Done when:** a week of team use with no open crash and no open blocker.

### 6B. External beta

- [ ] **Owner, $25/month:** upgrade Supabase to Pro before external testers join (see *Costs* in [PLAN-PHASE-4.md](PLAN-PHASE-4.md))
- [ ] **Owner:** external TestFlight group (Beta App Review, about a day), 20–50 neighbors, two weeks
- [ ] "What to Test" notes for each build
- [ ] Feedback through TestFlight, read at least every other day

**Done when:** the external beta ran for two weeks.

### 6C. Triage and the launch candidate

- [ ] Triage list in `docs/PROGRESS.md`: every report gets a severity, and "launch blocker" marks what must be fixed before 4H
- [ ] Fix everything marked "launch blocker"; upload the build that 4H submits

**Done when:** no open launch blockers and no crash affecting more than one tester; the privacy policy, terms and support pages are live. Then start 4H.
