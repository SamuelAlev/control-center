import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Turns raw identifiers into stable pseudonyms for analytics.
///
/// HMAC-SHA256 keyed by the install's pseudonym salt, truncated to 80 bits
/// (20 hex characters): collision-free at any realistic entity count, the
/// same on every surface of an install, and unlinkable to the raw ID without
/// the salt, which stays on the install and its authenticated clients.
class AnalyticsPseudonymizer {
  /// Creates a pseudonymizer keyed by [salt].
  AnalyticsPseudonymizer(String salt) : _hmac = Hmac(sha256, utf8.encode(salt));

  final Hmac _hmac;
  final _cache = <String, String>{};

  /// The pseudonym for [raw].
  String pseudonym(String raw) {
    final cached = _cache[raw];
    if (cached != null) {
      return cached;
    }
    // Bounded: IDs are few per session, but a long-lived server sees many.
    if (_cache.length > 4096) {
      _cache.clear();
    }
    return _cache[raw] = _hmac
        .convert(utf8.encode(raw))
        .toString()
        .substring(0, 20);
  }
}
