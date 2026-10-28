begin;
\ir helpers.psql
select no_plan();

-- Signed in with Apple, no profile yet.
insert into auth.users (id, email, aud, role)
values ('00000000-0000-0000-0000-00000000a11e', 'new@test.local', 'authenticated', 'authenticated');
select pg_temp.login('00000000-0000-0000-0000-00000000a11e');

select throws_ok($$select public.complete_profile('S', true, 1)$$,
    'P0001', 'validation', 'a one-letter name is refused');
select throws_ok($$select public.complete_profile(repeat('a', 31), true, 1)$$,
    'P0001', 'validation', 'a 31-letter name is refused');
select throws_ok($$select public.complete_profile('Sam', false, 1)$$,
    'P0001', 'validation', 'an under-18 sign-up is refused');
select throws_ok($$select public.complete_profile('Sam', true, 0)$$,
    'P0001', 'validation', 'not accepting the terms is refused');
select throws_ok($$select public.create_request('Need rice', '', 'ingredient', 40.755, -73.956, 'Here')$$,
    'P0001', 'not_signed_in', 'without a profile nothing can be posted');

select is((select display_name from public.complete_profile('  Sam ', true, 1)), 'Sam',
    'a valid profile is saved with the name trimmed');
select is((select accepted_terms_version from public.profiles where id = auth.uid()), 1,
    'the accepted terms version is recorded');
select is((select display_name from public.complete_profile('Sammy', true, 1)), 'Sammy',
    'the name can be changed later');

-- The validation text is what the app shows.
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
select pg_temp.login('00000000-0000-0000-0000-00000000a11e');
select is(pg_temp.detail_of($$select public.complete_profile('Sam', false, 1)$$),
    'You must be 18 or older to use Favorly.', 'validation errors carry the app''s message');

-- Signed out.
select pg_temp.logout();
set local role anon;
select throws_ok($$select public.complete_profile('Sam', true, 1)$$, '42501', null,
    'the anonymous key cannot call actions');
select throws_ok($$select count(*) from public.profiles$$, '42501', null,
    'the anonymous key cannot read tables');

select * from finish();
rollback;
