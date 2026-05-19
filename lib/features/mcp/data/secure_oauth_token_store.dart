import 'dart:convert';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// Persists MCP OAuth tokens in the platform keychain via [SecureStore].
///
/// Tokens are secrets (access + refresh material), so they live in the keychain
/// — never in app preferences. Keyed per server origin under an `mcp_oauth:`
/// prefix and validated against the server URL on read (the key IS the origin).
class SecureOAuthTokenStore implements McpOAuthTokenStore {
  /// Creates a [SecureOAuthTokenStore] over the given secure store.
  const SecureOAuthTokenStore(this._store);

  final SecureStore _store;

  static String _key(String serverKey) => 'mcp_oauth:$serverKey';

  @override
  Future<McpOAuthToken?> read(String serverKey) async {
    final raw = await _store.read(key: _key(serverKey));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return McpOAuthToken.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String serverKey, McpOAuthToken token) async {
    await _store.write(key: _key(serverKey), value: jsonEncode(token.toJson()));
  }

  @override
  Future<void> delete(String serverKey) async {
    await _store.delete(key: _key(serverKey));
  }
}
