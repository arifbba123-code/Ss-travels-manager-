# CHANGELOG — Build & Compatibility Fixes

Scope of this pass: make the project compile and build cleanly (debug +
release APK/AAB) on current Flutter/Android/Firebase tooling, without
touching UI, business logic, branding, assets, icons, or the splash screen.
No code was verified with a live `flutter build` in the sandbox this was
produced in (no Flutter SDK / no network access there) — every change below
is a manual, version-checked static fix. See "Known limitation" at the
bottom for the one item that still needs a local/CI step to fully resolve.

## Root cause found first

`firebase_auth` (the version already pinned in `pubspec.yaml`, and every
version currently on pub.dev) requires **minSdk 23**. The project's
`android/app/build.gradle` had `minSdk 21`. This alone would fail the build
the instant Gradle resolves the Firebase Auth AAR
(`uses-sdk:minSdkVersion 21 cannot be smaller than version 23`). Everything
else below layers on top of that fix.

## Android / Gradle

- **`android/app/build.gradle`**
  - `minSdk` raised from `21` → `23` (required by `firebase_auth`).
  - Added `multiDexEnabled true` and an `androidx.multidex` dependency —
    Firebase Auth + Cloud Firestore + Google Sign-In push the app close to
    the 64K method-count limit; this keeps release builds safe.
  - Added an optional real release-signing config: if `android/key.properties`
    exists (see `key.properties.example`) the release build type is signed
    with your own upload keystore; if it doesn't exist, it falls back to the
    debug key exactly as before, so CI keeps working with zero setup.
  - `compileSdk` / `targetSdk` were already `36` — left as-is (matches
    Android 15/16 and the AGP version below).
- **`android/build.gradle`**
  - AGP classpath `8.6.0` → `8.12.0` (latest stable; officially supports up
    to API level 36 — 8.6 only supported API 35).
  - Kotlin Gradle plugin `2.0.21` → `2.2.21` (latest stable 2.2.x).
