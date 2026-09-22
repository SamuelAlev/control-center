import 'package:cc_data/cc_data.dart' show pullRequestFromWireDto;
import 'package:cc_domain/cc_domain.dart' show PullRequestDto, RpcErrorCodes;
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No backing space for this PR, and the host will not mint one.
///
/// `pr.ensureSpace` provisions a worktree, so a demo (and an older host that
/// never shipped the verb) refuses it. Chat then looks up a seeded
/// review-space association by repo + number instead; if none exists there is
/// nothing to open.
final class PrSpaceUnavailable implements Exception {
  /// Creates a [PrSpaceUnavailable].
  const PrSpaceUnavailable();

  @override
  String toString() => 'No review space for this pull request';
}

/// Ensures a PR has a backing space (chat/terminal/files hang off it) and
/// returns its space id. Idempotent server-side (`pr.ensureSpace`): the
/// first call creates the space, links the review-space association and
/// kicks off provisioning of the repo worktree at the PR head; later calls
/// return the same space. Keyed by PR node id.
///
/// A demo never calls the verb: it seeds the association (and refuses
/// provisioning), so this resolves off `review_space.watchByWorkspace`
/// matched by repo + number — forge node ids on the fixture and the
/// association are not the same string.
final prSpaceProvider = FutureProvider.autoDispose.family<String, PullRequest>((
  ref,
  pr,
) async {
  if (ref.watch(isDemoServerProvider)) {
    final existing = await _existingPrSpaceId(ref, pr);
    if (existing != null) {
      return existing;
    }
    throw const PrSpaceUnavailable();
  }

  final client = ref.watch(rpcClientProvider);
  try {
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
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      final existing = await _existingPrSpaceId(ref, pr);
      if (existing != null) {
        return existing;
      }
      throw const PrSpaceUnavailable();
    }
    rethrow;
  }
});

/// The seeded (or already-linked) space for [pr], matched by repo + number.
///
/// Not by forge id: `PullRequest.externalId` is a GraphQL node id on the
/// demo fixtures (`PR_412`) while the association the seeder writes is
/// keyed off `detail.id` (`4120001`), and REST-fetched PRs often have an
/// empty external id. Repo + number is what the review tab already uses
/// for the same reason.
Future<String?> _existingPrSpaceId(Ref ref, PullRequest pr) async {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final all = await ref
      .watch(reviewSpaceRepositoryProvider)
      .watchByWorkspace(workspaceId)
      .first;
  for (final a in all) {
    if (a.repoFullName == pr.repoFullName && a.prNumber == pr.number) {
      return a.spaceId;
    }
  }
  return null;
}

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
/// The branch is the join, and it holds however the PR was opened — the compose screen,
/// `gh`, the GitHub web UI, or an agent in the space's own terminal.
/// Resolved SERVER-SIDE (`pr.forSpaceBranches`) off the open-PR poller's persisted
/// snapshot, so this costs a cache read rather than a forge call and the client holds one
/// PR instead of the whole open-PR list — which is deliberately autoDisposed (see
/// `prsByRepoProvider`) precisely because it is too big to keep resident, and a space
/// surface stays open while someone works.
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

/// PRs the space row in the global sidebar should badge.
///
/// A PR reaches a space two ways and only one of them writes a row. [linked]
/// is the review-space associations. [branchMatched] is every open PR whose
/// head is a worktree branch of the space — the same join the space panel
/// uses, which holds however the PR was opened (compose screen, `gh`, the
/// web UI, an agent terminal). An association wins when both name the same
/// PR, so it is not counted twice.
List<PullRequest> pullRequestsForSpaceRow({
  required List<PullRequest> linked,
  required Iterable<PullRequest> branchMatched,
}) {
  final prs = <String, PullRequest>{
    for (final pr in linked) '${pr.repoFullName}#${pr.number}': pr,
  };
  for (final pr in branchMatched) {
    prs.putIfAbsent('${pr.repoFullName}#${pr.number}', () => pr);
  }
  return prs.values.toList(growable: false);
}

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
