import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Integrations section for where Control Center's data lives: run a
/// local in-app `cc_server`, or connect to a remote instance over RPC. Mirrors
/// the first-run setup screen; changes here apply after a restart.
class ServerConnectionSection extends ConsumerWidget {
  /// Creates a [ServerConnectionSection].
  const ServerConnectionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConnectionConfigProvider);
    final notifier = ref.read(serverConnectionConfigProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // The web client is always a remote client — it cannot host a local server,
    // so the local/remote toggle is desktop-only and web shows the remote
    // connection fields directly.
    final isRemote = kIsWeb || config.mode == ServerConnectionMode.remote;

    return SectionCard(
      label: l10n.serverConnection,
      child: Column(
        children: [
          if (!kIsWeb)
            SettingsRow(
              icon: isRemote ? AppIcons.cloud : AppIcons.monitor,
              title: l10n.serverConnectionMode,
              subtitle: isRemote
                  ? l10n.serverModeRemoteDescription
                  : l10n.serverModeLocalDescription,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: CcSelect<ServerConnectionMode>(
                  options: [
                    CcSelectOption(
                      value: ServerConnectionMode.local,
                      label: l10n.serverModeLocal,
                    ),
                    CcSelectOption(
                      value: ServerConnectionMode.remote,
                      label: l10n.serverModeRemote,
                    ),
                  ],
                  value: config.mode,
                  onChanged: notifier.setMode,
                ),
              ),
            ),
          if (isRemote) ...[
            if (!kIsWeb) const SizedBox(height: 8),
            SettingsRow(
              icon: AppIcons.link,
              title: l10n.serverRemoteUrl,
              subtitle: config.remoteUrl.isEmpty
                  ? 'wss://host:9030/rpc'
                  : config.remoteUrl,
              trailing: CcButton(
                onPressed: () => showTokenDialog(
                  context,
                  title: l10n.serverRemoteUrl,
                  initialValue: config.remoteUrl,
                  obscure: false,
                  save: notifier.setRemoteUrl,
                ),
                variant: CcButtonVariant.secondary,
                child: Text(l10n.edit),
              ),
            ),
            const SizedBox(height: 8),
            SettingsRow(
              icon: AppIcons.smartphone,
              title: l10n.serverRemoteDeviceId,
              subtitle: config.remoteDeviceId,
              trailing: CcButton(
                onPressed: () => showTokenDialog(
                  context,
                  title: l10n.serverRemoteDeviceId,
                  initialValue: config.remoteDeviceId,
                  obscure: false,
                  save: notifier.setRemoteDeviceId,
                ),
                variant: CcButtonVariant.secondary,
                child: Text(l10n.edit),
              ),
            ),
            const SizedBox(height: 8),
            SettingsRow(
              icon: AppIcons.radio,
              title: l10n.serverRemotePairingKey,
              subtitle: l10n.serverRemotePairingKeyHint,
              trailing: CcButton(
                onPressed: () async {
                  final existing = await notifier.readPairingKey() ?? '';
                  if (!context.mounted) {
                    return;
                  }
                  await showTokenDialog(
                    context,
                    title: l10n.serverRemotePairingKey,
                    initialValue: existing,
                    save: notifier.setPairingKey,
                  );
                },
                variant: CcButtonVariant.secondary,
                child: Text(l10n.edit),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(AppIcons.alertCircle, size: 14, color: t.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kIsWeb
                      ? l10n.serverConnectionReloadHint
                      : l10n.serverConnectionRestartHint,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
