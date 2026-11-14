# Spentr

Group project for **SWE 463 — Mobile Application Development**, **Group 02**.

A Flutter app for Android and iOS with an ASP.NET Core and SQL Server back-end.

Spentr is a time and earnings diary for freelancers and part-time programmers. One tap records a shift, and the app turns the hours into money at the user's own hourly rate, tagged by client or project. Shifts are written to the phone first, so nothing depends on a connection, and they sync to the API when the phone is online.

## Team

The group has three members for Phase 3.

| Name | Student ID | Phase 3 responsibility | GitHub |
|------|------------|------------------------|--------|
| Abdulrazaq Musaab Ahmad | 202267720 | **1 — Data storage and shift records (E2):** Dart models, SQLite repository, `ShiftProvider`, manual entry, shift details, edit and delete, input validation | `amussab` |
| Osama Ahmed Alghamdi | 202172210 | **2 — App foundation and earnings (E3):** Material 3 theme, Provider setup, screens and navigation, hourly rate and currency settings, earnings calculations, timer screen | `1OSDD` |
| Moath Haimour | 202182130 | **3 — History, dashboard and integration (E4, E5):** History search, filters and sorting, dashboard connected to saved records, integration, tests and submission evidence | `MoathEssa` |

## Status

**Phase 3 — Working Flutter Prototype** (tag `phase-3`).

The app builds and runs on Android. Every major screen from the Phase 2 design is reachable. Four of the six essential features work end to end on saved data:

| # | Essential feature | Phase 3 status |
|---|---|---|
| E1 | Shift timer with notification | In progress — start, pause, continue, live earnings, and *Finish* saves the shift; restart recovery and the notification are Phase 4 |
| E2 | Shift log and manual entry | **Implemented** |
| E3 | Earnings (hourly rate and currency) | **Implemented** |
| E4 | Dashboard and month calendar | **Implemented** |
| E5 | History with search and filter | **Implemented** |
| E6 | Account and cloud sync | Not started — the Sign in / Sign up form validates input, but there is no server account yet; data stays on the device |

**4 of 6 essential features implemented (67%).** Optional features O1 (Statistics) and O2 (Export, import, app lock) are reachable placeholders.

Project layout:

- `app/` — Flutter client.
- `backend/` — ASP.NET Core Web API (planned for Phase 4).
- `Spentr-Preview.html` — standalone HTML interface prototype.
- `docs/phase2/` — [Phase 2 technical design](docs/phase2/Group02_Phase2_Technical_Design.md) and starter-app screenshots.
- `docs/phase3/screenshots/` — screenshots of the Phase 3 prototype running on an Android 15 phone.

## Run it

Requirements: Flutter SDK with Dart 3.6 or newer (developed with Flutter 3.27.3 and 3.47.9), and an Android device or emulator.

```bash
cd app
flutter pub get
flutter run
```

No account, API key or sample data is needed. On first launch:

1. Tap **New to Spentr? Create an account**, enter any valid email and a password of at least 8 characters (twice), and tap **Create account**. Accounts are not checked against a server yet.
2. Enter an hourly rate, for example `75`, choose a currency and tap **Start using Spentr**.
3. Add shifts from **History → Add manual shift**, or tap a day on the Home calendar and choose **Add a shift for this day**.

Checks before submission:

```bash
flutter analyze   # No issues found
flutter test      # 45 tests pass
```

## Phase 3 Features

**Shift records (E2).** Manual entry with start and end date and time, client / project tags, a note and reference links. Shift details, editing and confirmed deletion (a soft delete, kept for sync). The form rejects an end time before the start time and any link that is not a full `http`/`https` URL, and keeps the input when saving fails.

**Earnings (E3).** First-run rate setup and *Settings → Hourly rate & currency*. The rate must be a positive number with at most two decimals. Money is never stored: every screen computes it from the worked duration and the current rate, so changing the rate updates every shift and total at once. Settings survive restarts.

**Dashboard (E4).** This month's earnings and hours; today, this week (Monday start) and all time in hours and money; *Start shift*; a month calendar where worked days are highlighted with that day's earnings (or hours before a rate is set), with previous / next month; and the five most recent shifts with *View all*. Tapping a day opens the **Day details** sheet with that day's total and shifts and *Add a shift for this day*, which opens the form on that date.

**History (E5).** All saved shifts, grouped by month when sorted by date, with a summary of the listed shifts (count, hours, money).
- **Search** — case-insensitive text search over notes.
- **Filter sheet** — date range (inclusive, by the day the shift started) and client / project tags (a shift matches if it has any selected tag).
- **Sort** — newest first, oldest first, longest duration, highest earnings.
- Active filters appear as chips that can be removed one by one; the filter button shows how many are active.
- **No results** — *No shifts match* with *Clear search & filters*.

**Sign in / Sign up.** Email and password fields with validation (valid email; password required; at least 8 characters and a matching confirmation when creating an account), a show / hide password button, and switching between the two modes. A valid form continues to Rate setup or Home.

**Timer (E1, partly).** *Start shift* opens the timer with live earnings; pause and continue; *Finish shift* saves the worked time (pauses excluded) as a shift and opens its Shift details.

**Runtime states.** A spinner while saved shifts load; empty states on Home and History; an error message with *Retry* when the database cannot be read; *Saving…* and *Shift saved on this device* feedback; validation messages on every form.

### Working end-to-end flow

*History → Add manual shift → enter tags and a note → Save shift* → the shift is written to SQLite → History, the Home totals, the calendar day and the Day details sheet all update at once through `ShiftProvider` → close and reopen the app and the shift and rate are still there.

