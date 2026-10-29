begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset

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
select is(
    (select location_label from public.create_request('Need rice', '', 'other', 40.755, -73.956, '  Roosevelt Island ')),
    'Roosevelt Island', 'a neighborhood is trimmed and kept');
select lives_ok($$select public.create_request('Need tea', '', 'other', 40.755, -73.956, 'Hell''s Kitchen')$$,
    'apostrophes are fine');
select lives_ok($$select public.create_request('Need sugar', '', 'other', 40.755, -73.956, 'Cornell Tech, Roosevelt Island')$$,
    'commas are fine');
select lives_ok($$select public.create_request('Need salt', '', 'other', 40.755, -73.956, 'Ville-Émard')$$,
    'accented letters are fine');

select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.755, -73.956, '549 Main St')$$),
    'Use only letters for the neighborhood, not a street address.', 'a street address is refused');
select is(pg_temp.detail_of(format(
    'select public.create_request(%L, %L, %L, 40.755, -73.956, %L)', 'Need oil', '', 'other', repeat('a', 41))),
    'Neighborhood must be 40 characters or fewer.', 'a long neighborhood is refused');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.755, -73.956, 'Shit Street')$$),
    'Please remove offensive language.', 'an offensive neighborhood is refused');

select * from finish();
rollback;
