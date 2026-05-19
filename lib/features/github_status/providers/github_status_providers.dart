import 'dart:async';

import 'package:cc_domain/features/github_status/domain/entities/github_service_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Polls the GitHub status API (via the host) every [_refreshInterval] and
/// exposes the most recent snapshot as an [AsyncValue].
final githubStatusProvider =
    AsyncNotifierProvider<GitHubStatusNotifier, GitHubServiceStatus>(
      GitHubStatusNotifier.new,
    );

const Duration _refreshInterval = Duration(minutes: 2);

/// Notifier that fetches the GitHub status summary and refreshes it on a timer.
///
/// Fetched SERVER-SIDE over the `github.serviceStatus` RPC op: the host fetches
/// githubstatus.com (the browser can't reach it cross-origin) and relays the
/// raw `summary.json`, which this parses with the shared web-safe
/// [GitHubServiceStatus.fromSummaryJson].
class GitHubStatusNotifier extends AsyncNotifier<GitHubServiceStatus> {
  Timer? _timer;

  @override
  Future<GitHubServiceStatus> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer ??= Timer.periodic(_refreshInterval, (_) => _refreshSilent());
    return _fetch();
  }

  Future<GitHubServiceStatus> _fetch() async {
    final data = await ref
        .read(rpcClientProvider)
        .call('github.serviceStatus', const {});
    final summary = data['summary'];
    // A null summary means the host couldn't reach githubstatus.com — parse an
    // empty map into an "unknown" snapshot rather than throwing.
    return GitHubServiceStatus.fromSummaryJson(
      summary is Map ? summary.cast<String, dynamic>() : const {},
    );
  }

  /// Force-refresh from the UI (e.g. when the user opens the flyout).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> _refreshSilent() async {
    final next = await AsyncValue.guard(_fetch);
    if (next.hasValue) {
      state = next;
    }
  }
}
