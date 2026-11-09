import 'package:cc_connect_core/src/wire.dart';

/// `POST /v1/oauth/{lane}/start`.
final class OAuthStartRequest {
  /// Creates the request.
  const OAuthStartRequest({
    required this.workspaceId,
    required this.codeChallenge,
    this.loginHint = '',
  });

  /// Parses the body; throws [FormatException].
  factory OAuthStartRequest.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace_id'];
    final challenge = json['code_challenge'];
    final method = json['code_challenge_method'];
    // Older servers still say `purpose: sign_in` (the only flow there ever
    // was); anything else, or an installation id, is a flow this Connect
    // does not run.
    final purpose = json['purpose'];
    final hint = json['login_hint'];
    if (workspace is! String ||
        !isWorkspaceScope(workspace) ||
        challenge is! String ||
        method != 'S256' ||
        (purpose != null && purpose != 'sign_in') ||
        json['installation_id'] != null ||
        (hint != null && hint is! String)) {
      throw const FormatException('oauth start');
    }
    return OAuthStartRequest(
      workspaceId: workspace,
      codeChallenge: challenge,
      loginHint: hint as String? ?? '',
    );
  }

  /// The workspace the grant will belong to, or `global`.
  final String workspaceId;

  /// The server's PKCE S256 challenge.
  final String codeChallenge;

  /// An optional account hint (Google `login_hint`).
  final String loginHint;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'workspace_id': workspaceId,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    if (loginHint.isNotEmpty) 'login_hint': loginHint,
  };
}

/// The answer to [OAuthStartRequest].
final class OAuthStartResponse {
  /// Creates the response.
  const OAuthStartResponse({
    required this.loginId,
    required this.authorizeUrl,
    required this.expiresAt,
  });

  /// Parses the body; throws [FormatException].
  factory OAuthStartResponse.fromJson(Map<String, Object?> json) {
    final login = json['login_id'];
    final url = json['authorize_url'];
    final expires = json['expires_at'];
    final parsedUrl = url is String ? Uri.tryParse(url) : null;
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    if (login is! String || parsedUrl == null || parsedExpiry == null) {
      throw const FormatException('oauth start response');
    }
    return OAuthStartResponse(
      loginId: login,
      authorizeUrl: parsedUrl,
      expiresAt: parsedExpiry.toUtc(),
    );
  }

  /// The opaque login handle.
  final String loginId;

  /// Where to send the person's browser.
  final Uri authorizeUrl;

  /// When the login stops being claimable.
  final DateTime expiresAt;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'login_id': loginId,
    'authorize_url': authorizeUrl.toString(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };
}

/// `POST /v1/oauth/{lane}/claim`.
final class OAuthClaimRequest {
  /// Creates the request.
  const OAuthClaimRequest({
    required this.loginId,
    required this.confirmCode,
    required this.codeVerifier,
    required this.workspaceId,
  });

  /// Parses the body; throws [FormatException].
  factory OAuthClaimRequest.fromJson(Map<String, Object?> json) {
    final login = json['login_id'];
    final code = json['confirm_code'];
    final verifier = json['code_verifier'];
    final workspace = json['workspace_id'];
    if (login is! String ||
        code is! String ||
        verifier is! String ||
        workspace is! String ||
        !isWorkspaceScope(workspace)) {
      throw const FormatException('oauth claim');
    }
    return OAuthClaimRequest(
      loginId: login,
      confirmCode: code,
      codeVerifier: verifier,
      workspaceId: workspace,
    );
  }

  /// The login being claimed.
  final String loginId;

  /// The code the approving browser showed.
  final String confirmCode;

  /// The PKCE verifier for the challenge sent at start.
  final String codeVerifier;

  /// Must equal the workspace named at start.
  final String workspaceId;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'login_id': loginId,
    'confirm_code': confirmCode,
    'code_verifier': codeVerifier,
    'workspace_id': workspaceId,
  };
}

/// What Connect returns from a claim or a refresh for a sealed lane
/// (GitHub, Google, Slack). The access token is for the server's memory
/// only; the [seal] is what it persists.
final class SealedGrant {
  /// Creates the grant.
  const SealedGrant({
    required this.seal,
    required this.accessToken,
    required this.expiresAt,
    this.accountId = '',
    this.accountLogin = '',
    this.appId = '',
    this.teamId = '',
    this.teamName = '',
    this.botUserId = '',
    this.botId = '',
    this.authedUserId = '',
  });

  /// Parses the body; throws [FormatException].
  factory SealedGrant.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final access = json['access_token'];
    final expires = json['expires_at'];
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    if (seal is! String ||
        seal.isEmpty ||
        access is! String ||
        access.isEmpty ||
        parsedExpiry == null) {
      throw const FormatException('sealed grant');
    }
    String text(String key) {
      final value = json[key];
      return value is String ? value : (value is int ? '$value' : '');
    }

    return SealedGrant(
      seal: seal,
      accessToken: access,
      expiresAt: parsedExpiry.toUtc(),
      accountId: text('account_id'),
      accountLogin: text('account_login'),
      appId: text('app_id'),
      teamId: text('team_id'),
      teamName: text('team_name'),
      botUserId: text('bot_user_id'),
      botId: text('bot_id'),
      authedUserId: text('authed_user_id'),
    );
  }

  /// The opaque KMS-sealed refresh credential, bound to the install.
  final String seal;

  /// A short-lived provider access token.
  final String accessToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// Immutable provider account id (GitHub numeric id, Google `sub`, Slack
  /// team id for a bot grant).
  final String accountId;

  /// Display handle (GitHub login, Google email).
  final String accountLogin;

  /// The provider app id the grant belongs to.
  final String appId;

  /// Slack only: the team.
  final String teamId;

  /// Slack only: the team's name.
  final String teamName;

  /// Slack only: the bot's user id.
  final String botUserId;

  /// Slack only: the bot id.
  final String botId;

  /// Slack only: who installed.
  final String authedUserId;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'access_token': accessToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (accountId.isNotEmpty) 'account_id': accountId,
    if (accountLogin.isNotEmpty) 'account_login': accountLogin,
    if (appId.isNotEmpty) 'app_id': appId,
    if (teamId.isNotEmpty) 'team_id': teamId,
    if (teamName.isNotEmpty) 'team_name': teamName,
    if (botUserId.isNotEmpty) 'bot_user_id': botUserId,
    if (botId.isNotEmpty) 'bot_id': botId,
    if (authedUserId.isNotEmpty) 'authed_user_id': authedUserId,
  };
}

/// What a Linear claim returns: the authorization code, which the server
/// exchanges directly with Linear (Linear tokens never transit Connect).
final class LinearCodeGrant {
  /// Creates the grant.
  const LinearCodeGrant({required this.code, required this.redirectUri});

  /// Parses the body; throws [FormatException].
  factory LinearCodeGrant.fromJson(Map<String, Object?> json) {
    final code = json['code'];
    final redirect = json['redirect_uri'];
    if (code is! String || code.isEmpty || redirect is! String) {
      throw const FormatException('linear code grant');
    }
    return LinearCodeGrant(code: code, redirectUri: redirect);
  }

  /// The one-time authorization code.
  final String code;

  /// The redirect URI the code was issued for (Connect's callback).
  final String redirectUri;

  /// The wire body.
  Map<String, Object?> toJson() => {'code': code, 'redirect_uri': redirectUri};
}
