# GoGol

GoGol (formerly MADAL) is a Somali-first, video-focused social app for Android.

## Current beta features

Latest release: **GoGol 1.10.22**. Recent fixes include six-digit SMS verification validation, safer moderation-report deletion behavior, and accessible account form labels.
- Watch and upload videos.
- Create an account and sign in with email/password.
- Phone-number sign-in using Somalia's +252 format (requires Phone Auth and an SMS provider in Supabase).
- Like videos, comment, and follow creators.
- Search users by username and send private messages.
- Receive in-app prompts when a new web-app update is available.

## Download
[Download the latest MADAL Android APK](https://github.com/amiir2188-commits/MADAL/releases/latest/download/app-debug.apk)

[View all MADAL releases](https://github.com/amiir2188-commits/MADAL/releases)

## Supabase setup
For a fresh project, run [supabase_schema.sql](./supabase_schema.sql) in the Supabase SQL Editor.
For an existing project, the same script is designed to add the current social and messaging tables and policies without deleting existing posts.

To enable phone registration, turn on Phone Auth in Supabase Authentication and configure an SMS provider. Email sign-in remains available without SMS.

## Notes
- The Android APK is a beta/debug-signed build distributed directly; it is not a Play Store release.
- Regular web-content updates can be delivered inside the installed app. Native Android changes still require a new APK.
- The native Android package is `com.madal.app`. iPhone does not have a native IPA build yet.
