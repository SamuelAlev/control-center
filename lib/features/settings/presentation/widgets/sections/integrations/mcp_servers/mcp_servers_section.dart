import 'dart:async';

import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_row.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → MCP servers: the MCP servers of one [scope] in the current
/// workspace, bridged by Control Center into Claude Code and the built-in
/// harness alike.
///
/// [McpServerScope.workspace]: the workspace's, which every run in it gets.
/// Admins add, change and remove them; anyone else is told the list is the
/// admins', rather than shown a refusal. [McpServerScope.personal]: the
/// reader's own, which only the runs they start in this workspace get; every
/// member manages theirs.
class McpServersSection extends ConsumerWidget {
  /// Creates the section for [scope].
  const McpServersSection({super.key, required this.scope});

  /// Whose servers it lists.
  final McpServerScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final words = _McpServersWords.of(l10n, scope);
    // The demo has no `mcpServers.*` ops: listing could only fail.
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: words.title,
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
    final description = Text(words.description);
    if (scope == McpServerScope.workspace &&
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin != true) {
      return SectionCard(
        label: words.title,
        subtitle: description,
        child: _Note(text: l10n.mcpWorkspaceServersAdminsOnly),
      );
    }
    final key = (workspaceId: workspaceId, scope: scope);
    final serversAsync = ref.watch(workspaceMcpServersProvider(key));
    final available = serversAsync.value != null;
    return SectionCard(
      label: words.title,
      subtitle: description,
      trailing: available
          ? CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: () => unawaited(_add(context, ref, key)),
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
            return _Note(text: words.unavailable, inset: true);
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
                message: words.empty,
                description: words.emptyDescription,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in servers) ...[
                const CcDivider(),
                McpServerRow(
                  key: ValueKey(entry.definition.id),
                  workspaceId: workspaceId,
                  scope: scope,
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
    McpServersKey key,
  ) async {
    final control = ref.read(workspaceMcpServerControlProvider);
    final saved = await showMcpServerEditor(
      context,
      scope: key.scope,
      onSave: (draft) => control.save(key.workspaceId, key.scope, draft),
    );
    if (saved) {
      ref.invalidate(workspaceMcpServersProvider(key));
    }
  }
}

/// The section's copy for one scope.
class _McpServersWords {
  const _McpServersWords({
    required this.title,
    required this.description,
    required this.unavailable,
    required this.empty,
    required this.emptyDescription,
  });

  factory _McpServersWords.of(AppLocalizations l10n, McpServerScope scope) =>
      switch (scope) {
        McpServerScope.workspace => _McpServersWords(
          title: l10n.mcpWorkspaceServers,
          description: l10n.mcpWorkspaceServersDescription,
          unavailable: l10n.mcpWorkspaceServersUnavailable,
          empty: l10n.mcpWorkspaceServersEmpty,
          emptyDescription: l10n.mcpWorkspaceServersEmptyDescription,
        ),
        McpServerScope.personal => _McpServersWords(
          title: l10n.mcpPersonalServers,
          description: l10n.mcpPersonalServersDescription,
          unavailable: l10n.mcpPersonalServersUnavailable,
          empty: l10n.mcpPersonalServersEmpty,
          emptyDescription: l10n.mcpPersonalServersEmptyDescription,
        ),
      };

  final String title;
  final String description;
  final String unavailable;
  final String empty;
  final String emptyDescription;
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
