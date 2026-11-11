import 'dart:convert';

import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// A GitHub App user token pair.
final class GitHubTokens {
  /// Creates the pair.
  const GitHubTokens({
    required this.access,
    required this.accessExpiresAt,
    required this.refresh,
  });

  /// The `ghu_` user token.
  final String access;

  /// When [access] expires.
  final DateTime accessExpiresAt;

  /// The single-use `ghr_` refresh token.
  final String refresh;
}

/// The authenticated GitHub user.
final class GitHubUser {
  /// Creates the user.
  const GitHubUser({required this.id, required this.login});

  /// Immutable numeric id.
  final int id;

  /// Current login.
  final String login;
}

/// One installation of an app, as `GET /user/installations` reports it.
final class GitHubInstallation {
  /// Creates the installation.
  const GitHubInstallation({
    required this.id,
    required this.appId,
    required this.targetType,
    required this.accountId,
    required this.accountLogin,
    required this.suspended,
  });

  /// Parses one item; null when malformed.
  static GitHubInstallation? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final appId = json['app_id'];
    final type = json['target_type'];
    final account = json['account'];
    if (id is! int || appId is! int || type is! String || account is! Map) {
      return null;
    }
    final accountId = account['id'];
    final login = account['login'];
    if (accountId is! int || login is! String) {
      return null;
    }
    return GitHubInstallation(
      id: id,
      appId: appId,
      targetType: type,
      accountId: accountId,
      accountLogin: login,
      suspended: json['suspended_at'] != null,
    );
  }

  /// The installation id.
  final int id;

  /// The app it belongs to.
  final int appId;

  /// `Organization` or `User`.
  final String targetType;

  /// The account it is installed on.
  final int accountId;

  /// That account's login.
  final String accountLogin;

  /// Whether it is suspended.
  final bool suspended;

  /// The cache form.
  Map<String, Object?> toJson() => {
    'id': id,
    'app_id': appId,
    'target_type': targetType,
    'account': {'id': accountId, 'login': accountLogin},
    'suspended_at': suspended ? 'suspended' : null,
  };
}

/// The repository fields Connect needs.
final class GitHubRepo {
  /// Creates the repo.
  const GitHubRepo({
    required this.id,
    required this.ownerId,
    required this.isPrivate,
    required this.permissions,
  });

  /// Parses `GET /repos/{o}/{r}`; null when malformed.
  static GitHubRepo? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['id'];
    final owner = json['owner'];
    final private = json['private'];
    if (id is! int || owner is! Map || private is! bool) {
      return null;
    }
    final ownerId = owner['id'];
    if (ownerId is! int) {
      return null;
    }
    final permissions = json['permissions'];
    return GitHubRepo(
      id: id,
      ownerId: ownerId,
      isPrivate: private,
      permissions: {
        if (permissions is Map)
          for (final entry in permissions.entries)
            if (entry.key is String && entry.value is bool)
              entry.key as String: entry.value as bool,
      },
    );
  }

  /// Numeric repository id.
  final int id;

  /// Numeric owner id.
  final int ownerId;

  /// Whether it is private (or internal).
  final bool isPrivate;

  /// The caller's role flags.
  final Map<String, bool> permissions;
}

/// A child token from `POST /applications/{client_id}/token/scoped`, whose
/// answer proved a `selected` repository selection and exactly the requested
/// permissions.
final class GitHubScopedMint {
  /// Creates the mint.
  const GitHubScopedMint({
    required this.token,
    required this.expiresAt,
    required this.requestId,
  });

  /// The one-repository `ghu_`.
  final String token;

  /// When it expires, or null when GitHub did not say.
  final DateTime? expiresAt;

  /// GitHub's `x-github-request-id` for the mint, when shaped like one.
  final String? requestId;
}

/// A one-repository installation token from `POST
/// /app/installations/{id}/access_tokens`, with GitHub's own account of what
/// it covers.
final class GitHubInstallationMint {
  /// Creates the mint.
  const GitHubInstallationMint({
    required this.token,
    required this.expiresAt,
    required this.repositorySelection,
    required this.repositoryIds,
    required this.permissions,
    required this.requestId,
  });

