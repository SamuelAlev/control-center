import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';

/// Resolves a viewer's live workspace, repository and space grants before
/// applying the feed predicate. Push and RPC reads must use the same boundary;
/// do not retain the result across delivery, since grants can be revoked.
Future<List<NotificationFeedItem>> visibleNotificationItemsForUser({
  required String workspaceId,
  required String userId,
  required List<NotificationFeedItem> items,
  required WorkspaceMembershipRepository members,
  required WorkspaceRepository workspaces,
  required IsolatedRepoRepository isolatedRepos,
}) async {
  final member = await members.getMember(workspaceId, userId);
  if (member == null) {
    return const [];
  }
  final repos = await workspaces.watchReposForWorkspace(workspaceId).first;
  final grants = member.role.isAdmin
      ? const <String, RepoGrantLevel>{}
      : await members.getRepoGrants(workspaceId, userId);
  return filterNotificationFeedItems(
    workspaceId: workspaceId,
    userId: userId,
    items: items,
    isMember: true,
    repoIdsByCoordinate: {
      for (final repo in repos)
        if (repo.remoteOwner.isNotEmpty && repo.remoteName.isNotEmpty)
          '${repo.remoteOwner}/${repo.remoteName}'.toLowerCase(): repo.id,
    },
    readableRepoIds: {
      for (final repo in repos)
        if (member.role.isAdmin ||
            (grants[repo.id] ?? RepoGrantLevel.none).allowsRead)
          repo.id,
    },
    canReadSpace: (spaceId) async {
      if (member.role.isAdmin) {
        return true;
      }
      final spaceRepos = await isolatedRepos.forSpace(workspaceId, spaceId);
      for (final repo in spaceRepos) {
        if ((grants[repo.repoId] ?? RepoGrantLevel.none) ==
            RepoGrantLevel.none) {
          return false;
        }
      }
      return true;
    },
  );
}

/// Applies the same workspace, recipient, repository and space access checks
/// for feed subscriptions, item-state writes and push delivery.
/// `repoIdsByCoordinate` contains only linked workspace repositories;
/// `readableRepoIds` is intersected with the viewer's grants (admins receive
/// all linked IDs).
Future<List<NotificationFeedItem>> filterNotificationFeedItems({
  required String workspaceId,
  required String userId,
  required List<NotificationFeedItem> items,
  required bool isMember,
  required Map<String, String> repoIdsByCoordinate,
  required Set<String> readableRepoIds,
  required Future<bool> Function(String spaceId) canReadSpace,
}) async {
  if (!isMember) {
    return const [];
  }
  final visible = <NotificationFeedItem>[];
  final spaceAccess = <String, bool>{};
  for (final item in items) {
    if (item.workspaceId != workspaceId) {
      continue;
    }
    final params = item.params;
    final recipient = params['for_user_id'];
    if (recipient is String && recipient.isNotEmpty && recipient != userId) {
      continue;
    }
    final id = params['repo_id'];
    final owner = params['repo_owner'];
    final name = params['repo_name'];
    final coordinated = owner is String && name is String;
    final repoId = id is String && id.isNotEmpty
        ? id
        : coordinated
        ? repoIdsByCoordinate['$owner/$name'.toLowerCase()]
        : null;
    if ((id is String && id.isNotEmpty || coordinated) &&
        (repoId == null ||
            !readableRepoIds.contains(repoId) ||
            (coordinated &&
                repoIdsByCoordinate['$owner/$name'.toLowerCase()] != repoId))) {
      continue;
    }
    final space = params['space_id'];
    if (space is String &&
        space.isNotEmpty &&
        !(spaceAccess[space] ??= await canReadSpace(space))) {
      continue;
    }
    visible.add(item);
  }
  return visible;
}
