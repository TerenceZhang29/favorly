# Favorly backend

The server for Favorly: a Supabase project (Postgres with PostGIS, auth, realtime). Everything here runs locally in Docker; nothing in this folder creates or changes a hosted project. The plan is in [docs/PLAN-PHASE-4.md](../docs/PLAN-PHASE-4.md), phase 4B.

## Prerequisites

- Docker Desktop, running
- The Supabase CLI: `brew install supabase/tap/supabase`

## Commands

Run from this folder (`backend/`).

```bash
supabase start        # start the local stack in Docker (the first run downloads images)
supabase test db      # run the database tests in supabase/tests (pgTAP)
supabase db reset     # rebuild the local database from the migrations
supabase db lint --level warning --schema public,private
supabase status       # local URLs and keys
supabase stop         # stop the containers; data is kept until the next reset
```

The tests always run against the local database, which is rebuilt from the same migrations the hosted project gets. Never run them against the hosted project (`supabase test db --linked`): they create users directly and act as an admin. GitHub Actions runs them, with the lint, on every push that changes `backend/` (`.github/workflows/backend.yml`).

The local ports are moved up by 1000 from Supabase's defaults (API on 55321, database on 55322, Studio on 55323), so this project can run next to another local Supabase project.

Deploying to the hosted project is phase 4B's last step and needs the owner's approval first (see `PENDING_APPROVALS.md` if it exists, and the cost rule in `CLAUDE.md`).

## Layout

| Path | What it holds |
| --- | --- |
| `supabase/config.toml` | Local stack settings (ports, enabled services) |
| `supabase/migrations/` | The schema, in order: tables, read access, actions, auto-complete |
| `supabase/tests/` | pgTAP tests, one file per area; `helpers.psql` is included by each |
| `supabase/seed.sql` | Local seed data (empty: tests create their own users) |

## How it works

- **Reads** go straight to tables, filtered by row-level security: your own requests always; anyone else's unless cancelled or blocked; a thread only for its requester and helper; reports never.
- **Writes** only go through functions (`complete_profile`, `create_request`, `claim_request`, `cancel_request`, `complete_request`, `send_message`, `submit_review`, `report`, `block_user`, `unblock_user`, `delete_my_account`). They apply the same rules as `FavorlyCore`, so the app's copy decides which buttons to show and the server's copy is the truth. Clients cannot insert, update or delete rows directly.
- **Nearby** is `nearby_requests(center_latitude, center_longitude, radius_m)`: open requests within the radius, nearest first, then newest, with `distance_m`.
- **Kindness score** is `kindness_summary(user_id)`, computed from completed favors and review stars every time it is asked for.
- **Locations** are snapped to 3 decimal places (about 100 m) before they are stored.
- **Auto-complete** (rule 15): a `pg_cron` job runs `private.complete_due_requests()` every 15 minutes and completes picked-up requests 7 days after pick-up.
- **Rate limits**: at most 5 open requests per user, 20 new requests a day, and 30 messages a minute.
- **Blocks** hide profiles, requests and reviews in both directions, and stop pick-ups and messages between the two people.
- **Account deletion** (`delete_my_account`) removes the profile, every request the user posted that is not completed, the messages and reviews they wrote, reviews about them, and their blocks. A request they had picked up goes back to open with its thread cleared. Completed favors stay, with the deleted person's side left empty.

## Error contract

Every refused action raises SQLSTATE `P0001` with one of these messages. Phase 4C maps them to `FavorlyError`.

| Message | `FavorlyError` | When |
| --- | --- | --- |
| `not_signed_in` | `.notSignedIn` | No session, or the profile is not finished |
| `not_found` | `.notFound` | The request, message or user does not exist |
| `already_claimed` | `.alreadyClaimed` | Someone else picked it up first |
| `cannot_claim_own_request` | `.cannotClaimOwnRequest` | Picking up your own request |
| `not_allowed` | `.notAllowed` | Not the requester or helper the rule needs |
| `invalid_transition` | `.invalidTransition` | The status does not allow it any more |
| `validation` | `.validation(detail)` | The user-facing text is in the error's DETAIL, word for word what the app shows |
| `already_reviewed` | `.alreadyReviewed` | The favor already has a review |
| `rate_limited` | `.rateLimited` | Over one of the rate limits |
| `blocked` | `.blocked` | One of the two people blocked the other |

Calls with the anonymous key, or direct writes to tables, fail with SQLSTATE `42501` (permission denied).
