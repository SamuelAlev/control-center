import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/domain/mcp_config.dart';
import 'package:control_center/features/mcp/providers/mcp_config_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings section for the MCP server configuration.
class McpSection extends ConsumerWidget {
  /// Creates a [McpSection].
  const McpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(mcpConfigProvider);
    final notifier = ref.read(mcpConfigProvider.notifier);
    final server = ref.watch(mcpServerProvider);
    final running = ref.watch(mcpServerRunningProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.mcpServer,
      trailing: _StatusBadge(running: running),
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.power,
            title: running ? l10n.serverRunning : l10n.serverStopped,
            subtitle: running
                ? l10n.mcpListeningOnPort(config.port)
                : l10n.startServerToAccept,
            trailing: CcButton(
              onPressed: () async {
                try {
                  if (running) {
                    await server.stop();
                  } else {
                    await server.start();
                  }
                } catch (e) {
                  if (context.mounted) {
                    CcToastScope.of(context).show(
                      '$e',
                      variant: CcToastVariant.danger,
                    );
                  }
                }
              },
              variant: running
                  ? CcButtonVariant.destructive
                  : CcButtonVariant.primary,
              child: Text(running ? l10n.stop : l10n.startLabel),
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.toggleLeft,
            title: l10n.startOnAppLaunch,
            subtitle: l10n.whenOffServerStaysStopped,
            trailing: CcSwitch(
              value: config.enabled,
              onChanged: (v) async {
                await notifier.setEnabled(enabled: v);
                if (v) {
                  await server.start();
                } else {
                  await server.stop();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.network,
            title: l10n.portLabel,
            subtitle: running
                ? l10n.restartToApply
                : l10n.defaultPort(9020),
            trailing: SizedBox(width: 120, child: _PortField(config: config, notifier: notifier)),
          ),
          const SizedBox(height: 8),
          SettingsRow(
            icon: LucideIcons.lock,
            title: l10n.authenticationToken,
            subtitle: (config.token != null && config.token!.isNotEmpty)
                ? l10n.tokenConfigured
                : l10n.noTokenSet,
            trailing: _TokenActions(
              hasValue: config.token != null && config.token!.isNotEmpty,
              onEdit: () => showTokenDialog(
                context,
                title: l10n.mcpAuthToken,
                initialValue: config.token ?? '',
                save: (v) async => notifier.setToken(v.isEmpty ? null : v),
              ),
              onClear: () => notifier.setToken(null),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortField extends ConsumerStatefulWidget {
  const _PortField({required this.config, required this.notifier});
  final McpConfig config;
  final McpConfigNotifier notifier;

  @override
  ConsumerState<_PortField> createState() => _PortFieldState();
}

class _PortFieldState extends ConsumerState<_PortField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.config.port.toString());
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
          widget.notifier.setPort(port);
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
            running ? LucideIcons.circle : LucideIcons.circleDot,
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
