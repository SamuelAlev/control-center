import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    // Capture the setter at build time — the command palette pops (disposing
    // its element) before invoking onExecute, so `ref`/`context` must not be
    // used inside the callbacks.
    final setActiveRepo = ref.read(activeRepoIdProvider.notifier).setActive;
    final state = testState ?? ref.watch(prsByRepoProvider).value;
    final items = <CommandItem>[];

    // Always include a static "Go to pull requests list" entry.
    items.add(
      CommandItem(
        id: 'pr-list',
        label: 'Go to Pull Requests',
        description: 'Navigate to pull requests list',
        icon: LucideIcons.gitPullRequest,
        category: category,
        onExecute: () => router.go(pullRequestsRoute),
      ),
    );

    if (state == null) {
      return items;
    }

    for (final repoPrs in state.repos) {
      for (final pr in repoPrs.prs) {
        items.add(_prToCommandItem(pr, repoPrs.repo.id, setActiveRepo, router));
      }
    }

    return items;
  }

  CommandItem _prToCommandItem(
    PullRequest pr,
    String repoId,
    Future<void> Function(String repoId) setActiveRepo,
    GoRouter router,
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
      // The PR detail route is keyed only by number and resolves owner/repo
      // from the active repo. The palette aggregates PRs across every repo, so
      // switch the active repo to the PR's repo first — otherwise opening a PR
      // from another repo runs getPullRequest() against the wrong repo and
      // 404s. Mirrors openPrInRepo() used by the PR list.
      onExecute: () {
        setActiveRepo(repoId);
        router.go(pullRequestDetailRoute(pr.number));
      },
    );
  }

  IconData _iconForState(PullRequest pr) {
    if (pr.isDraft) {
      return LucideIcons.filePen;
    }
    if (pr.isMerged) {
      return LucideIcons.gitMerge;
    }
    if (pr.isClosed) {
      return LucideIcons.gitPullRequestClosed;
    }
    return LucideIcons.gitPullRequestArrow;
  }
}

/// Provider for the PR command source.
final prCommandSourceProvider = Provider<CommandSource>(
  (_) => PrCommandSource(),
);
