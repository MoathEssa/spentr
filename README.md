# Spentr

Group project for **SWE 463 — Mobile Application Development**, **Group 02**.

A Flutter app for Android and iOS with an ASP.NET Core and SQL Server back-end.

Spentr is a time and earnings diary for freelancers and part-time programmers. One tap records a shift, and the app turns the hours into money at the user's own hourly rate, tagged by client or project. Shifts are written to the phone first, so nothing depends on a connection, and they sync to the API when the phone is online.

## Team

| Name | Student ID | Initial responsibility |
|------|------------|------------------------|
| Moath Haimour | 202182130 | ASP.NET Core Web API, SQL Server database, EF Core migrations and JWT, API client and sync |
| Abdulkarim Hussain Althani | 201948610 | App architecture and theme, SQLite schema, state providers, session timer logic |
| Abdulrazaq Musaab Ahmad | 202267720 | Dashboard, calendar, history and sign-in screens, shared widgets |
| Osama Ahmed Alghamdi | 202172210 | Notifications, statistics, export to PDF/CSV/JSON, testing, documentation |

## Status

**Phase 2 — User Interface and Technical Design.**

The Phase 1 proposal, the Phase 2 interface designs and prototype, and the runnable Flutter starter project are in the repository. The final Phase 2 PDF report is being assembled.

Project layout:

- `app/` — Flutter client (Phase 2 starter: theme, models and placeholder navigation).
- `backend/` — ASP.NET Core Web API (planned).
- `Spentr-Preview.html` — standalone HTML interface prototype.
- `docs/phase2/` — [Phase 2 technical design](docs/phase2/Group02_Phase2_Technical_Design.md) (widget plan, data model, state management, project structure) and screenshots of the starter app running on Android.

## Flutter Starter App

The starter app opens and runs without compilation errors. Every main screen in the Figma navigation map exists as a placeholder that shows its purpose, the interface states designed for it, and buttons for its navigation. Real features are built in Phase 3.

### Run it

```bash
cd app
flutter pub get
flutter run
```

Built with Flutter 3.27 / Dart 3.6. Tested on an Android 15 phone; `flutter analyze` reports no issues and `flutter test` passes.

### Structure

```
app/lib/
  main.dart                 entry point
  app.dart                  MaterialApp, light and dark theme, routes
  core/
    routes.dart             named routes for every screen
    theme/                  colours and Material 3 theme from the Figma design system
  data/
    models/                 Shift, ActiveSession, AppSettings, User, SyncStatus
    local/                  SQLite database and settings store (Phase 3)
    remote/                 ApiClient, AuthService, SyncService (Phase 3)
    services/               notifications, biometrics, export (Phase 3)
  state/                    Provider ChangeNotifiers (Phase 3)
  ui/
    screens/                one file per screen or bottom sheet
    widgets/                shared widgets (placeholder view, confirm dialog)
```

Navigation: Sign in → Home. `RootShell` holds the four tabs (Home, History, Statistics, Settings) in an `IndexedStack` behind a Material 3 `NavigationBar`. Other screens are pushed with named routes; Day details and Filter are modal bottom sheets.

## Packages

| Package | Purpose | Licence |
|---------|---------|---------|
| `cupertino_icons` | Default iOS-style icon font from the Flutter template | MIT |
| `flutter_lints` (dev) | Recommended lint rules used by `flutter analyze` | BSD-3-Clause |

No other packages are added yet. The packages planned for Phase 3 (`provider`, `sqflite`, `shared_preferences`, `flutter_secure_storage`, `http`, `connectivity_plus`, `flutter_local_notifications`, `intl`, and for the optional features `fl_chart`, `pdf`, `printing`, `share_plus`, `file_picker`, `local_auth`) will be added to this table with their purpose and licence when they are introduced.

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

- **Anthropic Claude** helped draft and format the Phase 1 proposal, provided small code and debugging suggestions, generated the Phase 2 Flutter starter project (placeholder screens, routes, theme and model classes), and drafted the Phase 2 technical design sections (widget plan, data model and state management plan).
- **ChatGPT** helped extract the Phase 1 design context, generate initial interface designs, create the HTML prototype and Figma import script, and draft README updates.

The group is responsible for reviewing and revising AI-assisted material, ensuring its use follows the course policy, and accurately recording each member's actual contribution. Each member is responsible for understanding and explaining the work they submit.