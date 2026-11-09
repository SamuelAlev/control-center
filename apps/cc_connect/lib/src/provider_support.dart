import 'dart:convert';

import 'package:cc_connect/src/secrets.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// The provider refused Connect's client credentials. Retried once with the
/// previous secret generation, then answered `provider_unavailable`.
final class InvalidClientCredentials implements Exception {
  /// Creates the signal.
  const InvalidClientCredentials();
}

/// The provider says the grant (code or refresh token) is gone. A refresh
/// maps it to `needs_sign_in`; a claim to `access_denied`.
final class GrantRejected implements Exception {
  /// Creates the signal.
  const GrantRejected([this.reason = '']);

  /// The provider's error, as a log slug ([logSlug]).
  final String reason;
}

/// [parts] joined into one value the log keeps: anything outside
/// `[A-Za-z0-9_.:/-]` becomes `_`, at most 80 characters. For provider error
/// codes and descriptions, which carry no secret.
String logSlug(Iterable<Object?> parts) {
  final joined = [
    for (final part in parts)
      if (part is String && part.isNotEmpty) part,
  ].join(':').replaceAll(RegExp(r'[^A-Za-z0-9_.:/\-]+'), '_');
  return joined.length <= 80 ? joined : joined.substring(0, 80);
}

/// Calls [call] with the current secret and, on [InvalidClientCredentials],
/// once more with the previous one. [call] receives the secret and its
/// generation number. A lane whose secret is unreadable is unavailable.
Future<T> withDualSecret<T>(
  DualSecret secret,
  Future<T> Function(String secret, int generation) call,
) async {
  final current = secret.currentValue;
  if (current.isEmpty) {
    throw const ConnectException(ConnectErrorCode.providerUnavailable);
  }
  try {
    return await call(current, secret.generation);
  } on InvalidClientCredentials {
    final previous = secret.previousValue;
    if (previous == null) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    try {
      return await call(previous, secret.previousGeneration);
    } on InvalidClientCredentials {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
  }
}

/// Sends [request], turning transport failures and transient statuses into
/// `provider_unavailable`.
Future<UpstreamResponse> sendUpstream(
  UpstreamHttp http,
  UpstreamRequest request,
) async {
  final UpstreamResponse response;
  try {
    response = await http.send(request);
  } on UpstreamUnavailable {
    throw const ConnectException(ConnectErrorCode.providerUnavailable);
  }
  if (response.isTransient) {
    throw const ConnectException(ConnectErrorCode.providerUnavailable);
  }
  return response;
}

/// The claims of a JWT received directly from the provider's token endpoint
/// over TLS (OIDC Core §3.1.3.7: TLS server validation stands in for the
/// signature check). Null when it is not a JWT.
Map<String, Object?>? jwtClaims(String? token) {
  if (token == null) {
    return null;
  }
  final parts = token.split('.');
  if (parts.length != 3) {
    return null;
  }
  try {
    final decoded = jsonDecode(utf8.decode(unb64url(parts[1])));
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Whether [claims] has an `aud` equal to (or containing) [clientId] and,
/// when `azp` is present, `azp` also equals [clientId].
bool jwtAudienceIs(Map<String, Object?> claims, String clientId) {
  final azp = claims['azp'];
  if (azp != null && azp != clientId) {
    return false;
  }
  final aud = claims['aud'];
  if (aud is String) {
    return aud == clientId;
  }
  return aud is List && aud.length == 1 && aud.single == clientId;
}

/// Whether [claims] has not expired at [now] (a missing `exp` is expired).
bool jwtUnexpired(Map<String, Object?> claims, DateTime now) {
  final exp = claims['exp'];
  return exp is int &&
      DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).isAfter(now);
}

/// An integer field that providers sometimes send as a string.
int? intField(Object? value) =>
    value is int ? value : (value is String ? int.tryParse(value) : null);
