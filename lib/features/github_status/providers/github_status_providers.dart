import 'dart:async';

import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/features/github_status/data/services/github_status_service.dart';
import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedicated dio for GitHub status (no auth — the endpoint is public).
final githubStatusDioProvider = Provider<Dio>((ref) {
  final dio = createDio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10);
  ref.onDispose(dio.close);
  return dio;
});

/// Service that talks to githubstatus.com.
final githubStatusServiceProvider = Provider<GitHubStatusService>((ref) {
  return GitHubStatusService(ref.watch(githubStatusDioProvider));
});

/// Polls the GitHub status API every [_refreshInterval] and exposes the
/// most recent snapshot as an [AsyncValue].
final githubStatusProvider =
    AsyncNotifierProvider<GitHubStatusNotifier, GitHubServiceStatus>(
      GitHubStatusNotifier.new,
    );

const Duration _refreshInterval = Duration(minutes: 2);

/// Notifier that fetches the GitHub status summary and refreshes it on a timer.
class GitHubStatusNotifier extends AsyncNotifier<GitHubServiceStatus> {
  Timer? _timer;

  @override
  Future<GitHubServiceStatus> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(_refreshInterval, (_) => _refreshSilent());
    return ref.read(githubStatusServiceProvider).fetch();
  }

  /// Force-refresh from the UI (e.g. when the user opens the flyout).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(githubStatusServiceProvider).fetch(),
    );
  }

  Future<void> _refreshSilent() async {
    final next = await AsyncValue.guard(
      () => ref.read(githubStatusServiceProvider).fetch(),
    );
    if (next.hasValue) {
      state = next;
    }
  }
}
