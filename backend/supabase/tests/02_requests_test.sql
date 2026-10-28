begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset

-- MARK: Posting

select pg_temp.login(:'alex');
select throws_ok($$select public.create_request('  Hi ', '', 'other', 40.755, -73.956, 'Here')$$,
    'P0001', 'validation', 'a title under 3 characters is refused');
select throws_ok($$select public.create_request(repeat('a', 81), '', 'other', 40.755, -73.956, 'Here')$$,
    'P0001', 'validation', 'a title over 80 characters is refused');
select throws_ok($$select public.create_request('Need rice', repeat('a', 501), 'other', 40.755, -73.956, 'Here')$$,
    'P0001', 'validation', 'details over 500 characters are refused');
select throws_ok($$select public.create_request('Need rice', '', 'other', 95, -73.956, 'Here')$$,
    'P0001', 'validation', 'an impossible location is refused');

select id as rice from public.create_request('  Need a cup of rice ', ' Cooking tonight ', 'ingredient',
    40.75531, -73.95617, 'Roosevelt Island') \gset
select pg_temp.logout();
select is((select title from public.requests where requester_id = :'alex'), 'Need a cup of rice', 'the title is trimmed');
select is((select details from public.requests where requester_id = :'alex'), 'Cooking tonight', 'the details are trimmed');
select is((select array[latitude, longitude] from public.requests where requester_id = :'alex'),
    array[40.755, -73.956]::double precision[], 'the location is snapped to about 100 m');
select is((select status::text from public.requests where requester_id = :'alex'), 'open', 'a new request is open');

-- At most 5 open requests.
select pg_temp.login(:'alex');
select public.create_request('Request ' || n, '', 'other', 40.755, -73.956, 'Here') from generate_series(2, 5) n;
select throws_ok($$select public.create_request('Request 6', '', 'other', 40.755, -73.956, 'Here')$$,
    'P0001', 'rate_limited', 'a sixth open request is refused');

-- Nobody writes tables directly.
select throws_ok(
    format($$insert into public.requests (title, category, latitude, longitude, location_label, requester_id)
             values ('Sneaky', 'other', 0, 0, 'x', %L)$$, :'alex'),
    '42501', null, 'direct inserts are refused');
select throws_ok(format($$update public.requests set status = 'completed' where requester_id = %L$$, :'alex'),
    '42501', null, 'direct updates are refused');

-- MARK: Nearby

select pg_temp.logout();
select pg_temp.make_request(:'chen', 'Near, older') as near_old \gset
update public.requests set created_at = now() - interval '1 hour' where id = :'near_old';
insert into public.requests (title, category, latitude, longitude, location_label, requester_id)
values ('Five km away', 'other', 40.800, -73.956, 'Astoria', :'chen');
insert into public.requests (title, category, latitude, longitude, location_label, requester_id, helper_id, status, claimed_at)
values ('Already claimed', 'other', 40.755, -73.956, 'Here', :'chen', :'alex', 'claimed', now());

select pg_temp.login(:'bea');
select is(
    (select array_agg(title order by ordinality) from public.nearby_requests(40.755, -73.956, 1609) with ordinality),
    (select array_agg(t) from (values ('Need a cup of rice'), ('Request 2'), ('Request 3'), ('Request 4'),
        ('Request 5'), ('Near, older')) v(t)),
    'nearby lists open requests within the radius, nearest then newest'
);
select ok((select bool_and(distance_m < 1) from public.nearby_requests(40.755, -73.956, 1609)),
    'distances are in meters');
select is((select count(*) from public.nearby_requests(40.755, -73.956, 10000) where title = 'Five km away'), 1::bigint,
    'a bigger radius reaches further');

-- MARK: Pick up, cancel, complete

select throws_ok(format('select public.claim_request(%L)', gen_random_uuid()), 'P0001', 'not_found',
    'an unknown request cannot be picked up');
select pg_temp.login(:'alex');
select throws_ok(format('select public.claim_request(%L)', :'rice'), 'P0001', 'cannot_claim_own_request',
    'nobody picks up their own request');
select pg_temp.login(:'bea');
select is((select status::text from public.claim_request(:'rice')), 'claimed', 'someone else picks it up');
select pg_temp.logout();
select is((select helper_id from public.requests where id = :'rice'), :'bea'::uuid, 'the helper is recorded');
select isnt((select claimed_at from public.requests where id = :'rice'), null, 'the pick-up time is recorded');
select pg_temp.login(:'chen');
select throws_ok(format('select public.claim_request(%L)', :'rice'), 'P0001', 'already_claimed',
    'a picked-up request cannot be picked up again');

select pg_temp.login(:'bea');
select throws_ok(format('select public.complete_request(%L)', :'rice'), 'P0001', 'not_allowed',
    'the helper cannot mark it completed (rule 15)');
select throws_ok(format('select public.cancel_request(%L)', :'rice'), 'P0001', 'not_allowed',
    'the helper cannot cancel');
select pg_temp.login(:'chen');
select throws_ok(format('select public.complete_request(%L)', :'rice'), 'P0001', 'not_allowed',
    'a stranger cannot mark it completed');
select pg_temp.login(:'alex');
select is((select status::text from public.complete_request(:'rice')), 'completed', 'the requester marks it completed');
select throws_ok(format('select public.cancel_request(%L)', :'rice'), 'P0001', 'invalid_transition',
    'a completed request cannot be cancelled');
select pg_temp.logout();
create function pg_temp.detail_of(statement text) returns text language plpgsql as $$
declare
    detail text;
begin
    execute statement;
    return null;
exception when others then
    get stacked diagnostics detail = pg_exception_detail;
    return detail;
end;
$$;
grant execute on function pg_temp.detail_of(text) to authenticated;
select pg_temp.login(:'alex');
select is(pg_temp.detail_of(format('select public.cancel_request(%L)', :'rice')), 'completed',
    'invalid_transition says the current status');
select throws_ok(format('select public.claim_request(%L)', :'rice'), 'P0001', 'cannot_claim_own_request',
    'the requester still cannot pick it up');

select pg_temp.logout();
select pg_temp.make_request(:'alex', 'To cancel') as to_cancel \gset
select pg_temp.login(:'alex');
select throws_ok(format('select public.complete_request(%L)', :'to_cancel'), 'P0001', 'invalid_transition',
    'an open request cannot be completed');
select is((select status::text from public.cancel_request(:'to_cancel')), 'cancelled', 'the requester cancels');
select pg_temp.login(:'bea');
select throws_ok(format('select public.claim_request(%L)', :'to_cancel'), 'P0001', 'invalid_transition',
    'a cancelled request cannot be picked up');

-- MARK: Who sees what

select is((select count(*) from public.requests where id = :'to_cancel'), 0::bigint,
    'someone else''s cancelled request is hidden');
select is((select count(*) from public.requests where id = :'rice'), 1::bigint,
    'a completed favor is visible, for profiles');
select pg_temp.login(:'alex');
select is((select count(*) from public.requests where id = :'to_cancel'), 1::bigint,
    'your own cancelled request stays visible to you');

select * from finish();
rollback;
