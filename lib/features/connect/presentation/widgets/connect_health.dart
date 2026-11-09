import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What a Connect health code means for the operator, and what to do.
String connectHealthMessage(AppLocalizations l10n, ConnectHealthError error) =>
    switch (error) {
      ConnectHealthError.none => '',
      ConnectHealthError.hostedUnprovisioned =>
        l10n.connectErrorHostedUnprovisioned,
      ConnectHealthError.signature => l10n.connectErrorSignature,
      ConnectHealthError.rollback => l10n.connectErrorRollback,
      ConnectHealthError.unreachable => l10n.connectErrorUnreachable,
      ConnectHealthError.installBlocked => l10n.connectErrorInstallBlocked,
      ConnectHealthError.pinsChanged => l10n.connectErrorPinsChanged,
      ConnectHealthError.protocol => l10n.connectErrorProtocol,
      ConnectHealthError.unknown => l10n.connectErrorUnknown,
    };

/// The mode in words.
String connectModeLabel(AppLocalizations l10n, ConnectModeSetting mode) =>
    switch (mode) {
      ConnectModeSetting.unset => l10n.connectModeUnset,
      ConnectModeSetting.hosted => l10n.connectModeHosted,
      ConnectModeSetting.custom => l10n.connectModeCustom,
      ConnectModeSetting.off => l10n.connectModeOwn,
    };

/// Everything wrong with Connect right now, most urgent first: the health
/// error, new signing keys waiting for confirmation, a stale configuration.
class ConnectHealthAlerts extends StatelessWidget {
  /// Creates the alerts.
  const ConnectHealthAlerts({
    super.key,
    required this.status,
    required this.onConfirmPins,
    required this.confirming,
  });

  /// The status to report on.
  final ConnectStatus status;

  /// Accepts the pending pins.
  final VoidCallback onConfirmPins;

  /// Whether the confirmation is in flight.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pins = status.pendingPins;
    final alerts = <Widget>[
      if (status.error != ConnectHealthError.none &&
          status.error != ConnectHealthError.pinsChanged)
        CcAlert(
          title: connectHealthMessage(l10n, status.error),
          variant:
              status.error == ConnectHealthError.hostedUnprovisioned ||
                  status.error == ConnectHealthError.unreachable
              ? CcAlertVariant.warning
              : CcAlertVariant.danger,
        ),
      if (pins != null || status.error == ConnectHealthError.pinsChanged)
        CcAlert(
          title: l10n.connectErrorPinsChanged,
          icon: AppIcons.shieldAlert,
          variant: CcAlertVariant.warning,
          description: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.connectPinsConfirmHint),
              for (final pin in (pins ?? const <String, String>{}).entries)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  // RTL carve-out: key ids and fingerprints are machine
                  // strings.
                  child: Text(
                    '${pin.key}  ${pin.value}',
                    textDirection: TextDirection.ltr,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          action: CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: confirming,
            onPressed: confirming || pins == null ? null : onConfirmPins,
            child: Text(l10n.connectConfirmPins),
          ),
        ),
      if (status.stale)
        CcAlert(title: l10n.connectStale, variant: CcAlertVariant.warning),
    ];
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          alerts[i],
        ],
      ],
    );
  }
}

/// Every lane and where its credentials come from.
class ConnectLaneList extends StatelessWidget {
  /// Creates the list.
  const ConnectLaneList({super.key, required this.lanes});

  /// The lanes, in the server's order.
  final List<ConnectLaneStatus> lanes;

  static String _name(String lane) => switch (lane) {
    'github' => 'GitHub',
    'google' => 'Google Calendar',
    'linear' => 'Linear',
    'slack' => 'Slack',
    'klipy' => 'KLIPY',
    _ => lane,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final lane in lanes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 132,
                  child: Text(
                    _name(lane.lane),
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
                CcStatusTag(
                  label: switch (lane.source) {
                    ConnectLaneSource.own => l10n.connectLaneSourceOwn,
                    ConnectLaneSource.connect => l10n.connectLaneSourceConnect,
                    ConnectLaneSource.off => l10n.connectLaneSourceOff,
                  },
                  tone: lane.error.isNotEmpty
                      ? CcStatusTone.negative
                      : lane.source == ConnectLaneSource.off
                      ? CcStatusTone.neutral
                      : CcStatusTone.positive,
                ),
                if (lane.error.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      lane.error,
                      style: CcTypography.caption.copyWith(
                        color: t.textErrorPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
