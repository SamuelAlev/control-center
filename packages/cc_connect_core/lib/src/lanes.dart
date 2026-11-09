import 'package:cc_connect_core/src/install_identity.dart';

/// A browser OAuth lane Connect runs.
///
/// Each lane has a fixed provider host, a fixed scope set and a fixed Connect
/// callback. Nothing about a lane is caller-supplied, which is what lets a
/// server validate an authorization URL before it shows it to a human.
enum ConnectOAuthLane {
  /// GitHub App user sign-in (Web OAuth + PKCE + client secret).
  github('github'),

  /// Google Calendar, read-only.
  google('google'),

  /// A member's personal Linear account (`actor=user`).
  linear('linear'),

  /// The workspace's Linear app actor (`actor=app`) for automation.
  linearApp('linear_app'),

  /// Slack bot install, preceded by a Sign in with Slack pre-check.
  slack('slack');

  const ConnectOAuthLane(this.wire);

  /// The wire spelling, also the route segment.
  final String wire;

  /// Parses a wire value; null when unknown.
  static ConnectOAuthLane? fromWire(String? wire) {
    for (final lane in values) {
      if (lane.wire == wire) {
        return lane;
      }
    }
    return null;
  }

  /// The callback segment the provider redirects to first. Slack's first hop
  /// is the OIDC pre-check; its bot install has its own callback.
  String get firstCallbackSegment => this == slack ? 'slack_oidc' : wire;

  /// The provider this lane authenticates against.
  ConnectProvider get provider => switch (this) {
    github => ConnectProvider.github,
    google => ConnectProvider.google,
    linear || linearApp => ConnectProvider.linear,
    slack => ConnectProvider.slack,
  };
}

/// An upstream provider.
enum ConnectProvider {
  /// GitHub.
  github,

  /// Google.
  google,

  /// Linear.
  linear,

  /// Slack.
  slack;

  /// Parses a wire value; null when unknown.
  static ConnectProvider? fromWire(String? wire) {
    for (final provider in values) {
      if (provider.name == wire) {
        return provider;
      }
    }
    return null;
  }
}

/// Google's Calendar events scope: read every event on the person's
/// calendars, answer invitations, and create or delete events.
const String googleCalendarEventsScope =
    'https://www.googleapis.com/auth/calendar.events';

/// Google's read-only calendar-list scope. `calendar.events` covers events
/// only; listing which calendars a person has (and which they may write to)
/// needs this one.
const String googleCalendarListScope =
    'https://www.googleapis.com/auth/calendar.calendarlist.readonly';

/// The exact scope set the Google lane requests and accepts. `openid` and
/// `email` identify the account (`sub`, address) without a second API call.
/// Calendar access covers events (read, RSVP, create, delete) and reading
/// the calendar list; calendars themselves and their sharing stay untouched.
const List<String> googleConnectScopes = [
  'openid',
  'email',
  googleCalendarEventsScope,
  googleCalendarListScope,
];

/// The exact Linear OAuth scope set (comma-separated on Linear's wire).
const List<String> linearConnectScopes = ['read', 'write', 'issues:create'];

/// The scope set of Slack's OIDC pre-check. It identifies the person and the
/// team, and never touches the workspace's bot installation.
const List<String> slackOidcScopes = ['openid', 'profile'];

/// The fixed bot scope set of the shared Slack app.
const List<String> slackBotScopes = [
  'app_mentions:read',
  'assistant:write',
  'channels:history',
  'chat:write',
  'commands',
  'groups:history',
  'im:history',
  'users:read',
  'users:read.email',
];

/// Normalises one granted scope string so provider aliases compare equal
/// (Google reports `email` as its userinfo URL).
String normaliseScope(String scope) => switch (scope) {
  'https://www.googleapis.com/auth/userinfo.email' => 'email',
  'https://www.googleapis.com/auth/userinfo.profile' => 'profile',
  _ => scope,
};

/// Whether [granted] (as the provider reported it) is exactly [expected].
/// A widened grant is refused as firmly as a narrowed one.
bool scopesExactlyMatch(Iterable<String> granted, Iterable<String> expected) {
  final left = {for (final s in granted) normaliseScope(s.trim())}..remove('');
  final right = {for (final s in expected) normaliseScope(s)};
  return left.length == right.length && left.containsAll(right);
}

/// Splits a provider's scope string on spaces or commas.
List<String> splitScopes(String? raw) => raw == null
    ? const []
    : [
        for (final part in raw.split(RegExp(r'[ ,]+')))
          if (part.isNotEmpty) part,
      ];

