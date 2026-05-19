import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/remote_control/domain/entities/paired_device.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pair additional clients to the connected `cc_server`: another web browser, a
/// desktop app, or a phone. Drives the server's `pairing.*` ops over the
/// connected RPC client (so it works wherever the app is a thin client — the
/// web build, or the desktop in remote mode). The server mints a device id +
/// pre-shared key; this panel surfaces them (and a one-tap pairing link) for
/// the new client to dial the server directly.
///
/// Web-safe: depends only on cc_ui + cc_data + cc_domain + the RPC client.
class ServerPairingPanel extends ConsumerStatefulWidget {
  /// Creates a [ServerPairingPanel].
  const ServerPairingPanel({super.key});

  @override
  ConsumerState<ServerPairingPanel> createState() => _ServerPairingPanelState();
}

class _ServerPairingPanelState extends ConsumerState<ServerPairingPanel> {
  late RemotePairingRepository _repo;
  Future<List<PairedDevice>>? _devices;

  final TextEditingController _name = TextEditingController();
  String _platform = 'web';
  bool _formOpen = false;
  bool _busy = false;
  String? _error;
  PairingMint? _minted;

  @override
  void initState() {
    super.initState();
    _repo = RemotePairingRepository(ref.read(rpcClientProvider));
    _devices = _repo.list();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _devices = _repo.list();
  });

  Future<void> _mint() async {
    final label = _name.text.trim();
    if (label.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final mint = await _repo.mint(label: label, platform: _platform);
      if (!mounted) {
        return;
      }
      setState(() {
        _minted = mint;
        _formOpen = false;
        _name.clear();
        _busy = false;
      });
      _reload();
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _revoke(String deviceId) async {
    try {
      await _repo.revoke(deviceId);
    } on Object catch (_) {
      // Best-effort: a failed revoke leaves the row; the reload reflects truth.
    }
    _reload();
  }

  /// Builds a one-tap deep link for pairing another first-party THIN CLIENT (web
  /// browser / desktop) that dials the server directly: this app's origin + a
  /// base64url-JSON fragment ({s: serverUrl, i: deviceId, k: psk}) the connect
  /// gate reads (the PSK rides in the fragment, never the query). Returns '' off
  /// the web (the executable has no http origin) — desktop-client pairing is a
  /// copy-the-fields flow there, not a link.
  String _directClientLink(PairingMint mint) {
    final base = Uri.base;
    if (base.scheme != 'http' && base.scheme != 'https') {
      return '';
    }
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({'s': mint.serverUrl, 'i': mint.deviceId, 'k': mint.psk}),
          ),
        )
        .replaceAll('=', '');
    return '${base.origin}/#$payload';
  }

  /// Builds the PHONE pairing deep link: the cc_remote PWA host + a relay
  /// payload fragment ({m: relay, s: signalingUrl, r: deviceId, k: psk}). The
  /// phone scans it, joins the broker room, and reaches cc_server through the
  /// relay — no direct reachability required. Rendered as a QR below.
  String _relayLink(PairingMint mint) {
    return PairingPayload.relay(
      signalingUrl: mint.signalingUrl,
      deviceId: mint.room,
      psk: mint.psk,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ).toDeepLink(PairingPayload.defaultPwaHost);
  }

  /// Whether the just-minted credential is for a phone (gets the relay QR).
  bool _isPhone(String platform) => platform == 'ios' || platform == 'android';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.pairedClients,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Description(text: l10n.pairedClientsDescription),
          const SizedBox(height: 12),
          if (_minted != null) _MintedCard(
            mint: _minted!,
            directLink: _directClientLink(_minted!),
            relayLink: _isPhone(_minted!.platform) && _minted!.canRelay
                ? _relayLink(_minted!)
                : null,
            onDismiss: () => setState(() => _minted = null),
          ),
          if (_formOpen) _PairForm(
            name: _name,
            platform: _platform,
            busy: _busy,
            error: _error,
            onPlatform: (p) => setState(() => _platform = p),
            onCancel: () => setState(() {
              _formOpen = false;
              _error = null;
            }),
            onPair: _mint,
          ) else Align(
            alignment: Alignment.centerLeft,
            child: CcButton(
              onPressed: () => setState(() {
                _formOpen = true;
                _minted = null;
              }),
              variant: CcButtonVariant.secondary,
              child: Text(l10n.pairNewClient),
            ),
          ),
          const SizedBox(height: 12),
          _DeviceList(future: _devices, onRevoke: _revoke),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.bodySm.copyWith(color: t.textTertiary),
    );
  }
}

