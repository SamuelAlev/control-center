/// Network endpoint constants for the infra layer's HTTP clients.
///
/// These live with the dio clients that consume them (`cc_infra`) rather than
/// in the app's `app_constants` — they are an infrastructure concern, and the
/// clients link into the Flutter-free server binary. The desktop composition
/// root (`di/providers.dart`) imports the same values when it wires the
/// Calendar dio + auth interceptor.
library;

/// Base URL for the GitHub REST API.
const String githubApiBaseUrl = 'https://api.github.com';

/// Base URL for the Google Calendar REST API (v3).
const String googleCalendarApiBaseUrl =
    'https://www.googleapis.com/calendar/v3';

/// Request `extra` key naming which connected Google account a Calendar API
/// call is for. Every calendar request sets it so the auth interceptor can
/// attach (and refresh) that specific account's token.
const String googleAccountIdExtraKey = 'googleAccountId';

/// Google OAuth 2.0 token endpoint — used by the headless server for the
/// device-code grant's polling step and for refresh-token exchange.
const String googleOAuthTokenEndpoint = 'https://oauth2.googleapis.com/token';

/// Google OAuth 2.0 device authorization endpoint (RFC 8628). The headless
/// `cc_server` has no browser to catch a redirect, so it authorizes via the
/// device-code grant: it shows a short code + URL and polls until approval.
const String googleOAuthDeviceCodeEndpoint =
    'https://oauth2.googleapis.com/device/code';

/// OAuth scope the headless server requests when connecting a Google account.
///
/// Read-only calendar access plus the identity claims (`openid email`) so the
/// returned id_token carries the account email (used to key the stored
/// credentials). The server only *syncs* events — it never writes an RSVP — so
/// it deliberately omits the `calendar.events` write scope.
///
/// NOTE: Google's device-code (TV & limited-input) client type only grants an
/// allow-listed set of scopes; if Calendar is not permitted for that client in
/// your Cloud project the device-code request fails with `invalid_scope`, and
/// you must use a loopback or web client instead.
const String googleCalendarDeviceScope =
    'https://www.googleapis.com/auth/calendar.readonly openid email';
