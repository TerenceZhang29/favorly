-- Who can read what. Nobody writes tables directly; the actions in 20261028000003_actions.sql do.

-- True when either user has blocked the other. Blocks hide content both ways.
create function private.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.blocks
        where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
    );
$$;

grant usage on schema private to authenticated;
revoke all on function private.is_blocked_between(uuid, uuid) from public;
grant execute on function private.is_blocked_between(uuid, uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.requests enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.reports enable row level security;
alter table public.blocks enable row level security;

-- Signed-in users only; the anonymous key reads nothing.
revoke all on all tables in schema public from anon;
revoke insert, update, delete, truncate on all tables in schema public from authenticated;
grant select on all tables in schema public to authenticated;

create policy "Profiles are visible unless blocked"
on public.profiles for select to authenticated
using (not private.is_blocked_between((select auth.uid()), id));

-- Your own requests always; anyone else's unless cancelled or blocked.
create policy "Requests are visible to their people, or when not cancelled"
on public.requests for select to authenticated
using (
    requester_id = (select auth.uid())
    or helper_id = (select auth.uid())
    or (
        status <> 'cancelled'
        and not private.is_blocked_between((select auth.uid()), requester_id)
        and not private.is_blocked_between((select auth.uid()), helper_id)
    )
);

-- Only the requester and the helper read a thread (ChatRules.validateRead).
create policy "Messages are visible to the requester and helper"
on public.messages for select to authenticated
using (
    exists (
        select 1 from public.requests r
        where r.id = request_id
          and r.helper_id is not null
          and (r.requester_id = (select auth.uid()) or r.helper_id = (select auth.uid()))
    )
);

create policy "Reviews are visible unless blocked"
on public.reviews for select to authenticated
using (
    not private.is_blocked_between((select auth.uid()), reviewer_id)
    and not private.is_blocked_between((select auth.uid()), reviewee_id)
);

-- Reports have no select policy: only moderators read them, in the dashboard.

create policy "You see the people you blocked"
on public.blocks for select to authenticated
using (blocker_id = (select auth.uid()));
