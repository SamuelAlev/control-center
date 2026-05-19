import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/mcp/domain/services/conversation_mode_tool_guard.dart';
import 'package:cc_mcp/src/mcp_http_server.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_client_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_config_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_tools_provider.dart';
import 'package:control_center/features/sandboxing/data/adapters/confirmation_port_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that tracks whether the MCP HTTP server is currently running.
final mcpServerRunningProvider =
    NotifierProvider<McpServerRunningNotifier, bool>(
      McpServerRunningNotifier.new,
    );

/// Notifier that toggles and reports the MCP server running state.
class McpServerRunningNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.keepAlive();
    return false;
  }

  /// Updates the running state to [value].
  // ignore: avoid_positional_boolean_parameters
  void setRunning(bool value) {
    state = value;
  }
}

/// Builds the single shared [McpToolDispatcher] used by every RPC surface —
/// the MCP HTTP server and the remote-control WebRTC transport. One
/// dispatcher instance means one tool registry, one confirmation port, and one
/// conversation-mode guard regardless of how a request arrives.
final mcpToolDispatcherProvider = Provider<McpToolDispatcher>((ref) {
  final registry = ref.watch(mcpToolRegistryProvider);
  final modeGuard = ConversationModeToolGuard(
    ref.read(conversationModeResolverProvider),
    // Server-side dispatcher — owns the DB directly via dao*, never the RPC
    // path (this provider is in the rpcClient graph; routing it over RPC would
    // cycle).
    runLogs: ref.read(daoAgentRunLogRepositoryProvider),
  );
  // ConfirmationPort is overridden in the widget tree; read it lazily and
  // tolerate it not being available (e.g. in tests / headless server boot).
  ConfirmationPort? confirmationPort;
  try {
    confirmationPort = ref.read(confirmationPortProvider);
  } catch (_) {
    confirmationPort = null;
  }
  // PRD 01: external servers' resources/prompts surface through CC's own MCP
  // server. This dispatcher backs the kept-for-reference in-process host; the
  // LIVE approval posture is owned server-side by the spawned cc_server's
  // `ServerMcpClientControl` (steered over the `mcp.client.*` ops), so this
  // reference dispatcher just keeps the safe `always-ask` default.
  final mcpClient = ref.watch(mcpClientServiceProvider);
  return McpToolDispatcher(
    registry: registry,
    modeGuard: modeGuard,
    confirmationPort: confirmationPort,
    resourceProvider: mcpClient.resourceProvider,
    promptProvider: mcpClient.promptProvider,
  );
});

/// Riverpod provider that builds and manages the lifecycle of the [McpHttpServer].
final mcpServerProvider = Provider<McpHttpServer>((ref) {
  ref.keepAlive();
  final configNotifier = ref.read(mcpConfigProvider.notifier);
  final baseConfig = ref.read(mcpConfigProvider);
  final dispatcher = ref.watch(mcpToolDispatcherProvider);
  final runningNotifier = ref.read(mcpServerRunningProvider.notifier);
  final server = McpHttpServer(
    config: baseConfig,
    dispatcher: dispatcher,
    onRunningChanged: ({required running}) =>
        runningNotifier.setRunning(running),
  );
  ref.onDispose(() {
    server.onRunningChanged = null;
    server.stop();
  });
  if (baseConfig.enabled) {
    Future.microtask(() async {
      try {
        AppLog.i('MCP', 'Starting server on port ${baseConfig.port}...');
        final fullConfig = await configNotifier.loadFullConfig();
        server.updateConfig(fullConfig);
        await server.start();
        AppLog.i(
          'MCP',
          'Server started successfully on port ${baseConfig.port}',
        );
      } catch (e, st) {
        AppLog.e('MCP', 'Failed to start MCP server: $e', e, st);
      }
    });
  } else {
    AppLog.i('MCP', 'Server disabled in config');
  }
  return server;
});
