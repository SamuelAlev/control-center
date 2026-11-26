import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable key for a GitHub organization team.
typedef GitHubTeamKey = ({String organization, String slug});

final Set<String> _pendingForceTeamProfiles = <String>{};

String _teamForceKey(GitHubTeamKey key) =>
    '${key.organization.trim().toLowerCase()}/${key.slug.trim().toLowerCase()}';

/// Forces a fresh server fetch of [key]'s GitHub team profile.
Future<GitHubTeamProfile?> refreshGitHubTeamProfile(
  WidgetRef ref,
  GitHubTeamKey key,
) {
  if (key.organization.trim().isNotEmpty && key.slug.trim().isNotEmpty) {
    _pendingForceTeamProfiles.add(_teamForceKey(key));
  }
  return ref.refresh(githubTeamProfileProvider(key).future);
}

/// Fetches a GitHub team's metadata and members on the server.
///
/// The caller's server-side GitHub credential is used because private team
/// membership is principal-specific. No token crosses the RPC boundary.
final githubTeamProfileProvider = FutureProvider.autoDispose
    .family<GitHubTeamProfile?, GitHubTeamKey>((ref, key) async {
      if (key.organization.isEmpty || key.slug.isEmpty) {
        return null;
      }
      if (ref.watch(isDemoServerProvider)) {
        return null;
      }
      final force = _pendingForceTeamProfiles.remove(_teamForceKey(key));
      final data = await ref.watch(rpcClientProvider).call(
        'github.teamProfile',
        {
          'organization': key.organization,
          'slug': key.slug,
          if (force) 'force': true,
        },
      );
      final profile = data['profile'];
      if (profile is! Map) {
        return null;
      }
      return GitHubTeamProfile.fromWire(profile.cast<String, dynamic>());
    });
