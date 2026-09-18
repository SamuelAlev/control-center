import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable key for a GitHub organization team.
typedef GitHubTeamKey = ({String organization, String slug});

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
      final data = await ref.watch(rpcClientProvider).call(
        'github.teamProfile',
        {'organization': key.organization, 'slug': key.slug},
      );
      final profile = data['profile'];
      if (profile is! Map) {
        return null;
      }
      return GitHubTeamProfile.fromWire(profile.cast<String, dynamic>());
    });
