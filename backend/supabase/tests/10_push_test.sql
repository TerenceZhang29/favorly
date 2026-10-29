begin;
\ir helpers.psql
select no_plan();

select pg_temp.make_user('alex') as alex \gset
select pg_temp.make_user('bea') as bea \gset
select pg_temp.make_user('chen') as chen \gset
select pg_temp.make_request(:'alex', 'Need a cup of rice') as rice \gset

create function pg_temp.last_push() returns text language sql as $$
    select title || ' | ' || body || ' | ' || opens from public.push_outbox order by id desc limit 1
$$;
grant execute on function pg_temp.last_push() to authenticated;

-- MARK: Device tokens

select pg_temp.login(:'alex');
select lives_ok($$select public.register_device(repeat('ab', 32), 'sandbox')$$, 'a device registers');
select throws_ok($$select public.register_device('not-hex', 'sandbox')$$, '23514', null, 'a malformed token is refused');
select throws_ok($$select public.register_device(repeat('ab', 32), 'staging')$$, '23514', null,
    'an unknown environment is refused');
select is((select count(*) from public.device_tokens), 0::bigint, 'clients cannot read tokens');
select pg_temp.login(:'bea');
select public.register_device(repeat('AB', 32), 'production');
select pg_temp.logout();
select is((select user_id from public.device_tokens), :'bea'::uuid,
    'a token moves to whoever signed in on the device last, lowercased');
select is((select environment from public.device_tokens), 'production', 'with its environment');
select pg_temp.login(:'alex');
select public.unregister_device(repeat('ab', 32));
select pg_temp.logout();
select is((select count(*) from public.device_tokens), 1::bigint, 'nobody can remove someone else''s device');
select pg_temp.login(:'bea');
select public.unregister_device(repeat('ab', 32));
select pg_temp.logout();
select is((select count(*) from public.device_tokens), 0::bigint, 'signing out removes the device');

-- MARK: What is queued

select pg_temp.login(:'bea');
select public.claim_request(:'rice');
select pg_temp.logout();
select is(pg_temp.last_push(), 'Request picked up | Bea picked up "Need a cup of rice". | request',
    'the requester hears about the pick-up');
select is((select recipient_id from public.push_outbox order by id desc limit 1), :'alex'::uuid, 'Alex gets it');

select pg_temp.login(:'bea');
select public.send_message(:'rice', 'On my way');
select pg_temp.logout();
select is(pg_temp.last_push(), 'New message from Bea | On my way | chat', 'the other person hears about a message');
select pg_temp.login(:'alex');
select public.send_message(:'rice', repeat('a', 130));
select pg_temp.logout();
select is((select char_length(body) from public.push_outbox order by id desc limit 1), 120,
    'a long message is cut to 120 characters');
select is((select recipient_id from public.push_outbox order by id desc limit 1), :'bea'::uuid, 'and Bea gets it');

select pg_temp.login(:'alex');
select public.complete_request(:'rice');
select pg_temp.logout();
select is(pg_temp.last_push(), 'Favor completed | Alex marked "Need a cup of rice" completed. | request',
    'the helper hears the favor is completed');

select pg_temp.login(:'alex');
select public.submit_review(:'rice', 5, 'Thanks');
select pg_temp.logout();
select is(pg_temp.last_push(), 'New review | Alex left you a 5-star review. | request', 'and about the review');

-- Auto-complete has no signed-in user.
select pg_temp.make_request(:'alex', 'Hold a ladder') as ladder \gset
select pg_temp.login(:'bea');
select public.claim_request(:'ladder');
select pg_temp.logout();
select private.complete_due_requests(now() + interval '7 days');
select is(pg_temp.last_push(), 'Favor completed | "Hold a ladder" completed automatically after 7 days. | request',
    'an auto-completed favor says so');

-- Nothing for blocked people.
select pg_temp.make_request(:'chen', 'Borrow a drill') as drill \gset
select pg_temp.login(:'chen');
select public.block_user(:'bea');
select pg_temp.logout();
select count(*) as before from public.push_outbox \gset
update public.requests set helper_id = :'bea', status = 'claimed', claimed_at = now() where id = :'drill';
select is((select count(*) from public.push_outbox), :'before'::bigint, 'nobody is notified across a block');

-- MARK: Sending

select is((select count(*) from cron.job where jobname = 'favorly-push-retry'), 1::bigint, 'a retry job is scheduled');
select lives_ok($$select private.send_pushes()$$, 'without the Vault secrets, sending quietly does nothing');
select pg_temp.login(:'alex');
select throws_ok($$select private.send_pushes()$$, '42501', null, 'clients cannot trigger sending');
select is((select count(*) from public.push_outbox), 0::bigint, 'clients cannot read the outbox');

select * from finish();
rollback;
