# Moderating Favorly

App Review guideline 1.2 requires that reports of objectionable content are acted on promptly. Apple's guidance is within 24 hours. This is the routine for the owner, who moderates during the beta and after launch.

## What users can do

- **Report** a request (… menu on Request Detail), a message (long-press it in the chat) or a person (… menu on their profile), with a reason and an optional note. The reported person is not told who reported them.
- **Block** a person from the same menus. The two then don't see each other's requests, messages or profiles, and neither can pick up the other's requests. Blocks are undone from Profile → Blocked people.
- An **offensive-word filter** refuses titles, details, messages, reviews and names that contain words on the list, in the app and on the server (`ContentFilter.words` in FavorlyCore and `private.offensive_words()` in the safety migration; a test keeps them the same).

## Daily routine

1. Open the Supabase dashboard → project **favorly** → **SQL Editor**.
2. Run the saved query **Open reports** (query 1 in `backend/moderation/queries.sql`; save it once in the editor). An empty result means nothing to do.
3. For each open report, read `reported_content` and `note`. If you need context, run query 2 with `reported_user_id` to see everything that person has posted.
4. Decide, using the table below, and act.
5. Close the report with query 4. Close it even when no action is needed, so it does not come back tomorrow.

| What you find | Action |
| --- | --- |
| Nothing wrong (a misunderstanding, a dispute about a favor) | Close the report |
| Spam, a scam, or offensive content | Remove it (query 3), close the report |
| The same person again, or anything threatening, hateful or sexual | Remove the content, then ban the person: Authentication → Users → their row → **Ban user** (choose a long duration). Close the report |
| A threat to someone's safety, or anything involving a minor | Remove the content, ban the person, keep a copy of what was said, and contact the police (911 in an emergency). Close the report |

When a word slips past the filter, add it to both lists in the same commit: `ContentFilter.words` and a new migration that replaces `private.offensive_words()`. The test fails if the two differ.

## When you are away

Reports wait in the table until someone closes them. If nobody can check for more than a day during the beta or after launch, hand the routine to a teammate who has access to the Supabase project.

## Privacy

Reports, messages and profiles are personal data. Look only at what a report needs, don't copy it out of the dashboard except to pass a threat to the police, and don't share it with anyone outside the team.
