import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composite key identifying a commit for preview lookup.
class CommitReferenceKey {
  /// Creates a [CommitReferenceKey].
  const CommitReferenceKey({
    required this.owner,
    required this.repo,
    required this.sha,
  });

  /// GitHub repo owner.
  final String owner;

  /// GitHub repo name.
  final String repo;

  /// Commit SHA (lowercased, 7–40 hex chars).
  final String sha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitReferenceKey &&
          owner == other.owner &&
          repo == other.repo &&
          sha == other.sha;

  @override
  int get hashCode => Object.hash(owner, repo, sha);
}

/// Lightweight preview of a commit — just the fields the chip needs.
class CommitPreview {
  /// Creates a [CommitPreview].
  const CommitPreview({required this.title, required this.shortSha});

  /// First line of the commit message.
  final String title;

  /// Short 7-char SHA for display.
  final String shortSha;
}

/// Fetches commit preview metadata (title + short SHA) over the in-process RPC
/// server, which fetches from GitHub and SWR-caches the result workspace-side.
/// Returns `null` when the commit can't be resolved.
///
/// Flipped to RPC (the composition flip): the host owns GitHub auth + the SWR
/// disk cache; this provider holds no token and reaches no database.
final commitReferencePreviewProvider = FutureProvider.autoDispose
    .family<CommitPreview?, CommitReferenceKey>((ref, key) async {
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
        final dto = await repo.commitPreview(key.sha);
        if (dto == null) {
          return null;
        }
        return CommitPreview(title: dto.title, shortSha: dto.shortSha);
      } catch (_) {
        return null;
      }
    });
