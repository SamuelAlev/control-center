import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_rows.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Spaces with questions listed before leaving the rest to the inbox.
const int _maxWaiting = 5;

/// What waits on the operator: spaces with agent questions, and approvals.
///
/// A waiting space is the sidebar's row in its needs-input state, with the
/// question count beside the mark; the spaces list below leaves it out.
/// Absent when nothing waits, or while the connection is down (the counts
/// are not current then).
class TrayNeedsYouSection extends StatelessWidget {
  /// Creates a [TrayNeedsYouSection].
  const TrayNeedsYouSection({required this.status, super.key});

  /// The tray's status.
  final TrayStatus status;

  @override
  Widget build(BuildContext context) {
    final workspaceId = status.workspaceId;
    if (workspaceId == null ||
        status.connection != TrayConnection.online ||
        status.needsYou == 0) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final actions = TrayPanelScope.of(context);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return CcSidebarGroup(
      label: l10n.trayPanelNeedsYou,
      children: [
        for (final space in status.attention.take(_maxWaiting))
          _WaitingSpace(
            key: ValueKey(space.spaceId),
            space: space,
            count: number.format(space.openQuestions),
            onPress: () =>
                actions.openRoute(spaceRoute(workspaceId, space.spaceId)),
          ),
        if (status.approvals > 0)
          TrayPanelLinkRow(
            icon: AppIcons.shieldAlert,
            iconColor: t.warn,
            label: l10n.trayPanelApprovals,
            trailingLabel: number.format(status.approvals),
            onPress: () => actions.openRoute(inboxRoute(workspaceId)),
          ),
      ],
    );
  }
}

class _WaitingSpace extends ConsumerWidget implements CcFluidHoverTarget {
  const _WaitingSpace({
    required this.space,
    required this.count,
    required this.onPress,
    super.key,
  });

  final TrayAttentionSpace space;
  final String count;
  final VoidCallback onPress;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SpaceRow(
      leading: SpaceLeadingIcon(
        spaceId: space.spaceId,
        running: false,
        selected: false,
        absent: const SpaceStatusMark(),
      ),
      label: space.name.isEmpty ? l10n.spaceLabel : space.name,
      selected: false,
      status: SpaceStatus.needsInput,
      unread: false,
      leadingHandlesRunning: true,
      trailingLabel: count,
      onPress: onPress,
    );
  }
}
