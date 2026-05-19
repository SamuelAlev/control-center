# Calendar

Read-only Google Calendar integration. Each workspace connects its own Google
account, the app syncs upcoming events into the local Drift store, renders them
in month / week / agenda views, fires "meeting starting soon" alerts, and can
start a local meeting recording seeded from an event and link it back.

This feature is read-only against Google: it never writes to the user's
calendar. The only writes are to the local SQLite store and the platform
keychain.

## What it does

- **Per-workspace Google sign-in** via OAuth 2.0 with PKCE (no client secret —
  see [Authentication](#authentication)).
- **Periodic sync** of the next 30 days of the primary calendar's events
  (`CalendarSyncService`, every 7 min + once on connect / manual refresh).
- **Month / week / agenda UI** (`CalendarScreen`; month & week use the
  `kalender` package, agenda is a custom list).
- **"Meeting starting soon" alerts** (`MeetingAlertScheduler`, per-minute scan,
  configurable lead time, dedup persisted so an alert never fires twice).
- **Record & link**: start a local meeting recording from a calendar event and
  store a `meeting ↔ event` link (`CalendarRecordAndLinkUseCase`). See the
  [meetings feature](../meetings/) for the recording/transcription side.

> **`CalendarEvent` is not a `Meeting`.** A `CalendarEvent` is a synced,
> read-only Google Calendar entry. A `Meeting` (meetings feature) is a locally
> recorded/transcribed session. They are linked many-to-one via
> `MeetingCalendarLinksTable`, never merged.

## Architecture

Follows the project's Clean Architecture / ports-and-adapters convention.

```
features/calendar/
├── data/
│   ├── mappers/            calendar_event_mapper.dart        (row ↔ entity)
│   ├── repositories/
│   │   ├── dao_calendar_repository.dart                      (CalendarRepository impl over the DAO)
│   │   └── google_credentials_repository.dart                (per-workspace OAuth tokens in the keychain)
│   └── services/
│       ├── google_oauth_service.dart                         (PKCE auth-code flow + refresh)
│       ├── google_oauth_redirect_channel.dart               (carries the OS deep-link redirect to the in-flight flow)
│       ├── calendar_sync_service.dart                        (periodic read-only sync → local store)
│       └── meeting_alert_scheduler.dart                      (per-minute "starting soon" alerts)
├── domain/
│   ├── entities/calendar_event.dart                          (CalendarEvent, CalendarAttendee, CalendarEventStatus)
│   └── repositories/calendar_repository.dart                 (abstract port)
├── presentation/
│   ├── screens/calendar_screen.dart
│   ├── widgets/                                              (kalender host, agenda panel, detail panel, section)
│   ├── providers/                                            (UI state, connect-account, record-and-link)
│   └── calendar_view_mode.dart
└── providers/
    ├── google_auth_providers.dart                            (credentials notifier, client-id, is-authenticated)
    └── calendar_sync_providers.dart                          (keep-alive sync + alert scheduler)
```

Cross-cutting pieces that live in `core/` rather than the feature folder:

- `core/network/google_calendar_api_client.dart` — read-only Calendar API v3
  client (lists calendars + events, follows `nextPageToken`).
- `core/network/models/google_calendar_*.dart` — API response DTOs.
- `core/database/tables/calendar_accounts.dart`, `calendar_events.dart`,
  `meeting_calendar_links.dart` — Drift tables.
- `core/database/daos/calendar_dao.dart` — the DAO.
- `core/domain/events/calendar_events.dart` — `CalendarEventsRefreshed`,
  `MeetingStartingSoon` domain events.
- `core/config/env_config.dart` — reads `GOOGLE_OAUTH_CLIENT_ID`.

Composition root: `di/providers.dart` (`calendarRepositoryProvider`,
`googleCredentialsRepositoryProvider`, `googleOAuthServiceProvider`,
`googleOAuthRedirectChannelProvider`, `googleCalendarDioProvider`,
`googleCalendarApiClientProvider`, plus the `_GoogleAuthInterceptor` that
attaches the Bearer token and auto-refreshes on 401).

### Data flow

A workspace may connect **several** Google accounts. Each account is one
`CalendarAccount` row (`id = google:<workspaceId>:<email>`) with its own tokens.

```
Connect:   CalendarScreen/sidebar/settings → ConnectGoogleCalendarNotifier.connect()
              → GoogleOAuthService.authenticate()  (opens browser, PKCE)
              → OS routes redirect deep-link → GoogleOAuthRedirectChannel.emit()
              → token exchange → GoogleCredentialsRepository.save(accountId)
              → CalendarRepository.upsertAccount(accountId)   (adds, never replaces)

Sync:      CalendarSyncService (timer) → for each connected account:
              GoogleCalendarApiClient.listCalendars(accountId) → for each calendar:
              listEvents(accountId, calendarId) → CalendarRepository.upsertEvents()
              → publishes CalendarEventsRefreshed → eventsInRangeProvider rebuilds

Disconnect: ConnectGoogleCalendarNotifier.disconnect(accountId)
              → repo.deleteAccount (cascades events) + GoogleCredentialsRepository.clear(accountId)
```

### Token lifecycle

Every Calendar request sets `extra[googleAccountIdExtraKey]` naming its account.
`googleCalendarDioProvider`'s `_GoogleAuthInterceptor` reads that, attaches the
Bearer token via `GoogleTokenManager.accessTokenFor(accountId)` (refreshing if
expired), and on a 401 calls `forceRefresh(accountId)` once and retries.
Refreshes are single-flighted **per account**. Google does **not** return a new
refresh token on refresh, so the stored one is reused. The `Dio` used for the
OAuth calls themselves is a plain `createDio()` with none of the auth
interceptors, so a 401 during refresh can never recurse.

### OAuth scope

`googleCalendarOAuthScope` = `calendar.readonly` (read calendars + events) +
`calendar.events` (write the user's RSVP) + `openid email profile`. Accounts
connected before `calendar.events` was added keep read-only access until they
reconnect; RSVP fails gracefully in that case.

## Workspace isolation

Connected Google accounts are workspace-scoped, like everything else:

- `GoogleCredentialsRepository` stores one JSON credential blob per account
  under a single key suffixed with `__<accountId>` (one keychain item, so macOS
  prompts at most once per account), and account ids embed the workspace, so one
  workspace's tokens are structurally unreadable from another.
- `CalendarAccountsTable`, `CalendarEventsTable`, `MeetingCalendarLinksTable`
  all carry a non-null `workspaceId`; every DAO query filters on it. Account
  uniqueness is `(workspaceId, accountEmail)`.
- `googleAccountsProvider` watches `activeWorkspaceIdProvider`, so switching
  workspace lists only that workspace's accounts.
- `CalendarRecordAndLinkUseCase` sources `workspaceId` from the event itself,
  never a separate parameter.

## Authentication

The OAuth client is a **public "iOS"-type client** (Google Cloud Console →
Credentials → *iOS*). Two consequences drive the whole design:

1. **There is no client secret.** An iOS client is a genuinely public client;
   Google neither issues nor requires a secret on the token endpoint. PKCE
   (RFC 7636, S256) is what binds the authorization code to this client. This
   is why the binary can ship with the client id embedded and *nothing
   confidential in it*.
   - (Aside: the earlier "Desktop app" client type used a loopback redirect but
     Google rejects its code exchange without the embedded secret — hence the
     switch to the iOS type.)
2. **The redirect is the reversed-client-id custom scheme.** Google reserves
   `com.googleusercontent.apps.<client>` for the iOS client type, where
   `<client>` is the client id with its `.apps.googleusercontent.com` suffix
   stripped. The full redirect URI is:

   ```
   com.googleusercontent.apps.<client>:/oauth2redirect
   ```

   The OS must be told this app owns that scheme, so the redirect comes back as
   a deep link. That registration is **per platform** and is the part you must
   keep in sync with the client id (see [Setup](#setup-using-your-own-client-id)).

Scope requested: `calendar.readonly openid email profile` (read-only calendar +
the account email for display).

### Why a redirect channel?

With a custom-scheme deep link the redirect is delivered to the *running app* by
the OS (via the platform handlers below) — not to a loopback HTTP server the
flow owns. `GoogleOAuthRedirectChannel` is a long-lived broadcast bus that
decouples the startup deep-link handler (which can't know whether a sign-in is
in progress) from the transient `authenticate()` call (which subscribes for
exactly one redirect). `authenticate()` subscribes *before* opening the browser
so a fast callback is never missed.

### Per-platform deep-link plumbing

The redirect URL reaches `_handleIncomingUrl` in `main.dart`, which forwards
anything starting with `com.googleusercontent.apps.` to
`googleOAuthRedirectChannelProvider.emit()`:

- **macOS** — `AppDelegate.application(_:open:)` forwards the URL over the
  `com.controlcenter/app` `MethodChannel`. The scheme is declared in
  `macos/Runner/Info.plist` (`CFBundleURLTypes`) via `$(GOOGLE_REVERSED_CLIENT_ID)`.
- **Windows** — `windows/runner/main.cpp` registers the scheme under `HKCU` and,
  because a protocol launch spawns a fresh process, forwards the URL to the
  already-running instance over `WM_COPYDATA` (single-instance mutex).
- **Linux** — `linux/runner/my_application.cc` forwards the URL to the primary
  instance over D-Bus (`g_application_open`); the scheme is declared in the
  `.desktop` file's `MimeType`.

## Setup: using your own client id

The default `.env` ships a working public client id. If you fork the app, want
your own Google Cloud project, or need to rotate the client, do the following.
**The client id and the reversed-client-id scheme must match across all four
places below** — they encode the same value and the OAuth redirect silently
fails to route if any one drifts.

### 1. Create an iOS-type OAuth client

In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. Enable the **Google Calendar API** for your project.
2. Configure the **OAuth consent screen** and add the scopes
   `.../auth/calendar.readonly`, `openid`, `email`, `profile`. While the app is
   unverified, add your Google accounts as **test users**.
3. Create credentials → **OAuth client ID** → application type **iOS**.
   - For the **Bundle ID** field, use the app's bundle identifier
     (`com.alev.control-center`, or your own if you've renamed it — see
     [renaming the bundle id](#optional-renaming-the-app-bundle-id)). For
     desktop builds Google does not enforce this at the token endpoint (PKCE +
     no secret), but keep it consistent.
4. Copy the generated client id. It looks like
   `123456789-abcdef….apps.googleusercontent.com`.

Derive its reversed-client-id scheme by stripping `.apps.googleusercontent.com`
and prefixing `com.googleusercontent.apps.`:

```
client id:  123456789-abcdef.apps.googleusercontent.com
reversed:   com.googleusercontent.apps.123456789-abcdef
```

### 2. Update the four locations

| # | File | Value to set |
|---|------|--------------|
| 1 | `.env` (repo root; see `.env.template`) | `GOOGLE_OAUTH_CLIENT_ID=<full client id>` |
| 2 | `macos/Runner/Configs/AppInfo.xcconfig` | `GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.<client>` |
| 3 | `windows/runner/CMakeLists.txt` (the `set(GOOGLE_REVERSED_CLIENT_ID …)` fallback, **and** the matching `#define` fallback in `windows/runner/main.cpp`) | `com.googleusercontent.apps.<client>` |
| 4 | `linux/com.alev.control-center.desktop` (the `MimeType=` line, second handler) | `x-scheme-handler/com.googleusercontent.apps.<client>` |

- **(1)** is the only one read at runtime. `EnvConfig` reads
  `GOOGLE_OAUTH_CLIENT_ID` from the process environment first, then the repo-root
  `.env`. The PKCE flow and the derived redirect URI come straight from it.
- **(2)–(4)** are the OS scheme registrations. They are compile-/package-time
  constants, so a rebuild (and on Linux, reinstalling the `.desktop` file /
  `update-desktop-database`) is required for them to take effect.
- On Windows you can also override at configure time instead of editing the
  file: `cmake … -DGOOGLE_REVERSED_CLIENT_ID="com.googleusercontent.apps.<client>"`.

None of these values is a secret — the reversed client id is just the client id
rearranged, and the client itself is public. It's safe to commit them.

### 3. Rebuild and connect

Rebuild the desktop app for your platform, open **Calendar**, and click
**connect**. If the client id is unset or empty, the connect flow surfaces a
"configure Google client id" error (`GoogleOAuthFailureKind.missingClientId`)
rather than crashing.

### Troubleshooting

- **Browser opens, but nothing happens after consent** → the redirect scheme
  isn't registered for your platform, or it doesn't match the client id. Re-check
  locations (2)–(4) and rebuild. On Linux, confirm the `.desktop` file is
  installed and the MIME handler is registered.
- **`redirect_uri_mismatch` / `invalid_client` from Google** → the client id in
  `.env` isn't an **iOS**-type client, or the project doesn't have the Calendar
  API enabled.
- **Consent succeeds but sync is empty** → make sure your account is a **test
  user** on the consent screen and the `calendar.readonly` scope was granted.
- **"App hangs" / second window on Windows** → the OAuth redirect launches a new
  process that hands off to the running instance; this is expected (see the
  single-instance logic in `main.cpp`).

### Optional: renaming the app bundle id

If you fork and re-brand (separate from the OAuth client id), the app bundle id
`com.alev.control-center` also appears in:

- `macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_BUNDLE_IDENTIFIER`
- `windows/runner/main.cpp` — the single-instance mutex name
  (`com.alev.control-center.singleinstance`)
- `linux/com.alev.control-center.desktop` — the file name and `StartupWMClass`
- `linux/CMakeLists.txt` — `APPLICATION_ID`

These are independent of the OAuth client id; you only need to touch them if you
actually rename the application.

## Tests

Under `test/features/calendar/` and `test/core/`:

- `data/google_oauth_service_test.dart` — PKCE, reversed-client-id derivation,
  redirect URI, state mismatch, code exchange.
- `data/google_credentials_repository_test.dart` — per-workspace key scoping.
- `data/calendar_sync_service_test.dart` — sync → upsert → event publish.
- `data/meeting_alert_scheduler_test.dart` — lead window + alert dedup.
- `data/calendar_event_mapper_test.dart`, `presentation/record_and_link_use_case_test.dart`,
  and the UI tests (`agenda_panel`, `calendar_format`, `calendar_ui_providers`,
  `calendar_view_mode`).
- `test/core/database/daos/calendar_dao_test.dart` — DAO workspace scoping.
- `test/core/network/google_calendar_api_client_test.dart` and
  `models/google_calendar_event_test.dart` — API client + DTO decoding.
</content>
</invoke>
