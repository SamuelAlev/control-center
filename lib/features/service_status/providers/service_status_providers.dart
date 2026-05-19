import 'dart:async';

import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Polls the GitHub status API (via the host) every [_refreshInterval] and
/// exposes the most recent snapshot as an [AsyncValue].
final githubStatusProvider =
    AsyncNotifierProvider<GitHubStatusNotifier, GitHubServiceStatus>(
      GitHubStatusNotifier.new,
    );

/// Polls the Claude status API (via the host) every [_refreshInterval] and
/// exposes the most recent snapshot as an [AsyncValue].
final claudeStatusProvider =
    AsyncNotifierProvider<ClaudeStatusNotifier, GitHubServiceStatus>(
      ClaudeStatusNotifier.new,
    );

/// Polls the OpenAI (Codex) status API (via the host) every [_refreshInterval]
/// and exposes the most recent snapshot as an [AsyncValue].
final openaiStatusProvider =
    AsyncNotifierProvider<OpenAIStatusNotifier, GitHubServiceStatus>(
      OpenAIStatusNotifier.new,
    );

/// Polls the Kimi (Moonshot AI) status API (via the host) every
/// [_refreshInterval] and exposes the most recent snapshot as an [AsyncValue].
final kimiStatusProvider =
    AsyncNotifierProvider<KimiStatusNotifier, GitHubServiceStatus>(
      KimiStatusNotifier.new,
    );

const Duration _refreshInterval = Duration(minutes: 2);

/// Notifier that fetches the GitHub status summary and refreshes it on a timer.
class GitHubStatusNotifier extends ServiceStatusNotifier {
  @override
  String get statusOp => 'github.serviceStatus';
}

/// Notifier that fetches the Claude status summary and refreshes it on a timer.
class ClaudeStatusNotifier extends ServiceStatusNotifier {
  @override
  String get statusOp => 'claude.serviceStatus';
}

/// Notifier that fetches the OpenAI status summary and refreshes it on a timer.
class OpenAIStatusNotifier extends ServiceStatusNotifier {
  @override
  String get statusOp => 'openai.serviceStatus';
}

/// Notifier that fetches the Kimi (Moonshot AI) status summary and refreshes
/// it on a timer.
class KimiStatusNotifier extends ServiceStatusNotifier {
  @override
  String get statusOp => 'kimi.serviceStatus';
}

/// Polls a Statuspage v2 status summary (githubstatus.com, status.claude.com,
/// status.openai.com, status.moonshot.cn) and refreshes it on a timer.
///
/// Fetched SERVER-SIDE over [statusOp]: the host fetches the status page (the
/// browser can't reach it cross-origin) and relays the raw `summary.json`,
/// which this parses with the shared web-safe
/// [GitHubServiceStatus.fromSummaryJson].
abstract class ServiceStatusNotifier
    extends AsyncNotifier<GitHubServiceStatus> {
  /// The RPC op that relays the raw `summary.json` for this status page.
  String get statusOp;

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
    final data = await ref.read(rpcClientProvider).call(statusOp, const {});
    final summary = data['summary'];
    // A null summary means the host couldn't reach the status page — parse an
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
