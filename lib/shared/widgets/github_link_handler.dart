import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final isSameRepo =
        refInfo.owner == currentOwner && refInfo.repo == currentRepo;

    if (isSameRepo) {
      if (context.mounted) {
        context.go(pullRequestDetailRoute(refInfo.number));
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
        context.go(pullRequestDetailRoute(refInfo.number));
      }
      return;
    }

    // Repo not in any workspace — fall back to browser.
    await _openInBrowser(href);
  }
}

Future<void> _openInBrowser(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Result of finding a workspace that contains a given repo.
class _WorkspaceRepo {
  const _WorkspaceRepo({required this.workspaceId, required this.repo});
  final String workspaceId;
  final Repo repo;
}

/// Finds the first workspace that links the repo identified by [owner] and
/// [repo]. Returns `null` when the repo is not registered or not linked to
/// any workspace.
Future<_WorkspaceRepo?> _findWorkspaceForRepo(
  WidgetRef ref, {
  required String owner,
  required String repo,
}) async {
  final repoRepo = ref.read(repoRepositoryProvider);
  final wsRepo = ref.read(workspaceRepositoryProvider);

  final allRepos = await repoRepo.watchAll().first;
  final targetRepo = allRepos.firstWhereOrNull(
    (r) => r.githubOwner == owner && r.githubRepoName == repo,
  );

  if (targetRepo == null) {
    return null;
  }

  final allWorkspaces = await wsRepo.watchAll().first;
  for (final ws in allWorkspaces) {
    final wsRepos = await wsRepo.watchReposForWorkspace(ws.id).first;
    if (wsRepos.any((r) => r.id == targetRepo.id)) {
      return _WorkspaceRepo(workspaceId: ws.id, repo: targetRepo);
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
