import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_server_control_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for the MCP server configuration.
///
/// Platform-neutral: it reads the seamed [mcpServerControlProvider] +
/// [mcpServerStatusProvider]. On desktop these resolve to the in-process MCP
/// server; on web/thin clients they resolve to the connected server's MCP server
/// over the `mcp.*` RPC ops. When the connected server exposes no MCP control
/// (status is `null`), it renders an honest "not available" placeholder.
class McpSection extends ConsumerWidget {
  /// Creates a [McpSection].
  const McpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(mcpServerStatusProvider);

    return SectionCard(
      label: l10n.mcpServer,
      trailing: statusAsync.maybeWhen(
        data: (status) =>
            status == null ? null : _StatusBadge(running: status.running),
        orElse: () => null,
      ),
      child: statusAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$e'),
        ),
        data: (status) {
          if (status == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.mcpNotAvailableOnServer),
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
    } catch (e) {
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
      children: [
        SettingsRow(
          icon: AppIcons.power,
          title: running ? l10n.serverRunning : l10n.serverStopped,
          subtitle: running
              ? l10n.mcpListeningOnPort(status.port)
              : l10n.startServerToAccept,
          trailing: CcButton(
            onPressed: () => _run(
              context,
              ref,
              () => running ? control.stop() : control.start(),
            ),
            variant: running
                ? CcButtonVariant.destructive
                : CcButtonVariant.primary,
            child: Text(running ? l10n.stop : l10n.startLabel),
          ),
        ),
        const SizedBox(height: 8),
        SettingsRow(
          icon: AppIcons.toggleLeft,
          title: l10n.startOnAppLaunch,
          subtitle: l10n.whenOffServerStaysStopped,
          trailing: CcSwitch(
            value: status.enabled,
            onChanged: (v) =>
                _run(context, ref, () => control.setEnabled(enabled: v)),
          ),
        ),
        const SizedBox(height: 8),
        SettingsRow(
          icon: AppIcons.network,
          title: l10n.portLabel,
          subtitle: running ? l10n.restartToApply : l10n.defaultPort(9020),
          trailing: SizedBox(
            width: 120,
            child: _PortField(
              port: status.port,
              onSubmitted: (port) =>
                  _run(context, ref, () => control.setPort(port)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SettingsRow(
          icon: AppIcons.lock,
          title: l10n.authenticationToken,
          subtitle: status.hasToken ? l10n.tokenConfigured : l10n.noTokenSet,
          trailing: _TokenActions(
            hasValue: status.hasToken,
            onEdit: () => showTokenDialog(
              context,
              title: l10n.mcpAuthToken,
              initialValue: '',
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
    );
  }
}

class _PortField extends StatefulWidget {
  const _PortField({required this.port, required this.onSubmitted});

  final int port;
  final ValueChanged<int> onSubmitted;

  @override
  State<_PortField> createState() => _PortFieldState();
}

class _PortFieldState extends State<_PortField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.port.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcTextField(
      controller: _controller,
      hintText: '9020',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onSubmitted: (_) {
        final port = int.tryParse(_controller.text);
        if (port != null && port > 0 && port <= 65535) {
          widget.onSubmitted(port);
        }
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.running});
  final bool running;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final bgColor = running
        ? (tokens?.bgSuccessPrimary ?? Colors.green)
        : (tokens?.bgErrorPrimary ?? Colors.red);
    final fgColor = running
        ? (tokens?.fgSuccessPrimary ?? Colors.green)
        : (tokens?.fgErrorPrimary ?? Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            running ? AppIcons.circle : AppIcons.circleDot,
            size: 8,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            running ? l10n.running : l10n.stopped,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
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
        if (hasValue) ...[
          CcButton(
            onPressed: onClear,
            variant: CcButtonVariant.ghost,
            child: Text(l10n.clear),
          ),
          const SizedBox(width: 8),
        ],
        CcButton(
          onPressed: onEdit,
          variant: CcButtonVariant.secondary,
          child: Text(hasValue ? l10n.updateLabel : l10n.setLabel),
        ),
      ],
    );
  }
}
