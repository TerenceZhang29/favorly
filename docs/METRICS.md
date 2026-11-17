# Favorly metrics

What we measure during the public beta (Phase 6) and after launch, and the SQL that measures it. Every metric here comes from the tables the app writes for its own work, plus one table kept only for metrics: `request_views`, which records who opened a request (metric 15). No analytics SDK is used. Views are declared as Product Interaction in the App Privacy answers (`docs/release/app-privacy.md`), `PrivacyInfo.xcprivacy` and the privacy policy.

## How to run the queries

1. Supabase dashboard → project **favorly** → **SQL Editor**. The editor runs as the admin role, past row-level security.
2. Paste a query, run it, and save the ones you use weekly (for example "Metrics 1 – weekly favors").
3. Weeks start on Monday in New York time. Most queries look back 8 weeks; change the interval to look further.

To try a query without touching real data, run it against the local stack (`cd backend && supabase start`, then Studio on http://localhost:55323).

## The dashboard

The private **Favorly Metrics** dashboard (https://claude.ai/artifact/M9ssJ1ysAZ11EraV3a7FPg) shows these metrics from a snapshot file. It never connects to the database, so it changes only when the snapshot is refreshed:

1. `scripts/refresh-metrics.sh` runs every query below on the hosted project (read-only, free) and writes `build/metrics/favorly-metrics.json`. Add `--local` to try it on the local stack.
2. In a Claude Code session in this repo, ask Claude to "refresh the metrics dashboard". It runs the script, uploads the file and points the dashboard at it.

The script finds each query by the `<!-- dataset: <id> -->` line above its SQL block; the id is the dashboard's name for that source. A new metric needs that line, a unique id, and a section on the dashboard.

**Privacy.** The queries return counts, rates and times, never names or message text. Keep it that way: don't add `display_name`, `title`, `details`, `text` or `comment` to a metrics query, and don't export rows about single people. See the Privacy section of `docs/MODERATION.md`.

**Small numbers.** With a beta group of a few dozen people, one person changes a rate by several points. Read the counts next to every percentage, and look at the actual unclaimed requests before drawing conclusions.

## The metrics

| # | Metric | Question it answers | Watch for |
| --- | --- | --- | --- |
| 1 | Completed favors per week, per neighborhood | Are neighbors actually helping each other? (main metric) | Growth week over week |
| 2 | Request funnel | Where do requests drop out: unclaimed, cancelled, or never completed? | Claim rate under 50% |
| 3 | Time to claim | How long does someone wait for help? | Median over a few hours |
| 4 | Dead requests by category | Which kinds of favors nobody picks up? | One category far worse than the rest |
| 5 | Posters vs. helpers | Do we have enough helpers for the askers? | Far more posters than helpers |
| 6 | Supply and demand by neighborhood | Which neighborhoods are short of helpers? | Many open requests per helper |
| 7 | Activation | Do new people do something in their first week? | Under a third activating |
| 8 | Weekly retention | Do people come back? | Week 2 retention falling cohort to cohort |
| 9 | Repeat helpers | Does helping once lead to helping again? | Few helpers with 2+ favors |
| 10 | Chat and completion | Does messaging help a favor happen? | Long first replies; chats without completion |
| 11 | Trust and safety | Is the community safe, and are reports handled fast? | Reports waiting over 24 h |
| 12 | Reviews | Are favors going well, and are people leaving reviews? | Ratings of 1–2 stars |
| 13 | Notifications | Can we reach people, and does push delivery work? | Opt-in under half; stuck notifications |
| 14 | App health | Does the app crash? | Any crash affecting more than one tester |
| 15 | Views | Do requests reach people, and do people who see them help? | Many requests with no viewers; many viewers and no pick-up |

Definitions used throughout:

- A request is **claimed** when `claimed_at` is set. A request cancelled after pick-up keeps `claimed_at`, so it counts as claimed and then cancelled.
- A person is **active** in a period when they posted a request, picked one up, sent a message or wrote a review in it.
- A request's **neighborhood** is its `location_label`.

## 1. Completed favors per week, per neighborhood

The main metric. Grouped by the week the request was posted, because the table records no completion time (see *Gaps*). Recent weeks keep rising as their requests complete.

<!-- dataset: favors-by-neighborhood -->
```sql
select
    date_trunc('week', r.created_at at time zone 'America/New_York')::date as week,
    r.location_label as neighborhood,
    count(*) filter (where r.status = 'completed') as completed,
    count(*) as posted
from public.requests r
where r.created_at >= now() - interval '8 weeks'
group by 1, 2
order by week desc, completed desc;
```

## 2. Request funnel

Of the requests posted each week, how many were picked up, completed, cancelled, or are still open.

<!-- dataset: funnel -->
```sql
select
    week,
    posted,
    claimed,
    completed,
    cancelled,
    still_open,
    round(100.0 * claimed / nullif(posted, 0), 1) as claim_rate_pct,
    round(100.0 * completed / nullif(claimed, 0), 1) as completion_rate_pct
from (
    select
        date_trunc('week', r.created_at at time zone 'America/New_York')::date as week,
        count(*) as posted,
        count(*) filter (where r.claimed_at is not null) as claimed,
        count(*) filter (where r.status = 'completed') as completed,
        count(*) filter (where r.status = 'cancelled') as cancelled,
        count(*) filter (where r.status = 'open') as still_open
    from public.requests r
    where r.created_at >= now() - interval '8 weeks'
    group by 1
) w
order by week desc;
```

## 3. Time to claim

Minutes from posting to pick-up, by category, over the last 4 weeks. The median is the typical wait; the 90th percentile is the slow tail.

<!-- dataset: time-to-claim -->
```sql
select
    r.category,
    count(*) as claimed,
    round((percentile_cont(0.5) within group (
        order by extract(epoch from r.claimed_at - r.created_at) / 60))::numeric, 0) as median_minutes,
    round((percentile_cont(0.9) within group (
        order by extract(epoch from r.claimed_at - r.created_at) / 60))::numeric, 0) as p90_minutes
from public.requests r
where r.claimed_at is not null
  and r.created_at >= now() - interval '4 weeks'
group by r.category
order by median_minutes;
```

## 4. Dead requests by category

Requests that never got help: cancelled before anyone picked them up, or still open after 24 hours. Requests posted in the last 24 hours are left out because they still have a chance.

<!-- dataset: dead-requests -->
```sql
select
    r.category,
    count(*) as posted,
    count(*) filter (where r.status = 'cancelled' and r.claimed_at is null) as cancelled_unclaimed,
    count(*) filter (where r.status = 'open') as open_over_24h,
    round(100.0 * count(*) filter (
        where r.claimed_at is null and r.status in ('cancelled', 'open')) / count(*), 1) as dead_pct
from public.requests r
where r.created_at >= now() - interval '4 weeks'
  and r.created_at < now() - interval '24 hours'
group by r.category
order by dead_pct desc;
```

## 5. Posters vs. helpers

Everyone active in the last 28 days by role: only posts, only helps, or both.

<!-- dataset: posters-helpers -->
```sql
with recent as (
    select r.requester_id as user_id, 'posted' as role
    from public.requests r
    where r.created_at >= now() - interval '28 days' and r.requester_id is not null
    union all
    select r.helper_id, 'helped'
    from public.requests r
    where r.claimed_at >= now() - interval '28 days' and r.helper_id is not null
),
per_user as (
    select
        user_id,
        bool_or(role = 'posted') as posted,
        bool_or(role = 'helped') as helped
    from recent
    group by user_id
)
select
    case
        when posted and helped then 'both'
        when posted then 'posts only'
        else 'helps only'
    end as kind,
    count(*) as people
from per_user
group by 1
order by people desc;
```

## 6. Supply and demand by neighborhood

Open requests right now next to the helpers who picked something up in that neighborhood in the last 28 days. Many open requests per helper means requests go unanswered; very few means helpers have nothing to do.

<!-- dataset: supply-demand -->
```sql
with open_now as (
    select r.location_label as neighborhood, count(*) as open_requests
    from public.requests r
    where r.status = 'open'
    group by 1
),
helpers as (
    select r.location_label as neighborhood, count(distinct r.helper_id) as active_helpers
    from public.requests r
    where r.claimed_at >= now() - interval '28 days' and r.helper_id is not null
    group by 1
)
select
    coalesce(o.neighborhood, h.neighborhood) as neighborhood,
    coalesce(o.open_requests, 0) as open_requests,
    coalesce(h.active_helpers, 0) as active_helpers,
    round(coalesce(o.open_requests, 0)::numeric / nullif(h.active_helpers, 0), 1) as open_per_helper
from open_now o
full join helpers h on h.neighborhood = o.neighborhood
order by open_requests desc;
```

## 7. Activation

Of the people who finished sign-up each week, how many posted or picked up a request within 7 days. Accounts younger than 7 days are left out.

<!-- dataset: activation -->
```sql
with first_action as (
    select user_id, min(at) as first_at
    from (
        select r.requester_id as user_id, r.created_at as at from public.requests r
        union all
        select r.helper_id, r.claimed_at from public.requests r where r.claimed_at is not null
    ) a
    where user_id is not null
    group by user_id
)
select
    date_trunc('week', p.created_at at time zone 'America/New_York')::date as signup_week,
    count(*) as signed_up,
    count(*) filter (where f.first_at < p.created_at + interval '7 days') as activated,
    round(100.0 * count(*) filter (where f.first_at < p.created_at + interval '7 days') / count(*), 1)
        as activation_pct
from public.profiles p
left join first_action f on f.user_id = p.id
where p.created_at < now() - interval '7 days'
group by 1
order by signup_week desc;
```

## 8. Weekly retention

People grouped by sign-up week. Week 1 is days 7–13 after sign-up, week 2 is days 14–20. A person retains when they are active in that window. A cohort's columns stay empty until the window has passed.

<!-- dataset: retention -->
```sql
with activity as (
    select r.requester_id as user_id, r.created_at as at from public.requests r
    union all
    select r.helper_id, r.claimed_at from public.requests r where r.claimed_at is not null
    union all
    select m.sender_id, m.sent_at from public.messages m
    union all
    select v.reviewer_id, v.created_at from public.reviews v
)
select
    date_trunc('week', p.created_at at time zone 'America/New_York')::date as signup_week,
    count(*) as signed_up,
    case when max(p.created_at) < now() - interval '14 days' then round(100.0 * count(*) filter (
        where exists (select 1 from activity a where a.user_id = p.id
            and a.at >= p.created_at + interval '7 days' and a.at < p.created_at + interval '14 days'))
        / count(*), 1) end as week1_pct,
    case when max(p.created_at) < now() - interval '21 days' then round(100.0 * count(*) filter (
        where exists (select 1 from activity a where a.user_id = p.id
            and a.at >= p.created_at + interval '14 days' and a.at < p.created_at + interval '21 days'))
        / count(*), 1) end as week2_pct
from public.profiles p
group by 1
order by signup_week desc;
```

## 9. Repeat helpers

How many helpers have completed one favor, two, three, and so on. A long tail of one-time helpers means helping isn't becoming a habit.

<!-- dataset: repeat-helpers -->
```sql
select favors_completed, count(*) as helpers
from (
    select r.helper_id, count(*) as favors_completed
    from public.requests r
    where r.status = 'completed' and r.helper_id is not null
    group by r.helper_id
) h
group by favors_completed
order by favors_completed;
```

## 10. Chat and completion

For requests picked up in the last 8 weeks: how many had a conversation, how fast the other person first replied, and whether chats come before completed favors.

<!-- dataset: chat -->
```sql
with picked_up as (
    select r.id, r.status
    from public.requests r
    where r.claimed_at >= now() - interval '8 weeks'
),
chats as (
    select
        m.request_id,
        count(*) as messages,
        min(m.sent_at) as first_at,
        (array_agg(m.sender_id order by m.sent_at))[1] as first_sender
    from public.messages m
    group by m.request_id
),
first_reply as (
    select c.request_id, min(m.sent_at) - c.first_at as wait
    from chats c
    join public.messages m on m.request_id = c.request_id and m.sender_id <> c.first_sender
    group by c.request_id, c.first_at
)
select
    (c.request_id is not null) as had_chat,
    count(*) as requests,
    round(avg(c.messages), 1) as avg_messages,
    round((percentile_cont(0.5) within group (order by extract(epoch from f.wait) / 60))::numeric, 0)
        as median_first_reply_minutes,
    round(100.0 * count(*) filter (where p.status = 'completed') / count(*), 1) as completed_pct
from picked_up p
left join chats c on c.request_id = p.id
left join first_reply f on f.request_id = p.id
group by 1
order by 1 desc;
```

## 11. Trust and safety

Reports and blocks per 100 requests posted, by week, and how long reports waited before someone closed them.

<!-- dataset: safety-weekly -->
```sql
with weeks as (
    select generate_series(
        date_trunc('week', now() at time zone 'America/New_York') - interval '7 weeks',
        date_trunc('week', now() at time zone 'America/New_York'),
        interval '1 week')::date as week
),
requests as (
    select date_trunc('week', created_at at time zone 'America/New_York')::date as week, count(*) as n
    from public.requests group by 1
),
reports as (
    select
        date_trunc('week', created_at at time zone 'America/New_York')::date as week,
        count(*) as n,
        round((percentile_cont(0.5) within group (
            order by extract(epoch from resolved_at - created_at) / 3600))::numeric, 1) as median_hours_to_close,
        count(*) filter (where resolved_at is null) as still_open
    from public.reports group by 1
),
blocks as (
    select date_trunc('week', created_at at time zone 'America/New_York')::date as week, count(*) as n
    from public.blocks group by 1
)
select
    w.week,
    coalesce(q.n, 0) as requests_posted,
    coalesce(rp.n, 0) as reports,
    coalesce(b.n, 0) as blocks,
    round(100.0 * coalesce(rp.n, 0) / nullif(q.n, 0), 1) as reports_per_100_requests,
    rp.median_hours_to_close,
    coalesce(rp.still_open, 0) as reports_still_open
from weeks w
left join requests q using (week)
left join reports rp using (week)
left join blocks b using (week)
order by w.week desc;
```

The oldest open report, which must stay under 24 hours (see `docs/MODERATION.md`):

<!-- dataset: open-reports -->
```sql
select count(*) as open_reports, max(now() - created_at) as oldest_waiting
from public.reports
where resolved_at is null;
```

## 12. Reviews

The share of completed favors that got a review, and the spread of ratings, over the last 8 weeks.

<!-- dataset: reviews -->
```sql
select
    count(*) as completed,
    count(v.id) as reviewed,
    round(100.0 * count(v.id) / nullif(count(*), 0), 1) as reviewed_pct,
    round(avg(v.rating), 2) as avg_rating,
    count(*) filter (where v.rating = 5) as five,
    count(*) filter (where v.rating = 4) as four,
    count(*) filter (where v.rating = 3) as three,
    count(*) filter (where v.rating <= 2) as two_or_less
from public.requests r
left join public.reviews v on v.request_id = r.id
where r.status = 'completed'
  and r.created_at >= now() - interval '8 weeks';
```

## 13. Notifications

Push opt-in: the share of people who have a device token, which the app stores only after they allow notifications.

<!-- dataset: push-opt-in -->
```sql
select
    count(*) as people,
    count(*) filter (where exists (
        select 1 from public.device_tokens t where t.user_id = p.id)) as with_push,
    round(100.0 * count(*) filter (where exists (
        select 1 from public.device_tokens t where t.user_id = p.id)) / nullif(count(*), 0), 1) as push_opt_in_pct
from public.profiles p;
```

Delivery: notifications from the last 7 days, sent or stuck, and how many needed retries.

<!-- dataset: push-delivery -->
```sql
select
    p.opens,
    count(*) as queued,
    count(*) filter (where p.sent_at is not null) as sent,
    count(*) filter (where p.sent_at is null and p.created_at < now() - interval '10 minutes') as stuck,
    count(*) filter (where p.attempts > 1) as retried
from public.push_outbox p
where p.created_at >= now() - interval '7 days'
group by p.opens;
```

## 14. App health

Not in the database. Check these weekly:

- **Crashes:** Xcode → Window → Organizer → Crashes, and TestFlight feedback in App Store Connect. The beta's bar (`docs/PLAN-PHASE-6.md`): no crash affecting more than one tester.
- **Server errors and load:** Supabase dashboard → Logs (API and Postgres) and Reports, and usage against the free tier's limits.

## 15. Views

How many people opened each request, and whether requests that people saw got picked up. Grouped by how many people opened the request, for requests posted in the last 4 weeks. Only requests posted after the first recorded view count; older ones had no way to be viewed. A view is recorded once per person and request when someone opens Request Detail. The requester's own views, cancelled requests and blocked pairs don't count (`record_request_view`). Needs migration `20261116000012_request_views.sql` and an app version that records views; before that, the query fails or returns nothing.

<!-- dataset: views -->
```sql
with per_request as (
    select
        r.claimed_at is not null as picked_up,
        (select count(*) from public.request_views v where v.request_id = r.id) as viewers
    from public.requests r
    where r.created_at >= now() - interval '4 weeks'
      and r.created_at >= coalesce((select min(first_viewed_at) from public.request_views), now())
)
select
    case
        when viewers = 0 then '0'
        when viewers <= 2 then '1-2'
        when viewers <= 5 then '3-5'
        else '6+'
    end as viewers,
    count(*) as requests,
    count(*) filter (where picked_up) as picked_up,
    round(100.0 * count(*) filter (where picked_up) / count(*), 1) as picked_up_pct
from per_request
group by 1
order by min(viewers);
```

## Gaps

What these tables can't tell us yet, and the fix for each. None is needed to start; they are listed so a decision can be made with the owner.

| Gap | Effect | Fix |
| --- | --- | --- |
| No `completed_at` or `cancelled_at` on `requests` | Metric 1 groups by posting week, and time from pick-up to completion is unknown | Migration adding both columns, set by `complete_request`, `cancel_request` and `private.complete_due_requests()`. Needs a hosted deploy, with the owner's approval |
| No record of whether a favor was confirmed or auto-completed after 7 days | Can't tell a confirmed favor from a requester who never came back | A `completed_by` column (`'requester'` or `'auto'`) in the same migration |
| Offensive-word filter refusals aren't stored | Can't count filter hits | Store a count per day in a private table from `private.refuse_offensive_text`, with no text |
| Deleting an account removes that person's unfinished requests, messages and reviews | Past weeks can shrink a little after deletions | Accept for the beta; read past weeks as approximate |
| No other in-app events (app opens, screens, notification taps, posts started and abandoned); only request views are recorded | No session counts, no drop-off inside Post | A first-party `events` table or an analytics SDK. Either one changes the App Privacy answers and the privacy manifest; an SDK also needs a note in `docs/PROGRESS.md`. Skipped for the beta |
