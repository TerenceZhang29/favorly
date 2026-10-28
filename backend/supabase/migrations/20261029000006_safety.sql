-- Trust and safety (phase 4E): the offensive-word filter and the blocked-people list.

-- The words refused in anything other people read. The app's copy is ContentFilter.words in FavorlyCore;
-- ContentFilterTests checks the two lists are the same. Lowercase, letters only.
create function private.offensive_words()
returns text[]
language sql
immutable
as $$
    select array[
        'asshole', 'bastard', 'bitch', 'bullshit', 'chink', 'cock', 'cunt', 'dick', 'fag', 'faggot', 'fuck',
        'fucker', 'fucking', 'kike', 'motherfucker', 'nigga', 'nigger', 'pussy', 'retard', 'shit', 'slut',
        'spic', 'tranny', 'twat', 'wank', 'whore'
    ]
$$;

-- True when any word in the text, lowercased and split on anything but letters, is on the list, also with one
-- of the endings s, es, ed, er, ers, ing or y (ContentFilter.containsOffensiveWord).
create function private.contains_offensive_word(content text)
returns boolean
language sql
immutable
set search_path = ''
as $$
    select exists (
        select 1
        from regexp_split_to_table(lower(coalesce(content, '')), '[^a-z]+') as token,
             unnest(array['', 's', 'es', 'ed', 'er', 'ers', 'ing', 'y']) as ending
        where token <> ''
          and right(token, length(ending)) = ending
          and left(token, length(token) - length(ending)) = any (private.offensive_words())
    );
$$;

-- Refuses offensive text with the app's message, whichever action wrote it. Each trigger names the columns to
-- check as its arguments.
create function private.refuse_offensive_text()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    content text;
begin
    select string_agg(to_jsonb(new) ->> column_name, ' ') into content from unnest(tg_argv) as column_name;
    if private.contains_offensive_word(content) then
        perform private.fail('validation', 'Please remove offensive language.');
    end if;
    return new;
end;
$$;

create trigger refuse_offensive_text before insert or update of title, details on public.requests
    for each row execute function private.refuse_offensive_text('title', 'details');
create trigger refuse_offensive_text before insert or update of text on public.messages
    for each row execute function private.refuse_offensive_text('text');
create trigger refuse_offensive_text before insert or update of comment on public.reviews
    for each row execute function private.refuse_offensive_text('comment');
create trigger refuse_offensive_text before insert or update of display_name on public.profiles
    for each row execute function private.refuse_offensive_text('display_name');

-- The people the signed-in user blocked, with their names. Row-level security hides a blocked person's profile
-- from both sides, so the Blocked people list needs this function to show who is on it.
create function public.blocked_profiles()
returns table (id uuid, display_name text, neighborhood text)
language sql
stable
security definer
set search_path = ''
as $$
    select p.id, p.display_name, p.neighborhood
    from public.blocks b
    join public.profiles p on p.id = b.blocked_id
    where b.blocker_id = (select auth.uid())
    order by b.created_at desc;
$$;

revoke execute on function public.blocked_profiles() from public, anon;
grant execute on function public.blocked_profiles() to authenticated;
revoke execute on function private.offensive_words(), private.contains_offensive_word(text),
    private.refuse_offensive_text() from public, anon;
grant execute on function private.offensive_words(), private.contains_offensive_word(text) to authenticated;
