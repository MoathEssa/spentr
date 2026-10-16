# Spentr — Phase 2 Technical Design (sections 5, 6 and 7)

Group 02 · SWE 463. These sections go into `Group02_Phase2_Design.pdf` after the navigation flow.
Screen names match the Figma frames and `Spentr-Preview.html`; route and class names match the
starter project in `app/`.

---

## 5. Flutter Widget Plan

Material 3 throughout, with the Spentr colour scheme in light and dark. Main controls are at least
48 px high and every input keeps a visible label, as set in the Figma design system.

| Screen (route) | Purpose | Main Flutter widgets | Main interaction |
|---|---|---|---|
| **Sign in / Sign up** (`/`) | Create an account or sign in so shifts sync and can be restored | `Scaffold`, `SingleChildScrollView`, `Form`, `TextFormField` (email; password with `obscureText` and a visibility `IconButton`), `FilledButton`, `TextButton`, `CircularProgressIndicator`, `SnackBar` | Validate email and password, submit, show *Signing you in…*, show field errors or a network error; switch between Sign in and Create account |
| **Rate setup** (`/rate-setup`) | First-run hourly rate and currency | `Form`, `TextFormField` (number keyboard), `DropdownMenu` (currency), `Card` (earnings preview), `FilledButton` | Enter a rate, see "2 hours = SAR 150.00" update, tap *Start using Spentr* |
| **Root shell** (`/home`, `/history`, `/statistics`, `/settings`) | Hold the four main tabs | `Scaffold`, `IndexedStack`, `NavigationBar`, `NavigationDestination` | Tap a tab; each tab keeps its scroll position and search text |
| **Home / Dashboard** | Month earnings, period totals, start work, calendar, recent shifts | `CustomScrollView`, `SliverAppBar`, `Card` (month earnings), `Row` of stat cards, `FilledButton.icon` (*Start shift* / *Resume shift · 02:30:00* via `AnimatedSwitcher`), `Card` banner with `TextButton` (*Offline* / *Sync could not finish · Retry*), `GridView.builder` (7-column month calendar) with `IconButton` month arrows, `ListTile` (recent shifts), `CircularProgressIndicator`, empty-state column | *Start shift* → Timer; tap a calendar day → Day details sheet; tap a recent shift → Shift details; *View all* → History tab; *Retry* sync |
| **Day details** (sheet) | Shifts and total for one day | `showModalBottomSheet`, `ListView`, `ListTile`, `TextButton.icon` | Tap a shift → Shift details; *Add a shift for this day* → Add manual shift |
| **Session Timer** (`/timer`) | Run and control one shift | `Scaffold`, `AppBar`, `Chip` (*Tracking* / *Paused*), `Text` (large elapsed time and live earnings), `Card` (client / project, start time, paused time), `FilledButton.icon` (Pause / Continue), `OutlinedButton.icon` (Finish), `TextButton` (Cancel), `AlertDialog` | Pause and continue; *Finish shift* → confirm → saved Shift details; *Cancel shift* → confirm → discard and go back |
| **History** (tab) | Find, check and correct past shifts | `SearchBar`, `IconButton` (filter), `FilterChip` row (month, tag, sort), `CustomScrollView` with `SliverList` grouped by month and month headers, `ListTile` shift tiles, `FloatingActionButton.extended` (*Add manual shift*), empty / no-results state with *Clear search & filters* | Type to search notes; open Filter sheet; tap a shift → Shift details; *Add manual shift* → form |
| **Filter shifts** (sheet) | Date range, tag and sort order | `showModalBottomSheet`, `showDateRangePicker`, `FilterChip` (tags), `RadioListTile` (sort), `FilledButton` (*Apply filters*), `OutlinedButton` (*Reset*) | Pick filters and apply; the sheet returns the chosen filter to History |
| **Shift details** (`/shift`) | One shift in full | `Scaffold`, `ListView`, `Card` sections, `ListTile` rows (date, start → end, paused, client / project, note), `SelectableText` (reference link), `FilledButton` (*Edit shift*), `OutlinedButton` (*Delete shift*), `AlertDialog`, `MaterialBanner` (*Shift saved*) | *Edit shift* → form; *Delete shift* → confirm → back to the list |
| **Add manual shift / Edit shift** (`/shift/form`) | Enter or correct a shift by hand | `Form`, read-only `TextFormField`s opening `showDatePicker` and `showTimePicker`, `TextFormField` (client / project, note — multiline, reference link — URL keyboard), `Text` (earnings preview), `FilledButton` | Validate *End time must be after the start time*, show the earnings preview, save |
| **Statistics** (tab, O1) | Longer-term patterns | `SegmentedButton` (period), `Card` (total tracked), `BarChart` from `fl_chart` (hours by month), `GridView` of stat tiles (average, longest, shortest), `CustomPaint` (activity heat map), empty state | Change period; charts update |
| **Settings** (tab) | Account, preferences, sync, data | `ListView`, `ListTile` with `CircleAvatar` (account), `ListTile` rows with trailing value and chevron, `SwitchListTile` (notifications, app lock), `TextButton` (*Sign out*) with `AlertDialog` | Open Rate & currency, Export & import, App lock; change appearance; sign out → Sign in |
| **Rate & currency** (`/settings/rate`) | Change rate and currency | Same widgets as Rate setup, plus `FilledButton` (*Save settings*) | Validate, save, go back |
| **Export your hours** (`/settings/export`, O2) | Export a period to share with a client | Date range field (`showDateRangePicker`), `DropdownMenu` (client), `SegmentedButton` (PDF / CSV / JSON), `Card` (report preview), `FilledButton` (*Create & share report*), `AlertDialog` (*Report is ready*), `TextButton` (*Import JSON backup*) | Create the report and open the share sheet; open Import |
| **Import a backup** (`/settings/import`, O2) | Restore shifts from a JSON backup | `FilledButton` (*Choose JSON file*), `Card` (file summary: shifts found, duplicates skipped), `FilledButton` (*Import 10 shifts*), `TextButton` (*Cancel*) | Choose a file, review, import |
| **Lock** (`/lock`, O2) | Biometric unlock | `Center`, `Column`, `Icon`, `FilledButton` (*Unlock with biometrics*), `TextButton` (*Use device passcode*) | Authenticate, then return to the app |
| **Shift notification** (system) | Control a running shift outside the app | Ongoing notification from `flutter_local_notifications` with *Pause* and *Open timer* actions | *Pause* pauses the session; *Open timer* opens `/timer` |

