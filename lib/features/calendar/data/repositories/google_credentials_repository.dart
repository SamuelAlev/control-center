import 'dart:convert';

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// The stored Google OAuth credentials for a single workspace's connected
/// account. Held in the platform secure store, never in plain preferences.
class GoogleCredentials {
  /// Creates a [GoogleCredentials].
  const GoogleCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.accountEmail,
    required this.scope,
  });

  /// Reconstructs credentials from their [toJson] form, or `null` when the blob
  /// is missing the access/refresh token pair that makes an account usable.
  static GoogleCredentials? fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      return null;
    }
    return GoogleCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      accountEmail: json['accountEmail'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
    );
  }

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

  /// The JSON form persisted as a single secure-storage blob.
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'accountEmail': accountEmail,
        'scope': scope,
      };
}

/// Reads / writes / clears Google OAuth tokens in [SecureStore],
/// keyed **per connected account** so a workspace can hold several Google
/// accounts at once, each with its own tokens.
///
/// All fields are stored as a single JSON blob under one key per account
/// (`google_credentials__<accountId>`). One keychain item per account means
/// macOS asks for keychain access at most **once per account**, not once per
/// field. Account ids embed the workspace (`google:<workspaceId>:<email>`), so
/// a token written for one workspace's account is structurally unreadable from
/// another — the workspace-isolation invariant still holds.
class GoogleCredentialsRepository {
  /// Creates a [GoogleCredentialsRepository].
  GoogleCredentialsRepository(this._storage);

  final SecureStore _storage;

  /// Decrypted credentials cached for the process lifetime, keyed by
  /// `accountId`.
  ///
  /// The calendar layer reads a token on *every* outgoing API request (the auth
  /// interceptor) and the sync timer fires every few minutes, so an uncached
  /// path hits the keychain — a syscall + decrypt — on the hot path. Caching
  /// collapses that to a single keychain read per account per launch.
  ///
  /// This repository is the only reader/writer of Google tokens, so the cache
  /// cannot drift: [save] refreshes it and [clear] evicts it. Keeping a
  /// decrypted token in memory for the session mirrors how the GitHub token
  /// already lives in Riverpod state — the keychain guards data at rest, not
  /// within a running process.
  final Map<String, GoogleCredentials> _cache = {};

  String _key(String accountId) => '${googleCredentialsKey}__$accountId';

  /// Loads the credentials for [accountId], or `null` when no usable blob is
  /// stored (the account is not connected, or the blob is malformed).
  Future<GoogleCredentials?> load(String accountId) async {
    final cached = _cache[accountId];
    if (cached != null) {
      return cached;
    }
    final raw = await _storage.read(key: _key(accountId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final creds = _decode(raw);
    if (creds == null) {
      return null;
    }
    _cache[accountId] = creds;
    return creds;
  }

  /// Persists the full credential set for [accountId] as a single blob. The
  /// refresh path re-saves with a new access token + expiry via
  /// [GoogleCredentials.copyWithAccessToken]; there is no field-level write.
  Future<void> save(String accountId, GoogleCredentials creds) async {
    await _storage.write(
      key: _key(accountId),
      value: jsonEncode(creds.toJson()),
    );
    _cache[accountId] = creds;
  }

  /// Deletes the credential blob for [accountId] (disconnect).
  Future<void> clear(String accountId) async {
    await _storage.delete(key: _key(accountId));
    _cache.remove(accountId);
  }

  /// Parses a stored blob, returning `null` for malformed JSON or a credential
  /// set missing its tokens. Never throws — a bad blob just means "not
  /// connected" so the account surfaces as needing reconnect rather than
  /// crashing the auth path.
  GoogleCredentials? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return GoogleCredentials.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }
}
