import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_health.dart';
import 'package:control_center/features/connect/presentation/widgets/connect_mode_options.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A workspace's choice in words, as the facts row and the radio name it.
String workspaceConnectModeLabel(
  AppLocalizations l10n,
  WorkspaceConnectMode mode,
) => switch (mode) {
  WorkspaceConnectMode.inherit => l10n.workspaceConnectModeInherit,
  WorkspaceConnectMode.hosted => l10n.connectModeHosted,
  WorkspaceConnectMode.custom => l10n.connectModeCustom,
  WorkspaceConnectMode.own => l10n.connectModeOwn,
};

/// What "Same as this server" currently means: the server's own choice.
String workspaceConnectInheritHint(
  AppLocalizations l10n,
  WorkspaceConnectStatus status,
) => switch (status.serverMode) {
  ServerConnectChoice.hosted => l10n.workspaceConnectInheritHosted,
  ServerConnectChoice.custom => l10n.workspaceConnectInheritCustom(
    status.serverUrl,
  ),
  ServerConnectChoice.off => l10n.workspaceConnectInheritOwn,
  ServerConnectChoice.unset => l10n.workspaceConnectInheritUnset,
};

/// The four radio rows. [canEdit] false (a member) greys every row out;
/// [WorkspaceConnectStatus.locked] greys out the two Connect rows, which
/// `CC_CONNECT_URL` forbids here.
List<ConnectChoice<WorkspaceConnectMode>> workspaceConnectChoices(
  AppLocalizations l10n,
  WorkspaceConnectStatus status, {
  required bool canEdit,
}) {
  final connectAllowed = canEdit && !status.locked;
  return [
    ConnectChoice(
      value: WorkspaceConnectMode.inherit,
      title: l10n.workspaceConnectModeInherit,
      hint: workspaceConnectInheritHint(l10n, status),
      enabled: canEdit,
    ),
    ConnectChoice(
      value: WorkspaceConnectMode.hosted,
      title: l10n.connectModeHosted,
      hint: l10n.connectModeHostedDisclosure,
      enabled: connectAllowed,
    ),
    ConnectChoice(
      value: WorkspaceConnectMode.own,
      title: l10n.connectModeOwn,
      hint: l10n.workspaceConnectOwnHint,
      enabled: canEdit,
    ),
    ConnectChoice(
      value: WorkspaceConnectMode.custom,
      title: l10n.connectModeCustom,
      hint: l10n.connectModeCustomHint,
      enabled: connectAllowed,
    ),
  ];
}

/// The facts row: the choice, whether its Connect works, and the
/// configuration version while a Connect is in use.
class WorkspaceConnectFacts extends StatelessWidget {
  /// Creates the facts for [status].
  const WorkspaceConnectFacts({super.key, required this.status});

  /// What the server reported.
  final WorkspaceConnectStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final epoch = status.epoch;
    return SettingsSummary(
      facts: [
        SettingsFact(
          label: l10n.connectFactMode,
          value: workspaceConnectModeLabel(l10n, status.mode),
        ),
        SettingsFact(
          label: l10n.connectFactHealth,
          value: switch (status.health) {
            WorkspaceConnectHealth.off => l10n.connectHealthOff,
            WorkspaceConnectHealth.ok => l10n.connectHealthOk,
            WorkspaceConnectHealth.down => l10n.connectHealthDown,
          },
          tone: switch (status.health) {
            WorkspaceConnectHealth.off => null,
            WorkspaceConnectHealth.ok => CcStatusTone.positive,
            WorkspaceConnectHealth.down => CcStatusTone.negative,
          },
        ),
        if (epoch != null && status.effectiveMode.usesConnect)
          SettingsFact(label: l10n.connectFactEpoch, value: '$epoch'),
      ],
    );
  }
}

/// [status]'s lanes as [ConnectLaneList] rows.
List<ConnectLaneRow> workspaceConnectLaneRows(
  AppLocalizations l10n,
  WorkspaceConnectStatus status,
) => [
  for (final lane in status.lanes)
    ConnectLaneRow(
      provider: lane.provider,
      sourceLabel: switch (lane.source) {
        WorkspaceLaneSource.workspaceOwn =>
          l10n.workspaceConnectLaneWorkspaceOwn,
        WorkspaceLaneSource.serverOwn => l10n.workspaceConnectLaneServerOwn,
        WorkspaceLaneSource.connect => l10n.connectLaneSourceConnect,
        WorkspaceLaneSource.off => l10n.connectLaneSourceOff,
      },
      running: lane.source != WorkspaceLaneSource.off,
      error: lane.error,
    ),
];

/// The admin's tools for the Connect in use: this server's install id on it
/// (what a Connect operator allowlists) and a configuration test.
class WorkspaceConnectAdminActions extends StatelessWidget {
  /// Creates the actions.
  const WorkspaceConnectAdminActions({
    super.key,
    required this.installId,
    required this.testing,
    required this.onTest,
  });

  /// This server's install id on that Connect (empty before first use).
  final String installId;

  /// Whether a test is in flight.
  final bool testing;

  /// Runs the test.
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsGroup(
      gap: AppSpacing.md,
      children: [
        SettingsField(
          label: l10n.connectInstallId,
          description: l10n.connectInstallIdHint,
          layout: SettingsFieldLayout.stacked,
          child: SettingsCopyField(
            value: installId,
            emptyLabel: l10n.connectInstallIdEmpty,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.refreshCw,
            loading: testing,
            onPressed: testing ? null : onTest,
            child: Text(l10n.testLabel),
          ),
        ),
      ],
    );
  }
}
