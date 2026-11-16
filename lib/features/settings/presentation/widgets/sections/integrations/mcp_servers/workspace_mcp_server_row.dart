import 'dart:async';

import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/workspace_mcp_servers_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_actions.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_words.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One MCP server of a workspace, for one of its admins: its state, how it
/// is reached, the on/off switch, and — held back until hovered — reconnect
/// and remove. The row opens the editor. A server the current server owner
/// has not approved carries a line saying what approval would allow; the
/// owner gets **Approve** on it.
class WorkspaceMcpServerRow extends ConsumerWidget {
  /// Creates the row for [entry] of [workspaceId].
  const WorkspaceMcpServerRow({
    super.key,
    required this.workspaceId,
    required this.entry,
  });

  /// The workspace it belongs to.
  final String workspaceId;

  /// The server and its live state.
  final WorkspaceMcpServerEntry entry;

  void _refresh(WidgetRef ref) =>
      ref.invalidate(workspaceMcpServersProvider(workspaceId));

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
      scope: McpServerEditorScope.workspace,
      existing: entry.definition,
      onSave: (draft) => control.save(workspaceId, draft),
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
        (c) => c.delete(workspaceId, entry.definition.id),
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
            SettingsMetaFact(value: definition.transport.wire),
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
                      (c) => c.reconnect(workspaceId, entry.definition.id),
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
                  mcpServerEnabledDraft(definition, enabled: enabled),
                ),
              ),
            ),
          ),
          onPressed: () => unawaited(_edit(context, ref)),
        ),
        if (!entry.hostApproved)
          _ApprovalLine(
            entry: entry,
            owner: ref.watch(canUseHostProvider),
            onApprove: () => _act(
              context,
              ref,
              (c) => c.approve(workspaceId, entry.definition.id),
            ),
          ),
      ],
    );
  }
}

/// What approval would allow, under an unapproved server. Lined up with the
/// row's title; the owner gets the button that grants it.
class _ApprovalLine extends StatefulWidget {
  const _ApprovalLine({
    required this.entry,
    required this.owner,
    required this.onApprove,
  });

  final WorkspaceMcpServerEntry entry;
  final bool owner;
  final Future<void> Function() onApprove;

  @override
  State<_ApprovalLine> createState() => _ApprovalLineState();
}

class _ApprovalLineState extends State<_ApprovalLine> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    await widget.onApprove();
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final stdio = widget.entry.definition.runsOnHost;
    final text = switch ((stdio, widget.owner)) {
      (true, true) => l10n.mcpApprovalStdioOwner,
      (true, false) => l10n.mcpApprovalStdioMember,
      (false, true) => l10n.mcpApprovalRemoteOwner,
      (false, false) => l10n.mcpApprovalRemoteMember,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg + 28 + AppSpacing.md,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 1),
            child: Icon(AppIcons.info, size: 14, color: t.fgWarningPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          if (widget.owner) ...[
            const SizedBox(width: AppSpacing.md),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: _busy,
              onPressed: _busy ? null : () => unawaited(_approve()),
              child: Text(l10n.mcpApproveServer),
            ),
          ],
        ],
      ),
    );
  }
}
