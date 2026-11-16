import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/workspace_mcp_server_row.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → MCP servers: the MCP servers configured for the current
/// workspace, which every agent run in it gets (Claude Code and the built-in
/// harness alike, bridged through Control Center).
///
/// Workspace admins add, change and remove them over the `mcpServers.*` ops.
/// A server that runs a command on the host does not start until the server
/// owner approves it, and a remote one reaches only public addresses until
/// then; the owner approves from the row. Anyone else is told the list is the
/// admins', rather than shown a refusal.
class WorkspaceMcpServersSection extends ConsumerWidget {
  /// Creates a [WorkspaceMcpServersSection].
  const WorkspaceMcpServersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The demo has no `mcpServers.*` ops: listing could only fail.
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.mcpWorkspaceServers,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(capability: DemoCapability.mcp, compact: true),
        ),
      );
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final admin = ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin;
    final description = Text(l10n.mcpWorkspaceServersDescription);
    if (admin != true) {
      return SectionCard(
        label: l10n.mcpWorkspaceServers,
        subtitle: description,
        child: _Note(text: l10n.mcpWorkspaceServersAdminsOnly),
      );
    }
    final serversAsync = ref.watch(workspaceMcpServersProvider(workspaceId));
    final available = serversAsync.value != null;
    return SectionCard(
      label: l10n.mcpWorkspaceServers,
      subtitle: description,
      trailing: available
          ? CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: () => unawaited(_add(context, ref, workspaceId)),
              child: Text(l10n.mcpAddServer),
            )
          : null,
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      headerPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: serversAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => InlineLoadError(
          e,
          padding: const EdgeInsets.all(AppSpacing.lg),
          center: false,
        ),
        data: (servers) {
          if (servers == null) {
            return _Note(
              text: l10n.mcpWorkspaceServersUnavailable,
              inset: true,
            );
          }
          if (servers.isEmpty) {
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: CcEmptyState(
                icon: AppIcons.puzzle,
                message: l10n.mcpWorkspaceServersEmpty,
                description: l10n.mcpWorkspaceServersEmptyDescription,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in servers) ...[
                const CcDivider(),
                WorkspaceMcpServerRow(
                  key: ValueKey(entry.definition.id),
                  workspaceId: workspaceId,
                  entry: entry,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final control = ref.read(workspaceMcpServerControlProvider);
    final saved = await showMcpServerEditor(
      context,
      scope: McpServerEditorScope.workspace,
      onSave: (draft) => control.save(workspaceId, draft),
    );
    if (saved) {
      ref.invalidate(workspaceMcpServersProvider(workspaceId));
    }
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.inset = false});

  final String text;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: inset
          ? const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            )
          : EdgeInsetsDirectional.zero,
      child: Text(
        text,
        style: CcTypography.bodySm.copyWith(color: t.textTertiary),
      ),
    );
  }
}