/// The Connect callback URL for a callback [segment], under the Connect's
/// base URL (which may carry a mount prefix).
Uri connectCallbackUri(String connectBaseUrl, String segment) => Uri.parse(
  '${canonicalConnectBaseUrl(connectBaseUrl)}/oauth/$segment/callback',
);

/// Why an authorization URL was refused by [validateAuthorizeUrl].
final class AuthorizeUrlRejected implements Exception {
  /// Creates the rejection.
  const AuthorizeUrlRejected(this.reason);

  /// What was wrong.
  final String reason;

  @override
  String toString() => 'AuthorizeUrlRejected($reason)';
}

/// Checks the URL Connect handed back for [lane] before a server shows it.
///
/// A compromised or misconfigured Connect must not be able to send a human to
/// another host, another client, a widened scope or a callback that is not
/// Connect's own. Throws [AuthorizeUrlRejected] on any difference.
void validateAuthorizeUrl({
  required ConnectOAuthLane lane,
  required Uri url,
  required String connectBaseUrl,
  required String expectedClientId,
  required String codeChallenge,
}) {
  final expected = switch (lane) {
    ConnectOAuthLane.github => (
      host: 'github.com',
      path: '/login/oauth/authorize',
    ),
    ConnectOAuthLane.google => (
      host: 'accounts.google.com',
      path: '/o/oauth2/v2/auth',
    ),
    ConnectOAuthLane.linear || ConnectOAuthLane.linearApp => (
      host: 'linear.app',
      path: '/oauth/authorize',
    ),
    ConnectOAuthLane.slack => (
      host: 'slack.com',
      path: '/openid/connect/authorize',
    ),
  };
  if (url.scheme != 'https' ||
      url.host != expected.host ||
      url.path != expected.path ||
      url.hasPort && url.port != 443 ||
      url.userInfo.isNotEmpty ||
      url.hasFragment) {
    throw const AuthorizeUrlRejected('provider host');
  }
  final q = url.queryParametersAll;
  String? single(String key) {
    final values = q[key];
    if (values == null || values.length != 1) {
      return null;
    }
    return values.single;
  }

  if (single('client_id') != expectedClientId) {
    throw const AuthorizeUrlRejected('client_id');
  }
  final redirect = single('redirect_uri');
  final callback = connectCallbackUri(
    connectBaseUrl,
    lane.firstCallbackSegment,
  ).toString();
  if (redirect != callback) {
    throw const AuthorizeUrlRejected('redirect_uri');
  }
  if (single('response_type') != 'code') {
    throw const AuthorizeUrlRejected('response_type');
  }
  final state = single('state');
  if (state == null || state.length < 32) {
    throw const AuthorizeUrlRejected('state');
  }
  // Slack's OIDC hop carries no PKCE (Connect binds the verifier itself);
  // every other lane must carry the server's own challenge.
  if (lane != ConnectOAuthLane.slack) {
    if (single('code_challenge') != codeChallenge ||
        single('code_challenge_method') != 'S256') {
      throw const AuthorizeUrlRejected('code_challenge');
    }
  }
  final scopes = splitScopes(single('scope'));
  switch (lane) {
    case ConnectOAuthLane.github:
      if (q.containsKey('scope')) {
        throw const AuthorizeUrlRejected('scope');
      }
      if (single('prompt') != 'consent') {
        throw const AuthorizeUrlRejected('prompt');
      }
    case ConnectOAuthLane.google:
      if (!scopesExactlyMatch(scopes, googleConnectScopes)) {
        throw const AuthorizeUrlRejected('scope');
      }
      if (single('access_type') != 'offline' ||
          single('prompt') != 'consent select_account') {
        throw const AuthorizeUrlRejected('prompt');
      }
    case ConnectOAuthLane.linear || ConnectOAuthLane.linearApp:
      if (!scopesExactlyMatch(scopes, linearConnectScopes)) {
        throw const AuthorizeUrlRejected('scope');
      }
      final actor = lane == ConnectOAuthLane.linearApp ? 'app' : 'user';
      if (single('actor') != actor || single('prompt') != 'consent') {
        throw const AuthorizeUrlRejected('actor');
      }
    case ConnectOAuthLane.slack:
      if (!scopesExactlyMatch(scopes, slackOidcScopes)) {
        throw const AuthorizeUrlRejected('scope');
      }
  }
}
