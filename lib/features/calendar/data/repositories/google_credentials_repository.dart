import 'package:control_center/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The stored Google OAuth credentials for a single workspace's connected
/// account. Held in the platform secure store, never in `SharedPreferences`.
class GoogleCredentials {
  /// Creates a [GoogleCredentials].
  const GoogleCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.accountEmail,
    required this.scope,
  });

  /// Short-lived OAuth access token (Bearer).
  final String accessToken;

  /// Long-lived refresh token used to mint new access tokens.
  final String refreshToken;

  /// When [accessToken] expires.
  final DateTime expiresAt;

  /// The connected Google account's email (from the id_token).
  final String accountEmail;

  /// The granted scope string.
  final String scope;

  /// Whether [accessToken] is expired (or within [skew] of expiring).
  bool isExpired({Duration skew = const Duration(minutes: 5)}) =>
      DateTime.now().isAfter(expiresAt.subtract(skew));

  /// Returns a copy with the access token + expiry replaced (refresh path).
  GoogleCredentials copyWithAccessToken({
    required String accessToken,
    required DateTime expiresAt,
  }) =>
      GoogleCredentials(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        accountEmail: accountEmail,
        scope: scope,
      );
}

/// Reads / writes / clears Google OAuth tokens in [FlutterSecureStorage],
/// keyed **per connected account** so a workspace can hold several Google
/// accounts at once, each with its own tokens.
///
/// Every key is suffixed with `__<accountId>`. Account ids embed the workspace
/// (`google:<workspaceId>:<email>`), so a token written for one workspace's
/// account is structurally unreadable from another — the workspace-isolation
/// invariant still holds.
class GoogleCredentialsRepository {
  /// Creates a [GoogleCredentialsRepository].
  GoogleCredentialsRepository(this._storage);

  final FlutterSecureStorage _storage;

  String _key(String base, String accountId) => '${base}__$accountId';

  /// Loads the credentials for [accountId], or `null` when the access or
  /// refresh token is missing (i.e. the account is not connected).
  Future<GoogleCredentials?> load(String accountId) async {
    final accessToken =
        await _storage.read(key: _key(googleAccessTokenKey, accountId));
    final refreshToken =
        await _storage.read(key: _key(googleRefreshTokenKey, accountId));
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }
    final expiryRaw =
        await _storage.read(key: _key(googleTokenExpiryKey, accountId));
    final email =
        await _storage.read(key: _key(googleAccountEmailKey, accountId)) ?? '';
    final scope =
        await _storage.read(key: _key(googleScopeKey, accountId)) ?? '';
    return GoogleCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt:
          DateTime.tryParse(expiryRaw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      accountEmail: email,
      scope: scope,
    );
  }

  /// Persists the full credential set for [accountId].
  Future<void> save(String accountId, GoogleCredentials creds) async {
    await _storage.write(
      key: _key(googleAccessTokenKey, accountId),
      value: creds.accessToken,
    );
    await _storage.write(
      key: _key(googleRefreshTokenKey, accountId),
      value: creds.refreshToken,
    );
    await _storage.write(
      key: _key(googleTokenExpiryKey, accountId),
      value: creds.expiresAt.toIso8601String(),
    );
    await _storage.write(
      key: _key(googleAccountEmailKey, accountId),
      value: creds.accountEmail,
    );
    await _storage.write(
      key: _key(googleScopeKey, accountId),
      value: creds.scope,
    );
  }

  /// Rewrites just the access token + expiry after a refresh, preserving the
  /// refresh token, account email and scope already stored for [accountId].
  Future<void> updateAccessToken(
    String accountId, {
    required String accessToken,
    required DateTime expiresAt,
  }) async {
    await _storage.write(
      key: _key(googleAccessTokenKey, accountId),
      value: accessToken,
    );
    await _storage.write(
      key: _key(googleTokenExpiryKey, accountId),
      value: expiresAt.toIso8601String(),
    );
  }

  /// Deletes all Google credential keys for [accountId] (disconnect).
  Future<void> clear(String accountId) async {
    await _storage.delete(key: _key(googleAccessTokenKey, accountId));
    await _storage.delete(key: _key(googleRefreshTokenKey, accountId));
    await _storage.delete(key: _key(googleTokenExpiryKey, accountId));
    await _storage.delete(key: _key(googleAccountEmailKey, accountId));
    await _storage.delete(key: _key(googleScopeKey, accountId));
  }
}
