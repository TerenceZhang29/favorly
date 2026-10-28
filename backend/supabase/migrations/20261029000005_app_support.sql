-- Support for the app's remote data layer (phase 4C).

-- invalid_transition now carries the request's current status in DETAIL, so the app can build
-- FavorlyError.invalidTransition(from:to:). The functions are otherwise unchanged from 20261028000003.

create or replace function public.claim_request(request_id uuid)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
begin
    select * into target from public.requests r where r.id = claim_request.request_id for update;
    if not found then
        perform private.fail('not_found');
    end if;
    if target.requester_id = uid then
        perform private.fail('cannot_claim_own_request');
    end if;
    if target.status = 'claimed' then
        perform private.fail('already_claimed');
    end if;
    if target.status <> 'open' then
        perform private.fail('invalid_transition', target.status::text);
    end if;
    if private.is_blocked_between(uid, target.requester_id) then
        perform private.fail('blocked');
    end if;

    update public.requests r
    set helper_id = uid, status = 'claimed', claimed_at = now()
    where r.id = target.id
    returning * into target;
    return target;
end;
$$;

create or replace function public.cancel_request(request_id uuid)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
begin
    select * into target from public.requests r where r.id = cancel_request.request_id for update;
    if not found then
        perform private.fail('not_found');
    end if;
    if target.requester_id is distinct from uid then
        perform private.fail('not_allowed');
    end if;
    if target.status not in ('open', 'claimed') then
        perform private.fail('invalid_transition', target.status::text);
    end if;

    update public.requests r set status = 'cancelled' where r.id = target.id returning * into target;
    return target;
end;
$$;

create or replace function public.complete_request(request_id uuid)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
begin
    select * into target from public.requests r where r.id = complete_request.request_id for update;
    if not found then
        perform private.fail('not_found');
    end if;
    if target.requester_id is distinct from uid then
        perform private.fail('not_allowed');
    end if;
    if target.status <> 'claimed' then
        perform private.fail('invalid_transition', target.status::text);
    end if;

    update public.requests r set status = 'completed' where r.id = target.id returning * into target;
    return target;
end;
$$;

-- Realtime: open screens refresh when someone else changes a request, sends a message or leaves a review.
-- Realtime applies the same row-level security as reads, so nobody receives rows they cannot see.
alter publication supabase_realtime add table public.requests, public.messages, public.reviews;
