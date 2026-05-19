import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/mcp/providers/mcp_config_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mcp settings panel.
class McpSettingsPanel extends ConsumerWidget {
  /// Creates a new [McpSettingsPanel].
  const McpSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(mcpConfigProvider);
    final notifier = ref.read(mcpConfigProvider.notifier);
    final server = ref.watch(mcpServerProvider);
    final running = ref.watch(mcpServerRunningProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: Row(
            children: [
              Expanded(child: Text(l10n.mcpStatus)),
              _StatusBadge(isRunning: running),
            ],
          ),
          subtitle: Text(
            running
                ? l10n.mcpListeningOn(config.port)
                : l10n.mcpServerStopped,
          ),
          child: Row(
            children: [
              CcButton(
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
                child: Text(running ? l10n.stop : l10n.startLabel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  running
                      ? l10n.mcpActiveAccepting
                      : l10n.mcpNotRunning,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.designSystem?.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.port),
          subtitle: Text(
            running
                ? l10n.mcpRestartPortChanges
                : l10n.mcpDefaultPort(9020),
          ),
          child: _PortField(port: config.port, onPortChanged: notifier.setPort),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.mcpAuthentication),
          subtitle: Text(
            config.token != null && config.token!.isNotEmpty
                ? l10n.tokenConfigured
                : l10n.noTokenUnrestricted,
          ),
          child: Row(
            children: [
              CcButton(
                onPressed: () => _showTokenDialog(context, config, notifier),
                child: Text(
                  config.token != null && config.token!.isNotEmpty
                      ? l10n.updateToken
                      : l10n.setToken,
                ),
              ),
              if (config.token != null && config.token!.isNotEmpty) ...[
                const SizedBox(width: 12),
                CcButton(
                  onPressed: () => notifier.setToken(null),
                  variant: CcButtonVariant.ghost,
                  child: Text(AppLocalizations.of(context).remove),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: Text(l10n.enableMcpServer),
          subtitle: Text(
            l10n.mcpAutoStartDescription,
          ),
          child: Row(
            children: [
              CcSwitch(
                value: config.enabled,
                onChanged: (v) => notifier.setEnabled(enabled: v),
              ),
              const SizedBox(width: 12),
              Text(
                config.enabled ? l10n.enabled : l10n.disabled,
                style: TextStyle(
                  color: config.enabled
                      ? context.designSystem?.textPrimary
                      : context.designSystem?.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTokenDialog(
    BuildContext context,
    McpConfig config,
    McpConfigNotifier notifier,
  ) {
    final controller = TextEditingController(text: config.token ?? '');
    final l10n = AppLocalizations.of(context);
    showCcDialog<void>(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: l10n.mcpAuthToken,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.sharedSecretToken),
            const SizedBox(height: 6),
            CcTextField(
              controller: controller,
              hintText: l10n.enterTokenToAuth,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(dialogContext),
            variant: CcButtonVariant.ghost,
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CcButton(
            onPressed: () async {
              final token = controller.text;
              await notifier.setToken(token.isEmpty ? null : token);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _PortField extends StatefulWidget {
  const _PortField({required this.port, required this.onPortChanged});

  final int port;
  final ValueChanged<int> onPortChanged;

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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.port),
        const SizedBox(height: 6),
        CcTextField(
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
              widget.onPortChanged(port);
            }
          },
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final bgColor = isRunning
        ? (tokens?.bgSuccessPrimary ?? Colors.green)
        : (tokens?.bgErrorPrimary ?? Colors.red);
    final fgColor = isRunning
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
            isRunning ? AppIcons.circle : AppIcons.circleDot,
            size: 8,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            isRunning ? l10n.running : l10n.stopped,
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

