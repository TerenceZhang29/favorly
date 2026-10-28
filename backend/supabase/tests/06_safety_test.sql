begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset
select pg_temp.make_request(:'alex', 'Alex needs eggs') as alex_eggs \gset
select pg_temp.make_request(:'bea', 'Bea needs a ladder') as bea_ladder \gset
select pg_temp.make_request(:'chen', 'Chen needs rice') as chen_rice \gset

-- MARK: Reports

select pg_temp.login(:'bea');
select isnt(public.report('request', :'alex_eggs', 'spam', ' Looks fake '), null, 'a request can be reported');
select isnt(public.report('user', :'alex', 'unsafe'), null, 'a user can be reported');
select throws_ok(format($$select public.report('request', %L, 'spam')$$, gen_random_uuid()), 'P0001', 'not_found',
    'an unknown target cannot be reported');
select throws_ok(format($$select public.report('user', %L, 'spam')$$, :'bea'), 'P0001', 'not_allowed',
    'nobody reports themselves');
select is((select count(*) from public.reports), 0::bigint, 'reporters cannot read reports');
select pg_temp.logout();
select is((select note from public.reports where target_id = :'alex_eggs'), 'Looks fake', 'moderators see the trimmed note');

-- MARK: Blocks

select pg_temp.login(:'alex');
select throws_ok(format('select public.block_user(%L)', :'alex'), 'P0001', 'not_allowed', 'nobody blocks themselves');
select public.block_user(:'bea');
select lives_ok(format('select public.block_user(%L)', :'bea'), 'blocking twice is harmless');
select is((select array_agg(blocked_id) from public.blocks), array[:'bea'::uuid], 'you see who you blocked');

select is((select count(*) from public.nearby_requests(40.755, -73.956, 1609) where title = 'Bea needs a ladder'),
    0::bigint, 'the blocker no longer sees the blocked person''s requests');
select is((select count(*) from public.profiles where id = :'bea'), 0::bigint, 'or their profile');
select is((select count(*) from public.nearby_requests(40.755, -73.956, 1609) where title = 'Chen needs rice'),
    1::bigint, 'other people are unaffected');
select throws_ok(format('select public.claim_request(%L)', :'bea_ladder'), 'P0001', 'blocked',
    'the blocker cannot pick up their requests');

select pg_temp.login(:'bea');
select is((select count(*) from public.nearby_requests(40.755, -73.956, 1609) where title = 'Alex needs eggs'),
    0::bigint, 'blocks hide content both ways');
select is((select count(*) from public.blocks), 0::bigint, 'the blocked person cannot see the block');
select throws_ok(format('select public.claim_request(%L)', :'alex_eggs'), 'P0001', 'blocked',
    'the blocked person cannot pick up the blocker''s requests');

-- A thread that existed before the block goes quiet.
select pg_temp.login(:'chen');
select public.claim_request(:'bea_ladder');
select pg_temp.login(:'bea');
select public.send_message(:'bea_ladder', 'Thanks Chen');
select public.block_user(:'chen');
select throws_ok(format('select public.send_message(%L, %L)', :'bea_ladder', 'Hello?'), 'P0001', 'blocked',
    'nobody messages across a block');

select pg_temp.login(:'alex');
select public.unblock_user(:'bea');
select is((select count(*) from public.profiles where id = :'bea'), 1::bigint, 'unblocking shows them again');

select * from finish();
rollback;
