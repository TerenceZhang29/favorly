-- Every change a client makes goes through one of these functions, which apply the same rules as FavorlyCore.
-- Errors are raised with SQLSTATE P0001 and a fixed message the app maps to FavorlyError:
--   not_signed_in, not_found, already_claimed, cannot_claim_own_request, not_allowed, invalid_transition,
--   validation (the user-facing text is in DETAIL), already_reviewed, rate_limited, blocked.

-- Only raises, so it is safe to call from read-only (stable) functions; never immutable, which could be folded early.
create function private.fail(code text, detail text default '')
returns void
language plpgsql
stable
as $$
begin
    raise exception using errcode = 'P0001', message = code, detail = detail;
end;
$$;

-- The signed-in user, who must have finished their profile.
create function private.require_profile()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    uid uuid := auth.uid();
begin
    if uid is null or not exists (select 1 from public.profiles where id = uid) then
        perform private.fail('not_signed_in');
    end if;
    return uid;
end;
$$;

-- The Terms of Use version the app shows (ProfileSetupRules.termsVersion).
create function private.terms_version()
returns integer
language sql
immutable
as $$ select 1 $$;

-- Rounds a coordinate to 3 decimal places, about 100 m.
create function private.snap(coordinate double precision)
returns double precision
language sql
immutable
as $$ select round(coordinate::numeric, 3)::double precision $$;

-- MARK: Profiles

