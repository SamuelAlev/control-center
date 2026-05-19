import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';

/// One stored provider credential, with everything a refresh needs beside it.
///
/// Persisted as a JSON string because the server's secrets file is a flat
/// `String → String` map: an OAuth access token is useless on its own once it
/// expires, so the refresh token and the expiry travel in the same value rather
/// than in three sibling keys that could get out of step.
///
/// [accountLogin] is cached identity, not a secret — it saves a viewer probe on
/// every "who am I on this forge?" read, which is asked once per inbox section.
class ProviderToken {
  /// Creates a [ProviderToken].
  const ProviderToken({
    required this.accessToken,
    this.refreshToken = '',
    this.expiresAt,
    this.refreshExpiresAt,
    this.source = ForgeCredentialSource.settings,
    this.accountLogin = '',
  });

  /// Decodes a stored value. Returns null for anything unparseable, which the
  /// callers treat as "no credential" — a corrupt entry must not authenticate.
  static ProviderToken? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final access = decoded['access'];
      if (access is! String || access.isEmpty) {
        return null;
      }
      return ProviderToken(
        accessToken: access,
        refreshToken: decoded['refresh'] as String? ?? '',
        expiresAt: _parseTime(decoded['expires_at']),
        refreshExpiresAt: _parseTime(decoded['refresh_expires_at']),
        source: ForgeCredentialSource.fromWire(decoded['source'] as String?),
        accountLogin: decoded['account'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }

  static DateTime? _parseTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  /// The bearer credential itself.
  final String accessToken;

  /// The refresh credential, or empty when the provider issues none (a pasted
  /// PAT, a Linear token, a GitHub App that does not expire user tokens).
  final String refreshToken;

  /// When [accessToken] stops working, or null when it does not expire.
  final DateTime? expiresAt;

  /// When [refreshToken] itself stops working, or null when it does not
  /// expire. Past this point re-authentication is the only path, so the UI has
  /// to say "sign in again" rather than retry forever.
  final DateTime? refreshExpiresAt;

  /// How this credential was obtained.
  final ForgeCredentialSource source;

  /// The account name behind the token, when known.
  final String accountLogin;

  /// True when [accessToken] is at (or within a minute of) its expiry.
  ///
  /// The minute of slack is deliberate: a token that expires mid-flight fails
  /// the request it was attached to, and the caller has no way to distinguish
  /// that from a revoked credential.
  bool get isExpired {
    final at = expiresAt;
    return at != null &&
        !at.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 1)));
  }

  /// True when a refresh could still succeed.
  bool get canRefresh {
    if (refreshToken.isEmpty) {
      return false;
    }
    final at = refreshExpiresAt;
    return at == null || at.isAfter(DateTime.now().toUtc());
  }

  /// A copy with [accountLogin] replaced.
  ProviderToken withAccount(String login) => ProviderToken(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    refreshExpiresAt: refreshExpiresAt,
    source: source,
    accountLogin: login,
  );

  /// The stored form.
  String encode() => jsonEncode({
    'access': accessToken,
    if (refreshToken.isNotEmpty) 'refresh': refreshToken,
    if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
    if (refreshExpiresAt != null)
      'refresh_expires_at': refreshExpiresAt!.toUtc().toIso8601String(),
    'source': source.wire,
    if (accountLogin.isNotEmpty) 'account': accountLogin,
  });
}
