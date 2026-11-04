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

-- The data is loaded.
select cmp_ok((select count(*) from private.neighborhood_areas), '>', 200::bigint, 'NYC''s areas are loaded');
select is((select count(*) from private.neighborhood_names where name like '%(%' or name like '%-%'
    and name not in ('Bedford-Stuyvesant', 'Co-op City', 'Green-Wood Cemetery')), 0::bigint,
    'names are split and have no direction suffixes');

-- Signed-out callers get nothing.
select throws_ok($$select public.neighborhoods_near(40.755, -73.956)$$, 'P0001', 'not_signed_in',
    'neighborhoods_near needs a signed-in user');

select pg_temp.login(:'alex');

-- Cornell Tech, on Roosevelt Island: its area's names come first, in order, then the areas across the river.
select is((select array_agg(n) from (select public.neighborhoods_near(40.7553, -73.9562) n limit 3) s),
    array['Upper East Side', 'Lenox Hill', 'Roosevelt Island'], 'the containing area''s names come first');
select ok('Long Island City' = any (array(select public.neighborhoods_near(40.7553, -73.9562))),
    'a neighborhood across the river is offered');
select ok('Seattle' <> all (array(select public.neighborhoods_near(40.7553, -73.9562))), 'Seattle is not offered');
select cmp_ok((select count(*) from public.neighborhoods_near(40.7553, -73.9562)), '<=', 8::bigint,
    'at most 8 choices');
select is((select count(*) from (select n from public.neighborhoods_near(40.7553, -73.9562) n group by n
    having count(*) > 1) d), 0::bigint, 'no name is offered twice');
select is((select count(*) from public.neighborhoods_near(47.6062, -122.3321)), 0::bigint,
    'nothing is offered outside NYC');
select throws_ok($$select public.neighborhoods_near(95, -73.956)$$, 'P0001', 'validation',
    'an impossible location is refused');

-- create_request keeps only a name that is offered for the point.
select is((select location_label from public.create_request('Need rice', '', 'other', 40.7553, -73.9562,
    'Roosevelt Island')), 'Roosevelt Island', 'an offered neighborhood is kept');
select lives_ok($$select public.create_request('Need tea', '', 'other', 40.7553, -73.9562, 'Long Island City')$$,
    'a neighboring area is fine');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.7553, -73.9562, 'Seattle')$$),
    'Choose a neighborhood near you.', 'a faraway name is refused');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.7553, -73.9562, 'Harlem')$$),
    'Choose a neighborhood near you.', 'a real NYC neighborhood that is not nearby is refused');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.7553, -73.9562, '  ')$$),
    'Add a neighborhood for your request.', 'an empty neighborhood is refused');
select lives_ok($$select public.create_request('Need salt', '', 'other', 47.6062, -122.3321, 'Seattle')$$,
    'outside NYC a clean label is kept');

-- The meeting spot.
select is((select meeting_spot from public.create_request('Need sugar', '', 'other', 40.7553, -73.9562,
    'Roosevelt Island', '  Cornell Tech lobby ')), 'Cornell Tech lobby', 'a meeting spot is trimmed and kept');
select is((select meeting_spot from public.requests where title = 'Need rice'), '',
    'the meeting spot is optional');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.7553, -73.9562,
    'Roosevelt Island', 'Apt 4B')$$),
    'Use only letters for the meeting spot, not a street address.', 'an address in the meeting spot is refused');
select is(pg_temp.detail_of(format('select public.create_request(%L, %L, %L, 40.7553, -73.9562, %L, %L)',
    'Need oil', '', 'other', 'Roosevelt Island', repeat('a', 41))),
    'Meeting spot must be 40 characters or fewer.', 'a long meeting spot is refused');
select is(pg_temp.detail_of($$select public.create_request('Need oil', '', 'other', 40.7553, -73.9562,
    'Roosevelt Island', 'Shit corner')$$),
    'Please remove offensive language.', 'an offensive meeting spot is refused');
select is((select meeting_spot from public.nearby_requests(40.7553, -73.9562, 500) where title = 'Need sugar'),
    'Cornell Tech lobby', 'Nearby returns the meeting spot');

select * from finish();
rollback;
