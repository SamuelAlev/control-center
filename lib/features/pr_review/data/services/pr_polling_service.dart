import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Periodically polls GitHub for new open PRs on linked repos and emits
/// [ExternalPrDetected] events for each PR not seen in previous polls.
///
/// The first poll after construction is a **baseline** — it records
/// existing PR numbers without emitting events, so we don't spam
/// notifications for PRs that already existed when the app started.
class PrPollingService {
  /// Creates a [PrPollingService].
  ///
  /// [repos] is a list of `(owner, name)` tuples for repos to poll.
  /// [interval] defaults to 3 minutes.
  PrPollingService({
    required GitHubApiClient githubClient,
    required DomainEventBus eventBus,
    required List<({String owner, String name})> repos,
    Duration interval = const Duration(minutes: 3),
  })  : _githubClient = githubClient,
        _eventBus = eventBus,
        _repos = repos,
        _interval = interval;

  final GitHubApiClient _githubClient;
  final DomainEventBus _eventBus;
  final List<({String owner, String name})> _repos;
  final Duration _interval;

  Timer? _timer;
  final Map<String, Set<int>> _knownPrNumbers = {};
  bool _isBaseline = true;

  /// Starts the polling loop.
  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _poll());
    // Run the baseline scan immediately.
    _poll();
  }

  /// Stops the polling loop.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the service is currently running.
  bool get isRunning => _timer != null;

  Future<void> _poll() async {
    for (final repo in _repos) {
      await _pollRepo(repo.owner, repo.name);
    }
    // After the first successful poll, switch to notification mode.
    _isBaseline = false;
  }

  Future<void> _pollRepo(String owner, String name) async {
    final repoKey = '$owner/$name';
    try {
      final page = await _githubClient.pr.listOpenPullRequestsPage(
        owner,
        name,
      );
      final currentNumbers = page.items.map((pr) => pr.number).toSet();

      final previousNumbers = _knownPrNumbers[repoKey];
      _knownPrNumbers[repoKey] = currentNumbers;

      if (previousNumbers == null || _isBaseline) {
        // Baseline — just record, don't notify.
        return;
      }

      // Find PRs that are new (in current but not in previous).
      final newNumbers = currentNumbers.difference(previousNumbers);
      for (final prNumber in newNumbers) {
        final pr = page.items.firstWhere((p) => p.number == prNumber);
        _eventBus.publish(ExternalPrDetected(
          repoOwner: owner,
          repoName: name,
          prNumber: pr.number,
          prTitle: pr.title,
          author: pr.userLogin,
          // Polling runs once over all linked repos and a repo can belong to
          // several workspaces, so no single owning workspace applies — this
          // notification is cross-workspace by design and is therefore omitted
          // from the workspace-scoped dashboard feed (it still shows in the
          // global notification bell).
          workspaceId: null,
          occurredAt: DateTime.now(),
        ));
      }
    } on Object catch (e) {
      AppLog.w('pr_polling', 'Failed to poll $repoKey: $e');
    }
  }

  /// Disposes the timer.
  void dispose() {
    stop();
    _knownPrNumbers.clear();
  }
}
