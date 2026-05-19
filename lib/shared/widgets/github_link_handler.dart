import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Handles a tap on a markdown link that may be a GitHub PR or issue
/// reference.
///
/// * Same-repo PRs   → navigate in-app.
/// * Cross-repo PRs   → if the repo exists in a workspace, switch to that
///   workspace/repo and navigate in-app; otherwise open in browser.
/// * Issues           → open in browser.
/// * Unknown URLs     → open in browser.
///
/// [onSwitchToRepo] is called when a cross-repo PR is found in a workspace.
/// It receives the target `workspaceId` and `repoId` and is responsible for
/// updating the active workspace/repo state.
Future<void> handleGitHubLink({
  required BuildContext context,
  required WidgetRef ref,
  required String? href,
  required String currentOwner,
  required String currentRepo,
  Future<void> Function(String workspaceId, String repoId)? onSwitchToRepo,
}) async {
  if (href == null || href.isEmpty) {
    return;
  }

  final refInfo = parseAnyGitHubReference(
    href,
    currentOwner: currentOwner,
    currentRepo: currentRepo,
  );

  if (refInfo == null) {
    await _openInBrowser(href);
    return;
  }

  if (refInfo is GitHubIssueReference) {
    await _openInBrowser(href);
    return;
  }

  if (refInfo is GitHubPrReference) {
    // Case-insensitive, consistent with how the repo is resolved everywhere
    // else (currentPrRepoProvider / repoInActiveWorkspaceProvider lower-case
    // before comparing). A case mismatch between the href and the host PR's
    // stored owner/repo must NOT be misread as a cross-repo hop — that would
    // needlessly switch the active repo (or worse, flip the workspace).
    final isSameRepo =
        refInfo.owner.toLowerCase() == currentOwner.toLowerCase() &&
        refInfo.repo.toLowerCase() == currentRepo.toLowerCase();

    if (isSameRepo) {
      final wsId = ref.read(activeWorkspaceIdProvider);
      if (context.mounted && wsId != null) {
        context.go(
          pullRequestDetailRoute(
            wsId,
            '${refInfo.owner}/${refInfo.repo}',
            refInfo.number,
          ),
        );
      }
      return;
    }

    // Cross-repo: try to find the repo in a workspace.
    final targetWorkspaceRepo = await _findWorkspaceForRepo(
      ref,
      owner: refInfo.owner,
      repo: refInfo.repo,
    );

    if (targetWorkspaceRepo != null) {
      if (onSwitchToRepo != null) {
        await onSwitchToRepo(
          targetWorkspaceRepo.workspaceId,
          targetWorkspaceRepo.repo.id,
        );
      }

      if (context.mounted) {
        context.go(
          pullRequestDetailRoute(
            targetWorkspaceRepo.workspaceId,
            '${refInfo.owner}/${refInfo.repo}',
            refInfo.number,
          ),
        );
      }
      return;
    }

    // Repo not in any workspace — fall back to browser.
    await _openInBrowser(href);
  }
}

Future<void> _openInBrowser(String url) async {
  openExternalUrl(url);
}

/// Result of finding a workspace that contains a given repo.
class _WorkspaceRepo {
  const _WorkspaceRepo({required this.workspaceId, required this.repo});
  final String workspaceId;
  final Repo repo;
}

/// Finds the first workspace holding the repo identified by [owner] and
/// [repo]. Returns `null` when no workspace has that repo registered.
///
/// Repos live inside a workspace, so this asks each workspace in turn rather
/// than looking a repo up globally and then asking which workspace claims it.
/// Workspaces are visited in the operator's manual order, so a repo registered
/// in two workspaces resolves to the one the operator ranked first.
Future<_WorkspaceRepo?> _findWorkspaceForRepo(
  WidgetRef ref, {
  required String owner,
  required String repo,
}) async {
  final repoRepo = ref.read(repoRepositoryProvider);
  final wsRepo = ref.read(workspaceRepositoryProvider);

  final ownerLower = owner.toLowerCase();
  final repoLower = repo.toLowerCase();

  for (final ws in await wsRepo.getAll()) {
    final match = (await repoRepo.getAll(ws.id)).firstWhereOrNull(
      (r) =>
          r.githubOwner.toLowerCase() == ownerLower &&
          r.githubRepoName.toLowerCase() == repoLower,
    );
    if (match != null) {
      return _WorkspaceRepo(workspaceId: ws.id, repo: match);
    }
  }

  return null;
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
