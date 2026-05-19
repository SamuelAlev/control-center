import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_external_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Integrations: external MCP servers (PRD 01).
///
/// CC is now an MCP *client* too: the connected host (the spawned `cc_server`
/// the desktop AND the web client both talk to) connects to external MCP
/// servers and bridges their tools into the agent tool surface. This section
/// drives that subsystem over the `mcp.client.*` RPC ops — so it is identical
/// on desktop and web and never imports `cc_mcp_client`. It shows the host's
/// servers, the standing tool-approval posture, and authorize/reconnect actions.
class ExternalMcpSection extends ConsumerWidget {
  /// Creates an [ExternalMcpSection].
  const ExternalMcpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final modeAsync = ref.watch(mcpApprovalModeProvider);
    final serversAsync = ref.watch(mcpExternalServersProvider);
    final mode = modeAsync.value ?? ApprovalMode.alwaysAsk;

    return SectionCard(
      label: l10n.mcpExternalServers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.mcpExternalServersDescription,
              style: TextStyle(
                fontSize: 12,
                color: context.designSystem?.textTertiary,
              ),
            ),
          ),
          SettingsRow(
            icon: AppIcons.shield,
            title: l10n.mcpApprovalMode,
            subtitle: l10n.mcpApprovalModeDescription,
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
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
                  await ref.read(mcpClientControlProvider).setApprovalMode(v);
                  ref.invalidate(mcpApprovalModeProvider);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          serversAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CcSpinner()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('$e'),
            ),
            data: (servers) {
              if (servers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.mcpNoExternalServers,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.designSystem?.textTertiary,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final server in servers) _ServerRow(server: server),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mcpExternalConnectionsNote,
            style: TextStyle(
              fontSize: 11,
              color: context.designSystem?.textTertiary,
            ),
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

    final subtitle = StringBuffer(server.transport);
    if (server.source != null) {
      subtitle.write(' · ${server.source}');
    }
    if (server.isConnected) {
      subtitle.write(' · ${l10n.mcpToolsSummary(server.toolCount)}');
    }

    return SettingsRow(
      icon: server.transport == 'stdio' ? AppIcons.plug : AppIcons.globe,
      title: server.name,
      subtitle: subtitle.toString(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusBadge(lifecycle: server.lifecycle),
          if (server.usesOAuth && server.needsAuth) ...[
            const SizedBox(width: 8),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => _run(context, ref, _RowAction.authorize),
              child: Text(l10n.mcpAuthorize),
            ),
          ] else if (_canReconnect) ...[
            const SizedBox(width: 8),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => _run(context, ref, _RowAction.reconnect),
              child: Text(l10n.mcpReconnect),
            ),
          ],
        ],
      ),
    );
  }

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
    } catch (e) {
      if (context.mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }
}

enum _RowAction { authorize, reconnect }

/// A textual + colored status pill for a server's lifecycle. The label is
/// always shown alongside the dot, so status is never conveyed by colour alone
/// (WCAG: never status-by-colour-only).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.lifecycle});

  final String lifecycle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final (label, color) = switch (lifecycle) {
      'connected' => (l10n.mcpStatusConnected, tokens?.success),
      'connecting' => (l10n.mcpStatusConnecting, tokens?.muted),
      'needs_auth' || 'needs_client_registration' => (
        l10n.mcpStatusNeedsAuth,
        tokens?.textWarningPrimary,
      ),
      'failed' => (l10n.mcpStatusFailed, tokens?.danger),
      'circuit_open' => (l10n.mcpStatusCircuitOpen, tokens?.danger),
      _ => (l10n.mcpStatusDisabled, tokens?.muted),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF888888),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: tokens?.textSecondary),
        ),
      ],
    );
  }
}
