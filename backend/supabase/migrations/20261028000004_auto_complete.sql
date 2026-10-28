-- Rule 15: a picked-up request completes on its own 7 days after pick-up if the requester never confirms.

create function private.complete_due_requests(as_of timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    completed integer;
begin
    update public.requests r
    set status = 'completed'
    where r.status = 'claimed' and r.claimed_at <= as_of - interval '7 days';
    get diagnostics completed = row_count;
    return completed;
end;
$$;

revoke execute on function private.complete_due_requests(timestamptz) from public, anon, authenticated;

create extension if not exists pg_cron with schema pg_catalog;

-- Every 15 minutes, so a favor completes at most 15 minutes after its 7 days are up.
select cron.schedule('favorly-auto-complete', '*/15 * * * *', $$select private.complete_due_requests()$$);
