import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/server_build_provider.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/server_discovery_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Integrations section for the client's paired servers (PRD 15
/// §10): the local in-app server (desktop), every paired remote server with
/// its identity fingerprint, in-app switching, and adding a server by invite
/// code / URL — the URL field carries a discovery button listing `cc_server`
/// instances found on the LAN (mDNS) and the tailnet (desktop).
class ServerConnectionSection extends ConsumerStatefulWidget {
  /// Creates a [ServerConnectionSection].
  const ServerConnectionSection({super.key});

  @override
  ConsumerState<ServerConnectionSection> createState() =>
      _ServerConnectionSectionState();
}

class _ServerConnectionSectionState
    extends ConsumerState<ServerConnectionSection> {
  Object? _actionError;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _actionError = null);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _actionError = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serverListProvider);
    final notifier = ref.read(serverListProvider.notifier);
    final l10n = AppLocalizations.of(context);
    // Stale-binary detection (LOCAL mode): the spawned prebuilt cc_server is
    // older than this app — the honest explanation for missing-op errors
    // after an update. Same comparison the About section shows.
    final serverBuild = ref.watch(serverBuildProvider);
    final staleLocal =
        state.currentServerId == 'local' &&
        serverOlderThanClient(serverBuild) == true;

    return SectionCard(
      label: l10n.serverConnection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!kIsWeb) ...[
            _ServerRow(
              icon: AppIcons.monitor,
              title: l10n.serverModeLocal,
              subtitle: serverBuild?.version == null
                  ? l10n.serverModeLocalDescription
                  : '${l10n.serverModeLocalDescription} · ${serverBuild!.version}',
              isActive: state.currentServerId == 'local',
              busy: state.busy,
              onSwitch: () => _run(() => notifier.switchTo('local')),
            ),
            if (staleLocal) ...[
              const SizedBox(height: 8),
              CcAlert(
                title: l10n.serverStaleTitle,
                description: Text(
                  l10n.serverStaleBody(
                    serverBuild!.version ?? '?',
                    BuildInfo.buildVersion,
                  ),
                ),
                variant: CcAlertVariant.warning,
                icon: AppIcons.alertTriangle,
              ),
            ],
            const SizedBox(height: 8),
          ],
          for (final entry in state.entries) ...[
            _ServerRow(
              icon: AppIcons.cloud,
              title: entry.name,
              subtitle: _entrySubtitle(entry),
              isActive: state.currentServerId == entry.serverId,
              insecure: entry.descriptor.insecureAllowed,
              busy: state.busy,
              onSwitch: () => _run(() => notifier.switchTo(entry.serverId)),
              onRemove: state.currentServerId == entry.serverId
                  ? null
                  : () => _run(() => notifier.remove(entry.serverId)),
              removeHint: state.currentServerId == entry.serverId
                  ? l10n.serverListRemoveActiveHint
                  : null,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              CcButton(
                onPressed: state.busy ? null : _showAddDialog,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.serverListAddTitle),
              ),
            ],
          ),
          if (_actionError != null) ...[
            const SizedBox(height: 8),
            ConnectionErrorAlert(
              error: _actionError!,
              title: l10n.serverSwitchFailedTitle,
            ),
          ],
        ],
      ),
    );
  }

  String _entrySubtitle(ServerEntry entry) {
    final fp = entry.pinnedFingerprint;
    final shortFp = fp.length > 12 ? fp.substring(0, 12) : fp;
    final firstPath = entry.descriptor.paths.firstOrNull?.rpcUri?.toString();
    return firstPath == null ? shortFp : '$firstPath · $shortFp';
  }

  Future<void> _showAddDialog({String prefillUrl = ''}) async {
    final l10n = AppLocalizations.of(context);
    final pairedIds = {
      for (final e in ref.read(serverListProvider).entries) e.serverId,
    };
    final url = TextEditingController(text: prefillUrl);
    final invite = TextEditingController();
    final device = TextEditingController();
    final psk = TextEditingController();
    try {
      final confirmed = await showCcDialog<bool>(
        context: context,
        builder: (dialogContext) => CcDialog(
          title: l10n.serverListAddTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextField(
                controller: url,
                hintText: 'wss://host:9030/rpc',
                autofocus: true,
                // LAN + tailnet discovery behind a suffix button (desktop
                // only — a browser can neither browse mDNS nor probe the
                // tailnet). A pick fills this field; already-paired servers
                // are hidden.
                suffix: kIsWeb
                    ? null
                    : ServerDiscoveryButton(
                        excludeServerIds: pairedIds,
                        onSelected: (server) => url.text = server.rpcUrl,
                      ),
              ),
              const SizedBox(height: 8),
              CcTextField(
                controller: invite,
                hintText: l10n.serverSetupInviteCodeHint,
              ),
              const SizedBox(height: 8),
              CcTextField(
                controller: device,
                hintText: l10n.serverRemoteDeviceId,
              ),
              const SizedBox(height: 8),
              CcTextField(
                controller: psk,
                hintText: l10n.serverRemotePairingKey,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              variant: CcButtonVariant.secondary,
              child: Text(l10n.cancel),
            ),
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              variant: CcButtonVariant.accent,
              child: Text(l10n.serverSetupConnect),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await _run(
        () => ref
            .read(serverListProvider.notifier)
            .addServer(
              rawUrl: url.text,
              inviteCode: invite.text,
              deviceId: device.text.trim(),
              psk: psk.text.trim(),
            ),
      );
    } finally {
      url.dispose();
      invite.dispose();
      device.dispose();
      psk.dispose();
    }
  }
}

/// One server row: identity, active badge or switch action, optional remove.
class _ServerRow extends StatelessWidget {
  const _ServerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.busy,
    this.insecure = false,
    this.onSwitch,
    this.onRemove,
    this.removeHint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool busy;
  final bool insecure;
  final VoidCallback? onSwitch;
  final VoidCallback? onRemove;
  final String? removeHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        Icon(icon, size: 18, color: isActive ? t.fgBrandPrimary : t.fgTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (insecure) ...[
                    const SizedBox(width: 8),
                    CcBadge(
                      label: l10n.serverListInsecureBadge,
                      variant: CcBadgeVariant.danger,
                    ),
                  ],
                ],
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isActive)
          CcBadge(label: l10n.serverListActive, variant: CcBadgeVariant.success)
        else if (onSwitch != null)
          CcButton(
            onPressed: busy ? null : onSwitch,
            variant: CcButtonVariant.secondary,
            child: Text(l10n.serverListSwitch),
          ),
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          CcButton(
            onPressed: busy ? null : onRemove,
            variant: CcButtonVariant.destructive,
            child: Text(l10n.remove),
          ),
        ],
      ],
    );
  }
}
