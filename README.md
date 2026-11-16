# GoGol

GoGol (formerly MADAL) is a Somali-first, video-focused social app for Android and the web.

## Latest verified release

**Android and Web: GoGol 1.10.57 (LIVE beta integration)**

- [Download GoGol 1.10.56 for Android](https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.56/app-debug.apk)
- [Download GoGol 1.10.56 web bundle](https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.56/madal-web.zip)
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
- Multi-photo albums: upload up to 10 photos and browse the published album in a swipeable carousel.
- 24-hour Stories: upload, view with previous/next navigation, and delete photo/video updates (requires Supabase migration 008).\n- GoGol LIVE beta: create a live camera/microphone broadcast and join active streams as a viewer (requires migration 009, LiveKit credentials, and the `live-token` Edge Function).

This is still a beta. Some social and safety features depend on the matching Supabase tables, policies, and migrations being installed. The current release is not a Play Store production release. The Stories client and database migration are implemented; Stories become available after applying migration 008 and deploying the scheduled cleanup function. A first GoGol LIVE integration is included in 1.10.57: hosts can publish camera/microphone and signed-in users can join as viewers through LiveKit. It requires migration 009, deployment of the `live-token` Edge Function, and the LiveKit secrets below. It is not production-ready until multi-device tests, moderation/reporting, chat, capacity and network-failure tests are completed. The For You feed uses a local engagement/freshness ranking; it is not represented as a trained AI recommendation system.

## GoGol LIVE setup\n\nThe LIVE client uses LiveKit for real-time audio/video. Apply `supabase/migrations/20261116000900_live_streaming.sql`, deploy `supabase functions deploy live-token`, then set these Edge Function secrets in Supabase: `LIVEKIT_URL` (your LiveKit WebSocket URL), `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET`. Keep the API secret server-side only; the `live-token` function verifies the signed-in GoGol user and issues a room-scoped token with publish permission only for the session owner. See [LiveKit token and grant documentation](https://docs.livekit.io/home/server/generating-tokens). Configure a LiveKit Cloud project or self-hosted LiveKit server before testing. The browser client loads the LiveKit SDK from jsDelivr, so the first launch of LIVE requires internet access.\n\n## Supabase setup

### Optional controlled production deployment

A manual GitHub Actions workflow is provided at **Actions → Deploy GoGol Supabase backend**. Before running it, add these GitHub Actions secrets: `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, and a strong random `GOGOL_CRON_SECRET`. Configure the GitHub `production` environment with required reviewers. The workflow requires explicit production-deploy and database-backup confirmations, previews pending migrations, then applies migrations and deploys the account-deletion and expired-Stories functions. Review the SQL changes and take a restorable database backup before approving. It does not configure Supabase Cron automatically; after deployment, schedule the cleanup POST every 15 minutes in Supabase Dashboard → Integrations → Cron, using the same secret in the Authorization bearer header.


1. Configure the Supabase project URL and publishable/anon key for the app. Never put a service-role or secret key in client-side code.
2. For a new database, review `supabase_schema.sql` before running it in the Supabase SQL Editor.
3. For an existing database, review and apply only the migrations that match its current schema, in order. The profile/avatar, message read-receipt, media/message compatibility, user safety/moderation, photo album, social post-visibility, account deletion, and 24-hour Stories migrations are separate SQL files under `supabase/migrations/`.
4. Deploy the account deletion function with `supabase functions deploy delete-account`. Keep the Supabase service-role key only in the Edge Function environment; never put it in client code.
5. Enable Phone Auth and configure an SMS provider if phone-number sign-in is required.

6. Deploy the expired-Stories cleanup function with `supabase functions deploy cleanup-expired-stories`, then set a strong random `CRON_SECRET` using `supabase secrets set CRON_SECRET=...`. In Supabase Dashboard Cron, schedule a POST to `/functions/v1/cleanup-expired-stories` every 15 minutes with `Authorization: Bearer <CRON_SECRET>` and `Content-Type: application/json`. The function deletes expired media from `madal-media` before deleting their database rows; it processes up to 500 per run. Never expose this secret in the app.

Applying SQL is an administrator action and is not performed automatically by publishing the app. Back up the database and review migration contents before applying them to a production project. Report/block features require the user-safety migration and its RLS policies to be installed.

## Technical notes

- Android application ID: `com.madal.app` (keep this stable for upgrades).
- Native Android changes require a new APK; web-content changes can be published separately.
- iPhone does not currently have a native IPA build.
- Users should upload only media they own or are authorized to share.
