# SS Tours & Travels — Manager App

A fully **offline** Flutter app for managing a small tours & travels fleet:
daily collections/expenses, auto balance calculation, vehicle & driver
management, history with search/filter, and shareable PDF/PNG reports
(WhatsApp-ready). All data is stored locally with **SQLite (sqflite)** —
no internet or backend required.

## Features included

- Dashboard (today's collection/profit, month totals, quick menu)
- Daily Entry (all fields from the spec, with live auto-calculation)
- Edit Entry / Delete Entry (from the entry detail screen)
- Vehicle Management (add / edit / delete)
- Driver Management (add / edit / delete)
- History with search (vehicle, driver, notes, date) + filters (vehicle,
  driver, date range)
- Auto Balance Calculation:
  - `Total Collection = Online + Cash`
  - `Total Expense = CNG + Petrol + Driver Salary + Rental + Other Expense`
  - `Profit = Total Collection - Total Expense`
  - `Balance = Old Balance + Profit` (auto-fills next entry's Old Balance
    from the vehicle's last recorded balance)
- Professional PDF report (company logo, name, date, vehicle, driver,
  collection, expenses, balance) via the `pdf` + `printing` packages
- PNG image report (same layout, rendered via `screenshot` package)
- Share button → opens the system share sheet (WhatsApp, Email, Drive, etc.)
- Black & Gold themed UI throughout (`lib/theme/app_theme.dart`)

## Project structure

```
lib/
  main.dart                     – app entry point
  theme/app_theme.dart          – Black & Gold ThemeData
  db/db_helper.dart             – SQLite (sqflite) CRUD + aggregates
  models/                       – Vehicle, Driver, DailyEntry
  screens/
    splash_screen.dart          – branded welcome screen
    home_shell.dart             – bottom navigation shell
    dashboard_screen.dart       – home dashboard
    daily_entry_screen.dart     – add / edit entry form
    history_screen.dart         – search, filter, entry list
    entry_detail_screen.dart    – view / edit / delete / share an entry
    fleet_screen.dart           – vehicle & driver management (tabs)
    settings_screen.dart        – about / info
  services/report_service.dart  – PDF & PNG report generation + sharing
assets/images/logo.png          – placeholder company logo (replace with yours)
```

## How to build the APK

This project ships a **complete** Flutter project — Dart source (`lib/`),
`pubspec.yaml`, `assets/`, and a full `android/` platform folder with
launcher icons already generated from the logo. No `flutter create`
scaffolding step is needed; this folder can be built directly.

### Option A — Build on a computer with Flutter installed
```bash
cd sstours_travels
flutter pub get
flutter build apk --release
```
The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```
Copy that file to your phone and install it (enable "install from unknown
sources" if prompted).

### Option B — Build entirely from your phone, no computer needed
1. Extract this zip.
2. Create a free GitHub account and a new repository, then upload **all**
   the files/folders from this project (including the hidden `android/`
   folder and `codemagic.yaml`) into it.
3. Sign up at codemagic.io with your GitHub account and select this repo.
4. Codemagic will detect the included `codemagic.yaml` automatically
   (workflow: **android-release**) — just tap **Start new build**.
5. When the build finishes, download the `.apk` artifact straight to your
   phone and install it.

No internet permission is required at runtime — the app is 100% offline;
internet is only used during the *build* step to fetch Flutter packages.

### Optional: your real logo
Replace `assets/images/logo.png` with your actual SS Tours & Travels logo
(same filename) before building — it's used in both the PDF and PNG
reports.

## Notes
- Minimum Flutter SDK: 3.0+ (Dart 3).
- All packages used (`sqflite`, `pdf`, `printing`, `screenshot`,
  `share_plus`, `path_provider`, `intl`, `provider`) are actively
  maintained and available on pub.dev — `flutter pub get` will fetch
  them automatically, no manual downloads needed.
- The app works fully offline; `share_plus` only opens the device's native
  share sheet (e.g. WhatsApp) — it does not require its own internet
  access, since sending the file over WhatsApp is handled by WhatsApp
  itself.
