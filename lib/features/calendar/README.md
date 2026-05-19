# Calendar

Read-only Google Calendar integration. Each workspace connects its own Google
account(s); the **server** syncs upcoming events into its database, and every
client (web + desktop) reads them over RPC and renders them in month / week /
agenda views, fires "meeting starting soon" alerts, and can start a local
meeting recording seeded from an event and link it back.

This feature is read-only against Google: it never writes to the user's
calendar. The only writes are to the server's store.

## What it does

- **Per-workspace Google connection** via the OAuth 2.0 **device-code grant**
  (RFC 8628) — see [Authentication](#authentication). A workspace can connect
  several accounts.
- **Periodic server-side sync** of the surrounding ~5 months of every connected
  calendar (`CalendarSyncService`, every 7 min + once at boot / on connect).
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

The connection, OAuth tokens, and sync are **owned by the host** (the headless
`cc_server`, or the desktop's in-process host). Clients are thin: they drive the
connect flow and read synced events over RPC — they never hold a Google token.

```
Host (cc_server / desktop in-process host)
├── packages/cc_infra/lib/src/calendar/
│   ├── google_device_auth_client.dart      device-code request/poll + refresh + creds model
│   └── calendar_sync_service.dart          periodic read-only sync → DB
├── packages/cc_server_core/lib/src/
│   └── google_calendar_server.dart         file-backed credential store, token manager +
│                                           authed Calendar API client, CalendarConnectService
│                                           (begin/poll/disconnect), ServerCalendarSync, CLI connect
├── packages/cc_infra/lib/src/network/google_calendar_api_client.dart   read-only Calendar API v3
└── remote_rpc_catalog.dart                 calendar.* read ops + beginConnect/pollConnect/disconnect

Client (web + desktop)
├── packages/cc_data/lib/src/repositories/
│   ├── remote_calendar_repository.dart      reads events/accounts over calendar.* / calendar.watch*
│   └── remote_calendar_connect.dart         drives calendar.beginConnect / pollConnect / disconnect
└── features/calendar/
    ├── providers/connect_account_provider.dart      device-code connect state machine (begin → poll)
    ├── presentation/widgets/google_calendar_connect_dialog.dart   the connect form (id/secret → code → poll)
    ├── presentation/screens/calendar_screen.dart
    └── domain/entities/calendar_event.dart          CalendarEvent, CalendarAttendee, CalendarEventStatus
```

Shared / DB pieces:

- `core/database/tables/calendar_accounts.dart`, `calendar_events.dart`,
  `meeting_calendar_links.dart` — Drift tables (metadata only; **tokens are not
  in the DB** — they live in the host's credential store).
- `core/database/daos/calendar_dao.dart` — the DAO; `DaoCalendarRepository` is
  the host-side `CalendarRepository` impl.
- `core/domain/events/calendar_events.dart` — `CalendarEventsRefreshed`,
  `MeetingStartingSoon`, `CalendarAuthExpired` domain events.

### Data flow

```
Connect (GUI):  connect form → ConnectGoogleCalendarNotifier.connect(clientId, secret)
                  → RemoteCalendarConnect.begin → calendar.beginConnect (host)
                  → host: GoogleDeviceAuthClient.requestDeviceCode → {code, url, handle}
                  → form shows the code + URL; user approves on any device
                  → notifier polls calendar.pollConnect(handle) every interval
                  → host: GoogleDeviceAuthClient.pollOnce → on approval, store tokens +
                    upsert CalendarAccount → returns connected
Connect (CLI):  cc_server calendar connect --workspace <id>   (blocking device-code flow)

Sync:           ServerCalendarSync (host timer) → for each workspace w/ accounts:
                  GoogleCalendarApiClient.listCalendars → listEvents
                  → DaoCalendarRepository.upsertEvents + deletion reconcile
                  → publishes CalendarEventsRefreshed → clients' calendar.watch* streams update

Disconnect:     RemoteCalendarConnect.disconnect → calendar.disconnect (host)
                  → deleteAccount (cascades events) + clears stored tokens
```

### Token lifecycle

Tokens live **only on the host**, in a file-backed `FileGoogleCredentialsStore`
(`google_credentials.json` under the server's data dir / the desktop's
app-support dir), keyed by `accountId` (`google:<workspaceId>:<email>`). The
stored blob includes the client id + secret the account was connected with, so
`ServerGoogleTokenManager` can refresh without re-entry: it loads the creds,
refreshes via `GoogleDeviceAuthClient.refresh` when the access token is expired
(single-flighted per account), and saves the new token. On a terminal
`invalid_grant` it marks the account for re-connect (`markNeedsReauth`) and
publishes `CalendarAuthExpired`. The authed Calendar `Dio` attaches the per-
account Bearer and retries once on a 401.

### OAuth scope

The host requests `googleCalendarDeviceScope` =
`calendar.readonly openid email`. Read-only calendar access plus the identity
claims so the returned id_token carries the account email (used to key the
credentials). The server only *syncs* — it never writes an RSVP — so it omits
the `calendar.events` write scope.

## Workspace isolation

Connected accounts are workspace-scoped, like everything else:

- The host store keys tokens by `accountId`, which embeds the workspace
  (`google:<workspaceId>:<email>`), so one workspace's tokens are structurally
  unreadable from another.
- The connect RPC ops are workspace-scoped: `beginConnect` records the bound
  `ctx.workspaceId` against the returned handle, `pollConnect` rejects a handle
  that belongs to another workspace, and `disconnect` rejects an `accountId`
  whose embedded workspace doesn't match (`WorkspaceMismatchException`).
- `CalendarAccountsTable`, `CalendarEventsTable`, `MeetingCalendarLinksTable`
  all carry a non-null `workspaceId`; every DAO query filters on it. Account
  uniqueness is `(workspaceId, accountEmail)`.
- `googleAccountsProvider` watches `activeWorkspaceIdProvider`, so switching
  workspace lists only that workspace's accounts.

## Authentication

The host authorizes Google via the **device-code grant** (RFC 8628) — the only
flow that works for both a headless server (no browser) and a thin web/desktop
client (a browser can't catch a native redirect): the host requests a short
**user code** + **verification URL**, the user approves on any device, and the
host polls the token endpoint until approval, then stores the refresh token.

The client supplies the OAuth **client id + secret** at connect time (entered in
the connect form, or passed to the CLI). The device-code ("TV & limited input
devices") client is a *confidential* client: the secret is safe because it lives
only on the trusted host's store — it is never shipped in a client binary.

### Connecting from the GUI (web + desktop)

Every connect entry point — the calendar empty state, the sidebar "add account"
row, the reauth banner, and Settings → the calendar section — opens
`showGoogleCalendarConnectDialog`. The dialog:

1. Takes the OAuth **client id** + **client secret**.
2. Calls `calendar.beginConnect`; shows the **user code** + an "open
   verification page" button.
3. Polls `calendar.pollConnect` until the host reports connected (or
   denied/expired), then closes — the accounts stream refreshes the view.

### Connecting from the CLI (headless)

```
cc_server calendar connect --workspace <workspaceId> \
  --google-client-id <id> --google-client-secret <secret> --data-dir <dir>
```

(The client id/secret may instead come from `CC_GOOGLE_OAUTH_CLIENT_ID` /
`CC_GOOGLE_OAUTH_CLIENT_SECRET`.) It prints a code + URL, blocks until you
approve, then stores the token and upserts the account. The running server
syncs it on the next sweep.

## Setup: your Google OAuth client

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
   enable the **Google Calendar API**, configure the **OAuth consent screen**
   (add the `.../auth/calendar.readonly`, `openid`, `email` scopes; add your
   accounts as **test users** while unverified), then create an **OAuth client
   ID** of application type **"TV and Limited Input devices"**. Copy its client
   id **and secret**.
2. Provide them to whichever host owns your data:
   - **Headless `cc_server`**: via the connect command flags above, or
     `CC_GOOGLE_OAUTH_CLIENT_ID` / `CC_GOOGLE_OAUTH_CLIENT_SECRET`.
   - **GUI (web/desktop)**: enter them in the connect dialog.
3. Connect (GUI or CLI) and approve the code. The host syncs from then on.

None of these values is confidential to a *client* — the secret lives on the
host. It is safe to keep server-side.

> **Scope caveat.** Google's device-code (TV & limited-input) client type only
> grants an *allow-listed* set of scopes. If Calendar is not permitted for that
> client in your Cloud project, the device-code request fails with
> `invalid_scope`. In that case you'd need a loopback or web OAuth client for
> the host instead — only the device-flow piece (`GoogleDeviceAuthClient`)
> changes; the credential store + sync are reused.

### Troubleshooting

- **`invalid_scope` when connecting** → your device-code OAuth client isn't
  permitted the Calendar scope (see the caveat above).
- **`invalid_client` / `unauthorized_client`** → wrong client id/secret, or the
  client isn't a "TV and Limited Input devices" type.
- **Connected but no events** → make sure your account is a **test user** on the
  consent screen and the `calendar.readonly` scope was granted; the first sweep
  runs within ~7 minutes (immediately on a fresh server boot).
- **"Authorization was denied / code expired"** → the device code wasn't
  approved in time; just connect again.

## Legacy (being removed)

An older **client-side** OAuth path (a public iOS-type client + a reversed-
client-id custom-scheme redirect, with tokens in the OS keychain and a
client-run sync) still exists in the tree — `google_oauth_service.dart`,
`google_oauth_redirect_channel.dart`, the `google*` providers in
`di/providers.dart`, the client `CalendarSyncService` in
`calendar_sync_providers.dart`, and the `main.dart` deep-link handler. It is
**superseded** by the host-owned device-code flow above (the custom-scheme
redirect can't work on web, and the client-side sync can't write through the
thin-client RPC repository) and is slated for removal. Don't build on it.

## Tests

Under `test/features/calendar/` and `test/core/`:

- `data/calendar_sync_service_test.dart` — sync → upsert → event publish.
- `data/meeting_alert_scheduler_test.dart` — lead window + alert dedup.
- `data/calendar_event_mapper_test.dart`, `presentation/record_and_link_use_case_test.dart`,
  and the UI tests (`agenda_panel`, `calendar_format`, `calendar_ui_providers`,
  `calendar_view_mode`).
- `test/core/database/daos/calendar_dao_test.dart` — DAO workspace scoping.
- `test/core/network/google_calendar_api_client_test.dart` and
  `models/google_calendar_event_test.dart` — API client + DTO decoding.

> The device-code client, the server credential store + token manager, and the
> `CalendarConnectService` (begin/poll/disconnect + workspace isolation) are new
> and still need unit coverage — a follow-up.
