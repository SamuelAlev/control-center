import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// Who completed Sign in with Slack.
final class SlackOidcIdentity {
  /// Creates the identity.
  const SlackOidcIdentity({required this.teamId, required this.userId});

  /// The workspace.
  final String teamId;

  /// The person (`sub`).
  final String userId;
}

/// A bot grant from `oauth.v2.access` (token rotation on).
final class SlackBotGrant {
  /// Creates the grant.
  const SlackBotGrant({
    required this.access,
    required this.accessExpiresAt,
    required this.refresh,
    required this.scopes,
    required this.appId,
    required this.teamId,
    required this.teamName,
    required this.botUserId,
    required this.authedUserId,
    required this.isEnterpriseInstall,
  });

  /// The rotating `xoxe.xoxb-` bot token.
  final String access;

  /// When it expires.
  final DateTime accessExpiresAt;

  /// The single-use `xoxe-1-` refresh token.
  final String refresh;

  /// Granted bot scopes.
  final List<String> scopes;

  /// The app id.
  final String appId;

  /// The team.
  final String teamId;

  /// The team's name.
  final String teamName;

  /// The bot's user id.
  final String botUserId;

  /// Who installed (empty on a refresh).
  final String authedUserId;

  /// Whether this is an org-wide Enterprise Grid install.
  final bool isEnterpriseInstall;
}

/// `auth.test` for a bot token.
final class SlackAuthTest {
  /// Creates the result.
  const SlackAuthTest({
    required this.teamId,
    required this.userId,
    required this.botId,
  });

  /// The team.
  final String teamId;

  /// The bot user id.
  final String userId;

  /// The bot id.
  final String botId;
}

