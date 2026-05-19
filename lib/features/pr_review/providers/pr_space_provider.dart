import 'package:cc_data/cc_data.dart' show pullRequestFromWireDto;
import 'package:cc_domain/cc_domain.dart' show PullRequestDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures a PR has a backing space (chat/terminal/files hang off it) and
/// returns its space id. Idempotent server-side (`pr.ensureSpace`): the
/// first call creates the space, links the review-space association and
/// kicks off provisioning of the repo worktree at the PR head; later calls
/// return the same space. Keyed by PR node id.
final prSpaceProvider = FutureProvider.autoDispose.family<String, PullRequest>((
  ref,
  pr,
) async {
  final client = ref.watch(rpcClientProvider);
  final data = await client.call('pr.ensureSpace', {
    'repo_full_name': pr.repoFullName,
    'pr_number': pr.number,
    'pr_external_id': pr.externalId,
    'title': pr.title,
  });
  final spaceId = data['space_id'] as String?;
  if (spaceId == null || spaceId.isEmpty) {
    throw StateError('pr.ensureSpace returned no space_id');
  }
  return spaceId;
});

/// Resolves the workspace repo id for a PR's `owner/repo`, or null when the
/// active workspace / linked repo can't be resolved. Shared by the PR file and
/// source-control tabs so they agree on which repo checkout the worktree ops
/// target.
String? prRepoIdFor(WidgetRef ref, PullRequest pr) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  for (final r in repos) {
    if ('${r.remoteOwner}/${r.remoteName}' == pr.repoFullName) {
      return r.id;
    }
  }
  return null;
}

/// An open pull request whose head is one of a conversation's worktree
/// branches: the `pr` itself plus the `repoId` / `branch` it was matched
/// through, so a per-repo surface can pick out its own.
typedef SpaceBranchPr = ({
  String repoId,
  String repoFullName,
  String branch,
  PullRequest pr,
});

/// The pull requests opened FROM this conversation, matched by head branch.
///
/// A conversation commits on `conv/<id>` in its own CoW worktree. Pushing that
/// branch and opening a PR records nothing that links the two: the
/// `review_spaces` association runs the other way (`pr.ensureSpace` mints a
/// workbench space FOR a PR read off the PR list), so a conversation that
/// authored a PR had no way to know about it and every surface kept offering to
/// create one. The branch is the join, and it holds however the PR was opened —
/// the compose screen, `gh`, the GitHub web UI, or an agent in the space's own
/// terminal.
///
/// Resolved SERVER-SIDE (`pr.forSpaceBranches`) off the open-PR poller's
/// persisted snapshot, so this costs a cache read rather than a forge call and
/// the client holds one PR instead of the whole open-PR list — which is
/// deliberately autoDisposed (see `prsByRepoProvider`) precisely because it is
/// too big to keep resident, and a space surface stays open while someone works.
///
/// Not live: it resolves when a space surface mounts and on an explicit
/// refresh, rather than subscribing — the alternative is streaming the full
/// snapshot this exists to avoid. A PR opened while the panel is on screen
/// shows up on the next refresh or the next visit. A host too old to know the
/// op reports no matches rather than an error.
final spaceBranchPullRequestsProvider = FutureProvider.autoDispose
    .family<List<SpaceBranchPr>, String>((ref, spaceId) async {
      if (spaceId.isEmpty) {
        return const [];
      }
      try {
        final data = await ref.watch(rpcClientProvider).call(
          'pr.forSpaceBranches',
          {'space_id': spaceId},
        );
        return [
          for (final raw in (data['matches'] as List?) ?? const [])
            if (raw is Map)
              (
                repoId: raw['repo_id'] as String? ?? '',
                repoFullName: raw['repo_full_name'] as String? ?? '',
                branch: raw['branch'] as String? ?? '',
                pr: pullRequestFromWireDto(
                  PullRequestDto.fromJson(
                    (raw['pull_request'] as Map).cast<String, dynamic>(),
                  ),
                ),
              ),
        ];
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          return const [];
        }
        rethrow;
      }
    });

/// The pull request this conversation opened from `repoId`'s worktree branch,
/// or null when that branch has no open PR.
final spaceBranchPullRequestForRepoProvider = Provider.autoDispose
    .family<PullRequest?, ({String spaceId, String repoId})>((ref, key) {
      final matches =
          ref.watch(spaceBranchPullRequestsProvider(key.spaceId)).value ??
          const [];
      for (final m in matches) {
        if (m.repoId == key.repoId) {
          return m.pr;
        }
      }
      return null;
    });
