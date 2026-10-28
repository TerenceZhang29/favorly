begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset

select pg_temp.login(:'alex');
select is((select auth.uid()), :'alex'::uuid, 'login acts as the user');
select is(current_user::text, 'authenticated', 'login switches to the API role');
select pg_temp.logout();
select is(current_user::text, 'postgres', 'logout returns to the test role');

select pg_temp.login(:'bea');
select throws_ok(
    format('select public.claim_request(%L)', gen_random_uuid()),
    'P0001', 'not_found', 'errors use P0001 and a fixed code'
);

select * from finish();
rollback;
