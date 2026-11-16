import 'dart:async';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_external_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_actions.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One of the server owner's personal MCP servers: discovered from a tool's
/// config, or added by hand in Control Center. Only a hand-added one opens
/// the editor and can be removed; a discovered one belongs to its tool.
class ExternalMcpServerRow extends ConsumerWidget {
  /// Creates the row for [server].
  const ExternalMcpServerRow({super.key, required this.server});

  /// The server and its live state.
  final McpExternalServerInfo server;

  void _refresh(WidgetRef ref) => ref.invalidate(mcpExternalServersProvider);

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(McpClientControl control) action, {
    String? success,
  }) => runMcpServerAction(
    context,
    action: () => action(ref.read(mcpClientControlProvider)),
    refresh: () => _refresh(ref),
    success: success,
  );

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    McpServerDefinition definition,
  ) async {
    final control = ref.read(mcpClientControlProvider);
    final saved = await showMcpServerEditor(
      context,
      scope: McpServerEditorScope.personal,
      existing: definition,
      onSave: control.saveServer,
    );
    if (saved) {
      _refresh(ref);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    McpServerDefinition definition,
  ) async {
    if (await confirmRemoveMcpServer(context, definition) && context.mounted) {
      await _act(context, ref, (c) => c.deleteServer(definition.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = mcpLifecycleState(l10n, server.lifecycle);
    final definition = server.definition;
    final handAdded =
        definition != null ||
        server.source == McpExternalServerInfo.handAddedSource;
    final Widget? action;
    if (server.usesOAuth && server.needsAuth) {
      action = CcButton(
        variant: CcButtonVariant.accent,
        size: CcButtonSize.sm,
        onPressed: () => unawaited(
          _act(
            context,
            ref,
            (c) => c.authorize(server.name),
            success: l10n.success,
          ),
        ),
        child: Text(l10n.mcpAuthorize),
      );
    } else if (mcpLifecycleCanReconnect(server.lifecycle)) {
      action = CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        onPressed: () => unawaited(
          _act(
            context,
            ref,
            (c) => c.reconnect(server.name),
            success: l10n.success,
          ),
        ),
        child: Text(l10n.mcpReconnect),
      );
    } else {
      action = null;
    }

    return SettingsEntityRow(
      title: server.name,
      icon: server.transport == 'stdio' ? AppIcons.plug : AppIcons.globe,
      tone: state.tone,
      statusLabel: state.label,
      subtitle: handAdded ? l10n.mcpHandAddedSource : server.source,
      meta: [
        SettingsMetaFact(value: server.transport),
        if (server.isConnected)
          SettingsMetaFact(
            label: l10n.mcpBridgedToolsLabel,
            value: '${server.toolCount}',
          ),
      ],
      hoverTrailing: definition == null
          ? null
          : CcIconButton(
              icon: AppIcons.trash2,
              size: CcButtonSize.sm,
              variant: CcButtonVariant.destructive,
              tooltip: l10n.mcpRemoveServer,
              onPressed: () => unawaited(_remove(context, ref, definition)),
            ),
      trailing: action,
      onPressed: definition == null
          ? null
          : () => unawaited(_edit(context, ref, definition)),
    );
  }
}