-- Finishes sign-up (ProfileSetupRules), or changes the name later.
create function public.complete_profile(
    display_name text,
    confirmed_adult boolean,
    accepted_terms_version integer
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := auth.uid();
    name text := btrim(coalesce(display_name, ''), E' \t\n\r');
    result public.profiles;
begin
    if uid is null then
        perform private.fail('not_signed_in');
    end if;
    if char_length(name) < 2 then
        perform private.fail('validation', 'Name must be at least 2 characters.');
    end if;
    if char_length(name) > 30 then
        perform private.fail('validation', 'Name must be 30 characters or fewer.');
    end if;
    if not coalesce(confirmed_adult, false) then
        perform private.fail('validation', 'You must be 18 or older to use Favorly.');
    end if;
    if coalesce(accepted_terms_version, 0) < private.terms_version() then
        perform private.fail('validation', 'Please accept the Terms of Use and Privacy Policy.');
    end if;

    insert into public.profiles (id, display_name, confirmed_adult, accepted_terms_version)
    values (uid, name, true, accepted_terms_version)
    on conflict (id) do update
        set display_name = excluded.display_name,
            accepted_terms_version = excluded.accepted_terms_version
    returning * into result;
    return result;
end;
$$;

-- MARK: Requests

-- Open requests within the radius, nearest first, then newest (MockRequestRepository.nearby).
-- Runs as the caller, so row-level security hides blocked people's requests.
create function public.nearby_requests(
    center_latitude double precision,
    center_longitude double precision,
    radius_m double precision
)
returns table (
    id uuid,
    title text,
    details text,
    category public.request_category,
    latitude double precision,
    longitude double precision,
    location_label text,
    requester_id uuid,
    helper_id uuid,
    status public.request_status,
    created_at timestamptz,
    claimed_at timestamptz,
    distance_m double precision
)
language plpgsql
stable
set search_path = ''
as $$
#variable_conflict use_column
declare
    here extensions.geography := extensions.st_setsrid(
        extensions.st_makepoint(center_longitude, center_latitude), 4326
    )::extensions.geography;
    radius double precision := least(greatest(coalesce(radius_m, 0), 0), 50000);
begin
    perform private.require_profile();
    return query
    select r.id, r.title, r.details, r.category, r.latitude, r.longitude, r.location_label,
           r.requester_id, r.helper_id, r.status, r.created_at, r.claimed_at,
           extensions.st_distance(r.location, here) as distance_m
    from public.requests r
    where r.status = 'open'
      and extensions.st_dwithin(r.location, here, radius)
    order by distance_m, r.created_at desc;
end;
$$;

-- Posts a request (DraftValidator), with the location snapped to about 100 m.
-- At most 5 open requests per user and 20 new ones a day.
create function public.create_request(
    title text,
    details text,
    category public.request_category,
    latitude double precision,
    longitude double precision,
    location_label text
)
returns public.requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    clean_title text := btrim(coalesce(title, ''), E' \t\n\r');
    clean_details text := btrim(coalesce(details, ''), E' \t\n\r');
    clean_label text := btrim(coalesce(location_label, ''), E' \t\n\r');
    result public.requests;
begin
    if char_length(clean_title) < 3 then
        perform private.fail('validation', 'Title must be at least 3 characters.');
    end if;
    if char_length(clean_title) > 80 then
        perform private.fail('validation', 'Title must be 80 characters or fewer.');
    end if;
    if char_length(clean_details) > 500 then
        perform private.fail('validation', 'Details must be 500 characters or fewer.');
    end if;
    if category is null or char_length(clean_label) not between 1 and 80
        or latitude is null or longitude is null
        or latitude not between -90 and 90 or longitude not between -180 and 180 then
        perform private.fail('validation', 'This request is missing its location.');
    end if;
    if (select count(*) from public.requests r where r.requester_id = uid and r.status = 'open') >= 5
        or (select count(*) from public.requests r
            where r.requester_id = uid and r.created_at > now() - interval '1 day') >= 20 then
        perform private.fail('rate_limited');
    end if;

    insert into public.requests (title, details, category, latitude, longitude, location_label, requester_id)
    values (clean_title, clean_details, category, private.snap(latitude), private.snap(longitude), clean_label, uid)
    returning * into result;
    return result;
end;
$$;

-- Picks up an open request (RequestRules.validateClaim). Locks the row, so two claims cannot both succeed.
create function public.claim_request(request_id uuid)
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
        perform private.fail('invalid_transition');
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

-- Only the requester cancels, an open or picked-up request (RequestRules.validateCancel).
create function public.cancel_request(request_id uuid)
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
        perform private.fail('invalid_transition');
    end if;

    update public.requests r set status = 'cancelled' where r.id = target.id returning * into target;
    return target;
end;
$$;

-- Only the requester completes a picked-up request (rule 15, RequestRules.validateComplete).
create function public.complete_request(request_id uuid)
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
        perform private.fail('invalid_transition');
    end if;

    update public.requests r set status = 'completed' where r.id = target.id returning * into target;
    return target;
end;
$$;

-- MARK: Chat

-- Sends a message while the request is picked up (ChatRules.validateSend). At most 30 a minute.
create function public.send_message(request_id uuid, text text)
returns public.messages
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
    clean_text text := btrim(coalesce(send_message.text, ''), E' \t\n\r');
    result public.messages;
begin
    select * into target from public.requests r where r.id = send_message.request_id;
    if not found then
        perform private.fail('not_found');
    end if;
    if target.helper_id is null or uid not in (target.requester_id, target.helper_id)
        or target.status <> 'claimed' then
        perform private.fail('not_allowed');
    end if;
    if private.is_blocked_between(target.requester_id, target.helper_id) then
        perform private.fail('blocked');
    end if;
    if char_length(clean_text) < 1 then
        perform private.fail('validation', 'Message can''t be empty.');
    end if;
    if char_length(clean_text) > 500 then
        perform private.fail('validation', 'Message must be 500 characters or fewer.');
    end if;
    if (select count(*) from public.messages m
        where m.sender_id = uid and m.sent_at > now() - interval '1 minute') >= 30 then
        perform private.fail('rate_limited');
    end if;

    insert into public.messages (request_id, sender_id, text)
    values (target.id, uid, clean_text)
    returning * into result;
    return result;
end;
$$;

-- MARK: Reviews and Kindness

-- The requester reviews the helper of a completed request, once (ReviewRules).
create function public.submit_review(request_id uuid, rating integer, comment text)
returns public.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    target public.requests;
    clean_comment text := btrim(coalesce(submit_review.comment, ''), E' \t\n\r');
    result public.reviews;
begin
    select * into target from public.requests r where r.id = submit_review.request_id for update;
    if not found then
        perform private.fail('not_found');
    end if;
    if target.requester_id is distinct from uid or target.status <> 'completed' or target.helper_id is null then
        perform private.fail('not_allowed');
    end if;
    if exists (select 1 from public.reviews v where v.request_id = target.id) then
        perform private.fail('already_reviewed');
    end if;
    if submit_review.rating is null or submit_review.rating not between 1 and 5 then
        perform private.fail('validation', 'Choose a rating from 1 to 5 stars.');
    end if;
    if char_length(clean_comment) > 300 then
        perform private.fail('validation', 'Comment must be 300 characters or fewer.');
    end if;

    insert into public.reviews (request_id, reviewer_id, reviewee_id, rating, comment)
    values (target.id, uid, target.helper_id, submit_review.rating, clean_comment)
    returning * into result;
    return result;
end;
$$;

-- A user's Kindness score (KindnessRules.summary): 10 points per completed favor as helper, 2 per review star.
-- Computed every time; nothing stores a running total the app could change.
create function public.kindness_summary(user_id uuid)
returns table (completed_favors integer, review_count integer, average_rating double precision, lifetime_points integer)
language sql
stable
security definer
set search_path = ''
as $$
    with favors as (
        select r.id from public.requests r
        where r.helper_id = kindness_summary.user_id and r.status = 'completed'
    ),
    ratings as (
        select v.rating from public.reviews v join favors f on f.id = v.request_id
    )
    select
        (select count(*) from favors)::integer,
        (select count(*) from ratings)::integer,
        (select avg(rating) from ratings)::double precision,
        ((select count(*) from favors) * 10 + coalesce((select sum(rating) from ratings), 0) * 2)::integer;
$$;

-- MARK: Trust and safety

create function public.report(
    target_type public.report_target,
    target_id uuid,
    reason public.report_reason,
    note text default ''
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
    clean_note text := btrim(coalesce(report.note, ''), E' \t\n\r');
    result uuid;
begin
    if report.target_type is null or report.reason is null
        or (report.target_type = 'request' and not exists (select 1 from public.requests r where r.id = report.target_id))
        or (report.target_type = 'message' and not exists (select 1 from public.messages m where m.id = report.target_id))
        or (report.target_type = 'user' and not exists (select 1 from public.profiles p where p.id = report.target_id)) then
        perform private.fail('not_found');
    end if;
    if report.target_type = 'user' and report.target_id = uid then
        perform private.fail('not_allowed');
    end if;
    if char_length(clean_note) > 500 then
        perform private.fail('validation', 'Note must be 500 characters or fewer.');
    end if;

    insert into public.reports (reporter_id, target_type, target_id, reason, note)
    values (uid, report.target_type, report.target_id, report.reason, clean_note)
    returning id into result;
    return result;
end;
$$;

create function public.block_user(user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
begin
    if block_user.user_id = uid then
        perform private.fail('not_allowed');
    end if;
    if not exists (select 1 from public.profiles p where p.id = block_user.user_id) then
        perform private.fail('not_found');
    end if;
    insert into public.blocks (blocker_id, blocked_id) values (uid, block_user.user_id) on conflict do nothing;
end;
$$;

create function public.unblock_user(user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
begin
    delete from public.blocks b where b.blocker_id = uid and b.blocked_id = unblock_user.user_id;
end;
$$;

-- MARK: Account deletion

-- Deletes the signed-in account (guideline 5.1.1(v)). Deleted: the profile, every request they posted that is
-- not completed, the messages and reviews they wrote, reviews about them, their blocks. A request they had
-- picked up goes back to open. Completed favors stay, with the deleted person's side left empty.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := auth.uid();
begin
    if uid is null then
        perform private.fail('not_signed_in');
    end if;

    delete from public.requests r where r.requester_id = uid and r.status <> 'completed';
    delete from public.messages m
    where m.request_id in (select r.id from public.requests r where r.helper_id = uid and r.status = 'claimed');
    update public.requests r
    set helper_id = null, status = 'open', claimed_at = null
    where r.helper_id = uid and r.status = 'claimed';

    -- Cascades to the profile, and from it to messages, reviews and blocks; completed requests keep a null side.
    delete from auth.users u where u.id = uid;
end;
$$;

-- MARK: Who may call what

revoke execute on all functions in schema public from public, anon;
grant execute on function
    public.complete_profile(text, boolean, integer),
    public.nearby_requests(double precision, double precision, double precision),
    public.create_request(text, text, public.request_category, double precision, double precision, text),
    public.claim_request(uuid),
    public.cancel_request(uuid),
    public.complete_request(uuid),
    public.send_message(uuid, text),
    public.submit_review(uuid, integer, text),
    public.kindness_summary(uuid),
    public.report(public.report_target, uuid, public.report_reason, text),
    public.block_user(uuid),
    public.unblock_user(uuid),
    public.delete_my_account()
to authenticated;

revoke execute on all functions in schema private from public, anon;
grant execute on function private.fail(text, text), private.require_profile(), private.terms_version(),
    private.snap(double precision), private.is_blocked_between(uuid, uuid)
to authenticated;
