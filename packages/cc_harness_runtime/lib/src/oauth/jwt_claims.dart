import 'dart:convert';

/// Decodes a JWT's payload claims **without verifying the signature**.
///
/// Only ever used to read the identity a provider self-reports about a token it
/// just issued us over TLS (email, account id) so the UI can name the connected
/// account. Nothing is authorized on the strength of these claims — the token
/// itself is the credential and the provider validates it — so there is no
/// signature to check here. Returns an empty map for anything unparseable.
Map<String, dynamic> decodeJwtClaims(String? token) {
  if (token == null) {
    return const {};
  }
  final parts = token.split('.');
  if (parts.length < 2) {
    return const {};
  }
  try {
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final json = jsonDecode(decoded);
    return json is Map<String, dynamic> ? json : const {};
  } on Object {
    return const {};
  }
}

/// The first non-empty string among [keys] in [claims].
///
/// Providers disagree on which claim carries a human-readable identity, so a
/// caller lists the spellings it accepts in preference order and takes whatever
/// is actually present.
String? firstClaim(Map<String, dynamic> claims, List<String> keys) {
  for (final key in keys) {
    final value = claims[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
