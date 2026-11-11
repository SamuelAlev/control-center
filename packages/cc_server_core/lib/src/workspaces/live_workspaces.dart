import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';

/// Whether [workspaceId] is registered and not deleted, read now from the
/// registry. Background sweeps ask it right before touching a workspace.
Future<bool> isLiveWorkspace(
  WorkspaceRepository workspaces,
  String workspaceId,
) async {
  final row = await workspaces.getById(workspaceId);
  return row != null && !row.isDeleted;
}

/// Runs [visit] for every registered, non-deleted workspace, one at a time.
///
/// Each workspace is re-checked against the registry right before its visit,
/// not only when the list was read: a sweep over many workspaces takes long
/// enough for one to be deleted meanwhile, and opening a deleted workspace's
/// database would recreate the file its deletion just dropped.
Future<void> forEachLiveWorkspace(
  WorkspaceRepository workspaces,
  Future<void> Function(Workspace workspace) visit,
) async {
  for (final listed in await workspaces.getAll()) {
    if (listed.isDeleted) {
      continue;
    }
    final live = await workspaces.getById(listed.id);
    if (live == null || live.isDeleted) {
      continue;
    }
    await visit(live);
  }
}