  /// The `ghs_` token.
  final String token;

  /// When it expires, or null when GitHub did not say.
  final DateTime? expiresAt;

  /// `selected`.
  final String repositorySelection;

  /// The repository ids it covers (exactly one).
  final List<int> repositoryIds;

  /// The permissions it carries.
  final Map<String, String> permissions;

  /// GitHub's `x-github-request-id` for the mint, when shaped like one.
  final String? requestId;
}

final RegExp _requestIdShape = RegExp(r'^[A-Fa-f0-9:]{1,64}$');

String? _requestId(UpstreamResponse response) {
  final id = response.headers['x-github-request-id'];
  return id != null && _requestIdShape.hasMatch(id) ? id : null;
}

/// GitHub calls, all to fixed hosts. Error bodies are read only to pick a
/// wire code and never forwarded.
final class GitHubApi {
  /// Creates the client.
  GitHubApi(this._http, this._creds, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UpstreamHttp _http;
  final GitHubCredentials _creds;
  final DateTime Function() _clock;
  String _keyPem = '';
  RSAPrivateKey? _key;
  String _jwt = '';
  DateTime? _jwtIssuedAt;

  static final Uri _tokenUrl = Uri.parse(
    'https://github.com/login/oauth/access_token',
  );

  static Map<String, String> _apiHeaders(String token) => {
    'accept': 'application/vnd.github+json',
    'x-github-api-version': githubApiVersion,
    'authorization': 'Bearer $token',
  };

  String _basic(String secret) =>
      'Basic ${base64.encode(utf8.encode('${_creds.clientId}:$secret'))}';

  Future<GitHubTokens> _token(Map<String, String> fields) =>
      withDualSecret(_creds.clientSecret, (secret, _) async {
        final response = await sendUpstream(
          _http,
          UpstreamRequest.form(_tokenUrl, {
            'client_id': _creds.clientId,
            'client_secret': secret,
            ...fields,
          }),
        );
        final json = response.jsonObject;
        final error = json?['error'];
        if (error is String) {
          if (error == 'incorrect_client_credentials' ||
              error == 'invalid_client') {
            throw const InvalidClientCredentials();
          }
          // GitHub's own codes for a dead code or token, besides the shared
          // refresh table.
          if (oauthRefreshRejectedErrors.contains(error) ||
              error == 'bad_verification_code' ||
              error == 'expired_token') {
            throw GrantRejected(logSlug([error, json?['error_description']]));
          }
          throw const ConnectException(ConnectErrorCode.providerUnavailable);
        }
        if (!response.ok || json == null) {
          throw const ConnectException(ConnectErrorCode.providerUnavailable);
        }
        final access = json['access_token'];
        final expiresIn = intField(json['expires_in']);
        final refresh = json['refresh_token'];
        // Non-expiring tokens mean the App has expiry switched off: refuse
        // rather than seal a token that can never be rotated.
        if (access is! String ||
            !access.startsWith('ghu_') ||
            expiresIn == null ||
            expiresIn <= 0 ||
            refresh is! String ||
            !refresh.startsWith('ghr_')) {
          // No refresh token is the App's "Expire user authorization tokens"
          // switched off.
          throw ConnectException(
            ConnectErrorCode.accessDenied,
            reason: refresh is String && refresh.startsWith('ghr_')
                ? 'github_token_shape'
                : 'github_token_expiry_off',
          );
        }
        final now = _clock().toUtc();
        return GitHubTokens(
          access: access,
          accessExpiresAt: now.add(Duration(seconds: expiresIn)),
          refresh: refresh,
        );
      });

  /// Exchanges an authorization code (claim). A rejected code answers
  /// `access_denied`.
  Future<GitHubTokens> exchangeCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    try {
      return await _token({
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      });
    } on GrantRejected catch (e) {
      throw ConnectException(ConnectErrorCode.accessDenied, reason: e.reason);
    }
  }

