import 'dart:async';

import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_actions.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_row_notice.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_sign_in.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One MCP server of a workspace, the workspace's or the reader's own: its
/// state, how it is reached, the on/off switch, and — held back until
/// hovered — reconnect and remove. The row opens the editor.
///
/// Under it, what stands between the server and its tools: a workspace
/// server the current server owner has not approved says what approval would
/// allow (the owner gets **Approve**), and a remote server waiting for a
/// browser sign-in gets **Sign in**.
class McpServerRow extends ConsumerWidget {
  /// Creates the row for [entry] of [scope] in [workspaceId].
  const McpServerRow({
    super.key,
    required this.workspaceId,
    required this.scope,
    required this.entry,
  });

  /// The workspace it belongs to.
  final String workspaceId;

  /// Whose server it is.
  final McpServerScope scope;

  /// The server and its live state.
  final WorkspaceMcpServerEntry entry;

  void _refresh(WidgetRef ref) => ref.invalidate(
    workspaceMcpServersProvider((workspaceId: workspaceId, scope: scope)),
  );

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(WorkspaceMcpServerControl control) action,
  ) => runMcpServerAction(
    context,
    action: () => action(ref.read(workspaceMcpServerControlProvider)),
    refresh: () => _refresh(ref),
  );

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final control = ref.read(workspaceMcpServerControlProvider);
    final saved = await showMcpServerEditor(
      context,
      scope: scope,
      existing: entry.definition,
      onSave: (draft) => control.save(workspaceId, scope, draft),
    );
    if (saved) {
      _refresh(ref);
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (await confirmRemoveMcpServer(context, entry.definition) &&
        context.mounted) {
      await _act(
        context,
        ref,
        (c) => c.delete(workspaceId, scope, entry.definition.id),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final definition = entry.definition;
    final state = mcpLifecycleState(l10n, entry.lifecycle);
    final lastError = entry.lastError;
    final failed = mcpLifecycleCanReconnect(entry.lifecycle);
    final signIn =
        entry.needsAuth && definition.transport.isRemote && definition.enabled;
    // Nobody approves a member's own server; theirs only stays public.
    final awaitsApproval =
        scope == McpServerScope.workspace && !entry.hostApproved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsEntityRow(
          title: definition.name,
          icon: definition.runsOnHost ? AppIcons.plug : AppIcons.globe,
          tone: state.tone,
          statusLabel: state.label,
          subtitleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mcpServerTarget(definition),
                // RTL carve-out: a command line or URL reads left to right.
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcFonts.code(textStyle: CcTypography.caption),
              ),
              if (failed && lastError != null && lastError.isNotEmpty)
                Text(
                  lastError,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(
                    color: t.textErrorPrimary,
                  ),
                ),
            ],
          ),
          meta: [
            SettingsMetaFact(value: definition.transport.wire, code: true),
            if (entry.isConnected)
              SettingsMetaFact(
                label: l10n.mcpBridgedToolsLabel,
                value: '${entry.toolCount}',
              ),
            if (definition.transport.isRemote && !entry.hostApproved)
              SettingsMetaFact(value: l10n.mcpPublicAddressesOnly),
          ],
          hoverTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (failed)
                CcIconButton(
                  icon: AppIcons.refreshCw,
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.ghost,
                  tooltip: l10n.mcpReconnect,
                  onPressed: () => unawaited(
                    _act(
                      context,
                      ref,
                      (c) => c.reconnect(workspaceId, scope, definition.id),
                    ),
                  ),
                ),
              CcIconButton(
                icon: AppIcons.trash2,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
                tooltip: l10n.mcpRemoveServer,
                onPressed: () => unawaited(_remove(context, ref)),
              ),
            ],
          ),
          trailing: CcSwitch(
            value: definition.enabled,
            semanticLabel: l10n.mcpServerEnabledToggle(definition.name),
            onChanged: (enabled) => unawaited(
              _act(
                context,
                ref,
                (c) => c.save(
                  workspaceId,
                  scope,
                  mcpServerEnabledDraft(definition, enabled: enabled),
                ),
              ),
            ),
          ),
          onPressed: () => unawaited(_edit(context, ref)),
        ),
        if (awaitsApproval)
          McpServerApprovalNotice(
            entry: entry,
            owner: ref.watch(canUseHostProvider),
            onApprove: () => _act(
              context,
              ref,
              (c) => c.approve(workspaceId, definition.id),
            ),
          ),
        // Last: the step the reader can always take themselves.
        if (signIn)
          McpServerRowNotice(
            text: l10n.mcpServerSignInNeeded,
            actionLabel: l10n.mcpServerSignIn,
            onAction: () => signInToMcpServer(
              context,
              ref,
              workspaceId: workspaceId,
              scope: scope,
              definition: definition,
            ),
          ),
      ],
    );
  }
}
