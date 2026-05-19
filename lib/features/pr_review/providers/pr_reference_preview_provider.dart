import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composite key identifying a PR for preview lookup.
class PrReferenceKey {
  /// Creates a [PrReferenceKey].
  const PrReferenceKey({
    required this.owner,
    required this.repo,
    required this.number,
  });

  /// GitHub repo owner / org.
  final String owner;

  /// GitHub repo name.
  final String repo;

  /// PR number.
  final int number;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReferenceKey &&
          owner == other.owner &&
          repo == other.repo &&
          number == other.number;

  @override
  int get hashCode => Object.hash(owner, repo, number);
}

/// Lightweight preview of a PR — just the fields the chip needs.
class PrPreview {
  /// Creates a [PrPreview].
  const PrPreview({
    required this.title,
    required this.state,
    required this.isDraft,
    required this.isMerged,
    required this.htmlUrl,
  });

  /// PR title.
  final String title;

  /// Raw GitHub PR state (`open` or `closed`).
  final String state;

  /// Whether the PR is in draft mode.
  final bool isDraft;

  /// Whether the PR has been merged.
  final bool isMerged;

  /// Canonical GitHub web URL for the PR.
  final String htmlUrl;
}

/// Fetches PR preview metadata (title + state) over the in-process RPC server,
/// which fetches from GitHub and SWR-caches the result workspace-side. Returns
/// `null` when the PR can't be resolved (404, missing workspace context,
/// network failure) so callers can fall back to a plain link.
///
/// Flipped to RPC (the composition flip): the host owns GitHub auth + the SWR
/// disk cache; this provider holds no token and reaches no database.
final prReferencePreviewProvider = FutureProvider.autoDispose
    .family<PrPreview?, PrReferenceKey>((ref, key) async {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return null;
      }
      final repo = RpcPrReviewRepository(
        ref.watch(rpcClientProvider),
        workspaceId: workspaceId,
        owner: key.owner,
        repo: key.repo,
      );
      try {
        final dto = await repo.prPreview(key.number);
        if (dto == null) {
          return null;
        }
        return PrPreview(
          title: dto.title,
          state: dto.state,
          isDraft: dto.isDraft,
          isMerged: dto.isMerged,
          htmlUrl: dto.htmlUrl,
        );
      } catch (_) {
        return null;
      }
    });

/// Synchronous check: is `(owner, repo)` registered as a repo in the
/// currently active workspace? Used by the markdown builder to decide chip
/// vs. plain link without an async hop.
final repoInActiveWorkspaceProvider = Provider.autoDispose
    .family<bool, ({String owner, String repo})>((ref, args) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return false;
      }
      final repos =
          ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
      return repos.any(
        (r) =>
            r.githubOwner.toLowerCase() == args.owner.toLowerCase() &&
            r.githubRepoName.toLowerCase() == args.repo.toLowerCase(),
      );
    });
