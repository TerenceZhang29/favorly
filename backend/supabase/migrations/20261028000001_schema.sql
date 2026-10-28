-- Favorly schema: profiles, help requests, chat, reviews, reports and blocks.
-- Enum values match the Swift raw values in FavorlyCore (RequestCategory, RequestStatus).
-- Clients never write tables directly: every change goes through the functions in 20261028000003_actions.sql.

create extension if not exists postgis with schema extensions;

-- Helpers that policies and actions use. Not exposed through the API.
create schema if not exists private;

create type public.request_category as enum ('ingredient', 'movingHelp', 'carHelp', 'errand', 'other');
create type public.request_status as enum ('open', 'claimed', 'completed', 'cancelled');
create type public.report_target as enum ('request', 'message', 'user');
create type public.report_reason as enum ('spam', 'inappropriate', 'unsafe', 'other');

create table public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    display_name text not null check (char_length(display_name) between 2 and 30),
    neighborhood text not null default '',
    confirmed_adult boolean not null check (confirmed_adult),
    accepted_terms_version integer not null check (accepted_terms_version >= 1),
    created_at timestamptz not null default now()
);

create table public.requests (
    id uuid primary key default gen_random_uuid(),
    title text not null check (char_length(title) between 3 and 80),
    details text not null default '' check (char_length(details) <= 500),
    category public.request_category not null,
    -- Snapped to about 100 m before storing (3 decimal places), so nobody can find an exact address.
    latitude double precision not null check (latitude between -90 and 90),
    longitude double precision not null check (longitude between -180 and 180),
    location extensions.geography (point, 4326) generated always as (
        extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
    ) stored,
    -- A neighborhood-level name such as "Roosevelt Island", never a street address.
    location_label text not null check (char_length(location_label) between 1 and 80),
    -- Null once the requester or helper deletes their account; only completed favors keep such a row.
    requester_id uuid references public.profiles (id) on delete set null,
    helper_id uuid references public.profiles (id) on delete set null,
    status public.request_status not null default 'open',
    created_at timestamptz not null default now(),
    claimed_at timestamptz
);

create index requests_location_idx on public.requests using gist (location);
create index requests_requester_idx on public.requests (requester_id, created_at desc);
create index requests_helper_idx on public.requests (helper_id, claimed_at desc);
create index requests_claimed_idx on public.requests (claimed_at) where status = 'claimed';

create table public.messages (
    id uuid primary key default gen_random_uuid(),
    request_id uuid not null references public.requests (id) on delete cascade,
    sender_id uuid not null references public.profiles (id) on delete cascade,
    text text not null check (char_length(text) between 1 and 500),
    sent_at timestamptz not null default now()
);

create index messages_thread_idx on public.messages (request_id, sent_at);
create index messages_sender_idx on public.messages (sender_id, sent_at desc);

-- The requester's review of the helper; one per request.
create table public.reviews (
    id uuid primary key default gen_random_uuid(),
    request_id uuid not null unique references public.requests (id) on delete cascade,
    reviewer_id uuid not null references public.profiles (id) on delete cascade,
    reviewee_id uuid not null references public.profiles (id) on delete cascade,
    rating integer not null check (rating between 1 and 5),
    comment text not null default '' check (char_length(comment) <= 300),
    created_at timestamptz not null default now()
);

create index reviews_reviewee_idx on public.reviews (reviewee_id, created_at desc);

create table public.reports (
    id uuid primary key default gen_random_uuid(),
    reporter_id uuid references public.profiles (id) on delete set null,
    target_type public.report_target not null,
    target_id uuid not null,
    reason public.report_reason not null,
    note text not null default '' check (char_length(note) <= 500),
    created_at timestamptz not null default now(),
    resolved_at timestamptz
);

create index reports_open_idx on public.reports (created_at) where resolved_at is null;

create table public.blocks (
    blocker_id uuid not null references public.profiles (id) on delete cascade,
    blocked_id uuid not null references public.profiles (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (blocker_id, blocked_id),
    check (blocker_id <> blocked_id)
);

create index blocks_blocked_idx on public.blocks (blocked_id);
