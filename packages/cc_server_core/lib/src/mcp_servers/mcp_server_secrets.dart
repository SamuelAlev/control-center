import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';

/// The environment and header values of configured MCP servers, kept in the
/// server's owner-only secrets store and never in a database row.
///
/// Slots are `mcp_server:<scope>:<id>:<env|header>:<name>`, with the scope
/// `personal` or `ws:<workspaceId>`. `:` appears in no id, environment
/// variable or header name, so one scope's prefix never matches another's.
/// Header names are compared without case, so their slot uses the lower-cased
/// name.
class McpServerSecrets {
  /// Creates the store over [_secrets].
  McpServerSecrets(this._secrets);

  final SecretStorePort _secrets;

  static const _prefix = 'mcp_server:';

  static String _scope(String? workspaceId) =>
      workspaceId == null ? 'personal' : 'ws:$workspaceId';

  static String _serverPrefix(String? workspaceId, String id) =>
      '$_prefix${_scope(workspaceId)}:$id:';

  static String _envKey(String? workspaceId, String id, String name) =>
      '${_serverPrefix(workspaceId, id)}env:$name';

  static String _headerKey(String? workspaceId, String id, String name) =>
      '${_serverPrefix(workspaceId, id)}header:${name.toLowerCase()}';

  /// Applies [draft]'s values to [saved], the definition as just stored.
  /// [previous] is what it replaced: a change of transport drops every value
  /// it had, and names [saved] no longer carries are deleted.
  Future<void> apply({
    required McpServerDefinition saved,
    required McpServerDefinition? previous,
    required McpServerDraft draft,
  }) async {
    final ws = saved.workspaceId;
    final id = saved.id;
    if (previous != null) {
      final keptEnv = saved.envNames.toSet();
      for (final name in previous.envNames) {
        if (!keptEnv.contains(name)) {
          await _secrets.delete(_envKey(ws, id, name));
        }
      }
      final keptHeaders = {for (final h in saved.headerNames) h.toLowerCase()};
      for (final name in previous.headerNames) {
        if (!keptHeaders.contains(name.toLowerCase())) {
          await _secrets.delete(_headerKey(ws, id, name));
        }
      }
    }
    if (saved.transport.isRemote) {
      for (final entry in draft.headerSet.entries) {
        await _secrets.write(_headerKey(ws, id, entry.key), entry.value);
      }
    } else {
      for (final entry in draft.envSet.entries) {
        await _secrets.write(_envKey(ws, id, entry.key), entry.value);
      }
    }
  }

  /// Every value stored for [definition], by name. A name whose value is
  /// missing (a secrets file restored without it) reads as empty.
  Future<({Map<String, String> env, Map<String, String> headers})> resolve(
    McpServerDefinition definition,
  ) async {
    final ws = definition.workspaceId;
    final id = definition.id;
    return (
      env: {
        for (final name in definition.envNames)
          name: await _secrets.read(_envKey(ws, id, name)) ?? '',
      },
      headers: {
        for (final name in definition.headerNames)
          name: await _secrets.read(_headerKey(ws, id, name)) ?? '',
      },
    );
  }

  /// Deletes every value of server [id] in [workspaceId] (null: personal).
  Future<void> deleteServer(String? workspaceId, String id) {
    final prefix = _serverPrefix(workspaceId, id);
    return _secrets.deleteMatching((key) => key.startsWith(prefix));
  }

  /// Deletes every value of every server of [workspaceId].
  Future<int> deleteWorkspace(String workspaceId) {
    final prefix = '$_prefix${_scope(workspaceId)}:';
    return _secrets.deleteMatching((key) => key.startsWith(prefix));
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
