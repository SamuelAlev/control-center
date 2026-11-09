import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/repos/presentation/repo_deep_link_target.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a `control-center://pr/<owner>/<repo>/<number>` deep link into the
/// PR detail of the workspace holding that repo.
Future<void> openPrDeepLink(ProviderContainer container, PrDeepLink pr) async {
  final linked = await activateLinkedRepo(
    container,
    owner: pr.owner,
    repo: pr.repo,
  );
  if (linked.dismissed) {
    return;
  }

  // Navigate into the resolved workspace's PR detail; the workspace prefix in
  // the URL is what re-scopes the app. Fall back to the active workspace, then
  // the picker, if the PR's repo isn't linked anywhere.
  final wsId = linked.workspaceId ?? container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(
        wsId == null
            ? workspaceListRoute
            : pullRequestDetailRoute(
                wsId,
                '${pr.owner}/${pr.repo}',
                pr.number,
                // A comment permalink lands on the diff with the comment
                // revealed; the tab falls back to the timeline itself when the
                // comment turns out to be outdated or out of scope.
                tab: pr.commentId == null ? null : 'pr.diff',
                commentId: pr.commentId,
              ),
      );
}

/// Resolves a `control-center://pulls/<owner>/<repo>` deep link into the pull
/// request list of the workspace holding that repo, with it selected in the
/// rail. An unlinked repo falls back to the active workspace's plain list, then
/// the picker.
Future<void> openPullRequestsDeepLink(
  ProviderContainer container,
  PullRequestsDeepLink pulls,
) async {
  final linked = await activateLinkedRepo(
    container,
    owner: pulls.owner,
    repo: pulls.repo,
  );
  if (linked.dismissed) {
    return;
  }
  final wsId = linked.workspaceId ?? container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(
        wsId == null
            ? workspaceListRoute
            : pullRequestsRoute(wsId, repo: linked.repoFullName),
      );
}

/// Resolves a `control-center://inbox` deep link into the active workspace's
/// inbox, or the picker when none is active. Clears the inbox's filters: the
/// link asks for the whole inbox, and a repo filter left by an earlier
/// [RepoInboxDeepLink] would otherwise still narrow it.
void openInboxDeepLink(ProviderContainer container) {
  container.read(inboxListFiltersProvider.notifier).clear();
  final wsId = container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(wsId == null ? workspaceListRoute : inboxRoute(wsId));
}

/// Resolves a `control-center://inbox/<owner>/<repo>` deep link into the inbox
/// of the workspace holding that repo, filtered to it. A repo left unlinked
/// lands on an unfiltered inbox instead, then the picker.
Future<void> openRepoInboxDeepLink(
  ProviderContainer container,
  RepoInboxDeepLink inbox,
) async {
  final linked = await activateLinkedRepo(
    container,
    owner: inbox.owner,
    repo: inbox.repo,
  );
  if (linked.dismissed) {
    return;
  }
  // Set before navigating so the inbox's first frame is already filtered.
  final filters = container.read(inboxListFiltersProvider.notifier);
  if (linked.repoFullName == null) {
    filters.clear();
  } else {
    filters.showOnlyRepo(inbox.owner, inbox.repo);
  }
  final wsId = linked.workspaceId ?? container.read(activeWorkspaceIdProvider);
  container
      .read(routerProvider)
      .go(wsId == null ? workspaceListRoute : inboxRoute(wsId));
}
