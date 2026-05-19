import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dynamic [CommandSource] that contributes pull request items.
class PrCommandSource implements CommandSource {
  /// Test-only: override the state directly to bypass AsyncNotifier timing.
  @visibleForTesting
  PrsByRepoState? testState;

  /// Unique identifier for this command source.
  @override
  String get id => 'pull-requests';

  /// Category label shown in the command palette.
  @override
  String get category => 'Pull requests';

  /// Whether this source contributes dynamic (runtime-generated) items.
  @override
  bool get isDynamic => true;

  /// Builds command palette items from the current PR state.
  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    // Capture the setter and the active workspace at build time — the command
    // palette pops (disposing its element) before invoking onExecute, so
    // `ref`/`context` must not be used inside the callbacks.
    final setActiveRepo = ref.read(activeRepoIdProvider.notifier).setActive;
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final state = testState ?? ref.watch(prsByRepoProvider).value;
    final items = <CommandItem>[];

    // Always include a static "Go to pull requests list" entry.
    items.add(
      CommandItem(
        id: 'pr-list',
        label: 'Go to Pull Requests',
        description: 'Navigate to pull requests list',
        icon: AppIcons.gitPullRequest,
        category: category,
        onExecute: () => router.go(
          workspaceId == null
              ? workspaceListRoute
              : pullRequestsRoute(workspaceId),
        ),
      ),
    );

    if (state == null || workspaceId == null) {
      return items;
    }

    for (final repoPrs in state.repos) {
      for (final pr in repoPrs.prs) {
        items.add(
          _prToCommandItem(
            pr,
            repoPrs.repo.id,
            setActiveRepo,
            router,
            workspaceId,
          ),
        );
      }
    }

    return items;
  }

  CommandItem _prToCommandItem(
    PullRequest pr,
    String repoId,
    Future<void> Function(String repoId) setActiveRepo,
    GoRouter router,
    String workspaceId,
  ) {
    final authorLogin = pr.author?.login ?? '';
    final desc = authorLogin.isNotEmpty
        ? '${pr.repoFullName} · $authorLogin'
        : pr.repoFullName;

    return CommandItem(
      id: 'pr-${pr.number}',
      label: '#${pr.number} ${pr.title}',
      description: desc,
      icon: _iconForState(pr),
      category: category,
      // The PR detail URL carries the PR's repo (PR numbers are per-repo and
      // the palette aggregates PRs across every repo). Also pin the active repo
      // so repo-scoped chrome outside the PR surface follows. Mirrors
      // openPrInRepo() used by the PR list.
      onExecute: () {
        setActiveRepo(repoId);
        router.go(
          pullRequestDetailRoute(workspaceId, pr.repoFullName, pr.number),
        );
      },
    );
  }

  IconData _iconForState(PullRequest pr) {
    if (pr.isDraft) {
      return AppIcons.filePen;
    }
    if (pr.isMerged) {
      return AppIcons.gitMerge;
    }
    if (pr.isClosed) {
      return AppIcons.gitPullRequestClosed;
    }
    return AppIcons.gitPullRequestArrow;
  }
}

/// Provider for the PR command source.
final prCommandSourceProvider = Provider<CommandSource>(
  (_) => PrCommandSource(),
);
