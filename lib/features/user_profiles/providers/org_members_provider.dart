import 'package:cc_infra/src/network/models/github_user.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extracts unique GitHub owner logins from repos linked to the active workspace.
///
/// These owners may be GitHub organizations or individual users. The provider
/// filters out empty owners and deduplicates. Returns an empty set when no
/// workspace is active.
final repoOrgOwnersProvider = Provider<Set<String>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const {};
  }
  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  return repos
      .map((r) => r.githubOwner)
      .where((o) => o.isNotEmpty)
      .toSet();
});

/// Fetches public members from all GitHub orgs that own registered repos.
///
/// Returns a deduplicated list of [GitHubUser]. Failed requests for individual
/// orgs are silently ignored so one bad owner doesn't block the rest.
final orgMembersProvider = FutureProvider<List<GitHubUser>>((ref) async {
  // Fetched SERVER-SIDE on the host's gh client (the thin client holds no
  // token); the host derives the org owners from the bound workspace's repos
  // and fails soft per org. Guarded by the client-side owner set so the call is
  // skipped when no GitHub repos are linked.
  final owners = ref.watch(repoOrgOwnersProvider);
  if (owners.isEmpty) {
    return const [];
  }
  final data = await ref
      .watch(rpcClientProvider)
      .call('github.orgMembers', const {});
  final members = [
    for (final raw in (data['members'] as List?) ?? const [])
      if (raw is Map) GitHubUser.fromJson(raw.cast<String, dynamic>()),
  ];
  members.sort((a, b) => a.login.compareTo(b.login));
  return members;
});