Shared widgets in `ui/widgets/` keep the screens consistent: stat card, shift tile, section header,
sync banner, empty state, confirmation dialog.

---

## 6. Data and State Design

### 6.1 Data model

All times are stored as epoch milliseconds and converted to `DateTime` in Dart. Money is never
stored: earnings are always `hours × hourlyRate`, so changing the rate updates every total.

**Shift** — one finished work period (`data/models/shift.dart`)

| Field | Dart type | Notes |
|---|---|---|
| `id` | `int?` | Local SQLite row id; null before the first save |
| `serverId` | `String?` | Id from the API; null until synced once |
| `start`, `end` | `DateTime` | Start and end of the shift |
| `durationMs` | `int` | Worked time with pauses removed |
| `note` | `String` | e.g. "Website redesign" |
| `tags` | `List<String>` | Client / project, e.g. `['Acme', 'Website']` |
| `links` | `List<String>` | Reference links, e.g. a pull request URL |
| `updatedAt` | `DateTime` | Last change; the newer value wins a sync conflict |
| `isSynced` | `bool` | False until the server has this version |
| `isDeleted` | `bool` | Soft delete, so a deletion syncs like any other change |

Derived getters: `duration`, `paused` (`end − start − duration`), `earnings(rate)`.

```dart
class Shift {
  final int? id;
  final String? serverId;
  final DateTime start;
  final DateTime end;
  final int durationMs;
  final String note;
  final List<String> tags;
  final List<String> links;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;

  double earnings(double hourlyRate) =>
      durationMs / Duration.millisecondsPerHour * hourlyRate;
}
```

**ActiveSession** — the shift being timed (`data/models/active_session.dart`)

| Field | Dart type | Notes |
|---|---|---|
| `start` | `DateTime` | When the shift began |
| `status` | `SessionStatus` (`running`, `paused`) | |
| `accumulatedMs` | `int` | Worked time from segments that ended with a pause |
| `segmentStart` | `DateTime?` | Start of the current running segment; null while paused |
| `note`, `tags` | `String`, `List<String>` | Copied into the `Shift` on finish |

