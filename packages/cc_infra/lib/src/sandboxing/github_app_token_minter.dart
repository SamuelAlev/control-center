import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';

/// Credentials for a GitHub App, used to mint short-lived, repo-scoped
/// installation access tokens. All three fields are required; [isComplete]
/// gates whether the fine-grained path is available at all.
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

  /// The installation id the token is minted for.
  final String installationId;

  /// Whether every field needed to mint is present.
  bool get isComplete =>
      appId.isNotEmpty && privateKeyPem.isNotEmpty && installationId.isNotEmpty;
}

/// A minted installation token and its (server-reported) expiry.
class MintedToken {
  /// Creates a [MintedToken].
  const MintedToken({required this.token, this.expiresAt});

  /// The installation access token (`ghs_…`).
  final String token;

  /// When GitHub says the token expires (≈1h), or null if unparsed.
  final DateTime? expiresAt;
}

/// Mints (and revokes) **GitHub App installation access tokens** — short-lived,
/// repo-scoped, permission-restricted credentials — so a sandboxed agent run
/// never sees the user's broad PAT (FINDINGS §1.1/1.2).
///
/// Flow: build a ≤10-minute RS256-signed App JWT (`iss` = app id), present it
/// as `Bearer` to `POST /app/installations/{id}/access_tokens` with the
/// requested `repositories` + `permissions` and return the scoped token.
/// Revocation is `DELETE /installation/token` authed with the token itself.
class GitHubAppTokenMinter {
  /// Creates a minter over an [dio] based at `https://api.github.com`.
  GitHubAppTokenMinter({required Dio dio, required GitHubAppConfig config})
    : _dio = dio,
      _config = config;

  final Dio _dio;
  final GitHubAppConfig _config;

  /// The App JWT the minter presents to GitHub. Public for testability — a test
  /// can verify the RS256 signature + claims without a live GitHub.
  ///
  /// `dart_jsonwebtoken` stamps `iat = now` and (via `expiresIn`) `exp = now +
  /// 9 min`, comfortably under GitHub's 10-minute ceiling; `iss` is the app id.
  String buildAppJwt() {
    return JWT({'iss': _config.appId}).sign(
      RSAPrivateKey(_config.privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
      expiresIn: const Duration(minutes: 9),
    );
  }

  /// Exchanges a fresh App JWT for an installation token scoped to
  /// [repositories] (bare repo names) with [permissions]. Throws on failure.
  Future<MintedToken> mint({
    List<String> repositories = const [],
    Map<String, String> permissions = const {},
  }) async {
    final jwt = buildAppJwt();
    final res = await _dio.post<Map<String, dynamic>>(
      '/app/installations/${_config.installationId}/access_tokens',
      data: {
        if (repositories.isNotEmpty) 'repositories': repositories,
        if (permissions.isNotEmpty) 'permissions': permissions,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $jwt',
          'Accept': 'application/vnd.github+json',
        },
      ),
    );
    final data = res.data ?? const {};
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('GitHub App installation-token mint returned no token.');
    }
    final expStr = data['expires_at'] as String?;
    return MintedToken(
      token: token,
      expiresAt: expStr != null ? DateTime.tryParse(expStr) : null,
    );
  }

  /// Best-effort revocation of an installation [token] (`DELETE
  /// /installation/token`, authed with the token itself).
  Future<void> revoke(String token) async {
    await _dio.delete<void>(
      '/installation/token',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      ),
    );
  }
}
