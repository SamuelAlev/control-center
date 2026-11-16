import 'dart:async';

import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_external_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/external_mcp_server_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_editor_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Integrations: external MCP servers (PRD 01).
///
/// CC is now an MCP *client* too: the connected host (the spawned `cc_server`
/// the desktop AND the web client both talk to) connects to external MCP
/// servers and bridges their tools into the agent tool surface. This section
/// drives that subsystem over the `mcp.client.*` RPC ops — so it is identical
/// on desktop and web and never imports `cc_mcp_client`. It shows the host's
/// servers, the standing tool-approval posture and authorize/reconnect actions.
///
/// The approval mode leads, because it is the one setting here that changes
/// what an agent may do without asking; the servers below are the inventory it
/// applies to. The owner can add personal servers by hand next to the
/// discovered ones; only those can be edited or removed here, since a
/// discovered one belongs to the tool whose config it was read from.
class ExternalMcpSection extends ConsumerWidget {
  /// Creates an [ExternalMcpSection].
  const ExternalMcpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final modeAsync = ref.watch(mcpApprovalModeProvider);
    final serversAsync = ref.watch(mcpExternalServersProvider);
    final mode = modeAsync.value ?? ApprovalMode.alwaysAsk;
    final servers = serversAsync.value ?? const <McpExternalServerInfo>[];
    final connected = servers.where((s) => s.isConnected).length;
    final tools = servers.fold<int>(
      0,
      (sum, s) => sum + (s.isConnected ? s.toolCount : 0),
    );

    return SectionCard(
      label: l10n.mcpExternalServers,
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        icon: AppIcons.plus,
        onPressed: () => unawaited(_add(context, ref)),
        child: Text(l10n.mcpAddServer),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mcpExternalServersDescription),
          const SizedBox(height: AppSpacing.xs),
          // The server only offers these in runs its owner is accountable for.
          Text(l10n.mcpExternalServersOwnerRunsOnly),
        ],
      ),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      headerPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (servers.isNotEmpty)
                  SettingsSummary(
                    facts: [
                      SettingsFact(
                        label: l10n.connectedLabel,
                        value: l10n.settingsCountOfTotal(
                          connected,
                          servers.length,
                        ),
                        tone: connected > 0
                            ? CcStatusTone.positive
                            : CcStatusTone.caution,
                      ),
                      SettingsFact(
                        label: l10n.mcpBridgedToolsLabel,
                        value: '$tools',
                      ),
                    ],
                  ),
                if (servers.isNotEmpty) const SizedBox(height: AppSpacing.lg),
                SettingsField(
                  label: l10n.mcpApprovalMode,
                  description: l10n.mcpApprovalModeDescription,
                  controlWidth: 220,
                  trailingControl: true,
                  child: CcSelect<ApprovalMode>(
                    options: [
                      CcSelectOption(
                        value: ApprovalMode.alwaysAsk,
                        label: l10n.mcpApprovalAlwaysAsk,
                      ),
                      CcSelectOption(
                        value: ApprovalMode.write,
                        label: l10n.mcpApprovalWrite,
                      ),
                      CcSelectOption(
                        value: ApprovalMode.yolo,
                        label: l10n.mcpApprovalYolo,
                      ),
                    ],
                    value: mode,
                    onChanged: (v) async {
                      await ref
                          .read(mcpClientControlProvider)
                          .setApprovalMode(v);
                      ref.invalidate(mcpApprovalModeProvider);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          serversAsync.when(
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
              if (servers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: CcEmptyState(
                    icon: AppIcons.puzzle,
                    message: l10n.mcpNoExternalServers,
                    description: l10n.mcpExternalConnectionsNote,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final server in servers) ...[
                    const CcDivider(),
                    ExternalMcpServerRow(server: server),
                  ],
                  const CcDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Text(
                      l10n.mcpExternalConnectionsNote,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final control = ref.read(mcpClientControlProvider);
    final saved = await showMcpServerEditor(
      context,
      scope: McpServerEditorScope.personal,
      onSave: control.saveServer,
    );
    if (saved) {
      ref.invalidate(mcpExternalServersProvider);
    }
  }
}
