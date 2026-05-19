import 'dart:convert';
import 'dart:io';

/// A persisted OAuth token bundle for one MCP server, plus the material needed
/// to refresh it without re-running the whole flow.
class McpOAuthToken {
  /// Creates an [McpOAuthToken].
  const McpOAuthToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tokenType = 'Bearer',
    this.scope,
    this.tokenUrl,
    this.clientId,
    this.clientSecret,
    this.authorizationServer,
  });

  /// Reconstructs from a JSON map.
  factory McpOAuthToken.fromJson(Map<String, dynamic> json) => McpOAuthToken(
    accessToken: json['access_token'] as String? ?? '',
    refreshToken: json['refresh_token'] as String?,
    expiresAt: json['expires_at'] is num
        ? DateTime.fromMillisecondsSinceEpoch((json['expires_at'] as num).toInt())
        : null,
    tokenType: json['token_type'] as String? ?? 'Bearer',
    scope: json['scope'] as String?,
    tokenUrl: json['token_url'] as String?,
    clientId: json['client_id'] as String?,
    clientSecret: json['client_secret'] as String?,
    authorizationServer: json['authorization_server'] as String?,
  );

  /// The bearer access token.
  final String accessToken;

  /// The refresh token, when the server issued one.
  final String? refreshToken;

  /// Absolute expiry time, when known.
  final DateTime? expiresAt;

  /// Token type (almost always `Bearer`).
  final String tokenType;

  /// Granted scopes (space-delimited), when echoed by the server.
  final String? scope;

  /// The token endpoint, persisted so a refresh needs no re-discovery.
  final String? tokenUrl;

  /// The (possibly dynamically-registered) client id, persisted for refresh.
  final String? clientId;

  /// The client secret, when the server issued a confidential client.
  final String? clientSecret;

  /// The authorization server origin, persisted for same-origin resource
  /// filtering on refresh.
  final String? authorizationServer;

  /// True when [expiresAt] is within [buffer] of now (or already past). A null
  /// expiry is treated as non-expiring.
  bool isExpired({Duration buffer = const Duration(minutes: 5)}) {
    final exp = expiresAt;
    if (exp == null) {
      return false;
    }
    return DateTime.now().add(buffer).isAfter(exp);
  }

  /// The `Authorization` header value for this token.
  String get authorizationHeader => '$tokenType $accessToken';

  /// Serialises to a JSON map.
  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    if (refreshToken != null) 'refresh_token': refreshToken,
    if (expiresAt != null) 'expires_at': expiresAt!.millisecondsSinceEpoch,
    'token_type': tokenType,
    if (scope != null) 'scope': scope,
    if (tokenUrl != null) 'token_url': tokenUrl,
    if (clientId != null) 'client_id': clientId,
    if (clientSecret != null) 'client_secret': clientSecret,
    if (authorizationServer != null)
      'authorization_server': authorizationServer,
  };

  /// Returns a copy with the access/refresh material replaced (used after a
  /// refresh, which keeps the registration material).
  McpOAuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? scope,
  }) => McpOAuthToken(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    tokenType: tokenType,
    scope: scope ?? this.scope,
    tokenUrl: tokenUrl,
    clientId: clientId,
    clientSecret: clientSecret,
    authorizationServer: authorizationServer,
  );
}

/// Persists OAuth tokens per MCP server, keyed by the server origin/url.
///
/// The desktop wires a `flutter_secure_storage`-backed implementation (tokens
/// are secrets); the headless server can use a file/in-memory one. This package
/// only ships [InMemoryOAuthTokenStore] for tests and headless defaults.
abstract interface class McpOAuthTokenStore {
  /// Reads the token for [serverKey], or null if none is stored.
  Future<McpOAuthToken?> read(String serverKey);

  /// Stores [token] for [serverKey].
  Future<void> write(String serverKey, McpOAuthToken token);

  /// Deletes any token for [serverKey].
  Future<void> delete(String serverKey);
}

/// A non-persistent token store (tests, headless defaults).
class InMemoryOAuthTokenStore implements McpOAuthTokenStore {
  final _tokens = <String, McpOAuthToken>{};

  @override
  Future<McpOAuthToken?> read(String serverKey) async => _tokens[serverKey];

  @override
  Future<void> write(String serverKey, McpOAuthToken token) async {
    _tokens[serverKey] = token;
  }

  @override
  Future<void> delete(String serverKey) async {
    _tokens.remove(serverKey);
  }
}

/// A JSON-file-backed token store for the Flutter-free headless server, which
/// has no keychain (`flutter_secure_storage` needs a Flutter engine). The file
/// holds all servers' tokens keyed by origin; reads/writes are whole-file.
class FileOAuthTokenStore implements McpOAuthTokenStore {
  /// Creates a [FileOAuthTokenStore] writing to [filePath].
  FileOAuthTokenStore(this.filePath);

  /// Path to the JSON file backing the store.
  final String filePath;

  Future<Map<String, dynamic>> _readAll() async {
    try {
      final raw = await File(filePath).readAsString();
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on Object {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> all) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(all));
  }

  @override
  Future<McpOAuthToken?> read(String serverKey) async {
    final all = await _readAll();
    final entry = all[serverKey];
    if (entry is! Map) {
      return null;
    }
    return McpOAuthToken.fromJson(entry.cast<String, dynamic>());
  }

  @override
  Future<void> write(String serverKey, McpOAuthToken token) async {
    final all = await _readAll()..[serverKey] = token.toJson();
    await _writeAll(all);
  }

  @override
  Future<void> delete(String serverKey) async {
    final all = await _readAll()..remove(serverKey);
    await _writeAll(all);
  }
}
