-- Push notifications (phase 4F). Triggers write each notification to an outbox, with its final text; the
-- `push` Edge Function sends what is in the outbox to Apple. A failed send stays in the outbox and is retried.

create extension if not exists pg_net with schema extensions;

-- The devices a user receives notifications on. Clients change it only through the two functions below.
create table public.device_tokens (
    token text primary key check (token ~ '^[0-9a-f]{64,200}$'),
    user_id uuid not null references public.profiles (id) on delete cascade,
    -- Which APNs server the token belongs to: development builds use sandbox, TestFlight and the App Store
    -- production.
    environment text not null check (environment in ('sandbox', 'production')),
    updated_at timestamptz not null default now()
);

create index device_tokens_user_idx on public.device_tokens (user_id);
alter table public.device_tokens enable row level security;

-- One notification for one person. `opens` is what tapping it shows.
create table public.push_outbox (
    id bigint generated always as identity primary key,
    recipient_id uuid not null references public.profiles (id) on delete cascade,
    title text not null,
    body text not null,
    request_id uuid not null,
    opens text not null check (opens in ('request', 'chat')),
    created_at timestamptz not null default now(),
    sent_at timestamptz,
    attempts integer not null default 0
);

create index push_outbox_unsent_idx on public.push_outbox (id) where sent_at is null;
alter table public.push_outbox enable row level security;

-- MARK: Device tokens

-- Saves this device for the signed-in user. A token that belonged to someone else moves to them, since the
-- device now belongs to whoever signed in on it last.
create function public.register_device(token text, environment text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := private.require_profile();
begin
    insert into public.device_tokens (token, user_id, environment)
    values (lower(register_device.token), uid, register_device.environment)
    on conflict on constraint device_tokens_pkey do update
        set user_id = excluded.user_id, environment = excluded.environment, updated_at = now();
end;
$$;

-- Forgets this device, at sign-out.
create function public.unregister_device(token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    delete from public.device_tokens d where d.token = lower(unregister_device.token) and d.user_id = auth.uid();
end;
$$;

revoke execute on function public.register_device(text, text), public.unregister_device(text) from public, anon;
grant execute on function public.register_device(text, text), public.unregister_device(text) to authenticated;

-- MARK: What to send

create function private.display_name(user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$ select coalesce((select p.display_name from public.profiles p where p.id = user_id), 'A neighbor') $$;

-- Queues a notification, unless the recipient is gone or the two people blocked each other.
create function private.queue_push(
    recipient uuid, actor uuid, title text, body text, request_id uuid, opens text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if recipient is null or recipient = actor or private.is_blocked_between(recipient, actor) then
        return;
    end if;
    insert into public.push_outbox (recipient_id, title, body, request_id, opens)
    values (recipient, title, body, request_id, opens);
end;
$$;

-- "Bea picked up your request", and "Alex marked your favor completed" (or that it completed on its own).
create function private.push_for_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if old.status = 'open' and new.status = 'claimed' then
        perform private.queue_push(
            new.requester_id, new.helper_id,
            'Request picked up',
            private.display_name(new.helper_id) || ' picked up "' || new.title || '".',
            new.id, 'request'
        );
    elsif old.status = 'claimed' and new.status = 'completed' then
        perform private.queue_push(
            new.helper_id, new.requester_id,
            'Favor completed',
            case when auth.uid() = new.requester_id
                then private.display_name(new.requester_id) || ' marked "' || new.title || '" completed.'
                else '"' || new.title || '" completed automatically after 7 days.'
            end,
            new.id, 'request'
        );
    end if;
    return new;
end;
$$;

-- "New message from Bea", with the start of the message.
create function private.push_for_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    target public.requests;
begin
    select * into target from public.requests r where r.id = new.request_id;
    perform private.queue_push(
        case when new.sender_id = target.requester_id then target.helper_id else target.requester_id end,
        new.sender_id,
        'New message from ' || private.display_name(new.sender_id),
        case when char_length(new.text) > 120 then left(new.text, 119) || '…' else new.text end,
        new.request_id, 'chat'
    );
    return new;
end;
$$;

-- "Alex left you a review".
create function private.push_for_review()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform private.queue_push(
        new.reviewee_id, new.reviewer_id,
        'New review',
        private.display_name(new.reviewer_id) || ' left you a ' || new.rating || '-star review.',
        new.request_id, 'request'
    );
    return new;
end;
$$;

create trigger push_for_request after update of status on public.requests
    for each row execute function private.push_for_request();
create trigger push_for_message after insert on public.messages
    for each row execute function private.push_for_message();
create trigger push_for_review after insert on public.reviews
    for each row execute function private.push_for_review();

-- MARK: Sending

-- Asks the `push` Edge Function to send what is in the outbox. Its address and shared secret live in Vault as
-- `push_function_url` and `push_function_secret`; until both are set, nothing is sent and the outbox waits.
-- pg_net makes the call after the transaction commits, so a slow or failing function never blocks a write.
create function private.send_pushes()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    url text := (select decrypted_secret from vault.decrypted_secrets where name = 'push_function_url');
    secret text := (select decrypted_secret from vault.decrypted_secrets where name = 'push_function_secret');
begin
    if url is null or secret is null then
        return;
    end if;
    perform net.http_post(
        url := url,
        headers := jsonb_build_object('Content-Type', 'application/json', 'X-Push-Secret', secret),
        body := '{}'::jsonb
    );
end;
$$;

create function private.send_pushes_after_queue()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform private.send_pushes();
    return null;
end;
$$;

create trigger send_pushes after insert on public.push_outbox
    for each statement execute function private.send_pushes_after_queue();

-- Retries anything left unsent every 5 minutes.
select cron.schedule(
    'favorly-push-retry', '*/5 * * * *',
    $$select private.send_pushes() where exists (select 1 from public.push_outbox where sent_at is null and attempts < 5)$$
);

revoke execute on function private.display_name(uuid), private.queue_push(uuid, uuid, text, text, uuid, text),
    private.send_pushes() from public, anon, authenticated;
