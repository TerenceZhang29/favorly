-- The app now says "claim" instead of "pick up" (2026-11-04), so the notification a requester gets when
-- someone claims their request says so too: "Request claimed", "Bea claimed "Need a cup of rice".".
-- Only the wording changes; when and to whom the notification is queued stays the same.

create or replace function private.push_for_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if old.status = 'open' and new.status = 'claimed' then
        perform private.queue_push(
            new.requester_id, new.helper_id,
            'Request claimed',
            private.display_name(new.helper_id) || ' claimed "' || new.title || '".',
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
