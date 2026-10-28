begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset
select pg_temp.make_request(:'alex') as eggs \gset
select pg_temp.make_request(:'chen', 'Hold a ladder') as ladder \gset

select pg_temp.login(:'bea');
select is((select lifetime_points from public.kindness_summary(:'bea')), 0, 'a new user has 0 points');
select is((select average_rating from public.kindness_summary(:'bea')), null::double precision, 'and no average');
select public.claim_request(:'eggs');
select public.claim_request(:'ladder');
select is((select lifetime_points from public.kindness_summary(:'bea')), 0, 'picking up earns nothing yet');

select pg_temp.login(:'alex');
select throws_ok(format('select public.submit_review(%L, 5, %L)', :'eggs', 'Great'), 'P0001', 'not_allowed',
    'a request that is not completed cannot be reviewed');
select public.complete_request(:'eggs');
select is((select lifetime_points from public.kindness_summary(:'bea')), 10, 'a completed favor earns 10 points');

select throws_ok(format('select public.submit_review(%L, 0, %L)', :'eggs', ''), 'P0001', 'validation',
    'a rating of 0 is refused');
select throws_ok(format('select public.submit_review(%L, 6, %L)', :'eggs', ''), 'P0001', 'validation',
    'a rating of 6 is refused');
select throws_ok(format('select public.submit_review(%L, 5, %L)', :'eggs', repeat('a', 301)), 'P0001', 'validation',
    'a comment over 300 characters is refused');

select pg_temp.login(:'bea');
select throws_ok(format('select public.submit_review(%L, 5, %L)', :'eggs', 'Me!'), 'P0001', 'not_allowed',
    'the helper cannot review their own favor');

select pg_temp.login(:'alex');
select is((select reviewee_id from public.submit_review(:'eggs', 5, ' Fast and friendly ')), :'bea'::uuid,
    'the requester reviews the helper');
select is((select comment from public.reviews where request_id = :'eggs'), 'Fast and friendly', 'the comment is trimmed');
select throws_ok(format('select public.submit_review(%L, 4, %L)', :'eggs', 'Again'), 'P0001', 'already_reviewed',
    'a favor is reviewed once');

select is((select lifetime_points from public.kindness_summary(:'bea')), 20, '5 stars add 2 points each');
select is((select array[completed_favors, review_count] from public.kindness_summary(:'bea')), array[1, 1],
    'favors and reviews are counted');

select pg_temp.login(:'chen');
select public.complete_request(:'ladder');
select public.submit_review(:'ladder', 4, '');
select is((select lifetime_points from public.kindness_summary(:'bea')), 38, '10 + 10 + (5 + 4) * 2 = 38');
select is((select average_rating from public.kindness_summary(:'bea')), 4.5::double precision, 'the average rating');
select is((select lifetime_points from public.kindness_summary(:'alex')), 0, 'asking for help earns nothing');

select * from finish();
rollback;