class _PairForm extends StatelessWidget {
  const _PairForm({
    required this.name,
    required this.platform,
    required this.busy,
    required this.error,
    required this.onPlatform,
    required this.onCancel,
    required this.onPair,
  });

  final TextEditingController name;
  final String platform;
  final bool busy;
  final String? error;
  final ValueChanged<String> onPlatform;
  final VoidCallback onCancel;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTextField(
            controller: name,
            hintText: l10n.pairClientNameHint,
            enabled: !busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          CcSelect<String>(
            value: platform,
            onChanged: onPlatform,
            options: [
              CcSelectOption(value: 'web', label: l10n.pairClientTypeWeb),
              CcSelectOption(
                value: 'desktop',
                label: l10n.pairClientTypeDesktop,
              ),
              CcSelectOption(value: 'ios', label: l10n.pairClientTypePhone),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error!,
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                onPressed: busy ? null : onCancel,
                variant: CcButtonVariant.ghost,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                onPressed: busy ? null : onPair,
                variant: CcButtonVariant.accent,
                loading: busy,
                child: Text(l10n.pairAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MintedCard extends StatelessWidget {
  const _MintedCard({
    required this.mint,
    required this.directLink,
    required this.relayLink,
    required this.onDismiss,
  });

  final PairingMint mint;

  /// Direct-WS deep link for pairing another web/desktop thin client. '' off the
  /// web (no http origin to embed).
  final String directLink;

  /// Phone relay deep link (rendered as a QR) — null for non-phone mints.
  final String? relayLink;

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final relay = relayLink;
    return CcCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (relay != null) ...[
            // Phone: scan the QR with the camera. The link points the cc_remote
            // PWA at the broker + room; cc_server is already waiting there.
            Text(
              l10n.pairScanQr,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: const Color(0xFFFFFFFF),
                child: QrImageView(
                  data: relay,
                  size: 200,
                  backgroundColor: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CopyRow(label: l10n.pairLinkLabel, value: relay),
            _CopyRow(label: l10n.serverRemotePairingKey, value: mint.psk),
          ] else if (directLink.isNotEmpty || mint.isDirectlyReachable) ...[
            Text(
              l10n.pairCredentialsIntro,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (directLink.isNotEmpty)
              _CopyRow(label: l10n.pairLinkLabel, value: directLink),
            _CopyRow(label: l10n.serverRemoteUrl, value: mint.serverUrl),
            _CopyRow(label: l10n.serverRemoteDeviceId, value: mint.deviceId),
            _CopyRow(label: l10n.serverRemotePairingKey, value: mint.psk),
          ] else
            CcAlert(
              variant: CcAlertVariant.warning,
              title: l10n.pairServerUnreachableTitle,
              description: Text(
                l10n.pairServerUnreachable,
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: CcButton(
              onPressed: onDismiss,
              variant: CcButtonVariant.ghost,
              child: Text(l10n.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcFonts.code(
                textStyle: CcTypography.bodySm,
              ).copyWith(color: t.textSecondary),
            ),
          ),
          CcButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: value)),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.copy),
          ),
        ],
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.future, required this.onRevoke});
  final Future<List<PairedDevice>>? future;
  final ValueChanged<String> onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return FutureBuilder<List<PairedDevice>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CcSpinner()),
          );
        }
        final devices = snap.data ?? const <PairedDevice>[];
        if (devices.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              l10n.noPairedClients,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          );
        }
        return Column(
          children: [
            for (final d in devices)
              SettingsRow(
                icon: _iconFor(d.platform),
                title: d.label,
                subtitle: '${d.platform} · ${d.status}',
                trailing: CcButton(
                  onPressed: () => onRevoke(d.id),
                  variant: CcButtonVariant.ghost,
                  child: Text(l10n.revoke),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _iconFor(String platform) => switch (platform) {
    'web' => AppIcons.globe,
    'desktop' => AppIcons.monitor,
    'ios' || 'android' => AppIcons.smartphone,
    _ => AppIcons.radio,
  };
}
