import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:rhttp/rhttp.dart';

/// Credentials for ONE installation of a GitHub App, used to mint short-lived,
/// repo-scoped access tokens.
///
/// [installationId] is resolved per call by `GitHubAppClient` from the repo's
/// owner: an app is installed per account, and which account matters is only
/// known once a repo is picked.
class GitHubAppConfig {
  /// Creates a [GitHubAppConfig].
  const GitHubAppConfig({
    required this.appId,
    required this.privateKeyPem,
    required this.installationId,
  });

  /// The GitHub App's numeric id (the JWT `iss`).
  final String appId;

  /// The App's RSA private key in PEM form (PKCS#1 or PKCS#8).
  final String privateKeyPem;

  /// The installation the token is minted for, resolved from the repo's owner
  /// by the caller.
  final String installationId;
}

/// The App JWT GitHub's App endpoints authenticate with: RS256, `iss` the
/// App id, issued a minute in the past (GitHub's advice against clock skew)
/// and expiring nine minutes after [now], under GitHub's ten-minute ceiling.
String buildGitHubAppJwt({
  required String appId,
  required String privateKeyPem,
  required DateTime now,
}) {
  int seconds(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
  return JWT({
    'iss': appId,
    'iat': seconds(now.subtract(const Duration(seconds: 60))),
    'exp': seconds(now.add(const Duration(minutes: 9))),
  }).sign(
    RSAPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.RS256,
    noIssueAt: true,
  );
}

/// A minted installation token, its (server-reported) expiry, and what GitHub
/// said it covers.
class MintedToken {
  /// Creates a [MintedToken].
  const MintedToken({
    required this.token,
    this.expiresAt,
    this.coverage = const {},
    this.requestId = '',
  });

  /// The installation access token (`ghs_…`).
  final String token;

  /// When GitHub says the token expires (≈1h), or null if unparsed.
  final DateTime? expiresAt;

  /// GitHub's `permissions`, `repository_selection` and `repositories`, as
  /// answered, so a caller that knows the repository's id can prove the
  /// coverage again by id.
  final Map<String, Object?> coverage;

  /// GitHub's `x-github-request-id` for the mint, or ''.
  final String requestId;
}

/// Mints (and revokes) **GitHub App installation access tokens**: short-lived,
/// repo-scoped, permission-restricted credentials.
///
/// Flow: build an App JWT ([buildGitHubAppJwt]), present it as `Bearer` to
/// `POST /app/installations/{id}/access_tokens` with the requested
/// `repositories` + `permissions`, and return the scoped token only when
/// GitHub's answer covers exactly those repositories with exactly those
/// permissions. Revocation is `DELETE /installation/token` authed with the
/// token itself.
class GitHubAppTokenMinter {
  /// Creates a minter over an [_httpClient] based at `https://api.github.com`.
  GitHubAppTokenMinter({
    required this._httpClient,
    required this._config,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final RhttpClient _httpClient;
  final GitHubAppConfig _config;
  final DateTime Function() _now;

  /// The App JWT the minter presents to GitHub.
  String buildAppJwt() => buildGitHubAppJwt(
    appId: _config.appId,
    privateKeyPem: _config.privateKeyPem,
    now: _now(),
  );

  /// Exchanges a fresh App JWT for an installation token scoped to
  /// [repositories] (bare repo names) with [permissions].
  ///
  /// Throws [ArgumentError] for an empty [repositories] or [permissions]
  /// (GitHub reads either absent as "everything the installation has"),
  /// [FormatException] for an answer that is not a token, and [StateError]
  /// for a token wider than asked (revoked first).
  Future<MintedToken> mint({
    required List<String> repositories,
    required Map<String, String> permissions,
  }) async {
    if (repositories.isEmpty) {
      throw ArgumentError.value(repositories, 'repositories', 'is empty');
    }
    if (permissions.isEmpty) {
      throw ArgumentError.value(permissions, 'permissions', 'is empty');
    }
    final jwt = buildAppJwt();
    final res = await _httpClient.post(
      '/app/installations/${_config.installationId}/access_tokens',
      body: HttpBody.json({
        'repositories': repositories,
        'permissions': permissions,
      }),
      headers: HttpHeaders.rawMap({
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/vnd.github+json',
      }),
    );
    final data = httpJsonBody(res);
    final token = data is Map ? data['token'] : null;
    if (data is! Map || token is! String || token.isEmpty) {
      throw const FormatException(
        'GitHub App installation-token mint returned no token.',
      );
    }
    if (!_coversExactly(data, repositories, permissions)) {
      try {
        await revoke(token);
      } on Object {
        // Refused either way; an unrevoked token expires within the hour.
      }
      throw StateError(
        'GitHub App installation-token mint was not limited to the '
        'requested repositories and permissions.',
      );
    }
    final expires = data['expires_at'];
    return MintedToken(
      token: token,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
      coverage: {
        'permissions': data['permissions'],
        'repository_selection': data['repository_selection'],
        'repositories': data['repositories'],
      },
      requestId: _header(res.headers, 'x-github-request-id'),
    );
  }

  /// Whether the answer proves it covers exactly [repositories] with exactly
  /// [permissions]: a `selected` selection, a repository list naming them
  /// and nothing else, and a permission map equal to the one asked for.
  /// GitHub always lists both for an installation token, so an answer
  /// without them proves nothing and is refused.
  static bool _coversExactly(
    Map<dynamic, dynamic> data,
    List<String> repositories,
    Map<String, String> permissions,
  ) {
    if (data['repository_selection'] != 'selected') {
      return false;
    }
    final granted = data['permissions'];
    if (granted is! Map ||
        granted.length != permissions.length ||
        permissions.entries.any((e) => granted[e.key] != e.value)) {
      return false;
    }
    final listed = data['repositories'];
    if (listed is! List) {
      return false;
    }
    final names = {
      for (final r in listed)
        if (r is Map && r['name'] is String)
          (r['name'] as String).toLowerCase(),
    };
    return names.length == listed.length &&
        names.length == repositories.length &&
        repositories.every((r) => names.contains(r.toLowerCase()));
  }

  /// Best-effort revocation of an installation [token] (`DELETE
  /// /installation/token`, authed with the token itself).
  Future<void> revoke(String token) async {
    await _httpClient.delete(
      '/installation/token',
      headers: HttpHeaders.rawMap({
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
  }
}

/// [name]'s value in [headers], compared case-insensitively, or ''.
String _header(List<(String, String)> headers, String name) {
  for (final (key, value) in headers) {
    if (key.toLowerCase() == name) {
      return value;
    }
  }
  return '';
}
