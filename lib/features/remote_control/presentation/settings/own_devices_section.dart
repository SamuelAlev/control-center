import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's own paired devices: label, platform, pairing/last-seen
/// timing, with rename and revoke actions over the server's `pairing.*` ops.
class OwnDevicesSection extends ConsumerWidget {
  /// Creates an [OwnDevicesSection].
  const OwnDevicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final devicesAsync = ref.watch(ownDevicesProvider);

    return SectionCard(
      label: l10n.yourDevices,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.yourDevicesDescription,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 8),
          devicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CcSpinner()),
            ),
            error: (e, _) => Text(
              l10n.couldNotListDevices('$e'),
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
            data: (devices) {
              if (devices.isEmpty) {
                return Text(
                  l10n.noOwnDevices,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                );
              }
              return Column(
                children: [
                  for (final device in devices) _DeviceRow(device: device),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends ConsumerStatefulWidget {
  const _DeviceRow({required this.device});

  /// The `pairing.watchOwn` wire map (`device_id`, `label`, `platform`,
  /// `status`, `paired_at`, `last_seen_at`).
  final Map<String, dynamic> device;

  @override
  ConsumerState<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends ConsumerState<_DeviceRow> {
  bool _hovered = false;

  String get _id =>
      (widget.device['device_id'] ?? widget.device['id'] ?? '') as String;
  String get _label => widget.device['label'] as String? ?? '';
  String get _platform => widget.device['platform'] as String? ?? '';
  String get _status => widget.device['status'] as String? ?? '';

  DateTime? _time(String key) {
    final raw = widget.device[key];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _hovered ? t.bgPrimaryHover : null,
          borderRadius: AppRadii.brSm,
        ),
        child: SettingsRow(
          icon: _platformIcon,
          title: _label.isEmpty ? _id : _label,
          subtitle: _subtitle(l10n),
          subtitleWidget: _subtitleWidget(
            l10n,
            CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          // Row actions ride on hover (space reserved so the row never
          // shifts); invisible ones don't intercept clicks.
          trailing: IgnorePointer(
            ignoring: !_hovered,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _hovered ? 1 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CcButton(
                    variant: CcButtonVariant.ghost,
                    onPressed: () => _rename(context, ref, l10n),
                    child: Text(l10n.rename),
                  ),
                  const SizedBox(width: 8),
                  CcButton(
                    variant: CcButtonVariant.destructive,
                    onPressed: () => _confirmRevoke(context, ref, l10n),
                    child: Text(l10n.revoke),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) {
    final pairedAt = _time('paired_at');
    final lastSeen = _time('last_seen_at');
    final parts = [
      _platformLabel(l10n),
      _status,
      if (pairedAt != null)
        l10n.devicePairedTime(relativeTimeLabel(l10n, pairedAt)),
      lastSeen != null
          ? l10n.deviceLastSeenTime(relativeTimeLabel(l10n, lastSeen))
          : l10n.deviceNeverSeen,
    ];
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  /// The subtitle as widgets so the paired/last-seen instants each carry the
  /// shared accessibility timestamp hover card. Non-instant parts (platform,
  /// status, "never seen") render as plain text; ' · ' separates them.
  Widget _subtitleWidget(AppLocalizations l10n, TextStyle style) {
    final pairedAt = _time('paired_at');
    final lastSeen = _time('last_seen_at');
    final platform = _platformLabel(l10n);
    final segments = <Widget>[
      if (platform.isNotEmpty) Text(platform, style: style),
      if (_status.isNotEmpty) Text(_status, style: style),
      if (pairedAt != null)
        AppTimestamp(
          dateTime: pairedAt,
          child: Text(
            l10n.devicePairedTime(relativeTimeLabel(l10n, pairedAt)),
            style: style,
          ),
        ),
      if (lastSeen != null)
        AppTimestamp(
          dateTime: lastSeen,
          child: Text(
            l10n.deviceLastSeenTime(relativeTimeLabel(l10n, lastSeen)),
            style: style,
          ),
        )
      else
        Text(l10n.deviceNeverSeen, style: style),
    ];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) Text(' · ', style: style),
          segments[i],
        ],
      ],
    );
  }

  String _platformLabel(AppLocalizations l10n) => switch (_platform) {
    'web' => l10n.pairClientTypeWeb,
    'desktop' => l10n.pairClientTypeDesktop,
    'ios' || 'android' => l10n.pairClientTypePhone,
    _ => _platform,
  };

  IconData get _platformIcon => switch (_platform) {
    'web' => AppIcons.globe,
    'desktop' => AppIcons.monitor,
    'ios' || 'android' => AppIcons.smartphone,
    _ => AppIcons.radio,
  };

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) => showTokenDialog(
    context,
    title: l10n.renameDeviceTitle,
    initialValue: _label,
    obscure: false,
    save: (value) async {
      final label = value.trim();
      if (label.isEmpty || label == _label) {
        return;
      }
      await ref.read(rpcClientProvider).call('pairing.rename', {
        'device_id': _id,
        'label': label,
      });
    },
  );

  Future<void> _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CcDialog(
        title: l10n.revokeDeviceTitle,
        content: Text(l10n.revokeDeviceConfirm(_label.isEmpty ? _id : _label)),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.revoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(rpcClientProvider).call('pairing.revoke', {
        'device_id': _id,
      });
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }
}
