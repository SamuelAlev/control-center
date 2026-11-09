import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';

/// One stored provider credential, with everything a refresh needs beside it.
///
/// Two shapes share this type:
///
/// * **Own app** (`source: oauth`): the server ran the OAuth exchange with its
///   own client credentials and holds the access + refresh tokens itself.
/// * **Connect** (`source: connect`): the refresh credential exists only as a
///   KMS-sealed [seal] bound to this server's install id. The access token is
///   short-lived and lives in process memory only — [encode] never writes
///   it, so a copied secrets file or backup carries nothing usable without
///   this server's identity and the Connect that sealed it.
///
/// Persisted as a JSON string because the server's secrets file is a flat
/// `String → String` map.
class ProviderToken {
  /// Creates a [ProviderToken].
  const ProviderToken({
    this.accessToken = '',
    this.refreshToken = '',
    this.expiresAt,
    this.refreshExpiresAt,
    this.source = ForgeCredentialSource.settings,
    this.accountLogin = '',
    this.accountId = '',
    this.seal = '',
    this.sealInstallId = '',
    this.connectOrigin = '',
    this.appId = '',
    this.issuedAt,
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
      final seal = decoded['seal'];
      final hasSeal = seal is String && seal.isNotEmpty;
      final hasAccess = access is String && access.isNotEmpty;
      if (!hasSeal && !hasAccess) {
        return null;
      }
      String text(String key) {
        final value = decoded[key];
        return value is String ? value : '';
      }

      return ProviderToken(
        accessToken: hasSeal ? '' : access! as String,
        refreshToken: hasSeal ? '' : text('refresh'),
        expiresAt: hasSeal ? null : _parseTime(decoded['expires_at']),
        refreshExpiresAt: _parseTime(decoded['refresh_expires_at']),
        source: ForgeCredentialSource.fromWire(decoded['source'] as String?),
        accountLogin: text('account'),
        accountId: text('account_id'),
        seal: hasSeal ? seal : '',
        sealInstallId: text('seal_install_id'),
        connectOrigin: text('connect_origin'),
        appId: text('app_id'),
        issuedAt: _parseTime(decoded['issued_at']),
      );
    } on Object {
      return null;
    }
  }

  static DateTime? _parseTime(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  /// The bearer credential itself. Empty for a sealed credential whose
  /// access token has not been minted in this process yet.
  final String accessToken;

  /// The refresh credential (own-app only), or empty.
  final String refreshToken;

  /// When [accessToken] stops working, or null when it does not expire.
  final DateTime? expiresAt;

  /// When the refresh credential itself stops working, or null.
  final DateTime? refreshExpiresAt;

  /// How this credential was obtained.
  final ForgeCredentialSource source;

  /// The account name behind the token, when known.
  final String accountLogin;

  /// The provider's immutable account id (GitHub numeric id, Google `sub`).
  /// Matching people across events always uses this, never [accountLogin].
  final String accountId;

  /// The Connect seal, or empty for an own-app credential.
  final String seal;

  /// The install id the seal is bound to. A seal whose install id is not
  /// this server's current one (a restored backup on another machine, a
  /// rotated key) is unusable and reads as "sign in again".
  final String sealInstallId;

  /// The canonical base URL of the Connect that sealed it.
  final String connectOrigin;

  /// The provider app the grant belongs to.
  final String appId;

  /// When this server last obtained the grant (sign-in or refresh), so a
  /// refresh token can be renewed before it idles out. Null when unknown.
  final DateTime? issuedAt;

  /// Whether this is a Connect-sealed credential.
  bool get isSealed => seal.isNotEmpty;

  /// True when [accessToken] is missing, or at (or within a minute of) its
  /// expiry.
  ///
  /// The minute of slack is deliberate: a token that expires mid-flight fails
  /// the request it was attached to, and the caller has no way to distinguish
  /// that from a revoked credential.
  bool get isExpired {
    if (accessToken.isEmpty) {
      return true;
    }
    final at = expiresAt;
    return at != null &&
        !at.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 1)));
  }

  /// True when a refresh could still succeed.
  bool get canRefresh {
    if (isSealed) {
      return true;
    }
    if (refreshToken.isEmpty) {
      return false;
    }
    final at = refreshExpiresAt;
    return at == null || at.isAfter(DateTime.now().toUtc());
  }

  /// A copy with [accountLogin] replaced.
  ProviderToken withAccount(String login) => copyWith(accountLogin: login);

  /// A copy with the given fields replaced.
  ProviderToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    DateTime? refreshExpiresAt,
    ForgeCredentialSource? source,
    String? accountLogin,
    String? accountId,
    String? seal,
    String? sealInstallId,
    String? connectOrigin,
    String? appId,
    DateTime? issuedAt,
  }) => ProviderToken(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    source: source ?? this.source,
    accountLogin: accountLogin ?? this.accountLogin,
    accountId: accountId ?? this.accountId,
    seal: seal ?? this.seal,
    sealInstallId: sealInstallId ?? this.sealInstallId,
    connectOrigin: connectOrigin ?? this.connectOrigin,
    appId: appId ?? this.appId,
    issuedAt: issuedAt ?? this.issuedAt,
  );

  /// The stored form. A sealed credential stores no access token.
  String encode() => jsonEncode({
    if (!isSealed) 'access': accessToken,
    if (!isSealed && refreshToken.isNotEmpty) 'refresh': refreshToken,
    if (!isSealed && expiresAt != null)
      'expires_at': expiresAt!.toUtc().toIso8601String(),
    if (refreshExpiresAt != null)
      'refresh_expires_at': refreshExpiresAt!.toUtc().toIso8601String(),
    'source': source.wire,
    if (accountLogin.isNotEmpty) 'account': accountLogin,
    if (accountId.isNotEmpty) 'account_id': accountId,
    if (isSealed) 'seal': seal,
    if (sealInstallId.isNotEmpty) 'seal_install_id': sealInstallId,
    if (connectOrigin.isNotEmpty) 'connect_origin': connectOrigin,
    if (appId.isNotEmpty) 'app_id': appId,
    if (issuedAt != null) 'issued_at': issuedAt!.toUtc().toIso8601String(),
  });
}

/// What a refresh attempt produced.
///
/// Only [RefreshRejected] — the provider said the grant is gone
/// (`invalid_grant`, `needs_sign_in`) — may clear a stored credential. A
/// network blip, a provider outage, a rotated client secret mid-propagation
/// or Connect being down is [RefreshUnavailable]: the credential stays and
/// the next call tries again, so nobody is signed out by a transient failure.
sealed class RefreshOutcome {
  const RefreshOutcome();
}

/// The credential was renewed.
final class Refreshed extends RefreshOutcome {
  /// Creates the outcome.
  const Refreshed(this.token);

  /// The renewed credential (access token included, for memory).
  final ProviderToken token;
}

/// The provider refused the grant; sign in again.
final class RefreshRejected extends RefreshOutcome {
  /// Creates the outcome.
  const RefreshRejected();
}

/// Could not refresh right now; keep the credential.
final class RefreshUnavailable extends RefreshOutcome {
  /// Creates the outcome.
  const RefreshUnavailable();
}
