/// The closed set of failures Connect reports. Connect never echoes an
/// upstream provider's error body: every failure is one of these codes.
enum ConnectErrorCode {
  /// The grant is gone (revoked, expired, retired app or generation). The
  /// server clears the seal and asks the person to sign in again.
  needsSignIn('needs_sign_in', 401),

  /// The caller may not do this (bad signature, wrong install, wrong role,
  /// seal from another server, blocked scope).
  accessDenied('access_denied', 403),

  /// The app is not installed where the request needs it.
  notInstalled('not_installed', 404),

  /// A GitHub organization installation is bound to other servers.
  installationBoundElsewhere('installation_bound_elsewhere', 409),

  /// A Slack workspace is bound to another server.
  teamBoundElsewhere('team_bound_elsewhere', 409),

  /// Connecting a Slack workspace the first time takes one of its admins or
  /// owners, and the person who approved is neither.
  notAdmin('not_admin', 403),

  /// The installation or account is suspended.
  suspended('suspended', 423),

  /// Slow down.
  rateLimited('rate_limited', 429),

  /// The lane is not configured, or the provider is failing. Never clears a
  /// seal: it is transient by definition.
  providerUnavailable('provider_unavailable', 503),

  /// This install is not allowed on this Connect.
  installBlocked('install_blocked', 403),

  /// A signature outside the clock window, a replayed nonce, an expired
  /// login.
  staleRequest('stale_request', 400),

  /// The request body does not parse into the route's schema.
  invalidRequest('invalid_request', 400);

  const ConnectErrorCode(this.wire, this.httpStatus);

  /// The wire spelling.
  final String wire;

  /// The HTTP status Connect answers with.
  final int httpStatus;

  /// Parses a wire value; [providerUnavailable] for anything unknown, which
  /// is the one failure a client must never treat as "sign out".
  static ConnectErrorCode fromWire(Object? wire) {
    for (final code in values) {
      if (code.wire == wire) {
        return code;
      }
    }
    return providerUnavailable;
  }

  /// Whether a server should drop the stored seal on this failure.
  bool get clearsGrant => this == needsSignIn;
}

/// A failure answered by Connect (or synthesised by a client for a transport
/// failure, always as [ConnectErrorCode.providerUnavailable]).
final class ConnectException implements Exception {
  /// Creates the exception.
  const ConnectException(this.code, {this.reason = ''});

  /// What failed.
  final ConnectErrorCode code;

  /// Why, for the operator's log only: a short slug such as the provider's
  /// own error code. Never sent on the wire, never a token or a secret.
  final String reason;

  /// The wire body.
  Map<String, Object?> toJson() => {'error': code.wire};

  @override
  String toString() => reason.isEmpty
      ? 'ConnectException(${code.wire})'
      : 'ConnectException(${code.wire}: $reason)';
}

/// Why a server asks Connect to start a browser flow.
enum ConnectOAuthPurpose {
  /// Sign a person in.
  signIn('sign_in'),

  /// Install the GitHub App on an account and bind it to this server.
  installGitHubApp('install_github_app'),

  /// Have an organization admin authorize this server on an installation
  /// that exists already.
  authorizeServer('authorize_server');

  const ConnectOAuthPurpose(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; null when unknown.
  static ConnectOAuthPurpose? fromWire(Object? wire) {
    for (final purpose in values) {
      if (purpose.wire == wire) {
        return purpose;
      }
    }
    return null;
  }
}

/// `POST /v1/oauth/{lane}/start`.
final class OAuthStartRequest {
  /// Creates the request.
  const OAuthStartRequest({
    required this.workspaceId,
    required this.codeChallenge,
    this.purpose = ConnectOAuthPurpose.signIn,
    this.installationId,
    this.loginHint = '',
  });

  /// Parses the body; throws [FormatException].
  factory OAuthStartRequest.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace_id'];
    final challenge = json['code_challenge'];
    final method = json['code_challenge_method'];
    final purpose = ConnectOAuthPurpose.fromWire(
      json['purpose'] ?? ConnectOAuthPurpose.signIn.wire,
    );
    final installation = json['installation_id'];
    final hint = json['login_hint'];
    if (workspace is! String ||
        !isWorkspaceScope(workspace) ||
        challenge is! String ||
        method != 'S256' ||
        purpose == null ||
        (installation != null && installation is! int) ||
        (hint != null && hint is! String)) {
      throw const FormatException('oauth start');
    }
    return OAuthStartRequest(
      workspaceId: workspace,
      codeChallenge: challenge,
      purpose: purpose,
      installationId: installation as int?,
      loginHint: hint as String? ?? '',
    );
  }

  /// The workspace the grant will belong to, or `global`.
  final String workspaceId;

  /// The server's PKCE S256 challenge.
  final String codeChallenge;

