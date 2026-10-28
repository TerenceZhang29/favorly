begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset

-- Bea's history: a completed favor for Alex (reviewed), one she asked for that Chen completed and she reviewed,
-- an open request, and a request of Chen's she has picked up.
select pg_temp.make_request(:'alex', 'Alex asked, Bea helped') as helped \gset
select pg_temp.make_request(:'bea', 'Bea asked, Chen helped') as asked \gset
select pg_temp.make_request(:'bea', 'Bea still open') as bea_open \gset
select pg_temp.make_request(:'chen', 'Chen asked, Bea picked up') as picked_up \gset

select pg_temp.login(:'bea');
select public.claim_request(:'helped');
select public.claim_request(:'picked_up');
select public.send_message(:'picked_up', 'On my way');
select pg_temp.login(:'chen');
select public.claim_request(:'asked');
select pg_temp.login(:'alex');
select public.complete_request(:'helped');
select public.submit_review(:'helped', 5, 'Thanks Bea');
select pg_temp.login(:'bea');
select public.complete_request(:'asked');
select public.submit_review(:'asked', 4, 'Thanks Chen');
select public.block_user(:'alex');

select pg_temp.logout();
set local role anon;
select throws_ok($$select public.delete_my_account()$$, '42501', null, 'signed-out callers cannot delete anything');
select pg_temp.logout();

select pg_temp.login(:'bea');
select lives_ok($$select public.delete_my_account()$$, 'Bea deletes her account');
select pg_temp.logout();

select is((select count(*) from auth.users where id = :'bea'), 0::bigint, 'the sign-in is gone');
select is((select count(*) from public.profiles where id = :'bea'), 0::bigint, 'the profile is gone');
select is((select count(*) from public.requests where id = :'bea_open'), 0::bigint, 'her open request is gone');
select is((select array[status::text, helper_id::text] from public.requests where id = :'picked_up'),
    array['open', null], 'a request she had picked up is open again');
select is((select count(*) from public.messages where request_id = :'picked_up'), 0::bigint,
    'and its thread is cleared');
select is((select array[status::text, requester_id::text] from public.requests where id = :'helped'),
    array['completed', :'alex'], 'a favor she did stays completed for the requester');
select is((select helper_id from public.requests where id = :'helped'), null, 'with her side left empty');
select is((select count(*) from public.reviews where reviewer_id = :'bea' or reviewee_id = :'bea'), 0::bigint,
    'reviews by and about her are gone');
select is((select count(*) from public.requests where id = :'asked'), 1::bigint,
    'a favor she asked for stays, for the helper''s history');
select is((select lifetime_points from public.kindness_summary(:'chen')), 10,
    'the helper keeps the points for it, without her review''s stars');
select is((select count(*) from public.blocks), 0::bigint, 'her blocks are gone');

select * from finish();
rollback;
