begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_request(:'alex') as eggs \gset
select pg_temp.make_request(:'alex', 'Stays open') as open_one \gset
select pg_temp.make_request(:'alex', 'Gets cancelled') as cancelled \gset

select pg_temp.login(:'bea');
select public.claim_request(:'eggs');
select public.claim_request(:'cancelled');
select pg_temp.login(:'alex');
select public.cancel_request(:'cancelled');
select pg_temp.logout();

select is(private.complete_due_requests(now() + interval '7 days' - interval '1 second'), 0,
    'nothing is due 1 second before 7 days');
select is((select status::text from public.requests where id = :'eggs'), 'claimed', 'still picked up');
select is(private.complete_due_requests(now() + interval '7 days'), 1, 'exactly 7 days after pick-up it is due');
select is((select status::text from public.requests where id = :'eggs'), 'completed', 'and it is completed');
select is((select status::text from public.requests where id = :'open_one'), 'open', 'an open request never auto-completes');
select is((select status::text from public.requests where id = :'cancelled'), 'cancelled',
    'a cancelled request never auto-completes');

select is((select lifetime_points from public.kindness_summary(:'bea')), 10, 'the helper earns the points');
select pg_temp.login(:'alex');
select is((select rating from public.submit_review(:'eggs', 5, '')), 5, 'and the requester can still review it');

select pg_temp.logout();
select is((select count(*) from cron.job where jobname = 'favorly-auto-complete' and schedule = '*/15 * * * *'),
    1::bigint, 'a cron job runs it every 15 minutes');
select pg_temp.login(:'bea');
select throws_ok($$select private.complete_due_requests()$$, '42501', null, 'clients cannot run it');

select * from finish();
rollback;