  /// Rotates a `ghr_` refresh token. A rejected token answers
  /// `needs_sign_in`.
  Future<GitHubTokens> refresh(String refreshToken) async {
    try {
      return await _token({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      });
    } on GrantRejected {
      throw const ConnectException(ConnectErrorCode.needsSignIn);
    }
  }

  Future<UpstreamResponse> _api(
    String method,
    String path,
    String token, {
    Map<String, String>? query,
  }) async {
    final response = await sendUpstream(
      _http,
      UpstreamRequest(
        method,
        Uri.https('api.github.com', path, query),
        headers: _apiHeaders(token),
      ),
    );
    if (response.status == 401) {
      throw const ConnectException(ConnectErrorCode.needsSignIn);
    }
    if (response.status == 403 &&
        response.headers['x-ratelimit-remaining'] == '0') {
      throw const ConnectException(ConnectErrorCode.rateLimited);
    }
    return response;
  }

  /// `GET /user`; the token must belong to a `User`.
  Future<GitHubUser> user(String token) async {
    final response = await _api('GET', '/user', token);
    final json = response.jsonObject;
    final id = json?['id'];
    final login = json?['login'];
    if (!response.ok || id is! int || login is! String) {
      throw ConnectException(
        ConnectErrorCode.accessDenied,
        reason: 'github_user_http_${response.status}',
      );
    }
    if (json?['type'] != 'User') {
      throw const ConnectException(
        ConnectErrorCode.accessDenied,
        reason: 'github_not_a_user',
      );
    }
    return GitHubUser(id: id, login: login);
  }

  /// `GET /user/installations`, every page (at most 1000 installations), of
  /// this app only.
  Future<List<GitHubInstallation>> installations(String token) async {
    final out = <GitHubInstallation>[];
    for (var page = 1; page <= 10; page++) {
      final response = await _api(
        'GET',
        '/user/installations',
        token,
        query: {'per_page': '100', 'page': '$page'},
      );
      final items = response.jsonObject?['installations'];
      if (!response.ok || items is! List) {
        throw const ConnectException(ConnectErrorCode.accessDenied);
      }
      for (final item in items) {
        final installation = GitHubInstallation.tryParse(item);
        if (installation != null && installation.appId == _creds.appId) {
          out.add(installation);
        }
      }
      if (items.length < 100) {
        break;
      }
    }
    return out;
  }

