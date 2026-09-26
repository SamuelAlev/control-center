# Calendar

Google Calendar integration is read-only against Google. `cc_server` syncs each workspace's accounts into its database; web and desktop clients render month/week/agenda views, meeting-soon alerts, and can start a local recording linked to an event. A `CalendarEvent` is a synced entry, **not** a recorded `Meeting`; `MeetingCalendarLinksTable` links them many-to-one.

## Ownership and data flow

- Server: `packages/cc_infra/lib/src/calendar/google_device_auth_client.dart` handles device-code OAuth, polling and refresh; `calendar_sync_service.dart` and `network/google_calendar_api_client.dart` list calendars/events. `packages/cc_server_core/lib/src/google_calendar_server.dart` owns credential storage, token management and the connect flow. `remote_rpc_catalog.dart` serves `calendar.*` reads/watch plus connect/disconnect operations.
- Client: `packages/cc_data/lib/src/repositories/remote_calendar_repository.dart` reads watches; `remote_calendar_connect.dart` and `providers/connect_account_provider.dart` drive begin → poll → connected. The client **never holds Google tokens**. `CalendarRecordAndLinkUseCase` links a locally started recording.
- Accounts/events/meeting links have a non-null workspace id. DAO queries filter by workspace, accounts are unique on `(workspaceId, accountEmail)`, and the provider follows `activeWorkspaceIdProvider`. Connect handles bind to `ctx.workspaceId`; polling another workspace's handle or disconnecting another workspace's account is rejected.
- The host syncs roughly five months every seven minutes and at boot/connect, reconciles deleted events, publishes `CalendarEventsRefreshed` and updates `calendar.watch*` clients. Disconnect cascades event deletion and clears stored credentials.

OAuth uses RFC 8628 device-code grant with `calendar.readonly openid email`; no RSVP/write scope. The host requests a code/verification URL, the user approves on any device, and the host polls until approval or expiry. Access and refresh tokens stay in host `secrets.json` (`FileGoogleCredentialsStore`, `google_*` keys, account id `google:<workspaceId>:<email>`), **not** in Drift or the client. Refresh is single-flight per account; terminal `invalid_grant` marks reauth and publishes `CalendarAuthExpired`. Authenticated Calendar requests retry once after a 401.

The builtin client comes from `--google-client-id` / `GOOGLE_OAUTH_CLIENT_ID`, otherwise the release's `builtin_credentials.dart`. `calendar.connectInfo` reveals only availability, never credentials; an account stores a builtin-client marker so rotation re-resolves the current server configuration. Users may instead supply their own client id/secret per account via GUI or CLI. Device-code client secrets are non-confidential under Google's installed-device model, but keep them host-side and out of the public repository; refresh tokens are confidential. See [SECURITY.md](../../../SECURITY.md) for the general credential boundary.

## Connect your own Google client

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials), enable the Calendar API; configure consent for `calendar.readonly`, `openid` and `email` and add test users while unverified. Create an OAuth client of type **TV and Limited Input devices** and copy both id and secret.
2. Enter them in the Calendar connection dialog (or choose the server builtin client if available), approve the displayed device code, and wait for connected status. The calendar empty state, sidebar add-account, reauth banner and Settings all use the same dialog.
3. For a headless host, connect with:

```sh
cc_server calendar connect --workspace <workspaceId> \
  --google-client-id <id> --google-client-secret <secret> --data-dir <dir>
```

`GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` may supply the CLI pair. The running server picks up the account on its next sweep.

**Scope caveat:** Google's TV/limited-input device client permits only allow-listed scopes; a project that rejects Calendar scope returns `invalid_scope`. A loopback/web OAuth client on the host would require a different device-flow adapter, not a change to the store/sync model. `invalid_client` or `unauthorized_client` usually means incorrect credentials or client type; no events after connecting may mean absent test-user access or read scope. An expired/denied code needs a new connection attempt.

An older client-side OAuth/keychain and client-run sync path still exists (`google_oauth_service.dart`, `google_oauth_redirect_channel.dart`, `calendar_sync_providers.dart`, `main.dart` deep link). Do not extend it: web cannot use its custom-scheme redirect and thin clients cannot write via that sync path.
