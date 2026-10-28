begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset
select pg_temp.make_request(:'alex') as eggs \gset

select pg_temp.login(:'alex');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', 'Hello'), 'P0001', 'not_allowed',
    'no thread before pick-up');

select pg_temp.login(:'bea');
select public.claim_request(:'eggs');
select is((select text from public.send_message(:'eggs', '  On my way  ')), 'On my way', 'the helper sends, trimmed');
select pg_temp.login(:'alex');
select is((select sender_id from public.send_message(:'eggs', 'Thank you!')), :'alex'::uuid, 'the requester replies');
select is((select count(*) from public.messages where request_id = :'eggs'), 2::bigint, 'the requester reads the thread');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', '   '), 'P0001', 'validation',
    'an empty message is refused');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', repeat('a', 501)), 'P0001', 'validation',
    'a message over 500 characters is refused');

select pg_temp.login(:'chen');
select is((select count(*) from public.messages where request_id = :'eggs'), 0::bigint, 'a stranger reads nothing');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', 'Hi'), 'P0001', 'not_allowed',
    'a stranger cannot write');

select pg_temp.login(:'bea');
select public.send_message(:'eggs', 'Message ' || n) from generate_series(2, 30) n;
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', 'One too many'), 'P0001', 'rate_limited',
    'more than 30 messages a minute are refused');

select pg_temp.login(:'alex');
select public.complete_request(:'eggs');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', 'Late'), 'P0001', 'not_allowed',
    'the thread is read-only after completion');
select is((select count(*) from public.messages where request_id = :'eggs'), 31::bigint, 'but still readable');

select * from finish();
rollback;
