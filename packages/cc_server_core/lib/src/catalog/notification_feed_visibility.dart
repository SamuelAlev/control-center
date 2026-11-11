import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart'
    show SpaceReadGate;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart'
    show RepoVisibility;
import 'package:cc_server_core/src/notification_wire.dart'
    show notificationTargetsUser;

/// Whether a notification [method] is derived from a pull request (its
/// repository's PR data, a review of it). Such an item is shown only to a
/// viewer who may see that repository's pull requests ([RepoVisibility]).
bool isPrDerivedNotification(String method) =>
    method.startsWith('notifications/pr_') ||
    method == 'notifications/external_pr_merged' ||
    method == 'notifications/review_stale';

/// Resolves a viewer's live workspace, repository and space grants before
/// applying the feed predicate. Push and RPC reads must use the same boundary;
/// do not retain the result across delivery, since grants can be revoked.
/// [prVisibility] is the viewer's PR visibility in [workspaceId] (grant AND
/// their own forge sign-in); a PR-derived item needs its repo visible there.
///
/// A space's item needs the space readable by the space read gate
/// [spaceRead], the same gate every space read applies.
Future<List<NotificationFeedItem>> visibleNotificationItemsForUser({
  required String workspaceId,
  required String userId,
  required List<NotificationFeedItem> items,
  required WorkspaceMembershipRepository members,
  required WorkspaceRepository workspaces,
  required RepoVisibility prVisibility,
  required SpaceReadGate spaceRead,
}) async {
  final member = await members.getMember(workspaceId, userId);
  if (member == null) {
    return const [];
  }
  final repos = await workspaces.watchReposForWorkspace(workspaceId).first;
  final grants = member.role.isAdmin
      ? const <String, RepoGrantLevel>{}
      : await members.getRepoGrants(workspaceId, userId);
  Future<Set<String>>? unreadable;
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
    prVisibleRepoIds: prVisibility.visible.keys.toSet(),
    canReadSpace: (spaceId) async =>
        !(await (unreadable ??= spaceRead.unreadable(
          workspaceId,
          userId,
        ))).contains(spaceId),
  );
}

/// Whether a person may see a notification item delivered outside the feed
/// (a web push, a live frame): the feed's own rule
/// ([visibleNotificationItemsForUser]) with their PR visibility resolved per
/// delivery ([visibilityOf]) and the space read gate [spaceRead], so a
/// delivery never shows what `notifications.watch` would not.
Future<bool> Function(NotificationFeedItem item, String userId)
notificationDeliveryCheck({
  required WorkspaceMembershipRepository members,
  required WorkspaceRepository workspaces,
  required SpaceReadGate spaceRead,
  required Future<RepoVisibility> Function(String workspaceId, String userId)
  visibilityOf,
}) => (item, userId) async => (await visibleNotificationItemsForUser(
  workspaceId: item.workspaceId,
  userId: userId,
  items: [item],
  members: members,
  workspaces: workspaces,
  spaceRead: spaceRead,
  prVisibility: await visibilityOf(item.workspaceId, userId),
)).isNotEmpty;

/// Applies the same workspace, recipient ([notificationTargetsUser]),
/// repository and space access checks for feed subscriptions, item-state
/// writes and push delivery.
/// `repoIdsByCoordinate` contains only linked workspace repositories;
/// `readableRepoIds` is intersected with the viewer's grants (admins receive
/// all linked IDs). `prVisibleRepoIds` are the repos whose pull requests the
/// viewer may see (PR visibility); a PR-derived item
/// ([isPrDerivedNotification]) about any other linked repo is left out.
Future<List<NotificationFeedItem>> filterNotificationFeedItems({
  required String workspaceId,
  required String userId,
  required List<NotificationFeedItem> items,
  required bool isMember,
  required Map<String, String> repoIdsByCoordinate,
  required Set<String> readableRepoIds,
  required Set<String> prVisibleRepoIds,
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
    // The same "who is notified" rule as the live forwarder and Web Push.
    if (!notificationTargetsUser(item.method, params, userId)) {
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
    // A PR-derived row naming a repo needs that repo's pull requests
    // visible to the viewer (grant AND their own forge sign-in). One naming
    // no repo (an agent's published PR, by lifecycle id) carries no repo data.
    if (isPrDerivedNotification(item.method) &&
        repoId != null &&
        !prVisibleRepoIds.contains(repoId)) {
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
