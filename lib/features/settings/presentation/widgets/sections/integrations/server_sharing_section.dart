import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Advanced section for sharing this server (PRD 15 §5): mDNS
/// advertisement state, the tunnel-provider opt-in (`connectivity.setTunnel`),
/// the tunnel's public URL when up and the relay usage this month.
///
/// Public exposure is strictly opt-in — the copy says so — and pairing
/// invites embed the server's current addresses automatically (descriptor
/// refresh), so a new tunnel URL propagates without re-pairing. Renders a
/// quiet "not available" row when the server doesn't expose the
/// `connectivity.*` ops (older binary, or no network runtime).
class ServerSharingSection extends ConsumerStatefulWidget {
  /// Creates a [ServerSharingSection].
  const ServerSharingSection({super.key});

  @override
  ConsumerState<ServerSharingSection> createState() =>
      _ServerSharingSectionState();
}

class _ServerSharingSectionState extends ConsumerState<ServerSharingSection> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _unavailable = false;
  bool _busy = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ref
          .read(rpcClientProvider)
          .call('connectivity.status', const {});
      if (!mounted) {
        return;
      }
      setState(() {
        _status = res;
        _loading = false;
        _unavailable = false;
      });
    } on Object {
      // Unknown op (-33006 on an older server), no network runtime, or a
      // transport failure — either way there is nothing to control here.
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _unavailable = true;
      });
    }
    _syncPolling();
  }

  Future<void> _setTunnel(String provider) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await ref.read(rpcClientProvider).call(
        'connectivity.setTunnel',
        {'provider': provider},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _status = res;
        _busy = false;
      });
      _syncPolling();
    } on Object catch (e) {
      // Owner-only AuthException (and validation errors) surface as the
      // RemoteRpcException message — show it, keep the previous state.
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '$e'.replaceFirst(
          RegExp(r'^RemoteRpcException\(-?\d+\): '),
          '',
        );
      });
    }
  }

  /// While a tunnel is starting, refresh until it settles (up or error) so
  /// the public URL appears without a manual reload.
  void _syncPolling() {
    final starting = _tunnel?['state'] == 'starting';
    if (starting && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
    } else if (!starting) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Map<String, dynamic>? get _tunnel =>
      (_status?['tunnel'] as Map?)?.cast<String, dynamic>();

  Map<String, dynamic>? get _relay =>
      (_status?['relay'] as Map?)?.cast<String, dynamic>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return SectionCard(
      label: l10n.serverSharingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CcSpinner()),
            )
          else if (_unavailable)
            Text(
              l10n.serverSharingUnavailable,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          else ...[
            Text(
              l10n.serverSharingDescription,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            SettingsRow(
              icon: AppIcons.radio,
              title: l10n.serverSharingMdnsLabel,
              subtitle: _status?['mdns'] == true
                  ? l10n.serverSharingMdnsOn
                  : l10n.serverSharingMdnsOff,
              trailing: const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),
            CcSelect<String>(
              label: l10n.serverSharingTunnelLabel,
              helperText: l10n.serverSharingTunnelHelper,
              enabled: !_busy,
              value: _status?['tunnel_provider'] as String? ?? 'off',
              options: [
                CcSelectOption(
                  value: 'off',
                  label: l10n.serverSharingProviderOff,
                ),
                CcSelectOption(
                  value: 'cloudflared',
                  label: l10n.serverSharingProviderCloudflared,
                ),
                CcSelectOption(
                  value: 'ngrok',
                  label: l10n.serverSharingProviderNgrok,
                ),
                CcSelectOption(
                  value: 'tailscale',
                  label: l10n.serverSharingProviderTailscale,
                ),
              ],
              onChanged: _setTunnel,
            ),
            ..._tunnelStatusRows(l10n, t),
            if (_relay != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SettingsRow(
                icon: AppIcons.cloud,
                title: l10n.serverSharingRelayLabel,
                subtitle: _relaySubtitle(l10n),
                trailing: const SizedBox.shrink(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              CcAlert(
                variant: CcAlertVariant.danger,
                title: l10n.serverSharingUpdateFailedTitle,
                description: Text(
                  _error!,
                  style: CcTypography.bodySm.copyWith(
                    color: t.textErrorPrimary,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _tunnelStatusRows(AppLocalizations l10n, DesignSystemTokens t) {
    final tunnel = _tunnel;
    if (tunnel == null) {
      return const [];
    }
    final state = tunnel['state'] as String? ?? 'off';
    final publicUrl = tunnel['publicUrl'] as String?;
    switch (state) {
      case 'starting':
        return [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const CcSpinner(size: 12),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.serverSharingTunnelStarting,
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ];
      case 'up':
        if (publicUrl == null || publicUrl.isEmpty) {
          // A cloudflared named tunnel prints no URL — the operator's DNS
          // hostname is the address.
          return [
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.serverSharingTunnelUpNoUrl,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ];
        }
        return [
          const SizedBox(height: AppSpacing.sm),
          _CopyRow(label: l10n.serverSharingPublicUrlLabel, value: publicUrl),
        ];
      case 'error':
        return [
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.serverSharingTunnelError(tunnel['error'] as String? ?? ''),
            style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
          ),
        ];
      default:
        return const [];
    }
  }

  String _relaySubtitle(AppLocalizations l10n) {
    final relay = _relay!;
    final chars = (relay['chars_this_month'] as num?) ?? 0;
    return [
      l10n.serverSharingRelayUsage(_formatBytes(chars)),
      if (relay['connected'] == true)
        l10n.serverSharingRelaySessions(
          (relay['sessions'] as num?)?.toInt() ?? 0,
        ),
    ].join(' · ');
  }

  /// Relay chars are ~bytes on the wire — format as a human byte size.
  static String _formatBytes(num chars) {
    final bytes = chars.toDouble();
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    }
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }
    return '${bytes.toStringAsFixed(0)} B';
  }
}

/// Label + monospaced value + copy button (the pairing-panel treatment); the
/// copy confirms with a toast.
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        SizedBox(
          width: 110,
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
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              CcToastScope.of(context).show(l10n.copied);
            }
          },
          variant: CcButtonVariant.ghost,
          child: Text(l10n.copy),
        ),
      ],
    );
  }
}
