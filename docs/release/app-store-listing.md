# App Store listing and review notes (draft)

What to enter in App Store Connect for Favorly 1.0.0. The App Privacy answers are in [app-privacy.md](app-privacy.md). Character limits are App Store Connect's; every field below fits.

## App information

| Field | Value |
| --- | --- |
| Name (30) | Favorly |
| Subtitle (30) | Small favors from neighbors |
| Primary category | Lifestyle |
| Secondary category | Social Networking |
| Content rights | Contains no third-party content (NYC neighborhood names come from NYC Open Data, credited in `backend/README.md`) |
| Age rating | 18+ (see *Age rating* in [app-privacy.md](app-privacy.md)) |
| Price | Free, no in-app purchases |
| Availability | United States only |

## Version 1.0.0

| Field | Value |
| --- | --- |
| Support URL | https://favorly-app.vercel.app/support |
| Marketing URL | https://favorly-app.vercel.app |
| Privacy Policy URL | https://favorly-app.vercel.app/privacy |
| Copyright | 2026 *the account holder's legal name* |
| Build | 1.0.0 (9) |

**Promotional text (170)**

> Out of eggs mid-recipe? Need a hand with a couch? Ask the neighbors around you, or help someone nearby and earn Kindness points.

**Description (4,000)**

> Favorly connects you with the neighbors around you for small, everyday favors.
>
> ASK FOR A HAND
> Post what you need in a few words: a cup of rice, a ladder for an hour, help carrying groceries up the stairs. Pick your neighborhood and, if you like, a public spot to meet. Your exact location is never shown.
>
> HELP SOMEONE NEARBY
> See requests within a quarter mile to three miles of you, newest first. Tap "I can help", confirm, and message the neighbor to sort out the details.
>
> BUILD YOUR KINDNESS SCORE
> Every completed favor earns Kindness points, and the neighbors you help can leave a star rating and a short review. Your profile shows the favors you've done and what people said.
>
> SAFE BY DESIGN
> • Sign in with Apple, so your email stays private
> • Locations rounded to about 100 m and shown as a neighborhood, never an address
> • Report any request, message or person, and block anyone
> • Requests and messages are checked for offensive words
> • For adults 18 and over
>
> Favorly is starting on Roosevelt Island and across New York City. Ask for your first favor today.

**Keywords (100)**

```
neighbor,neighborhood,help,favor,borrow,local,community,errand,volunteer,kindness,nyc,share
```

(91 characters. Leave "Favorly" out: the name is already indexed.)

**What's New:** not shown for a first version.

## Screenshots

6.9-inch iPhone (1320 × 2868), made by `sh scripts/make-store-screenshots.sh` into `docs/release/screenshots/`, uploaded in this order:

1. `1-nearby.png`: requests from neighbors nearby
2. `2-request-detail.png`: a neighbor's request
3. `3-claim.png`: claiming it
4. `4-chat.png`: messaging the neighbor
5. `5-profile.png`: Kindness score and reviews
6. `6-post.png`: asking for a favor

App Store Connect scales the 6.9-inch set down for smaller iPhones, so no other sizes are needed. Favorly is iPhone-only, so no iPad set.

## App Review information

**Sign-in required:** leave it unticked, so no user name or password is given. Favorly uses Sign in with Apple only, which has no password to share; the reviewer signs in with their own Apple ID and creates a profile. Never enter the owner's Apple ID. If Apple still asks for a demo account, reply with the SIGN-IN note below; a separate email reviewer login would need a new build and email sign-in turned on in Supabase.

**Contact:** the account holder's name, phone and email. Moderation contact: favorlysupport@gmail.com.

**Notes (4,000):**

> Favorly lets neighbors post small help requests ("Need a cup of rice") and lets people nearby claim them, message each other and leave a review when the favor is done.
>
> SIGN-IN: Favorly uses Sign in with Apple only. There is no username or password, so no demo account is provided. Please sign in with any Apple ID on the review device, then choose a display name, confirm you are 18 or older and accept the Terms. A new account is created automatically.
>
> LOCATION: Favorly shows requests near the device's location. It launches in New York City, so a device elsewhere will see an empty Nearby list at first. That is expected: you can still post a request from the Post tab (outside NYC the neighborhood is the location's own name), and it appears on Nearby and in My Activity right away.
>
> THE FULL FLOW NEEDS TWO PEOPLE: one posts, the other claims, they chat, the requester marks it completed and reviews the helper. The attached screen recording shows the whole flow on two phones.
>
> SAFETY (guideline 1.2): a request or a profile has Report and Block in its "…" menu (top right); a chat message is reported by touching and holding it. Blocked people are listed under Profile → Settings (gear) → Blocked people. Requests and messages are checked for offensive words in the app and on the server. Reports reach our moderation queue, checked daily; contact favorlysupport@gmail.com. Terms of Use, Privacy Policy and safety tips are linked from Profile → Settings.
>
> ACCOUNT DELETION (5.1.1(v)): Profile → Settings (gear) → Delete account.
>
> Notifications are optional and only about the user's own requests and chats.

**Attachment:** a screen recording of the two-phone flow (post, claim, chat, complete, review). Record it on two TestFlight phones before submitting.
