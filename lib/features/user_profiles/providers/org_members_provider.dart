import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/di/providers.dart';
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
  final owners = ref.watch(repoOrgOwnersProvider);
  if (owners.isEmpty) {
    return const [];
  }

  final client = ref.watch(githubApiClientProvider).content;
  final allMembers = <String, GitHubUser>{};

  for (final org in owners) {
    try {
      final members = await client.getOrganizationMembers(org);
      for (final m in members) {
        allMembers.putIfAbsent(m.login, () => m);
      }
    } on Exception {
      // Silently skip orgs that fail (network, auth, etc.)
    }
  }

  return allMembers.values.toList()
    ..sort((a, b) => a.login.compareTo(b.login));
});