Elapsed time is `accumulatedMs + (now − segmentStart)` while running. It is computed from stored
timestamps, never counted by a ticker, so it stays correct after the app is closed or the phone
reboots.

**AppSettings** (`data/models/app_settings.dart`)

| Field | Dart type | Notes |
|---|---|---|
| `hourlyRate` | `double` | 0 means "not set yet" → Rate setup after sign-up |
| `currencyCode` | `String` | ISO 4217, e.g. `SAR` |
| `themeMode` | `ThemeMode` | System, light or dark |
| `notificationsEnabled` | `bool` | Ongoing shift notification |
| `appLockEnabled` | `bool` | Biometric lock (O2) |
| `lastSyncAt` | `DateTime?` | Shown as "Synced just now" |

**User** (`data/models/user.dart`)

| Field | Dart type | Notes |
|---|---|---|
| `id` | `String` | From the API |
| `email` | `String` | |
| `displayName` | `String?` | Falls back to the part of the email before `@` |

**SyncStatus** (`data/models/sync_status.dart`) — `enum { synced, syncing, offline, failed }`,
drives the Home banner and the Settings sync row.

### 6.2 Data sources and persistence

| Data | Source / storage | Package | Survives restart? |
|---|---|---|---|
| Shifts | Local SQLite table `shifts(id, server_id, start_time, end_time, duration_ms, note, tags, links, updated_at, is_synced, is_deleted)`, indexed on `start_time DESC`; tags and links stored as JSON text | `sqflite`, `path` | Yes |
| Settings | Key–value store | `shared_preferences` | Yes |
| Running shift | `ActiveSession` saved as JSON on every change | `shared_preferences` | Yes, also after a reboot |
| JWT token | Platform keystore / keychain | `flutter_secure_storage` | Yes |
| Account, shifts and rate on the server | ASP.NET Core Web API over SQL Server | `http`, `connectivity_plus` | Yes, and on a new phone |

**How data enters the app**
1. **Timer:** *Finish shift* turns the `ActiveSession` into a `Shift` and inserts it locally.
2. **Manual entry / edit:** the form validates and inserts or updates a row.
3. **Sign in on a new phone:** `GET /api/shifts?since=0` downloads the full history.
4. **Import (O2):** a JSON backup is read with `file_picker`; duplicates are skipped.

**Where changes are saved.** Every change is written to SQLite first, with `is_synced = 0` and a new
`updated_at`. The screens only read the local database, so the network never blocks the UI and the
app works offline. `SyncService` then pushes unsynced rows (`POST`, `PUT`, `DELETE /api/shifts`)
and pulls everything changed since `lastSyncAt`. It runs on app start, after a shift is finished
and when the connection returns. When the same shift changed in two places, the newer `updatedAt`
wins. Deletes are soft deletes, so they sync like any other change.

### 6.3 State management plan

**Chosen approach: Provider** (`provider` package, `ChangeNotifier`). There are four shared stores,
supplied by one `MultiProvider` above `MaterialApp`. Screens read with `context.watch` / `Selector`
and call actions with `context.read`. Local `setState` is used only for state that a single screen
owns. No other state-management package is used.

**Shared state (Provider)**

| Changing value | Owner | Screens that use it |
|---|---|---|
| Signed-in `User`, JWT, auth loading / error | `AuthProvider` | Sign in, Settings (account, sign out), app start (choose Sign in or Home) |
| `AppSettings` — rate, currency, theme, toggles, last sync time | `SettingsProvider` | `MaterialApp` (theme), Rate setup, Rate & currency, Home, Timer, History, Shift details, Manual entry, Statistics, Export, Settings |
| Shift list, CRUD, derived totals (today / week / month / all time, per-day totals for the calendar), `SyncStatus` | `ShiftProvider` | Home, Day details, History, Shift details, Manual entry / Edit, Statistics, Export, Settings (sync row) |
| `ActiveSession` (running / paused, start, accumulated time) and its notification | `SessionProvider` | Home (*Resume shift* pill), Timer, notification actions |

**Local state (`setState`)**

