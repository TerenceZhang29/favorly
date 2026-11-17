begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('cam') as cam \gset
select pg_temp.make_request(:'alex') as eggs \gset

create function pg_temp.views_of(request uuid) returns bigint language sql as $$
    select count(*) from public.request_views where request_id = request;
$$;

-- MARK: Recording

select pg_temp.login(:'bea');
select lives_ok(format('select public.record_request_view(%L)', :'eggs'), 'a neighbor''s view is recorded');
select lives_ok(format('select public.record_request_view(%L)', :'eggs'), 'opening it again is fine');
select pg_temp.logout();
select is(pg_temp.views_of(:'eggs'), 1::bigint, 'one person counts once');

select pg_temp.login(:'alex');
select public.record_request_view(:'eggs');
select pg_temp.logout();
select is(pg_temp.views_of(:'eggs'), 1::bigint, 'the requester''s own view does not count');

select pg_temp.login(:'cam');
select lives_ok(format('select public.record_request_view(%L)', gen_random_uuid()), 'an unknown request is skipped quietly');
select public.block_user(:'alex');
select public.record_request_view(:'eggs');
select pg_temp.logout();
select is(pg_temp.views_of(:'eggs'), 1::bigint, 'a view between blocked people is not recorded');

select pg_temp.make_request(:'alex', 'Help moving a couch') as couch \gset
update public.requests set status = 'cancelled' where id = :'couch';
select pg_temp.login(:'bea');
select public.record_request_view(:'couch');
select pg_temp.logout();
select is(pg_temp.views_of(:'couch'), 0::bigint, 'a cancelled request is not recorded');

-- MARK: Access

select pg_temp.login(:'bea');
select throws_ok('select count(*) from public.request_views', '42501', null, 'clients cannot read views');
select throws_ok(format('insert into public.request_views (request_id, viewer_id) values (%L, %L)', :'eggs', :'bea'),
    '42501', null, 'clients cannot write views directly');
select pg_temp.logout();

select set_config('role', 'anon', true);
select throws_ok(format('select public.record_request_view(%L)', :'eggs'), '42501', null,
    'the anonymous key cannot record a view');
select pg_temp.logout();

-- MARK: Deletion

delete from auth.users where id = :'bea';
select is(pg_temp.views_of(:'eggs'), 0::bigint, 'a deleted account takes its views with it');

select * from finish();
rollback;
