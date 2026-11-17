-- Request views (post-1.0 metrics): who has opened a request's detail screen, once per person and request,
-- so docs/METRICS.md can tell a request nobody saw from one people saw and passed on. Recorded only;
-- the app shows view counts to nobody. The requester's own views don't count.

create table public.request_views (
    request_id uuid not null references public.requests (id) on delete cascade,
    viewer_id uuid not null references public.profiles (id) on delete cascade,
    first_viewed_at timestamptz not null default now(),
    primary key (request_id, viewer_id)
);

create index request_views_viewer_idx on public.request_views (viewer_id);

-- No policies and no grants: clients can neither read nor write the table; only record_request_view writes it.
alter table public.request_views enable row level security;
revoke all on public.request_views from public, anon, authenticated;

-- Records that the signed-in person opened a request (RequestRepository.recordView). Counted once per person
-- and request; the requester, a cancelled request and a request between blocked people are skipped silently,
-- since the app calls this in the background and never shows an error for it.
create function public.record_request_view(request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
begin
    select * into target from public.requests r where r.id = record_request_view.request_id;
    if not found
        or target.requester_id is not distinct from uid
        or target.status = 'cancelled'
        or private.is_blocked_between(uid, target.requester_id) then
        return;
    end if;
    insert into public.request_views (request_id, viewer_id)
    values (target.id, uid)
    on conflict do nothing;
end;
$$;

revoke execute on function public.record_request_view(uuid) from public, anon;
grant execute on function public.record_request_view(uuid) to authenticated;
