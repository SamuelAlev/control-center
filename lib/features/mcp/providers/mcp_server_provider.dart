import 'package:control_center/core/domain/ports/confirmation_port.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/mcp/data/services/mcp_http_server.dart';
import 'package:control_center/features/mcp/data/services/mcp_tool_dispatcher.dart';
import 'package:control_center/features/mcp/domain/services/conversation_mode_tool_guard.dart';
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

/// Riverpod provider that builds and manages the lifecycle of the [McpHttpServer].
final mcpServerProvider = Provider<McpHttpServer>((ref) {
  ref.keepAlive();
  final configNotifier = ref.read(mcpConfigProvider.notifier);
  final baseConfig = ref.read(mcpConfigProvider);
  final registry = ref.watch(mcpToolRegistryProvider);
  final modeGuard = ConversationModeToolGuard(
    ref.read(conversationModeResolverProvider),
    runLogs: ref.read(agentRunLogRepositoryProvider),
  );
  // ConfirmationPort is overridden in the widget tree; read it lazily and
  // tolerate it not being available (e.g. in tests / headless server boot).
  ConfirmationPort? confirmationPort;
  try {
    confirmationPort = ref.read(confirmationPortProvider);
  } catch (_) {
    confirmationPort = null;
  }
  final dispatcher = McpToolDispatcher(
    registry: registry,
    modeGuard: modeGuard,
    confirmationPort: confirmationPort,
  );
  final runningNotifier = ref.read(mcpServerRunningProvider.notifier);
  final server = McpHttpServer(
    config: baseConfig,
    dispatcher: dispatcher,
    onRunningChanged: ({required running}) => runningNotifier.setRunning(running),
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
        AppLog.i('MCP', 'Server started successfully on port ${baseConfig.port}');
      } catch (e, st) {
        AppLog.e('MCP', 'Failed to start MCP server: $e', e, st);
      }
    });
  } else {
    AppLog.i('MCP', 'Server disabled in config');
  }
  return server;
});