## State and Data

**State management: Provider** (`ChangeNotifier`), as approved in Phase 2.

| Shared state | Owner | Used by |
|---|---|---|
| Saved shifts, loading / saving / error state, CRUD | `ShiftProvider` | Home, Day details, History, Shift details, Manual entry |
| Hourly rate, currency, theme | `SettingsProvider` | Rate setup, Settings, Home, History, Shift details, Manual entry, Timer |

Screen-only state uses `setState`: History's search text, filter and sort; the calendar month on Home; form fields; the selected tab. Search, filtering and sorting are plain Dart (`core/shift_query.dart`) and the dashboard totals come from `core/dashboard_summary.dart` and `core/period_earnings.dart`, so they are unit-tested without the UI.

**Data sources.**

| Data | Storage | Notes |
|---|---|---|
| Shifts | SQLite (`sqflite`), table `shifts`, through the `ShiftRepository` interface (`SqliteShiftRepository`) | Survives restarts; soft delete; tests use an in-memory fake |
| Settings | `shared_preferences` through `SettingsStore` | Survives restarts |

**Temporary parts.** Shifts are stored under a fixed local user id (`local-demo`) until sign-in exists. The ASP.NET Core API and sync (E6) are not connected; because screens only depend on `ShiftRepository` and `SettingsStore`, the sync layer can be added in Phase 4 without changing the screens.

## Project Structure

```
app/lib/
  main.dart                 loads saved settings, then starts the app
  app.dart                  MultiProvider, MaterialApp, light and dark theme, routes
  core/
    routes.dart             named routes for every screen
    theme/                  colours and Material 3 theme from the Figma design system
    money.dart              currencies, rate validation, money formatting
    period_earnings.dart    today / week / month / all-time earnings
    dashboard_summary.dart  period hours, per-day totals for the calendar
    shift_query.dart        History search, filters and sorting
    date_labels.dart, shift_formatters.dart
  data/
    models/                 Shift, ActiveSession, AppSettings, User, SyncStatus
    repositories/           ShiftRepository interface
    local/                  SQLite shift repository, settings store
  state/                    ShiftProvider, SettingsProvider
  ui/
    screens/                one file per screen or bottom sheet
    widgets/                shift tile, empty state, hourly rate form, confirm dialog, placeholder view
app/test/                   45 unit and widget tests, with an in-memory repository and settings store
```

## Packages

| Package | Purpose | Licence |
|---------|---------|---------|
| `provider` | Shared state (`ShiftProvider`, `SettingsProvider`) | MIT |
| `sqflite` | Local SQLite database for shifts | BSD-2-Clause |
| `path` | Builds the database file path | BSD-3-Clause |
| `shared_preferences` | Hourly rate, currency and other settings | BSD-3-Clause |
| `cupertino_icons` | iOS-style icon font from the Flutter template | MIT |
| `flutter_lints` (dev) | Lint rules used by `flutter analyze` | BSD-3-Clause |

Resolved versions are in `app/pubspec.lock`. The minimum versions are set so the project resolves on Flutter 3.27 as well as newer SDKs.

## Known Issues and Phase 4 Work

- **Timer (E1):** the running shift is not kept if the app is closed before *Finish*, and there is no ongoing notification yet.
- **Account and sync (E6):** the Sign in / Sign up form only validates the email and password locally; the API, JWT and sync are not built.
- **Optional features:** Statistics (O1), Export / Import and App lock (O2) are placeholder screens.
- A shift that crosses midnight is counted on the day it started, on the calendar and in the totals.
- Search looks in notes only; client / project tags are found with the tag filter.

## UI Design and Prototype

### Figma

[View the Spentr design in Figma](https://www.figma.com/design/gjchVuZul3TXw3rcZkFjQG/Untitled?node-id=0-1)

The design covers sign-in and registration, the dashboard and calendar, shift timer controls, history, manual entry, shift details, and settings. It also includes relevant loading, empty, validation, success, and offline/error states, plus dark-theme examples.

Statistics, export/import, and biometric lock are shown as **optional features**, consistent with the Phase 1 proposal.

### HTML Prototype

The standalone prototype is available at the repository root:

[Download the HTML prototype](./Spentr-Preview.html)

To view it, download `Spentr-Preview.html` and open it in a modern web browser. No installation, server, or internet connection is required after downloading.

Click through the screens or use the sidebar to inspect individual designs and interface states. Select **Restart flow** to begin at Sign In.

The prototype uses illustrative data and prepared screen transitions. Authentication, timer tracking, cloud sync, notifications, biometrics, and file export/import are simulated for design review.

## AI Use

As required by the course policy, we disclose the following assistance:

- **Anthropic Claude** helped draft and format the Phase 1 proposal, provided small code and debugging suggestions, generated the Phase 2 Flutter starter project (placeholder screens, routes, theme and model classes), and drafted the Phase 2 technical design sections (widget plan, data model and state management plan). In Phase 3 (Claude Code) it assisted Moath's part: the History search, filter and sort logic and screens, the dashboard and Day details sheet, the Sign in form and saving a shift on timer Finish, their tests, the dependency and Android build fixes, this README, and checking the app on an Android phone.
- **ChatGPT** helped extract the Phase 1 design context, generate initial interface designs, create the HTML prototype and Figma import script, and draft README updates.
- **Cursor Grok** assisted the Phase 3 app foundation, hourly-rate persistence, earnings calculation, and timer earnings display.

The group is responsible for reviewing and revising AI-assisted material, ensuring its use follows the course policy, and accurately recording each member's actual contribution. Each member is responsible for understanding and explaining the work they submit.
