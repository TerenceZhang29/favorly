begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_request(:'alex') as eggs \gset

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

-- MARK: The filter

select ok(private.contains_offensive_word('What the SHIT'), 'case does not matter');
select ok(private.contains_offensive_word('two dicks'), 'endings are matched');
select ok(not private.contains_offensive_word('Dickens novels'), 'longer words that contain one are fine');
select ok(not private.contains_offensive_word('Scunthorpe, cocktails and shiitake'), 'ordinary text passes');
select ok(not private.contains_offensive_word(null), 'nothing passes');

select pg_temp.login(:'alex');
select is(pg_temp.detail_of($$select public.create_request('Need shit', '', 'other', 40.755, -73.956, 'Here')$$),
    'Please remove offensive language.', 'an offensive title is refused with the app''s message');
select throws_ok($$select public.create_request('Need rice', 'fuck it', 'other', 40.755, -73.956, 'Here')$$,
    'P0001', 'validation', 'offensive details are refused');
select throws_ok($$select public.complete_profile('Dick', true, 1)$$, 'P0001', 'validation',
    'an offensive name is refused');

select pg_temp.login(:'bea');
select public.claim_request(:'eggs');
select throws_ok(format('select public.send_message(%L, %L)', :'eggs', 'you bitch'), 'P0001', 'validation',
    'an offensive message is refused');
select lives_ok(format('select public.send_message(%L, %L)', :'eggs', 'On my way'), 'a friendly one is sent');

select pg_temp.login(:'alex');
select public.complete_request(:'eggs');
select throws_ok(format('select public.submit_review(%L, 1, %L)', :'eggs', 'asshole'), 'P0001', 'validation',
    'an offensive review is refused');

-- MARK: Blocked people

select pg_temp.login(:'alex');
select public.block_user(:'bea');
select is((select count(*) from public.profiles where id = :'bea'), 0::bigint, 'a blocked profile is hidden');
select is((select array_agg(display_name) from public.blocked_profiles()), array['Bea'],
    'but the blocked list still names them');
select pg_temp.login(:'bea');
select is((select count(*) from public.blocked_profiles()), 0::bigint, 'the blocked person sees no list of theirs');

select * from finish();
rollback;