  /// Why the flow runs.
  final ConnectOAuthPurpose purpose;

  /// The installation to authorize this server on
  /// ([ConnectOAuthPurpose.authorizeServer]).
  final int? installationId;

  /// An optional account hint (Google `login_hint`).
  final String loginHint;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'workspace_id': workspaceId,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    'purpose': purpose.wire,
    'installation_id': ?installationId,
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

/// `POST /v1/{github,google,slack}/refresh` and `/v1/slack/revoke`.
final class SealRequest {
  /// Creates the request.
  const SealRequest({required this.seal, required this.workspaceId});

  /// Parses the body; throws [FormatException].
  factory SealRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    if (seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace)) {
      throw const FormatException('seal request');
    }
    return SealRequest(seal: seal, workspaceId: workspace);
  }

  /// The seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The wire body.
  Map<String, Object?> toJson() => {'seal': seal, 'workspace_id': workspaceId};
}

/// `POST /v1/github/scope`.
final class GitHubScopeRequest {
  /// Creates the request.
  const GitHubScopeRequest({
    required this.seal,
    required this.workspaceId,
    required this.repoId,
    required this.repoOwner,
    required this.repoName,
    required this.scope,
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopeRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    final repoId = json['repo_id'];
    final owner = json['repo_owner'];
    final name = json['repo_name'];
    final scope = json['scope'];
    if (seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace) ||
        repoId is! int ||
        repoId <= 0 ||
        owner is! String ||
        name is! String ||
        scope is! String) {
      throw const FormatException('github scope');
    }
    return GitHubScopeRequest(
      seal: seal,
      workspaceId: workspace,
      repoId: repoId,
      repoOwner: owner,
      repoName: name,
      scope: scope,
    );
  }

  /// The accountable human's GitHub seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The numeric repository id (from the linked repo record).
  final int repoId;

  /// The repository owner login.
  final String repoOwner;

  /// The repository name.
  final String repoName;

  /// The requested scope wire value.
  final String scope;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'workspace_id': workspaceId,
    'repo_id': repoId,
    'repo_owner': repoOwner,
    'repo_name': repoName,
    'scope': scope,
  };
}

/// The answer to [GitHubScopeRequest].
final class GitHubScopedToken {
  /// Creates the token.
  const GitHubScopedToken({
    required this.accessToken,
    required this.grantedScope,
    required this.expiresAt,
    this.updatedSeal = '',
    this.installationId = 0,
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopedToken.fromJson(Map<String, Object?> json) {
    final access = json['access_token'];
    final granted = json['granted_scope'];
    final expires = json['expires_at'];
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    final updated = json['updated_seal'];
    final installation = json['installation_id'];
    if (access is! String ||
        access.isEmpty ||
        granted is! String ||
        parsedExpiry == null) {
      throw const FormatException('github scoped token');
    }
    return GitHubScopedToken(
      accessToken: access,
      grantedScope: granted,
      expiresAt: parsedExpiry.toUtc(),
      updatedSeal: updated is String ? updated : '',
      installationId: installation is int ? installation : 0,
    );
  }

  /// The one-repository `ghu_` token.
  final String accessToken;

  /// The scope actually granted (possibly clamped below the request).
  final String grantedScope;

  /// When the token expires.
  final DateTime expiresAt;

  /// A rotated parent seal the server must persist, when the parent was
  /// refreshed on the way.
  final String updatedSeal;

  /// The installation the token was minted through.
  final int installationId;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'granted_scope': grantedScope,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
    if (installationId > 0) 'installation_id': installationId,
  };
}

/// `POST /v1/github/revoke`: a full disconnect (seal) or one scoped token.
final class GitHubRevokeRequest {
  /// Creates the request.
  const GitHubRevokeRequest({
    required this.workspaceId,
    this.seal = '',
    this.scopedToken = '',
  });

  /// Parses the body; throws [FormatException].
  factory GitHubRevokeRequest.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace_id'];
    final seal = json['seal'];
    final token = json['scoped_token'];
    if (workspace is! String ||
        !isWorkspaceScope(workspace) ||
        seal is! String ||
        seal.isEmpty ||
        (token != null && token is! String)) {
      throw const FormatException('github revoke');
    }
    return GitHubRevokeRequest(
      workspaceId: workspace,
      seal: seal,
      scopedToken: token as String? ?? '',
    );
  }

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The grant's seal (proves the caller owns it).
  final String seal;

  /// When set, only this scoped token is revoked; otherwise the whole grant.
  final String scopedToken;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'workspace_id': workspaceId,
    'seal': seal,
    if (scopedToken.isNotEmpty) 'scoped_token': scopedToken,
  };
}

