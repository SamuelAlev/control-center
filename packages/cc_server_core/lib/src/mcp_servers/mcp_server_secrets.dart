import 'dart:convert';

import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';

/// The environment and header values of configured MCP servers, and their
/// browser sign-ins, kept in the server's owner-only secrets store and never
/// in a database row.
///
/// Value slots are `mcp_server:<scope>:<id>:<env|header>:<name>` and sign-in
/// slots `mcp_oauth:<scope>:<server origin>`, with the scope `ws:<workspaceId>`
/// for the workspace's servers or `wsu:<workspaceId>:<userId>` for one
/// member's own. `:` appears in no id, environment variable or header name,
/// so one scope's prefix never matches another's. Header names are compared
/// without case, so their slot uses the lower-cased name.
class McpServerSecrets {
  /// Creates the store over [_secrets].
  McpServerSecrets(this._secrets);

  final SecretStorePort _secrets;

  static const _prefix = 'mcp_server:';

  static const _oauthPrefix = 'mcp_oauth:';

  static String _scope(String workspaceId, String? userId) =>
      userId == null ? 'ws:$workspaceId' : 'wsu:$workspaceId:$userId';

  static String _serverPrefix(McpServerDefinition d) =>
      '$_prefix${_scope(d.workspaceId, d.userId)}:${d.id}:';

  static String _envKey(McpServerDefinition d, String name) =>
      '${_serverPrefix(d)}env:$name';

  static String _headerKey(McpServerDefinition d, String name) =>
      '${_serverPrefix(d)}header:${name.toLowerCase()}';

  /// The sign-ins of one audience: the workspace's servers ([userId] null)
  /// or one member's own. Each audience has its own, so a member's sign-in
  /// is never sent on the workspace's connection to the same origin.
  McpOAuthTokenStore tokenStore(String workspaceId, String? userId) =>
      _SecretsOAuthTokenStore(
        _secrets,
        '$_oauthPrefix${_scope(workspaceId, userId)}:',
      );

  /// Deletes what the releases before per-member servers kept: the server
  /// owner's personal values. Their definitions and sign-ins were files.
  Future<int> deleteLegacyPersonal() =>
      _secrets.deleteMatching((key) => key.startsWith('${_prefix}personal:'));

  /// Applies [draft]'s values to [saved], the definition as just stored.
  /// [previous] is what it replaced: a change of transport drops every value
  /// it had, and names [saved] no longer carries are deleted.
  Future<void> apply({
    required McpServerDefinition saved,
    required McpServerDefinition? previous,
    required McpServerDraft draft,
  }) async {
    if (previous != null) {
      final keptEnv = saved.envNames.toSet();
      for (final name in previous.envNames) {
        if (!keptEnv.contains(name)) {
          await _secrets.delete(_envKey(saved, name));
        }
      }
      final keptHeaders = {for (final h in saved.headerNames) h.toLowerCase()};
      for (final name in previous.headerNames) {
        if (!keptHeaders.contains(name.toLowerCase())) {
          await _secrets.delete(_headerKey(saved, name));
        }
      }
    }
    if (saved.transport.isRemote) {
      for (final entry in draft.headerSet.entries) {
        await _secrets.write(_headerKey(saved, entry.key), entry.value);
      }
    } else {
      for (final entry in draft.envSet.entries) {
        await _secrets.write(_envKey(saved, entry.key), entry.value);
      }
    }
  }

  /// Every value stored for [definition], by name. A name whose value is
  /// missing (a secrets file restored without it) reads as empty.
  Future<({Map<String, String> env, Map<String, String> headers})> resolve(
    McpServerDefinition definition,
  ) async {
    return (
      env: {
        for (final name in definition.envNames)
          name: await _secrets.read(_envKey(definition, name)) ?? '',
      },
      headers: {
        for (final name in definition.headerNames)
          name: await _secrets.read(_headerKey(definition, name)) ?? '',
      },
    );
  }

  /// Deletes every value of [definition].
  Future<void> deleteServer(McpServerDefinition definition) {
    final prefix = _serverPrefix(definition);
    return _secrets.deleteMatching((key) => key.startsWith(prefix));
  }

  /// Deletes every value and sign-in of every server of [workspaceId], the
  /// workspace's and its members' own.
  Future<int> deleteWorkspace(String workspaceId) {
    final prefixes = [
      for (final kind in const [_prefix, _oauthPrefix]) ...[
        '${kind}ws:$workspaceId:',
        '${kind}wsu:$workspaceId:',
      ],
    ];
    return _secrets.deleteMatching((key) => prefixes.any(key.startsWith));
  }

  /// The connection config of [definition] with its stored values.
  /// [publicOnly] confines an http/sse server to public addresses.
  Future<McpServerConfig> configFor(
    McpServerDefinition definition, {
    required String source,
    bool publicOnly = false,
  }) async {
    final values = await resolve(definition);
    return switch (definition.transport) {
      McpServerTransport.stdio => McpServerConfig.stdio(
        name: definition.name,
        command: definition.command!,
        args: definition.args,
        env: values.env,
        enabled: definition.enabled,
        source: source,
      ),
      McpServerTransport.http => McpServerConfig.http(
        name: definition.name,
        url: definition.url!,
        headers: values.headers,
        enabled: definition.enabled,
        source: source,
      ).copyWith(publicOnly: publicOnly),
      McpServerTransport.sse => McpServerConfig.sse(
        name: definition.name,
        url: definition.url!,
        headers: values.headers,
        enabled: definition.enabled,
        source: source,
      ).copyWith(publicOnly: publicOnly),
    };
  }
}

/// [McpOAuthTokenStore] over the secrets store, under one audience's prefix.
class _SecretsOAuthTokenStore implements McpOAuthTokenStore {
  _SecretsOAuthTokenStore(this._secrets, this._prefix);

  final SecretStorePort _secrets;
  final String _prefix;

  @override
  Future<McpOAuthToken?> read(String serverKey) async {
    final raw = await _secrets.read('$_prefix$serverKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? McpOAuthToken.fromJson(decoded.cast<String, dynamic>())
          : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String serverKey, McpOAuthToken token) =>
      _secrets.write('$_prefix$serverKey', jsonEncode(token.toJson()));

  @override
  Future<void> delete(String serverKey) =>
      _secrets.delete('$_prefix$serverKey');
}
