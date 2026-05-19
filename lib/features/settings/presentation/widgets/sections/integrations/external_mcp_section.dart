import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_external_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
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
/// applies to.
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
      subtitle: Text(l10n.mcpExternalServersDescription),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
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
                    _ServerRow(server: server),
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
}

class _ServerRow extends ConsumerWidget {
  const _ServerRow({required this.server});

  final McpExternalServerInfo server;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = _lifecycleState(l10n);

    return SettingsEntityRow(
      title: server.name,
      icon: server.transport == 'stdio' ? AppIcons.plug : AppIcons.globe,
      tone: state.tone,
      statusLabel: state.label,
      subtitle: server.source,
      meta: [
        SettingsMetaFact(value: server.transport),
        if (server.isConnected)
          SettingsMetaFact(
            label: l10n.mcpBridgedToolsLabel,
            value: '${server.toolCount}',
          ),
      ],
      trailing: server.usesOAuth && server.needsAuth
          ? CcButton(
              variant: CcButtonVariant.accent,
              size: CcButtonSize.sm,
              onPressed: () => _run(context, ref, _RowAction.authorize),
              child: Text(l10n.mcpAuthorize),
            )
          : _canReconnect
          ? CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => _run(context, ref, _RowAction.reconnect),
              child: Text(l10n.mcpReconnect),
            )
          : null,
    );
  }

  /// Lifecycle → a design-system tone plus a word. Never colour alone.
  ({String label, CcStatusTone tone}) _lifecycleState(AppLocalizations l10n) =>
      switch (server.lifecycle) {
        'connected' => (
          label: l10n.mcpStatusConnected,
          tone: CcStatusTone.positive,
        ),
        'connecting' => (
          label: l10n.mcpStatusConnecting,
          tone: CcStatusTone.neutral,
        ),
        'needs_auth' || 'needs_client_registration' => (
          label: l10n.mcpStatusNeedsAuth,
          tone: CcStatusTone.caution,
        ),
        'failed' => (label: l10n.mcpStatusFailed, tone: CcStatusTone.negative),
        'circuit_open' => (
          label: l10n.mcpStatusCircuitOpen,
          tone: CcStatusTone.negative,
        ),
        _ => (label: l10n.mcpStatusDisabled, tone: CcStatusTone.neutral),
      };

  bool get _canReconnect =>
      server.lifecycle == 'failed' || server.lifecycle == 'circuit_open';

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _RowAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final control = ref.read(mcpClientControlProvider);
      switch (action) {
        case _RowAction.authorize:
          await control.authorize(server.name);
        case _RowAction.reconnect:
          await control.reconnect(server.name);
      }
      ref.invalidate(mcpExternalServersProvider);
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.success, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

enum _RowAction { authorize, reconnect }