- **`android/settings.gradle`**
  - Matching plugin-version bumps: `com.android.application` → `8.12.0`,
    `org.jetbrains.kotlin.android` → `2.2.21`, `com.google.gms.google-services`
    → `4.5.0` (latest, per Firebase's own docs).
- **`android/gradle/wrapper/gradle-wrapper.properties`**
  - Gradle `8.14` → `8.14.3` (latest patch in the 8.14 line; compatible with
    AGP 8.12).
- **`android/gradle.properties`**
  - Added `org.gradle.parallel=true` and `org.gradle.caching=true` for
    faster builds.
  - Disabled `android.enableJetifier` — every plugin this project uses
    already ships AndroidX-native artifacts, so Jetifier was dead weight.
- **`android/app/src/main/AndroidManifest.xml`**
  - Added `INTERNET` and `ACCESS_NETWORK_STATE` permissions. The debug and
    profile manifests already had `INTERNET` (Flutter adds it automatically
    for the debug VM service), but the **release** manifest did not. Since
    `firebase_auth`, `cloud_firestore`, and `google_sign_in` were added to
    `pubspec.yaml`, every release build would have silently been unable to
    reach the network for any of them. Replaced the now-inaccurate "fully
    offline, no network permission" comment with an accurate one — the core
    fleet-management data still lives entirely in local SQLite and never
    needs network access; only the Firebase/Google integrations do.
- **`android/gradlew`, `android/gradlew.bat`** — added. The uploaded project
  was missing the Gradle wrapper launcher scripts entirely, which are
  required for `flutter build` to invoke Gradle at all, locally or in CI.
- **`android/key.properties.example`** — added, as a template for real
  release signing (see above).
- **`.gitignore`** — added (there wasn't one). Ignores build output,
  `local.properties`, and keystore/`key.properties` secrets, while
  explicitly keeping the Gradle wrapper files tracked.

## `pubspec.yaml`

- `environment.sdk`: `>=3.0.0 <4.0.0` → `>=3.6.0 <4.0.0` (matches current
  Flutter stable's bundled Dart SDK; the old floor was wide enough to
  resolve against SDKs too old for the Firebase versions below).
- `firebase_core`: `^4.1.0` → `^4.12.1` (latest stable).
- `firebase_auth`: `^6.0.2` → `^6.5.6` (latest stable).
- `cloud_firestore`: `^6.0.1` → `^6.7.1` (latest stable).
- `google_sign_in` left at `^7.1.1` — already current, and see the note
  below about it being unused in code.
- `flutter_launcher_icons.min_sdk_android`: `21` → `23`, just to stay
  consistent with the real app `minSdk` above (this setting only affects
  which launcher-icon shapes are generated, not the build itself).
- All other dependencies (`sqflite`, `path`, `path_provider`, `provider`,
  `pdf`, `printing`, `screenshot`, `share_plus`, `intl`, `cupertino_icons`,
  `flutter_native_splash`) were already on current, mutually-compatible
  versions and were left untouched.

## Dart source

- **`lib/main.dart`** — wrapped `Firebase.initializeApp()` in a `try/catch`.
  Previously, if Firebase failed to initialize (no network on first launch,
  missing Play Services, etc.) the whole app would fail to start, even
  though every actual feature (vehicles, drivers, daily entries, PDF/PNG
  reports) runs entirely offline against the local SQLite database. Now a
  Firebase failure is silently absorbed and the app starts normally.
- **`lib/screens/entry_detail_screen.dart`** — replaced deprecated
  `WillPopScope` with `PopScope` (`onPopInvokedWithResult`), matching the
  same back-button behavior (confirms whether the entry changed before
  popping).
- **`withOpacity(...)` → `withValues(alpha: ...)`** (deprecated in current
  Flutter) in:
  - `lib/screens/auth/role_dashboard_widgets.dart` (3 call sites)
  - `lib/screens/auth/login_screen.dart`
  - `lib/screens/auth/driver_dashboard_screen.dart`
  - `lib/screens/auth/auth_loading_screen.dart`

No UI, layout, colors, navigation, or business logic changed — only the API
surface used to express the same values.

## `codemagic.yaml`

- `flutter: "3.32.8"` → `flutter: stable`, so CI always builds against the
  current Flutter stable release rather than a version that will keep
  drifting further out of date.
- Added a step that runs `gradle wrapper --gradle-version 8.14.3
  --distribution-type bin` before the Flutter build (see "Known limitation"
  below — Codemagic's macOS images ship Gradle preinstalled, so this
  regenerates the missing wrapper jar automatically on every build).
- Added a second build step for `flutter build appbundle --release`
  alongside the existing `flutter build apk --release`, and added the
  matching `.aab` artifact path, so both APK and AAB come out of every run.

## Not changed, on purpose

- **`AuthService` (`lib/services/auth_service.dart`) was left as-is.** It's
  a local, in-memory stub (hardcoded owner/admin/driver accounts) and
  nothing in the codebase currently calls `firebase_auth`, `cloud_firestore`,
  or `google_sign_in` anywhere — they were declared in `pubspec.yaml` but
  dead weight. This pass makes all three compile and link correctly and
  wires up the plumbing they need (INTERNET permission, minSdk 23, current
  SDK versions), but it does **not** invent a new login flow against them,
  since that's a feature to build, not a bug to fix. If/when you want real
  Firebase Authentication (and, separately, real Google Sign-In) wired into
  the login screen, that's a follow-up task.
- **`android/app/google-services.json`** — the `package_name` inside it
  already matches `applicationId "com.sstours.sstours_travels"`, so it's
  correctly configured for what's there. Its `oauth_client` array is empty,
  which means Google Sign-In has no OAuth client ID configured yet — that
  has to be set up in the Firebase console (add your app's SHA-1
  fingerprint, then re-download `google-services.json`) before Google
  Sign-In can actually complete a sign-in; it isn't something fixable from
  source code alone.
- Assets, icons, splash screen, theme, navigation structure, and all
  screens' business logic are untouched.

## Known limitation — please read

**`android/gradle/wrapper/gradle-wrapper.jar` (the small binary that
bootstraps Gradle) could not be regenerated in the sandbox this fix was
produced in** — it has no internet access and no local Gradle/JDK compiler
to produce a verified binary, and fabricating one blind would risk shipping
a corrupt jar that fails in a confusing way. Three ways to resolve it,
pick whichever is easiest for you:

1. **Do nothing extra for Codemagic** — the updated `codemagic.yaml` now
   regenerates this file automatically at the start of every build using
   the Gradle already installed on Codemagic's macOS build image.
2. **Open the project in Android Studio once** — it detects the missing
   wrapper jar and regenerates it automatically on sync.
3. **Locally, with any Gradle installed:** run
   `cd android && gradle wrapper --gradle-version 8.14.3 --distribution-type bin`
   once, then commit the generated `gradle/wrapper/gradle-wrapper.jar`.

`gradlew` and `gradlew.bat` themselves (the launcher scripts, plain text)
are included in this ZIP and do not need regenerating.
