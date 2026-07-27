# SS Tours & Travels — Cloud Multi-Admin Migration Notes

## The one thing you still need to do

Your `google-services.json` has no `oauth_client` entry, which means
**Google Sign-In will fail on Android until you register your app's SHA-1
fingerprint with Firebase**:

1. Get your SHA-1: `cd android && ./gradlew signingReport` (debug SHA-1 is
   enough to test; add your release keystore's SHA-1 too before you ship).
2. Firebase Console → Project Settings → Your apps → (Android app) → Add
   fingerprint → paste the SHA-1.
3. Re-download `google-services.json` and replace `android/app/google-services.json`.

Email/password login, Forgot Password, and email verification all work
without this step — it's only Google Sign-In that needs it.

Also deploy the included `firestore.rules` (Firebase Console → Firestore
Database → Rules, or `firebase deploy --only firestore:rules`) — without
it your database is likely still in test mode or locked closed.

## What changed

- **SQLite is gone.** Every screen now reads/writes Cloud Firestore in
  real time via `StreamBuilder`/stream subscriptions — no manual refresh
  anywhere.
- **Collections:** `admins`, `vehicles`, `drivers`, `daily_collections`,
  `expenses` (auto-mirrored from each daily entry), `reports` (a log
  entry each time a PDF/PNG is generated), `settings`, `audit_logs`
  (one entry per create/update/delete, everywhere).
- **Every document** carries `createdBy`, `createdAt`, `updatedBy`,
  `updatedAt`.
- **Auth:** email/password, Google Sign-In, Forgot Password, email
  verification (soft — a dismissible banner, not a hard lock-out),
  auto-login (Firebase persists sessions on Android natively), and a
  "Remember me" checkbox that actually signs you out on next launch if
  unchecked.
- **Roles:** Super Admin (full access incl. managing admins) and Admin.
  The very first person to ever sign in is automatically bootstrapped as
  Super Admin; every Super Admin afterwards must be created by an
  existing Super Admin from the new **Manage Admins** screen.
  Creating a new admin uses a secondary throwaway Firebase app instance
  so the acting Super Admin isn't logged out in the process.
- Super Admin accounts can never be deactivated or deleted through the
  app (enforced both client-side and in `firestore.rules`).
- New **Audit Log** screen (Settings → Audit Log, or Super Admin
  dashboard tile) shows every change across the whole app in real time.
- UI, navigation, colors, and existing business logic are unchanged.

## Known limitation (by design, not an oversight)

Deleting an admin removes their Firestore profile (which is what
actually gates access to the app), but their underlying Firebase Auth
account isn't deleted — that requires the Firebase Admin SDK / Cloud
Functions, which a client-only Flutter app can't do. Functionally this
is equivalent to a delete from inside the app.

## Driver dashboard

`driver_dashboard_screen.dart` was left in the codebase (repointed to
Firestore so it still compiles) but isn't reachable from the new login
flow — your spec's admin system only defines Super Admin / Admin roles,
so there's no driver-login account type in the `admins` collection.
Let me know if you want driver logins added as a third role.

## Codemagic

`codemagic.yaml` now verifies `google-services.json` is present, writes
`android/key.properties` automatically **only if** you've configured a
keystore in Codemagic's Code Signing settings (build still succeeds
without one, using the debug key), and enables core library desugaring
(a common Gradle failure point with Firebase on minSdk 23).
