import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ensures a PR has a backing channel (chat/terminal/files hang off it) and
/// returns its channel id. Idempotent server-side (`pr.ensureChannel`): the
/// first call creates the channel, links the review-channel association, and
/// kicks off provisioning of the repo worktree at the PR head; later calls
/// return the same channel. Keyed by PR node id.
final prChannelProvider = FutureProvider.autoDispose
    .family<String, PullRequest>((ref, pr) async {
      final client = ref.watch(rpcClientProvider);
      final data = await client.call('pr.ensureChannel', {
        'repo_full_name': pr.repoFullName,
        'pr_number': pr.number,
        'pr_node_id': pr.nodeId,
        'title': pr.title,
      });
      final channelId = data['channel_id'] as String?;
      if (channelId == null || channelId.isEmpty) {
        throw StateError('pr.ensureChannel returned no channel_id');
      }
      return channelId;
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
    if ('${r.githubOwner}/${r.githubRepoName}' == pr.repoFullName) {
      return r.id;
    }
  }
  return null;
}
