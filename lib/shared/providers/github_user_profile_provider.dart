import 'package:cc_infra/src/network/models/github_user_profile.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches a GitHub user's full profile (name, bio, contributions).
///
/// Resolved SERVER-SIDE over RPC (the thin client holds no GitHub token); a
/// public profile is global data keyed only by login, so the op is not
/// workspace-scoped. Auto-disposed when no widgets are listening.
final githubUserProfileProvider =
    FutureProvider.autoDispose.family<GitHubUserProfile?, String>(
  (ref, login) async {
    if (login.isEmpty) {
      return null;
    }
    final data = await ref
        .watch(rpcClientProvider)
        .call('github.userProfile', {'login': login});
    final profile = data['profile'];
    if (profile is! Map) {
      return null;
    }
    return GitHubUserProfile.fromWire(profile.cast<String, dynamic>());
  },
);