  /// `GET /repos/{owner}/{name}` as the person.
  Future<GitHubRepo> repo(String token, String owner, String name) async {
    final response = await _api('GET', '/repos/$owner/$name', token);
    if (response.status == 404 || response.status == 403) {
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final repo = GitHubRepo.tryParse(response.jsonObject);
    if (!response.ok || repo == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    return repo;
  }

  /// Mints a one-repository child of [parent]. GitHub intersects the
  /// person's role, SSO, rulesets and the installation with the request.
  /// The answer must name exactly [permissions] (and, when it lists them,
  /// exactly [repoId]); anything else is refused.
  Future<GitHubScopedMint> scoped({
    required String parent,
    required int targetId,
    required int repoId,
    required Map<String, String> permissions,
  }) => withDualSecret(_creds.clientSecret, (secret, _) async {
    final response = await sendUpstream(
      _http,
      UpstreamRequest.json(
        'POST',
        Uri.https(
          'api.github.com',
          '/applications/${_creds.clientId}/token/scoped',
        ),
        {
          'access_token': parent,
          'target_id': targetId,
          'repository_ids': [repoId],
          'permissions': permissions,
        },
        headers: {
          'accept': 'application/vnd.github+json',
          'x-github-api-version': githubApiVersion,
          'authorization': _basic(secret),
        },
      ),
    );
    switch (response.status) {
      case 200 || 201:
        break;
      case 401:
        throw const InvalidClientCredentials();
      case 404:
        // Unknown parent token, or (during a rotation) unknown credentials.
        throw const ConnectException(ConnectErrorCode.accessDenied);
      case 422:
        throw const ConnectException(ConnectErrorCode.accessDenied);
      default:
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    final json = response.jsonObject;
    final token = json?['token'];
    if (json == null || token is! String || !token.startsWith('ghu_')) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    // GitHub's answer names the selection and permissions (under
    // `installation`) but no repository list; the request named [repoId].
    if (!scopedTokenMatches(
      json,
      repoId: repoId,
      permissions: permissions,
      requireRepositories: false,
    )) {
      try {
        await deleteToken(token);
      } on Object {
        // Refused either way; the child dies with its parent's expiry.
      }
      throw const ConnectException(ConnectErrorCode.accessDenied);
    }
    final expires = json['expires_at'];
    return GitHubScopedMint(
      token: token,
      expiresAt: expires is String ? DateTime.tryParse(expires)?.toUtc() : null,
      requestId: _requestId(response),
    );
  });

  Future<void> _delete(String path, String token) =>
      withDualSecret(_creds.clientSecret, (secret, _) async {
        final response = await sendUpstream(
          _http,
          UpstreamRequest.json(
            'DELETE',
            Uri.https('api.github.com', path),
            {'access_token': token},
            headers: {
              'accept': 'application/vnd.github+json',
              'x-github-api-version': githubApiVersion,
              'authorization': _basic(secret),
            },
          ),
        );
        // 404/422: the token or grant is already gone, which is the goal.
        if (response.ok || response.status == 404 || response.status == 422) {
          return;
        }
        if (response.status == 401) {
          throw const InvalidClientCredentials();
        }
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      });

  // ------------------------------------------------------ App installations

  /// How long one App JWT is reused: it lives nine minutes.
  static const Duration appJwtReuse = Duration(minutes: 8);

  /// The App JWT (RS256, `iss` = app id, issued a minute in the past for
  /// clock skew, nine minutes of life: GitHub caps it at ten), reused for
  /// [appJwtReuse]. The parsed key is kept until the key's value changes
  /// (a file-backed key is re-read on rotation).
  String _appJwt() {
    final pem = _creds.privateKey.value;
    if (pem.isEmpty) {
      throw const ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_app_key_missing',
      );
    }
    final now = _clock().toUtc();
    final issued = _jwtIssuedAt;
    if (pem == _keyPem &&
        issued != null &&
        now.difference(issued) < appJwtReuse &&
        !now.isBefore(issued)) {
      return _jwt;
    }
    try {
      var key = _key;
      if (key == null || pem != _keyPem) {
        key = RSAPrivateKey(normalizePem(pem));
        _key = key;
        _keyPem = pem;
      }
      final seconds = now.millisecondsSinceEpoch ~/ 1000;
      _jwt = JWT({
        'iss': '${_creds.appId}',
        'iat': seconds - 60,
        'exp': seconds + 9 * 60,
      }).sign(key, algorithm: JWTAlgorithm.RS256, noIssueAt: true);
      _jwtIssuedAt = now;
      return _jwt;
    } on Object {
      _key = null;
      _keyPem = '';
      _jwtIssuedAt = null;
      throw const ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_app_key_unreadable',
      );
    }
  }

  Future<UpstreamResponse> _app(String method, String path, {Object? json}) =>
      sendUpstream(
        _http,
        json == null
            ? UpstreamRequest(
                method,
                Uri.https('api.github.com', path),
                headers: _apiHeaders(_appJwt()),
              )
            : UpstreamRequest.json(
                method,
                Uri.https('api.github.com', path),
                json,
                headers: _apiHeaders(_appJwt()),
              ),
      );

  GitHubInstallation? _ownInstallation(UpstreamResponse response) {
    final installation = GitHubInstallation.tryParse(response.jsonObject);
    if (installation == null || installation.appId != _creds.appId) {
      throw const ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_installation_shape',
      );
    }
    return installation;
  }

