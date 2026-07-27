# MIGRATION_REPORT.md — Dependency Upgrade (July 2026)

**I could not execute `flutter pub get` / `flutter analyze` / `flutter build apk` in
this environment** (no Flutter SDK, no network access to pub.dev). Everything
below was verified by hand: researching each package's current published
version and changelog, tracing the actual dependency graph, and reading every
call site in this codebase against the current API. Please run the three
commands yourself as a final check — see **Manual steps** below.

## Root cause of the original conflict

`firebase_auth_web` (pulled in transitively by `firebase_auth`) had moved to
`web: ^1.0.0`, while the pinned `share_plus ^9.0.0` was still on `web: ^0.5.0`.
Pub resolves the dependency graph for **all** platform variants a package
declares (web included), even on an Android-only build, so this failed
`pub get` outright. The fix is version, not code: `share_plus` (and every
other package below) has since moved to the `web: ^1.x` generation, so the
whole graph now resolves on one consistent major.

## Packages updated (pubspec.yaml)

| Package | Old | New | Why |
|---|---|---|---|
| firebase_core | (unpinned/implicit) | `^4.8.0` | Floor required by firebase_auth 6.5.0 |
| firebase_auth | `^5.3.3` | `^6.5.0` | Latest stable; source of the original `web` conflict |
| cloud_firestore | `^5.5.0` | `^6.1.2` | Released in lockstep with firebase_auth/core |
| google_sign_in | `^6.2.2` | `^7.2.0` | Latest stable — **major breaking API**, see below |
| share_plus | `^9.0.0` | `^12.0.1` | The actual fix for the reported conflict (now on `web ^1.x`) |
| shared_preferences | `^2.3.3` | `^2.5.0` | Latest stable (legacy `SharedPreferences.getInstance()` API unchanged, still supported) |
| path_provider | `^2.1.3` | `^2.1.5` | Latest stable, no API change |
| pdf | `^3.11.0` | `^3.11.3` | Latest stable, no API change |
| printing | `^5.13.1` | `^5.14.3` | Latest stable, no API change (not currently called directly — see note below) |
| screenshot | `^3.0.0` | `^3.0.0` | Already latest; no change |
| provider | `^6.1.2` | `^6.1.2` | Already latest; no change |
| flutter_launcher_icons | `^0.14.3` | `^0.14.3` | Already latest; confirmed no longer conflicts with flutter_native_splash's `image` dependency (that was a real historical conflict pre-0.13, already avoided) |
| flutter_native_splash | `^2.4.4` | `^2.4.4` | Already latest; no change |
| Dart SDK floor | `>=3.5.0` | `>=3.7.0` | Raised to match google_sign_in 7.x's actual minimum Dart requirement |

`printing` is declared but not directly imported anywhere in `lib/` — the app
generates PDFs via `pdf` and shares the file via `share_plus`, it never calls
`Printing.layoutPdf`. Left in for future "print to a real printer" support;
harmless either way.

## Files modified

- **`pubspec.yaml`** — all version bumps above.
- **`lib/services/firebase_auth_service.dart`** (the Google Sign-In /
  Firebase Auth wrapper) — full rewrite of the Google Sign-In flow for the
  v7 API. This is the only file with real breaking-API surface.
- **`lib/main.dart`** — Firestore offline-cache configuration migrated off
  the deprecated `Settings(persistenceEnabled:, cacheSizeBytes:)` fields.
- **`lib/screens/settings_screen.dart`** — one Flutter-SDK-level deprecation
  fixed (`Color.withOpacity` → `Color.withValues(alpha:)`), unrelated to the
  package bumps but caught in the same "no deprecated APIs" sweep.
