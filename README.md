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

The Phase 1 proposal and Phase 2 interface designs and prototype are prepared. The remaining Phase 2 work includes the technical design documentation, runnable Flutter starter project, and final PDF report.

Planned project layout:

- `app/` — Flutter client.
- `backend/` — ASP.NET Core Web API.
- `Spentr-Preview.html` — standalone HTML interface prototype.

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

- **Anthropic Claude** helped draft and format the Phase 1 proposal and provided small code and debugging suggestions.
- **ChatGPT** helped extract the Phase 1 design context, generate initial interface designs, create the HTML prototype and Figma import script, and draft README updates.

The group is responsible for reviewing and revising AI-assisted material, ensuring its use follows the course policy, and accurately recording each member's actual contribution. Each member is responsible for understanding and explaining the work they submit.