-- The neighborhood shown with a request is now chosen by the requester (phase 4G). The same rule as the app's
-- DraftValidator.validateLocationLabel: at most 40 characters, letters, spaces and , . - ' ’ only (no digits, so no
-- house numbers), and through the offensive-word filter.

create function private.check_location_label()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    label text := btrim(coalesce(new.location_label, ''), E' \t\n\r');
begin
    if char_length(label) = 0 then
        perform private.fail('validation', 'Add a neighborhood for your request.');
    end if;
    if char_length(label) > 40 then
        perform private.fail('validation', 'Neighborhood must be 40 characters or fewer.');
    end if;
    if label !~ '^[[:alpha:] ,.''’-]+$' then
        perform private.fail('validation', 'Use only letters for the neighborhood, not a street address.');
    end if;
    new.location_label := label;
    return new;
end;
$$;

create trigger check_location_label before insert or update of location_label on public.requests
    for each row execute function private.check_location_label();

-- The word filter now reads the neighborhood too.
drop trigger refuse_offensive_text on public.requests;
create trigger refuse_offensive_text before insert or update of title, details, location_label on public.requests
    for each row execute function private.refuse_offensive_text('title', 'details', 'location_label');

revoke execute on function private.check_location_label() from public, anon;
