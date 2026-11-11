import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_ui/cc_ui.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_server_control_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_token_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for the MCP server configuration.
///
/// Platform-neutral: it reads the seamed [mcpServerControlProvider] +
/// [mcpServerStatusProvider]. On every client these resolve to the
/// connected server's MCP server over the `mcp.*` RPC ops. When the connected server exposes no MCP control
/// (status is `null`), it renders an honest "not available" placeholder.
///
/// The card opens with the facts that decide whether an external tool can
/// reach this server (is it running, on which port) rather than with the
/// button that changes the first. Every MCP request carries the server's
/// token as an `Authorization: Bearer` header; the token always exists, and
/// only the server owner sees, copies or rotates it, or starts and stops the
/// endpoint. Anyone else sees the facts and that the endpoint is owner-only.
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

class _McpControls extends ConsumerStatefulWidget {
  const _McpControls({required this.status});

  final McpServerStatus status;

  @override
  ConsumerState<_McpControls> createState() => _McpControlsState();
}

class _McpControlsState extends ConsumerState<_McpControls> {
  /// The server refused the token although identity said owner: trust the
  /// server, and re-read identity so every owner surface follows.
  bool _refused = false;

  void _ownerOnly() {
    setState(() => _refused = true);
    ref.invalidate(currentIdentityProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      // Refresh the snapshot after every action (start/stop/config change).
      ref.invalidate(mcpServerStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final control = ref.watch(mcpServerControlProvider);
    final owner = ref.watch(isServerOwnerProvider) && !_refused;
    final running = widget.status.running;

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
              value: '${widget.status.port}',
              mono: true,
            ),
          ],
          trailing: owner
              ? CcButton(
                  onPressed: () =>
                      _run(() => running ? control.stop() : control.start()),
                  variant: running
                      ? CcButtonVariant.secondary
                      : CcButtonVariant.accent,
                  size: CcButtonSize.sm,
                  child: Text(running ? l10n.stop : l10n.startLabel),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (owner)
          SettingsGroup(
            showRule: true,
            gap: AppSpacing.md,
            children: [
              SettingsToggle(
                title: l10n.startOnAppLaunch,
                description: l10n.whenOffServerStaysStopped,
                value: widget.status.enabled,
                onChanged: (v) => _run(() => control.setEnabled(enabled: v)),
              ),
              McpTokenField(onOwnerOnly: _ownerOnly),
            ],
          )
        else
          CcAlert(
            title: l10n.mcpOwnerOnlyTitle,
            description: Text(l10n.mcpOwnerOnlyBody),
          ),
      ],
    );
  }
}
