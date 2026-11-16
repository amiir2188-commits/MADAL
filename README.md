# GoGol

GoGol (formerly MADAL) is a Somali-first, video-focused social app for Android and the web.

## Latest verified release

**Android and Web: GoGol 1.10.53**

- [Download GoGol 1.10.53 for Android](https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.53/app-debug.apk)
- [Download GoGol 1.10.53 web bundle](https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.53/madal-web.zip)
- [All releases](https://github.com/amiir2188-commits/MADAL/releases)

The Android APK is a beta/debug-signed build distributed directly; it is not a Play Store release.

## Current beta capabilities

- Browse and upload photo and video posts, including multi-photo albums (up to 10 images).
- Create an account and sign in with email and password.
- Phone sign-in with Somalia's +252 numbers when Supabase Phone Auth and an SMS provider are configured.
- Like and comment on posts, follow creators, and view For You and Following feeds.
- Search creators, view profiles, and send private messages.
- Share and repost content; save favorites.
- In-app web-content update notifications.
- Somali account sign-up and sign-in interface with required privacy-policy and terms consent.
- Privacy policy, community guidelines, and terms pages.
- Secure account deletion from Settings (requires the matching Supabase migration and deployed Edge Function).
- 24-hour Stories: upload, view, and delete photo/video updates (requires Supabase migration 008).

This is still a beta. Some social and safety features depend on the matching Supabase tables, policies, and migrations being installed. The current release is not a Play Store production release. The Stories client and database migration are implemented; Stories become available after applying migration 008. Live streaming is not implemented yet. The For You feed uses a local engagement/freshness ranking; it is not represented as a trained AI recommendation system.

## Supabase setup

1. Configure the Supabase project URL and publishable/anon key for the app. Never put a service-role or secret key in client-side code.
2. For a new database, review `supabase_schema.sql` before running it in the Supabase SQL Editor.
3. For an existing database, review and apply only the migrations that match its current schema, in order. The profile/avatar, message read-receipt, media/message compatibility, user safety/moderation, photo album, social post-visibility, account deletion, and 24-hour Stories migrations are separate SQL files under `supabase/migrations/`.
4. Deploy the account deletion function with `supabase functions deploy delete-account`. Keep the Supabase service-role key only in the Edge Function environment; never put it in client code.
5. Enable Phone Auth and configure an SMS provider if phone-number sign-in is required.

Applying SQL is an administrator action and is not performed automatically by publishing the app. Back up the database and review migration contents before applying them to a production project. Report/block features require the user-safety migration and its RLS policies to be installed.

## Technical notes

- Android application ID: `com.madal.app` (keep this stable for upgrades).
- Native Android changes require a new APK; web-content changes can be published separately.
- iPhone does not currently have a native IPA build.
- Users should upload only media they own or are authorized to share.