/// Slack Web API calls Connect makes. Slack answers HTTP 200 with
/// `{"ok": false, "error": …}`; the error string picks a wire code and is
/// never forwarded.
final class SlackApi {
  /// Creates the client.
  SlackApi(this._http, this._creds, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UpstreamHttp _http;
  final SlackCredentials _creds;
  final DateTime Function() _clock;

  static Uri _method(String name) => Uri.https('slack.com', '/api/$name');

  static const Set<String> _clientErrors = {
    'bad_client_secret',
    'invalid_client_id',
    'invalid_client',
  };

  /// Slack's own codes for a dead code or token, besides the shared
  /// refresh table ([oauthRefreshRejectedErrors]).
  static const Set<String> _grantErrors = {
    'invalid_code',
    'code_already_used',
    'code_expired',
    'invalid_refresh_token',
    'token_expired',
    'token_revoked',
    'invalid_auth',
    'account_inactive',
    'not_authed',
  };

  static bool _grantRejected(Object? error) =>
      oauthRefreshRejectedErrors.contains(error) ||
      _grantErrors.contains(error);

  Future<Map<String, Object?>> _call(
    String method,
    Map<String, String> fields,
  ) => withDualSecret(_creds.clientSecret, (secret, _) async {
    final response = await sendUpstream(
      _http,
      UpstreamRequest.form(_method(method), {
        'client_id': _creds.clientId,
        'client_secret': secret,
        ...fields,
      }),
    );
    final json = response.jsonObject;
    if (!response.ok || json == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    if (json['ok'] != true) {
      final error = json['error'];
      if (_clientErrors.contains(error)) {
        throw const InvalidClientCredentials();
      }
      if (_grantRejected(error)) {
        throw const GrantRejected();
      }
      if (error == 'ratelimited') {
        throw const ConnectException(ConnectErrorCode.rateLimited);
      }
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    return json;
  });

  /// Exchanges the OIDC pre-check code (`openid.connect.token`). This call
  /// never touches the workspace's bot installation.
  Future<SlackOidcIdentity> oidcIdentity({
    required String code,
    required String redirectUri,
    required String nonce,
  }) async {
    final Map<String, Object?> json;
    try {
      json = await _call('openid.connect.token', {
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      });
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final idToken = json['id_token'];
    final claims = jwtClaims(idToken is String ? idToken : null);
    if (claims == null ||
        claims['iss'] != 'https://slack.com' ||
        !jwtAudienceIs(claims, _creds.clientId) ||
        !jwtUnexpired(claims, _clock().toUtc()) ||
        claims['nonce'] != nonce) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final team = claims['https://slack.com/team_id'];
    final sub = claims['sub'];
    if (team is! String || !isSlackId(team) || sub is! String || sub.isEmpty) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return SlackOidcIdentity(teamId: team, userId: sub);
  }

  /// Parses an `oauth.v2.access` answer. A refresh answer may leave out the
  /// team, app and bot user ([rotation]); the caller fills them from the
  /// seal, and a value that is present must still match it.
  SlackBotGrant _grant(Map<String, Object?> json, {bool rotation = false}) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final expiresIn = intField(json['expires_in']);
    final team = json['team'];
    final teamId = team is Map ? team['id'] : null;
    final teamName = team is Map ? team['name'] : null;
    final scope = json['scope'];
    final appId = json['app_id'];
    final botUser = json['bot_user_id'];
    final authed = json['authed_user'];
    final authedId = authed is Map ? authed['id'] : null;
    // Token rotation must be on: a long-lived xoxb- could never be rotated
    // or contained.
    if (access is! String ||
        !access.startsWith('xoxe.xoxb-') ||
        refresh is! String ||
        !refresh.startsWith('xoxe-1-') ||
        expiresIn == null ||
        expiresIn <= 0 ||
        !(teamId is String || (rotation && teamId == null)) ||
        !(appId is String || (rotation && appId == null)) ||
        !(botUser is String || (rotation && botUser == null))) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return SlackBotGrant(
      access: access,
      accessExpiresAt: _clock().toUtc().add(Duration(seconds: expiresIn)),
      refresh: refresh,
      scopes: splitScopes(scope is String ? scope : null),
      appId: appId is String ? appId : '',
      teamId: teamId is String ? teamId : '',
      teamName: teamName is String ? teamName : '',
      botUserId: botUser is String ? botUser : '',
      authedUserId: authedId is String ? authedId : '',
      isEnterpriseInstall: json['is_enterprise_install'] == true,
    );
  }

  /// Exchanges the bot install code (`oauth.v2.access`). This rotates the
  /// workspace's bot token, which is why the OIDC pre-check runs first.
  Future<SlackBotGrant> oauthAccess({
    required String code,
    required String redirectUri,
  }) async {
    try {
      return _grant(
        await _call('oauth.v2.access', {
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
  }

  /// Rotates a bot refresh token.
  Future<SlackBotGrant> refresh(String refreshToken) async {
    try {
      return _grant(
        await _call('oauth.v2.access', {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
        rotation: true,
      );
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.needsSignIn);
    }
  }

  Future<Map<String, Object?>> _bearer(
    String method,
    String token, {
    Map<String, String> fields = const {},
  }) async {
    final response = await sendUpstream(
      _http,
      UpstreamRequest.form(
        _method(method),
        fields,
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    final json = response.jsonObject;
    if (!response.ok || json == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    if (json['ok'] != true) {
      if (_grantRejected(json['error'])) {
        throw const GrantRejected();
      }
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    return json;
  }

  /// `auth.test` with a bot token.
  Future<SlackAuthTest> authTest(String token) async {
    final Map<String, Object?> json;
    try {
      json = await _bearer('auth.test', token);
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final team = json['team_id'];
    final user = json['user_id'];
    final bot = json['bot_id'];
    if (team is! String || user is! String || bot is! String) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    return SlackAuthTest(teamId: team, userId: user, botId: bot);
  }

  /// Whether [userId] administers [teamId] (`users.info` with a bot token):
  /// an active full member who is an admin or an owner.
  Future<bool> isWorkspaceAdmin(
    String token, {
    required String teamId,
    required String userId,
  }) async {
    final Map<String, Object?> json;
    try {
      json = await _bearer('users.info', token, fields: {'user': userId});
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final user = json['user'];
    if (user is! Map || user['id'] != userId || user['team_id'] != teamId) {
      return false;
    }
    bool flag(String key) => user[key] == true;
    return !flag('deleted') &&
        !flag('is_bot') &&
        !flag('is_restricted') &&
        !flag('is_ultra_restricted') &&
        (flag('is_admin') || flag('is_owner') || flag('is_primary_owner'));
  }

  /// `auth.revoke`. True when Slack revoked it or it was already dead.
  Future<void> revoke(String token) async {
    try {
      await _bearer('auth.revoke', token);
    } on GrantRejected {
      // Already revoked: the goal.
    }
  }
}

/// A Slack team, enterprise or user id (`T…`, `E…`, `U…`, `W…`).
bool isSlackId(String value) => RegExp(r'^[A-Z0-9]{2,32}$').hasMatch(value);
