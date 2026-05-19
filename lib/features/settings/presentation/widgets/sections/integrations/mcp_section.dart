import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_ui/cc_ui.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_control_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for the MCP server configuration.
///
/// Platform-neutral: it reads the seamed [mcpServerControlProvider] +
/// [mcpServerStatusProvider]. On desktop these resolve to the in-process MCP
/// server; on web/thin clients they resolve to the connected server's MCP server
/// over the `mcp.*` RPC ops. When the connected server exposes no MCP control
/// (status is `null`), it renders an honest "not available" placeholder.
///
/// The card opens with the three facts that decide whether an external tool can
/// reach this server at all — is it running, on which port, is a token required
/// — rather than with the button that changes the first of them.
class McpSection extends ConsumerWidget {
  /// Creates a [McpSection].
  const McpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // The demo never mounts the MCP surface: `mcp.*` is absent from its op
    // registry AND `/mcp` + `/sse` 404, so the status query can only fail and
    // the start/stop controls would act on nothing.
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.mcpServer,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.mcp,
            compact: true,
          ),
        ),
      );
    }

    final statusAsync = ref.watch(mcpServerStatusProvider);

    return SectionCard(
      label: l10n.mcpServer,
      trailing: statusAsync.maybeWhen(
        data: (status) => status == null
            ? null
            : CcStatusTag(
                label: status.running ? l10n.running : l10n.stopped,
                tone: status.running
                    ? CcStatusTone.positive
                    : CcStatusTone.neutral,
              ),
        orElse: () => null,
      ),
      child: statusAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => InlineLoadError(
          e,
          padding: const EdgeInsets.all(AppSpacing.lg),
          center: false,
        ),
        data: (status) {
          if (status == null) {
            return CcAlert(
              title: l10n.mcpNotAvailableOnServer,
              variant: CcAlertVariant.info,
            );
          }
          return _McpControls(status: status);
        },
      ),
    );
  }
}

class _McpControls extends ConsumerWidget {
  const _McpControls({required this.status});

  final McpServerStatus status;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      // Refresh the snapshot after every action (start/stop/config change).
      ref.invalidate(mcpServerStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final control = ref.watch(mcpServerControlProvider);
    final running = status.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSummary(
          facts: [
            SettingsFact(
              label: l10n.mcpServer,
              value: running ? l10n.running : l10n.stopped,
              tone: running ? CcStatusTone.positive : CcStatusTone.neutral,
              mono: false,
            ),
            SettingsFact(
              label: l10n.portLabel,
              value: '${status.port}',
              mono: true,
            ),
            SettingsFact(
              label: l10n.authenticationToken,
              value: status.hasToken
                  ? l10n.configuredLabel
                  : l10n.notConfiguredLabel,
              tone: status.hasToken
                  ? CcStatusTone.positive
                  : CcStatusTone.caution,
              mono: false,
            ),
          ],
          note: status.hasToken ? null : l10n.mcpNoTokenWarning,
          trailing: CcButton(
            onPressed: () => _run(
              context,
              ref,
              () => running ? control.stop() : control.start(),
            ),
            variant: running
                ? CcButtonVariant.secondary
                : CcButtonVariant.accent,
            size: CcButtonSize.sm,
            child: Text(running ? l10n.stop : l10n.startLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsGroup(
          showRule: true,
          gap: AppSpacing.md,
          children: [
            SettingsToggle(
              title: l10n.startOnAppLaunch,
              description: l10n.whenOffServerStaysStopped,
              value: status.enabled,
              onChanged: (v) =>
                  _run(context, ref, () => control.setEnabled(enabled: v)),
            ),
            SettingsField(
              label: l10n.authenticationToken,
              description: status.hasToken
                  ? l10n.tokenConfigured
                  : l10n.noTokenSet,
              controlWidth: 200,
              child: _TokenActions(
                hasValue: status.hasToken,
                onEdit: () => showTokenDialog(
                  context,
                  title: l10n.mcpAuthToken,
                  save: (v) => _run(
                    context,
                    ref,
                    () => control.setToken(v.isEmpty ? null : v),
                  ),
                ),
                onClear: () => _run(context, ref, () => control.setToken(null)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TokenActions extends StatelessWidget {
  const _TokenActions({
    required this.hasValue,
    required this.onEdit,
    required this.onClear,
  });

  final bool hasValue;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcButton(
          onPressed: onEdit,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          child: Text(hasValue ? l10n.updateLabel : l10n.setLabel),
        ),
        if (hasValue) ...[
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            onPressed: onClear,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            child: Text(l10n.clear),
          ),
        ],
      ],
    );
  }
}
