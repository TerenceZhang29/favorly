# App Store privacy answers (draft)

What to enter in App Store Connect → App Privacy for Favorly 1.0. It must match what the app does and the Privacy Policy (`site/privacy.html`). Re-check before every release that changes what is collected.

## Does the app collect data?

Yes. None of it is used for tracking (no data is linked with other companies' data for advertising, and no data broker sees it), so **Data Used to Track You: none**.

## Data linked to the user

| Apple's category | Type | What Favorly collects | Purpose (Apple's names) |
| --- | --- | --- | --- |
| Contact Info | Name | The display name the user chooses | App Functionality |
| Identifiers | User ID | Sign in with Apple's user identifier, and the account ID | App Functionality |
| Identifiers | Device ID | The APNs push token, if notifications are allowed | App Functionality |
| Location | Precise Location | The position rounded to 3 decimal places (about 100 m), with requests and to find nearby ones | App Functionality |
| User Content | Other User Content | Requests (title, details, category, neighborhood) and reviews | App Functionality |
| User Content | Other User Content | Reports and blocks | App Functionality (moderation) |
| User Content | Emails or Text Messages | Chat messages between requester and helper | App Functionality |

Not collected: email address, phone number, contacts, photos, health, financial info, browsing or search history, purchases, usage data, diagnostics, advertising data.

Notes for the questionnaire:

- **Precise, not coarse, location.** Apple's definitions call a location precise when it has three or more decimal places of latitude and longitude. Favorly keeps exactly three (about 100 m), so it declares **Precise Location**. Declaring Coarse Location would need rounding to two places (about 1 km), which would make the 0.25-mile radius on Nearby meaningless. The Privacy Policy still describes it as rounded to about 100 m.
- **Diagnostics.** Favorly includes no crash reporting SDK. Crash logs Apple shares with developers through Xcode Organizer are covered by Apple's own disclosure, not the app's.
- **Name.** Display names are chosen by the user and may be a nickname; Apple still treats them as Name.

## Age rating

Answer the questionnaire with: user-generated content and messaging between users, unrestricted. Favorly requires users to be 18 or older at sign-up; choose the 18+ rating.