/// A body-stripped Slack event reference. Carries ids and timestamps only:
/// the bound server re-reads the message from Slack itself.
final class SlackEventRef {
  /// Creates the reference.
  const SlackEventRef({
    required this.eventId,
    required this.teamId,
    required this.eventType,
    this.channelId = '',
    this.threadTs = '',
    this.messageTs = '',
  });

  /// Parses one reference; null when malformed.
  static SlackEventRef? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['event_id'];
    final team = json['team_id'];
    final type = json['event_type'];
    if (id is! String || team is! String || type is! String) {
      return null;
    }
    String text(String key) {
      final value = json[key];
      return value is String ? value : '';
    }

    return SlackEventRef(
      eventId: id,
      teamId: team,
      eventType: type,
      channelId: text('channel_id'),
      threadTs: text('thread_ts'),
      messageTs: text('message_ts'),
    );
  }

  /// Slack's event id, the dedupe key.
  final String eventId;

  /// The team the event belongs to.
  final String teamId;

  /// `app_mention`, `message.im`, `assistant_thread_started`, …
  final String eventType;

  /// The channel.
  final String channelId;

  /// The thread root, when in a thread.
  final String threadTs;

  /// The message timestamp.
  final String messageTs;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'kind': 'event',
    'event_id': eventId,
    'team_id': teamId,
    'event_type': eventType,
    if (channelId.isNotEmpty) 'channel_id': channelId,
    if (threadTs.isNotEmpty) 'thread_ts': threadTs,
    if (messageTs.isNotEmpty) 'message_ts': messageTs,
  };
}

/// A Slack slash command reference. A command cannot be re-read from Slack,
/// so its argument text travels — bounded — and only ever creates a draft
/// the person confirms inside Control Center.
final class SlackCommandRef {
  /// Creates the reference.
  const SlackCommandRef({
    required this.commandId,
    required this.teamId,
    required this.userId,
    required this.channelId,
    required this.command,
    required this.text,
    required this.responseUrl,
  });

  /// Parses one reference; null when malformed.
  static SlackCommandRef? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final fields = [
      'command_id',
      'team_id',
      'user_id',
      'channel_id',
      'command',
      'text',
      'response_url',
    ];
    for (final field in fields) {
      if (json[field] is! String) {
        return null;
      }
    }
    return SlackCommandRef(
      commandId: json['command_id']! as String,
      teamId: json['team_id']! as String,
      userId: json['user_id']! as String,
      channelId: json['channel_id']! as String,
      command: json['command']! as String,
      text: json['text']! as String,
      responseUrl: json['response_url']! as String,
    );
  }

  /// Longest command argument relayed.
  static const int maxText = 500;

  /// Unique id assigned by Connect (Slack sends none).
  final String commandId;

  /// The team.
  final String teamId;

  /// Who ran it.
  final String userId;

  /// Where.
  final String channelId;

  /// The command (`/cc`).
  final String command;

  /// Its argument text, at most [maxText] characters.
  final String text;

  /// Slack's response URL (only `https://hooks.slack.com/` is honoured).
  final String responseUrl;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'kind': 'command',
    'command_id': commandId,
    'team_id': teamId,
    'user_id': userId,
    'channel_id': channelId,
    'command': command,
    'text': text,
    'response_url': responseUrl,
  };
}

/// Whether [url] is a Slack response URL a server may post to.
bool isSlackResponseUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'hooks.slack.com' &&
      !uri.hasPort &&
      uri.userInfo.isEmpty;
}

/// One normalised GIF from the Klipy proxy.
final class KlipyGif {
  /// Creates the item.
  const KlipyGif({
    required this.id,
    required this.title,
    required this.width,
    required this.height,
    required this.previewUrl,
    required this.gifUrl,
  });

  /// Parses one item; null when malformed or when a URL is off Klipy's CDN.
  static KlipyGif? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final title = json['title'];
    final width = json['width'];
    final height = json['height'];
    final preview = json['preview_url'];
    final gif = json['gif_url'];
    if (id is! String ||
        title is! String ||
        width is! int ||
        height is! int ||
        preview is! String ||
        gif is! String ||
        !isKlipyCdnUrl(preview) ||
        !isKlipyCdnUrl(gif)) {
      return null;
    }
    return KlipyGif(
      id: id,
      title: title,
      width: width,
      height: height,
      previewUrl: preview,
      gifUrl: gif,
    );
  }

  /// Klipy's id.
  final String id;

  /// Its title.
  final String title;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// A small preview, on Klipy's CDN.
  final String previewUrl;

  /// The full GIF, on Klipy's CDN.
  final String gifUrl;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'width': width,
    'height': height,
    'preview_url': previewUrl,
    'gif_url': gifUrl,
  };
}

/// Klipy's API host. It carries the app key in its paths, so it is never a
/// media host.
const String klipyApiHost = 'api.klipy.com';

