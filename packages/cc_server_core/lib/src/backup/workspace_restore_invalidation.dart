import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/caching_workspace_membership_repository.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/repo_workspace_index.dart';

/// Drops what the server remembers about a workspace whose authority rows
/// were rewritten underneath it: a restored or imported database file
/// ([WorkspaceRestored]), or an imported grant the server owner accepted
/// ([ImportedAuthorityAccepted]). Both write the workspace's file without
/// going through the repositories that keep these caches exact.
///
/// The membership cache goes first: every other cache re-reads memberships
/// through it, and one rebuilt before it would rebuild from the old roles.
/// The member diff events the import publishes after [WorkspaceRestored]
/// reach the per-member listeners (live subscriptions, forwarders, the forge
/// lanes) on their own.
///
/// Returns the subscription; cancel it on shutdown.
StreamSubscription<WorkspaceAuthorityRewritten> invalidateOnAuthorityRewrite({
  required DomainEventBus eventBus,
  required CachingWorkspaceMembershipRepository memberships,
  GitHubLoginDirectory? githubLogins,
  RepoWorkspaceIndex? repoIndex,
  PrRepoVisibility? prVisibility,
  RepoAccessRegistry? repoAccess,
}) => eventBus.on<WorkspaceAuthorityRewritten>().listen((event) async {
  final workspaceId = event.workspaceId;
  memberships.clearCache();
  githubLogins?.invalidate(workspaceId);
  repoIndex?.invalidate();
  if (event is WorkspaceRestored) {
    // The records of which repositories the server cannot act on came with
    // the file. Accepting a held grant replaces no file, so it leaves them.
    try {
      await repoAccess?.reload(workspaceId);
    } on Object catch (e) {
      CcHostLog.warning(
        'restore: repository access records of $workspaceId not re-read '
        '(${e.runtimeType}); the next sweep re-establishes them',
      );
    }
  }
  if (prVisibility == null) {
    return;
  }
  // A repo grant demoted on import changes no role, so no member event
  // carries it: re-check every current member's reach here.
  try {
    for (final member in await memberships.getForWorkspace(workspaceId)) {
      prVisibility.invalidateUser(member.userId, workspaceId: workspaceId);
    }
  } on Object catch (e) {
    CcHostLog.warning(
      'restore: PR visibility of $workspaceId not re-checked '
      '(${e.runtimeType}); it refreshes on its own schedule',
    );
  }
});