  /// The installation of this App that covers [owner]/[name]
  /// (`GET /repos/{o}/{r}/installation`, App JWT), or null when none does:
  /// not installed on the owner, or installed without this repository.
  Future<GitHubInstallation?> repoInstallation(
    String owner,
    String name,
  ) async {
    final response = await _app('GET', '/repos/$owner/$name/installation');
    if (response.status == 404) {
      return null;
    }
    if (!response.ok) {
      throw ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_repo_installation_http_${response.status}',
      );
    }
    return _ownInstallation(response);
  }

  /// The installation of this App on the account [owner]
  /// (`GET /users/{owner}/installation`, App JWT; organizations included),
  /// or null when it is not installed there.
  Future<GitHubInstallation?> accountInstallation(String owner) async {
    final response = await _app('GET', '/users/$owner/installation');
    if (response.status == 404) {
      return null;
    }
    if (!response.ok) {
      throw ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_account_installation_http_${response.status}',
      );
    }
    return _ownInstallation(response);
  }

  /// Mints an installation token for exactly repository [repoId] with
  /// exactly [permissions]. An answer that covers anything else is revoked
  /// (`DELETE /installation/token`) and refused.
  Future<GitHubInstallationMint> installationToken({
    required int installationId,
    required int repoId,
    required Map<String, String> permissions,
  }) async {
    final response = await _app(
      'POST',
      '/app/installations/$installationId/access_tokens',
      json: {
        'repository_ids': [repoId],
        'permissions': permissions,
      },
    );
    final json = response.jsonObject;
    switch (response.status) {
      case 200 || 201:
        break;
      case 403:
        final message = '${json?['message'] ?? ''}'.toLowerCase();
        throw message.contains('suspended')
            ? const ConnectException(ConnectErrorCode.suspended)
            : const ConnectException(
                ConnectErrorCode.accessDenied,
                reason: 'github_installation_token_forbidden',
              );
      case 404:
        throw const ConnectException(ConnectErrorCode.notInstalled);
      case 422:
        // The repository is not in the installation, or the App lacks a
        // permission the scope asks for (an App misconfiguration).
        final message = '${json?['message'] ?? ''}'.toLowerCase();
        throw message.contains('permission')
            ? const ConnectException(
                ConnectErrorCode.accessDenied,
                reason: 'github_app_permission_missing',
              )
            : const ConnectException(ConnectErrorCode.repoNotSelected);
      default:
        throw ConnectException(
          ConnectErrorCode.providerUnavailable,
          reason: 'github_installation_token_http_${response.status}',
        );
    }
    final token = json?['token'];
    if (json == null || token is! String || !token.startsWith('ghs_')) {
      throw const ConnectException(
        ConnectErrorCode.providerUnavailable,
        reason: 'github_installation_token_shape',
      );
    }
    if (!scopedTokenMatches(json, repoId: repoId, permissions: permissions) ||
        json['repository_selection'] != 'selected') {
      await revokeInstallationToken(token);
      throw const ConnectException(
        ConnectErrorCode.accessDenied,
        reason: 'github_installation_token_too_wide',
      );
    }
    final listed = json['repositories'];
    final expires = json['expires_at'];
    return GitHubInstallationMint(
      token: token,
      expiresAt: expires is String ? DateTime.tryParse(expires)?.toUtc() : null,
      repositorySelection: 'selected',
      repositoryIds: listed is List
          ? [
              for (final r in listed)
                if (r is Map && r['id'] is int) r['id'] as int,
            ]
          : [repoId],
      permissions: permissions,
      requestId: _requestId(response),
    );
  }

  /// Revokes an installation token with itself (`DELETE
  /// /installation/token`), best effort: it expires within the hour.
  Future<void> revokeInstallationToken(String token) async {
    try {
      await sendUpstream(
        _http,
        UpstreamRequest(
          'DELETE',
          Uri.https('api.github.com', '/installation/token'),
          headers: _apiHeaders(token),
        ),
      );
    } on Object {
      // Refused either way.
    }
  }

  /// Revokes one token (`DELETE /applications/{client_id}/token`). Never the
  /// whole authorization: on a shared App that would sign the person out of
  /// every other server too.
  Future<void> deleteToken(String token) =>
      _delete('/applications/${_creds.clientId}/token', token);
}