/// Whether [url] is an HTTPS URL on Klipy's media CDN (a `klipy.com`
/// subdomain other than [klipyApiHost]). GIF bytes load straight from there
/// in the client; any other host in a search answer is dropped.
bool isKlipyCdnUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) {
    return false;
  }
  final host = uri.host.toLowerCase();
  return host.endsWith('.klipy.com') && host != klipyApiHost;
}

/// The workspace scope of a grant that belongs to no single workspace.
const String globalWorkspaceScope = 'global';

/// Whether [value] is a workspace id or [globalWorkspaceScope].
bool isWorkspaceScope(String value) =>
    value.isNotEmpty &&
    value.length <= 64 &&
    RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

/// `POST /v1/github/install/start`: a signed-in person asks for a GitHub App
/// install link whose post-install redirect binds the new installation to
/// this server (the person's own seal proves who installs).
final class GitHubInstallStartResponse {
  /// Creates the response.
  const GitHubInstallStartResponse({
    required this.installUrl,
    required this.expiresAt,
    this.updatedSeal = '',
  });

  /// Parses the body; throws [FormatException].
  factory GitHubInstallStartResponse.fromJson(Map<String, Object?> json) {
    final url = json['install_url'];
    final expires = json['expires_at'];
    final updated = json['updated_seal'];
    final parsedUrl = url is String ? Uri.tryParse(url) : null;
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host != 'github.com' ||
        parsedExpiry == null) {
      throw const FormatException('github install start');
    }
    return GitHubInstallStartResponse(
      installUrl: parsedUrl,
      expiresAt: parsedExpiry.toUtc(),
      updatedSeal: updated is String ? updated : '',
    );
  }

  /// `https://github.com/apps/<slug>/installations/new?state=<ticket>`.
  final Uri installUrl;

  /// When the ticket in [installUrl] expires.
  final DateTime expiresAt;

  /// A rotated seal the server must persist: the ticket carries a parent
  /// token fresh enough to outlive it, because the browser-side setup
  /// redirect has no way to hand a rotated seal back.
  final String updatedSeal;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'install_url': installUrl.toString(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
  };
}

/// `POST /v1/github/authorize_server`: an organization admin (or the owner
/// of a personal installation) adds this server to an installation's
/// binding.
final class GitHubAuthorizeServerRequest {
  /// Creates the request.
  const GitHubAuthorizeServerRequest({
    required this.seal,
    required this.workspaceId,
    required this.installationId,
  });

  /// Parses the body; throws [FormatException].
  factory GitHubAuthorizeServerRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    final installation = json['installation_id'];
    if (seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace) ||
        installation is! int ||
        installation <= 0) {
      throw const FormatException('github authorize server');
    }
    return GitHubAuthorizeServerRequest(
      seal: seal,
      workspaceId: workspace,
      installationId: installation,
    );
  }

  /// The admin's seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The installation to bind this server to.
  final int installationId;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'workspace_id': workspaceId,
    'installation_id': installationId,
  };
}

/// One installation of the shared GitHub App the signed-in person can see,
/// with whether this server may mint against it
/// (`POST /v1/github/installations`, body: [SealRequest]).
final class GitHubInstallationView {
  /// Creates the view.
  const GitHubInstallationView({
    required this.installationId,
    required this.accountId,
    required this.accountLogin,
    required this.targetType,
    required this.boundHere,
    required this.suspended,
    required this.callerIsAdmin,
  });

  /// Parses one item; null when malformed.
  static GitHubInstallationView? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['installation_id'];
    final accountId = json['account_id'];
    final login = json['account_login'];
    final type = json['target_type'];
    if (id is! int ||
        accountId is! int ||
        login is! String ||
        type is! String) {
      return null;
    }
    return GitHubInstallationView(
      installationId: id,
      accountId: accountId,
      accountLogin: login,
      targetType: type,
      boundHere: json['bound_here'] == true,
      suspended: json['suspended'] == true,
      callerIsAdmin: json['caller_is_admin'] == true,
    );
  }

  /// GitHub's installation id.
  final int installationId;

  /// The account the app is installed on (numeric).
  final int accountId;

  /// Its login.
  final String accountLogin;

  /// `Organization` or `User`.
  final String targetType;

  /// Whether this server is in the installation's binding (always true for
  /// the caller's own personal installation).
  final bool boundHere;

  /// Whether the installation is suspended.
  final bool suspended;

  /// Whether the caller may authorize servers on it.
  final bool callerIsAdmin;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'installation_id': installationId,
    'account_id': accountId,
    'account_login': accountLogin,
    'target_type': targetType,
    'bound_here': boundHere,
    'suspended': suspended,
    'caller_is_admin': callerIsAdmin,
  };
}
