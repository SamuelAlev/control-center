import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream of aggregated dashboard workspace counts.
final dashboardStatusProvider = StreamProvider<DashboardStatus>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll().map((list) {
    return DashboardStatus(
      totalWorkspaces: list.length,
    );
  });
});

/// Stream of all workspaces for the dashboard.
final dashboardWorkspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.watchAll();
});

/// Stream of agents for the active workspace (dashboard).
final dashboardAgentsProvider = StreamProvider<List<Agent>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final repo = ref.watch(agentRepositoryProvider);
  if (workspaceId != null) {
    return repo.watchByWorkspace(workspaceId);
  }
  return repo.watchAll();
});

/// Recent in-app notifications scoped to the **active workspace**.
///
/// [notificationCenterProvider] is an app-wide history (used by the title-bar
/// bell); the dashboard's "Recent activity" panel is workspace-scoped, so it
/// keeps only entries whose notification `workspaceId` matches the active
/// workspace. Entries with a null workspace (e.g. cross-workspace external-PR
/// polling) and entries from other workspaces are filtered out, preventing
/// other workspaces' activity from leaking onto this workspace's dashboard.
/// Returns an empty list when no workspace is active.
final workspaceRecentActivityProvider = Provider<List<NotificationEntry>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final entries = ref.watch(notificationCenterProvider);
  if (workspaceId == null) {
    return const [];
  }
  return entries
      .where((e) => e.notification.workspaceId == workspaceId)
      .toList();
});

