import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
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
///
/// Shared by the server's Connect card and a workspace's, so both explain a
/// failure in the same words.
class ConnectHealthAlerts extends StatelessWidget {
  /// Creates the alerts.
  const ConnectHealthAlerts({
    super.key,
    required this.error,
    required this.stale,
    this.pendingPins,
    this.onConfirmPins,
    this.confirming = false,
  });

  /// Why Connect is not usable, or [ConnectHealthError.none].
  final ConnectHealthError error;

  /// Whether the configuration in use is a cached copy past its refresh.
  final bool stale;

  /// New signing pins waiting for confirmation; null when there are none or
  /// the reader may not see them.
  final Map<String, String>? pendingPins;

  /// Accepts the pending pins; null hides the action (the reader may not).
  final VoidCallback? onConfirmPins;

  /// Whether the confirmation is in flight.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pins = pendingPins;
    final alerts = <Widget>[
      if (error != ConnectHealthError.none &&
          error != ConnectHealthError.pinsChanged)
        CcAlert(
          title: connectHealthMessage(l10n, error),
          variant:
              error == ConnectHealthError.hostedUnprovisioned ||
                  error == ConnectHealthError.unreachable
              ? CcAlertVariant.warning
              : CcAlertVariant.danger,
        ),
      if (pins != null || error == ConnectHealthError.pinsChanged)
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
          action: onConfirmPins == null
              ? null
              : CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  loading: confirming,
                  onPressed: confirming || pins == null ? null : onConfirmPins,
                  child: Text(l10n.connectConfirmPins),
                ),
        ),
      if (stale)
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

/// One provider in a [ConnectLaneList]: its name, where it runs, and what is
/// wrong with it.
@immutable
class ConnectLaneRow {
  /// Creates a row.
  const ConnectLaneRow({
    required this.provider,
    required this.sourceLabel,
    required this.running,
    this.error = '',
  });

  /// One lane of `connect.status`.
  factory ConnectLaneRow.fromServer(
    AppLocalizations l10n,
    ConnectLaneStatus lane,
  ) => ConnectLaneRow(
    provider: lane.lane,
    sourceLabel: switch (lane.source) {
      ConnectLaneSource.own => l10n.connectLaneSourceOwn,
      ConnectLaneSource.connect => l10n.connectLaneSourceConnect,
      ConnectLaneSource.off => l10n.connectLaneSourceOff,
    },
    running: lane.source != ConnectLaneSource.off,
    error: lane.error,
  );

  /// The provider's wire id (`github`, `google`, `linear`, `slack`, `klipy`).
  final String provider;

  /// Where it runs, in words.
  final String sourceLabel;

  /// Whether anything runs it at all (false reads as off).
  final bool running;

  /// Why it does not work, already phrased for a person; empty when it does.
  final String error;
}

/// The provider's name as people know it; brand names stay untranslated.
String connectLaneName(String provider) => switch (provider) {
  'github' => 'GitHub',
  'google' => 'Google Calendar',
  'linear' => 'Linear',
  'slack' => 'Slack',
  'klipy' => 'KLIPY',
  _ => provider,
};

/// Every lane and where its credentials come from.
class ConnectLaneList extends StatelessWidget {
  /// Creates the list.
  const ConnectLaneList({super.key, required this.rows});

  /// The lanes, in the server's order.
  final List<ConnectLaneRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 132,
                  child: Text(
                    connectLaneName(row.provider),
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
                CcStatusTag(
                  label: row.sourceLabel,
                  tone: row.error.isNotEmpty
                      ? CcStatusTone.negative
                      : row.running
                      ? CcStatusTone.positive
                      : CcStatusTone.neutral,
                ),
                if (row.error.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      row.error,
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
