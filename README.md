# GoGol

GoGol (formerly MADAL) is a Somali-first, video-focused social app for Android and the web.

## Latest verified release

**GoGol 1.10.30**

- [Download GoGol 1.10.30 for Android](https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.30/app-debug.apk)
- [Release notes and web bundle](https://github.com/amiir2188-commits/MADAL/releases/tag/v1.10.30)
- [All releases](https://github.com/amiir2188-commits/MADAL/releases)

The Android APK build and GitHub Pages deployment for this release completed successfully. The APK is a beta/debug-signed build distributed directly; it is not a Play Store release.

## Current beta capabilities

- Browse and upload video posts.
- Create an account and sign in with email and password.
- Phone sign-in with Somalia's +252 numbers when Supabase Phone Auth and an SMS provider are configured.
- Like and comment on posts, follow creators, and view For You and Following feeds.
- Search creators, view profiles, and send private messages.
- Share and repost content; save favorites.
- In-app web-content update notifications.

Some social and safety features depend on the matching Supabase tables, policies, and migrations being installed. Stories and live streaming are not yet implemented as complete user-facing features. The For You feed uses a local engagement/freshness ranking; it is not represented as a trained AI recommendation system.

## Supabase setup

1. Configure the Supabase project URL and publishable/anon key for the app. Never put a service-role or secret key in client-side code.
2. For a new database, review `supabase_schema.sql` before running it in the Supabase SQL Editor.
3. For an existing database, review and apply only the migrations that match its current schema, in order. In particular, the social v2, message read-receipt, media/message compatibility, and user safety/moderation migrations are separate SQL files under `supabase/migrations/`.
4. Enable Phone Auth and configure an SMS provider if phone-number sign-in is required.

Applying SQL is an administrator action and is not performed automatically by publishing the app. Back up the database and review migration contents before applying them to a production project. Report/block features require the user-safety migration and its RLS policies to be installed.

## Technical notes

- Android application ID: `com.madal.app` (keep this stable for upgrades).
- Native Android changes require a new APK; web-content changes can be published separately.
- iPhone does not currently have a native IPA build.
- Users should upload only media they own or are authorized to share.
