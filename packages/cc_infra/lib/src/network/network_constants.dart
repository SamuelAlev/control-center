/// Network endpoint constants for the infra layer's HTTP clients.
///
/// These live with the HTTP clients that consume them (`cc_infra`) rather
/// than the app's constants. `cc_server_core` uses the same endpoints when
/// composing Calendar clients and their account-scoped auth interceptor.
library;

/// Base URL for the Slack Web API. Every Slack call is an outbound HTTPS POST,
/// which is what lets the Socket Mode bridge run on a server with no public
/// endpoint.
const String slackApiBaseUrl = 'https://slack.com/api';

/// Base URL for the Google Calendar REST API (v3).
const String googleCalendarApiBaseUrl =
    'https://www.googleapis.com/calendar/v3';

/// Request `additionalData` key naming which connected Google account a Calendar API
/// call is for. Every calendar request sets it so the auth interceptor can
/// attach (and refresh) that specific account's token.
const String googleAccountIdExtraKey = 'googleAccountId';
