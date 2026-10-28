begin;
\ir helpers.psql
select no_plan();

select is(
    (select array_agg(tablename::text order by tablename) from pg_publication_tables
     where pubname = 'supabase_realtime' and schemaname = 'public'),
    array['messages', 'requests', 'reviews'],
    'requests, messages and reviews are published to realtime'
);

select * from finish();
rollback;