| Value | Screen |
|---|---|
| Sign in ↔ Sign up mode, password visibility, submit loading flag | Sign in |
| Form field values and validation errors (`TextEditingController`s + `Form`) | Sign in, Rate setup, Rate & currency, Manual entry / Edit |
| Selected tab index | Root shell |
| Calendar month being shown | Home |
| Search text, selected filter and sort order (returned from the Filter sheet) | History |
| One-second redraw of the elapsed time (`Timer.periodic`); the value itself comes from `SessionProvider` | Timer |
| Selected period | Statistics |
| Selected format, period and client | Export |

**Justification.**
- The timer, shifts and settings are each used by many screens. For example, finishing a shift on
  the Timer must update Home totals, the calendar, History and Statistics at once. A shared
  `ChangeNotifier` does this without passing callbacks down through the tree.
- The four stores match four clearly separate concerns, so each team member can work on one
  provider without editing the others.
- Provider is the approach taught in the course and is enough for an app of this size. Bloc or
  Riverpod would add boilerplate or a second mental model without solving a problem we have.
- Temporary interface details stay in `setState` so the providers hold only real app data.

---

## 7. Project Structure and Repository

**GitHub:** https://github.com/MoathEssa/spentr (branch `main`; the Flutter app is in `app/`)

```
app/lib/
  main.dart                 entry point
  app.dart                  MaterialApp, light and dark theme, routes
  core/
    routes.dart             named routes for every screen
    theme/                  app_colors.dart, app_theme.dart (Material 3, from the Figma design system)
  data/
    models/                 shift, active_session, app_settings, user, sync_status
    local/                  SQLite database and settings store (Phase 3)
    remote/                 ApiClient, AuthService, SyncService (Phase 3)
    services/               notifications, biometrics, export (Phase 3)
  state/                    AuthProvider, SettingsProvider, ShiftProvider, SessionProvider (Phase 3)
  ui/
    screens/                one file per screen or bottom sheet (16 files)
    widgets/                placeholder_view.dart, confirm_dialog.dart
app/test/widget_test.dart   navigation smoke tests
```

**Packages**

| Package | Purpose | Licence | Status |
|---|---|---|---|
| `cupertino_icons` | iOS-style icon font (Flutter template default) | MIT | Added |
| `flutter_lints` (dev) | Lint rules for `flutter analyze` | BSD-3-Clause | Added |
| `provider` | Shared state | MIT | Phase 3 |
| `sqflite`, `path` | Local shift database | BSD-2-Clause, BSD-3-Clause | Phase 3 |
| `shared_preferences` | Settings and the running shift | BSD-3-Clause | Phase 3 |
| `flutter_secure_storage` | JWT storage | BSD-3-Clause | Phase 3 |
| `http`, `connectivity_plus` | API calls, detect when the connection returns | BSD-3-Clause | Phase 3 |
| `flutter_local_notifications` | Ongoing shift notification | BSD-3-Clause | Phase 3 |
| `intl` | Date, time and currency formatting | BSD-3-Clause | Phase 3 |
| `fl_chart` | Statistics charts (O1) | MIT | Phase 3 |
| `pdf`, `printing`, `share_plus`, `file_picker` | Export and import (O2) | Apache-2.0, Apache-2.0, BSD-3-Clause, MIT | Phase 3 |
| `local_auth` | Biometric lock (O2) | BSD-3-Clause | Phase 3 |

**Proof that the starter app runs.** `flutter analyze` reports no issues and `flutter test` passes
both navigation tests. The screenshots below were taken from the debug build on an Infinix X6725
(Android 15), which was in dark mode. Files are in `docs/phase2/screenshots/` in the repository:

| File | Shows |
|---|---|
| `01_sign_in.png`, `02_sign_up.png` | Start screen, both modes |
| `03_rate_setup.png` | Rate setup after creating an account |
| `04_home.png` | Root shell with bottom navigation, Home tab |
| `05_day_details_sheet.png` | Day details bottom sheet |
| `06_session_timer.png`, `07_finish_dialog.png` | Timer and the finish confirmation |
| `08_shift_details.png` | Shift details after finishing |
| `09_history.png`, `10_filter_sheet.png`, `11_add_manual_shift.png` | History, Filter sheet, manual entry |
| `12_statistics.png`, `13_settings.png` | Statistics and Settings tabs |
| `14_export.png`, `15_app_lock.png` | Export and App lock (optional features) |

Suggested for the PDF: 04, 06, 09 and 13 side by side. They show the app running, the tabs and a
pushed screen.
