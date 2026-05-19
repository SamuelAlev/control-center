import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp_client/src/config/mcp_client_models.dart';

/// Invokes a remote tool on a named server and returns the raw MCP
/// `tools/call` result (`{content: [...], isError?}`). Supplied by the
/// `ConnectionManager`, which owns reconnect-and-retry.
typedef RemoteToolInvoker =
    Future<Map<String, dynamic>> Function(
      String serverName,
      String toolName,
      Map<String, dynamic> arguments,
    );

/// Decides the [ToolApproval] tier for a bridged tool call, given the server,
/// the remote tool, and the parsed arguments. Lets the host classify external
/// tools (e.g. read-only `*_get`/`*_list`/`*_search` patterns) instead of
/// treating every external tool as `exec`.
typedef BridgedTierResolver =
    ToolApproval Function(
      String serverName,
      McpRemoteTool tool,
      Map<String, dynamic> arguments,
    );

/// Adapts a remote MCP tool into CC's local [McpTool] surface so it is served
/// to agents through CC's own MCP server alongside the native tools — agents
/// never dial the external server directly.
///
/// The tool is namespaced `mcp__<server>__<tool>` (sanitised to the
/// `^[a-zA-Z0-9_-]{1,64}$` shape model providers require) so two servers can
/// expose a tool of the same name without colliding.
class BridgedMcpTool extends McpTool {
  /// Creates a [BridgedMcpTool].
  BridgedMcpTool({
    required this.serverName,
    required this.remoteTool,
    required RemoteToolInvoker invoker,
    BridgedTierResolver? tierResolver,
  }) : _invoker = invoker,
       _tierResolver = tierResolver,
       name = bridgedName(serverName, remoteTool.name);

  final RemoteToolInvoker _invoker;
  final BridgedTierResolver? _tierResolver;

  /// The server this tool belongs to.
  final String serverName;

  /// The remote tool definition.
  final McpRemoteTool remoteTool;

  @override
  final String name;

  @override
  String get description {
    final base = remoteTool.description.trim();
    final prefix = '[$serverName] ';
    return base.isEmpty ? '${prefix}external MCP tool' : '$prefix$base';
  }

  @override
  Map<String, dynamic> get inputSchema => remoteTool.inputSchema;

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) {
    final resolver = _tierResolver;
    if (resolver != null) {
      return resolver(serverName, remoteTool, arguments);
    }
    // External tools are untrusted by default: assume the most dangerous tier
    // so they prompt unless the user has relaxed the approval mode.
    return ToolApproval.exec;
  }

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(
        title: 'Run external tool ${remoteTool.name}',
        detail:
            'Server "$serverName" · ${remoteTool.name}\n'
            '${_summariseArgs(arguments)}',
        isDestructive:
            toolApproval(arguments).tier == CapabilityTier.exec,
      );

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final raw = await _invoker(serverName, remoteTool.name, arguments);
    return _resultFromRemote(raw);
  }

  /// Converts a remote `tools/call` result into a CC [CallResult].
  static CallResult _resultFromRemote(Map<String, dynamic> raw) {
    final isError = raw['isError'] == true;
    final content = raw['content'];
    final buffer = StringBuffer();
    if (content is List) {
      for (final block in content) {
        if (block is Map) {
          final type = block['type'];
          if (type == 'text') {
            buffer.writeln(block['text']?.toString() ?? '');
          } else if (type == 'resource') {
            final resource = block['resource'];
            if (resource is Map && resource['text'] != null) {
              buffer.writeln(resource['text'].toString());
            } else {
              buffer.writeln(jsonEncode(block));
            }
          } else {
            // image / audio / unknown — preserve the structured block.
            buffer.writeln(jsonEncode(block));
          }
        }
      }
    }
    final text = buffer.toString().trimRight();
    return isError
        ? CallResult.error(text.isEmpty ? 'remote tool error' : text)
        : CallResult.success(text);
  }

  static String _summariseArgs(Map<String, dynamic> arguments) {
    if (arguments.isEmpty) {
      return 'No arguments.';
    }
    final encoded = jsonEncode(arguments);
    return encoded.length <= 400
        ? 'Arguments: $encoded'
        : 'Arguments: ${encoded.substring(0, 400)}…';
  }

  /// The `mcp__<server>__<tool>` namespaced name a remote tool is exposed under.
  static String bridgedName(String server, String tool) {
    final s = _sanitize(server);
    final t = _sanitize(tool);
    var combined = 'mcp__${s}__$t';
    if (combined.length > 64) {
      // Keep the head and tail so the name stays legible + unique.
      combined = combined.substring(0, 64);
    }
    return combined;
  }

  /// Whether [name] looks like a bridged external tool.
  static bool isBridgedName(String name) => name.startsWith('mcp__');

  static String _sanitize(String raw) =>
      raw.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
}
