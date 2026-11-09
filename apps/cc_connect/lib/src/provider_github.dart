import 'dart:convert';

import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// A GitHub App user token pair.
final class GitHubTokens {
  /// Creates the pair.
  const GitHubTokens({
    required this.access,
    required this.accessExpiresAt,
    required this.refresh,
    required this.refreshExpiresAt,
    required this.generation,
  });

  /// The `ghu_` user token.
  final String access;

  /// When [access] expires.
  final DateTime accessExpiresAt;

  /// The single-use `ghr_` refresh token.
  final String refresh;

  /// When [refresh] expires, or null when GitHub did not say.
  final DateTime? refreshExpiresAt;

  /// The client-secret generation that obtained the pair.
  final int generation;
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

  /// Whether it is on an organization.
  bool get isOrganization => targetType == 'Organization';

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

  /// The cache form.
  Map<String, Object?> toJson() => {
    'id': id,
    'owner': {'id': ownerId},
    'private': isPrivate,
    'permissions': permissions,
  };
}

/// A child token from `POST /applications/{client_id}/token/scoped`.
final class GitHubScopedMint {
  /// Creates the mint.
  const GitHubScopedMint({required this.token, required this.expiresAt});

  /// The one-repository `ghu_`.
  final String token;

  /// When it expires, or null when GitHub did not say.
  final DateTime? expiresAt;
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

  static final Uri _tokenUrl = Uri.parse(
    'https://github.com/login/oauth/access_token',
  );

  static Map<String, String> _apiHeaders(String token) => {
    'accept': 'application/vnd.github+json',
    'x-github-api-version': '2022-11-28',
    'authorization': 'Bearer $token',
  };

  String _basic(String secret) =>
      'Basic ${base64.encode(utf8.encode('${_creds.clientId}:$secret'))}';

  Future<GitHubTokens> _token(Map<String, String> fields) => withDualSecret(
    _creds.clientSecret,
    (secret, generation) async {
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
        switch (error) {
          case 'incorrect_client_credentials' || 'invalid_client':
            throw const InvalidClientCredentials();
          case 'bad_verification_code' ||
              'bad_refresh_token' ||
              'invalid_grant' ||
              'expired_token' ||
              'unauthorized_client':
            throw GrantRejected(logSlug([error, json?['error_description']]));
          default:
            throw const ConnectException(ConnectErrorCode.providerUnavailable);
        }
      }
      if (!response.ok || json == null) {
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      }
      final access = json['access_token'];
      final expiresIn = intField(json['expires_in']);
      final refresh = json['refresh_token'];
      final refreshIn = intField(json['refresh_token_expires_in']);
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
        refreshExpiresAt: refreshIn == null
            ? null
            : now.add(Duration(seconds: refreshIn)),
        generation: generation,
      );
    },
  );

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

  /// Whether [login] is an active admin of [org]
  /// (`GET /orgs/{org}/memberships/{username}`).
  Future<bool> isActiveOrgAdmin(String token, String org, String login) async {
    if (!isGitHubSegment(org) || !isGitHubSegment(login)) {
      return false;
    }
    final response = await _api('GET', '/orgs/$org/memberships/$login', token);
    if (!response.ok) {
      return false;
    }
    final json = response.jsonObject;
    return json?['role'] == 'admin' && json?['state'] == 'active';
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
          'x-github-api-version': '2022-11-28',
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
    if (!scopedTokenMatches(json, repoId: repoId, permissions: permissions)) {
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
              'x-github-api-version': '2022-11-28',
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

  /// Revokes one token (`DELETE /applications/{client_id}/token`).
  Future<void> deleteToken(String token) =>
      _delete('/applications/${_creds.clientId}/token', token);

  /// Revokes the whole authorization (`DELETE
  /// /applications/{client_id}/grant`).
  Future<void> deleteGrant(String token) =>
      _delete('/applications/${_creds.clientId}/grant', token);
}
