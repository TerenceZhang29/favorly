-- Moderation queries for the Supabase dashboard (SQL Editor). See docs/MODERATION.md for when to use each.
-- They run as the dashboard's admin role, past row-level security. Replace the <...> placeholders before running.

-- 1. Open reports, oldest first, with what was reported and by whom. Save this one as "Open reports".
select
    r.id as report_id,
    r.created_at,
    r.reason,
    r.note,
    r.target_type,
    r.target_id,
    reporter.display_name as reporter,
    case r.target_type
        when 'request' then (select q.title || ' | ' || q.details from public.requests q where q.id = r.target_id)
        when 'message' then (select m.text from public.messages m where m.id = r.target_id)
        when 'user' then (select p.display_name from public.profiles p where p.id = r.target_id)
    end as reported_content,
    case r.target_type
        when 'request' then (select q.requester_id from public.requests q where q.id = r.target_id)
        when 'message' then (select m.sender_id from public.messages m where m.id = r.target_id)
        when 'user' then r.target_id
    end as reported_user_id,
    (select count(*) from public.reports earlier
     where earlier.target_id = r.target_id and earlier.id <> r.id) as other_reports_of_same_target
from public.reports r
left join public.profiles reporter on reporter.id = r.reporter_id
where r.resolved_at is null
order by r.created_at;

-- 2. Everything one person has posted and said, to judge a pattern.
select 'request' as kind, q.id, q.created_at, q.status::text as status, q.title || ' | ' || q.details as content
from public.requests q where q.requester_id = '<user id>'
union all
select 'message', m.id, m.sent_at, null, m.text from public.messages m where m.sender_id = '<user id>'
union all
select 'review', v.id, v.created_at, null, v.comment from public.reviews v where v.reviewer_id = '<user id>'
order by created_at desc;

-- 3. Remove content. A request is cancelled rather than deleted, so the other person's history stays readable.
update public.requests set status = 'cancelled' where id = '<request id>' and status in ('open', 'claimed');
delete from public.messages where id = '<message id>';
delete from public.reviews where id = '<review id>';

-- 4. Close a report once it is handled (also for reports that need no action).
update public.reports set resolved_at = now() where id = '<report id>';
-- Or every open report about the same thing:
update public.reports set resolved_at = now() where target_id = '<target id>' and resolved_at is null;