- **`android/app/build.gradle`** — `compileSdk`/`targetSdk` 36, `minSdk` 23
  (firebase_auth 6.x's floor), core library desugaring enabled. Already
  correct for these versions; re-verified, no further change needed.
- **`android/build.gradle`** — AGP 8.12.0 / Kotlin 2.2.21. Already ahead of
  what these package versions require; re-verified, no change needed.
- **`codemagic.yaml`** — re-verified against the new dependency set; no
  change needed (it already just runs `flutter pub get` / `analyze` /
  `build apk` / `build appbundle` generically).
- **iOS** — not applicable. This project has no `ios/` directory; it is an
  Android-only app (confirmed — `flutter_launcher_icons`/`flutter_native_splash`
  already had `ios: false`).

Everything else (`lib/providers/auth_provider.dart`,
`lib/services/admin_repository.dart`, `lib/screens/auth/login_screen.dart`,
every Firestore repository, every screen) was read against the new package
APIs and needed **no changes** — they only use long-stable
`cloud_firestore`/`firebase_auth` surface (`collection().doc().snapshots()`,
`signInWithEmailAndPassword`, `signInWithCredential`, `FieldValue.serverTimestamp()`,
`WriteBatch`, `FirebaseAuth.instanceFor(app:)`, etc.) that didn't change in
these releases.

## Breaking API fixes, in detail

### 1. Google Sign-In v7 (the big one)

`google_sign_in` v7 replaced the old constructor + instance-method API with
a singleton that must be explicitly initialized, and swapped null-on-cancel
for a thrown exception:

| Old (v6) | New (v7) |
|---|---|
| `GoogleSignIn(scopes: [...])` | `GoogleSignIn.instance` (singleton) + one-time `await instance.initialize()` |
| `await googleSignIn.signIn()` → `null` on cancel | `await googleSignIn.authenticate()` → throws `GoogleSignInException` on cancel |
| `await googleUser.authentication` (async) | `googleUser.authentication` (synchronous property, ID token only) |
| `googleAuth.accessToken` | `await googleUser.authorizationClient.authorizeScopes([...])` → separate step for the access token |

`lib/services/firebase_auth_service.dart` now:
- Lazily calls `GoogleSignIn.instance.initialize()` once before first use
  (no client ID needed — resolved automatically from `google-services.json`,
  provided its web OAuth client entry exists, which needs your SHA-1
  registered — see Manual steps).
- Calls `authenticate()` inside a `try`/`on GoogleSignInException` block and
  maps `GoogleSignInExceptionCode.canceled` / `.interrupted` to
  user-facing messages instead of relying on a null return.
- Gets the ID token off the synchronous `authentication` property and the
  access token via `authorizationClient.authorizeScopes(['email','profile'])`,
  then builds the same `GoogleAuthProvider.credential(idToken:, accessToken:)`
  as before — `signInWithCredential` itself is unchanged.
- `signOut()` now only calls `GoogleSignIn.instance.signOut()` if it was
  actually initialized this session (avoids an avoidable exception on an
  email/password-only session).

### 2. Firestore offline cache — deprecated `Settings` fields

`Settings(persistenceEnabled: true, cacheSizeBytes: ...)` is deprecated
(and in newer natives, setting it alongside `cacheSettings` throws at
runtime). `lib/main.dart` now uses:

```dart
FirebaseFirestore.instance.settings = Settings(
  cacheSettings: PersistentCacheSettings(sizeBytes: Settings.CACHE_SIZE_UNLIMITED),
);
```

Same behavior (unlimited persistent on-disk cache), current API.

### 3. `Color.withOpacity` → `Color.withValues(alpha:)`

Flutter-SDK-level deprecation (not a package bump), fixed in
`settings_screen.dart`'s email-verification banner background color.

## What did *not* need to change, and why

- **`share_plus` call sites** (`lib/services/report_service.dart`) already
  used the current `SharePlus.instance.share(ShareParams(files:, text:))`
  API — that's been stable since share_plus ~10.x, so bumping to 12.0.1 was
  a pure version change with zero code impact.
- **firebase_auth 6.x / cloud_firestore 6.x "removed deprecated functions"**
  — checked the actual removed-symbol list (`MicrosoftAuthProvider.credential()`,
  `ActionCodeSettings.dynamicLinkDomain`, and Firestore's old cache-config
  path handled in item 2 above); none of the other symbols this app uses
  (`signInWithEmailAndPassword`, `sendPasswordResetEmail`,
  `sendEmailVerification`, `reload`, `updateDisplayName`, `signOut`,
  `authStateChanges`, `FieldValue.serverTimestamp()`, `WriteBatch`,
  `SetOptions(merge: true)`, query `.where`/`.orderBy`/`.limit`) were on
  that list.
- **Android Gradle config** was already provisioned for this exact
  generation of Firebase packages (compileSdk 36, minSdk 23, AGP 8.12,
  Kotlin 2.2.21, core library desugaring) from the previous migration pass
  — re-checked, still correct, nothing to bump.

## Manual steps (still required — unrelated to this dependency bump)

1. **Run the three commands yourself to get real confirmation**, since I
   can't execute them here:
   ```
   flutter pub get
   flutter analyze
   flutter build apk --release
   ```
   If `pub get` reports any remaining conflict, `flutter pub deps` will show
   exactly which package pins it, and `flutter pub upgrade --major-versions`
   is the fastest path to a resolvable set.
2. **Google Sign-In still needs your SHA-1 fingerprint registered in
   Firebase** (unchanged from before — this is a Firebase Console step, not
   a code issue): `cd android && ./gradlew signingReport`, then Firebase
   Console → Project Settings → your Android app → Add fingerprint, then
   re-download `google-services.json`.
