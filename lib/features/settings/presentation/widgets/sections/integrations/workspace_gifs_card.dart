import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/providers/workspace_connect_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_own_app_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_provider_app_detail.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Integrations → GIFs: where GIF search runs here.
///
/// Everyone sees the one-line answer, read from the workspace's Connect
/// lanes. An admin of a workspace on its own apps also gets the Klipy key
/// field, since that key is then the only way GIF search works here. Shown
/// while there is either to show ([watchWorkspaceGifsApplies]).
class WorkspaceGifsCard extends ConsumerWidget {
  /// Creates a [WorkspaceGifsCard].
  const WorkspaceGifsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final lane = _klipyLane(ref, workspaceId);
    final app = _klipyApp(ref, workspaceId);
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.workspaceGifsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lane != null) ...[
            Text(
              _sourceLine(l10n, lane.source),
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            if (lane.error.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                lane.error,
                style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
              ),
            ],
          ],
          if (app != null) ...[
            if (lane != null) const SizedBox(height: AppSpacing.lg),
            WorkspaceProviderAppDetail(app: app),
          ],
        ],
      ),
    );
  }

  static String _sourceLine(
    AppLocalizations l10n,
    WorkspaceLaneSource source,
  ) => switch (source) {
    WorkspaceLaneSource.workspaceOwn => l10n.workspaceGifsSourceWorkspaceOwn,
    WorkspaceLaneSource.serverOwn => l10n.workspaceGifsSourceServerOwn,
    WorkspaceLaneSource.connect => l10n.workspaceGifsSourceConnect,
    WorkspaceLaneSource.off => l10n.workspaceGifsSourceOff,
  };
}

/// Whether [WorkspaceGifsCard] has anything to say: inside a workspace, once
/// its GIF lane is known or while the reader can set the workspace's own
/// Klipy key.
bool watchWorkspaceGifsApplies(WidgetRef ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return workspaceId != null &&
      (_klipyLane(ref, workspaceId) != null ||
          _klipyApp(ref, workspaceId) != null);
}

/// Where GIF search runs in [workspaceId], once its Connect lanes are known.
WorkspaceConnectLane? _klipyLane(WidgetRef ref, String workspaceId) => ref
    .watch(workspaceConnectStatusProvider(workspaceId))
    .value
    ?.laneFor('klipy');

/// The workspace's own Klipy app, for an admin of a workspace on its own apps.
WorkspaceProviderAppView? _klipyApp(WidgetRef ref, String workspaceId) {
  final own =
      ref.watch(workspaceConnectModeProvider(workspaceId)) ==
      WorkspaceConnectMode.own;
  final isAdmin =
      ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
  return own && isAdmin
      ? workspaceProviderAppFor(
          ref.watch(workspaceProviderAppsProvider).value,
          'klipy',
        )
      : null;
}
