import 'package:control_center/core/network/models/github_user_profile.dart';
import 'package:control_center/di/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches a GitHub user's full profile (name, bio, contributions).
///
/// Auto-disposed when no widgets are listening.
final githubUserProfileProvider =
    FutureProvider.autoDispose.family<GitHubUserProfile?, String>(
  (ref, login) async {
    if (login.isEmpty) {
      return null;
    }

    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);

    final client = ref.watch(githubApiClientProvider);
    return client.graphql.getUserProfile(
      login: login,
      cancelToken: cancelToken,
    );
  },
);
