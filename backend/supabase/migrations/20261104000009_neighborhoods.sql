-- Verified neighborhood and meeting spot (phase 4G). A request's neighborhood is no longer typed: it must be one
-- of the names neighborhoods_near gives for the request's point, taken from NYC's neighborhood boundaries (loaded
-- by the next migration). Free text moves to meeting_spot, which keeps the old typed tag's rules.

create table private.neighborhood_areas (
    nta_code text primary key,
    borough text not null,
    -- The NTA type: 0 residential, 6 other special areas, 8 airports, 9 parks.
    kind smallint not null,
    area extensions.geography (multipolygon, 4326) not null
);

create index neighborhood_areas_area_idx on private.neighborhood_areas using gist (area);

-- An area's name split into neighborhoods: "Upper East Side-Lenox Hill-Roosevelt Island" is three rows.
create table private.neighborhood_names (
    nta_code text not null references private.neighborhood_areas (nta_code) on delete cascade,
    name text not null,
    position smallint not null,
    primary key (nta_code, position)
);

-- The names around a point, after snapping it like create_request does: those of the area that contains it in
-- their listed order, then those of areas within 750 m, nearest first. At most 8, no repeats. Empty outside NYC.
create function private.neighborhood_choices(latitude double precision, longitude double precision)
returns setof text
language sql
stable
set search_path = ''
as $$
    with here as (
        select extensions.st_setsrid(
            extensions.st_makepoint(private.snap(longitude), private.snap(latitude)), 4326
        )::extensions.geography as point
    ),
    near as (
        select a.nta_code, extensions.st_distance(a.area, here.point) as distance
        from private.neighborhood_areas a, here
        where extensions.st_dwithin(a.area, here.point, 750)
    ),
    ranked as (
        select n.name, near.distance, n.position,
               row_number() over (partition by n.name order by near.distance, n.position) as copy
        from near join private.neighborhood_names n using (nta_code)
    )
    select ranked.name from ranked where copy = 1 order by distance, position, name limit 8;
$$;

-- What Post offers as the request's neighborhood (NeighborhoodDirectory).
create function public.neighborhoods_near(latitude double precision, longitude double precision)
returns setof text
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform private.require_profile();
    if latitude is null or longitude is null
        or latitude not between -90 and 90 or longitude not between -180 and 180 then
        perform private.fail('validation', 'This request is missing its location.');
    end if;
    return query select private.neighborhood_choices(latitude, longitude);
end;
$$;

-- The meeting spot: optional, at most 40 characters, letters, spaces and , . - ' ’ only (no digits, so no house or
-- unit numbers), like DraftValidator.validateMeetingSpot.
alter table public.requests add column meeting_spot text not null default '';

create function private.check_meeting_spot()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    spot text := btrim(coalesce(new.meeting_spot, ''), E' \t\n\r');
begin
    if char_length(spot) > 40 then
        perform private.fail('validation', 'Meeting spot must be 40 characters or fewer.');
    end if;
    if spot <> '' and spot !~ '^[[:alpha:] ,.''’-]+$' then
        perform private.fail('validation', 'Use only letters for the meeting spot, not a street address.');
    end if;
    new.meeting_spot := spot;
    return new;
end;
$$;

create trigger check_meeting_spot before insert or update of meeting_spot on public.requests
    for each row execute function private.check_meeting_spot();

drop trigger refuse_offensive_text on public.requests;
create trigger refuse_offensive_text before insert or update of title, details, location_label, meeting_spot
    on public.requests
    for each row execute function private.refuse_offensive_text('title', 'details', 'location_label', 'meeting_spot');

-- create_request gains meeting_spot (optional, so build 1.0.0 (1) keeps working) and checks the neighborhood.
drop function public.create_request(text, text, public.request_category, double precision, double precision, text);

create function public.create_request(
    title text,
    details text,
    category public.request_category,
    latitude double precision,
    longitude double precision,
    location_label text,
    meeting_spot text default ''
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
    choices text[];
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
    if category is null or latitude is null or longitude is null
        or latitude not between -90 and 90 or longitude not between -180 and 180 then
        perform private.fail('validation', 'This request is missing its location.');
    end if;
    if char_length(clean_label) = 0 then
        perform private.fail('validation', 'Add a neighborhood for your request.');
    end if;
    -- Outside the NYC areas there are no choices, and any label that passes check_location_label is kept.
    choices := array(select private.neighborhood_choices(latitude, longitude));
    if cardinality(choices) > 0 and not clean_label = any (choices) then
        perform private.fail('validation', 'Choose a neighborhood near you.');
    end if;
    if (select count(*) from public.requests r where r.requester_id = uid and r.status = 'open') >= 5
        or (select count(*) from public.requests r
            where r.requester_id = uid and r.created_at > now() - interval '1 day') >= 20 then
        perform private.fail('rate_limited');
    end if;

    insert into public.requests (
        title, details, category, latitude, longitude, location_label, meeting_spot, requester_id
    )
    values (
        clean_title, clean_details, category, private.snap(latitude), private.snap(longitude), clean_label,
        coalesce(meeting_spot, ''), uid
    )
    returning * into result;
    return result;
end;
$$;

-- nearby_requests returns the meeting spot too. Its row type changes, so it is dropped and created again.
drop function public.nearby_requests(double precision, double precision, double precision);

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
    meeting_spot text,
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
    select r.id, r.title, r.details, r.category, r.latitude, r.longitude, r.location_label, r.meeting_spot,
           r.requester_id, r.helper_id, r.status, r.created_at, r.claimed_at,
           extensions.st_distance(r.location, here) as distance_m
    from public.requests r
    where r.status = 'open'
      and extensions.st_dwithin(r.location, here, radius)
    order by distance_m, r.created_at desc;
end;
$$;

revoke execute on function
    public.create_request(text, text, public.request_category, double precision, double precision, text, text),
    public.nearby_requests(double precision, double precision, double precision),
    public.neighborhoods_near(double precision, double precision)
from public, anon;
grant execute on function
    public.create_request(text, text, public.request_category, double precision, double precision, text, text),
    public.nearby_requests(double precision, double precision, double precision),
    public.neighborhoods_near(double precision, double precision)
to authenticated;

revoke execute on function private.neighborhood_choices(double precision, double precision), private.check_meeting_spot()
from public, anon;
revoke all on private.neighborhood_areas, private.neighborhood_names from public, anon, authenticated;
