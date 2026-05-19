
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/network/github_pr_client.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/features/pr_review/data/services/pr_polling_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakePrClient extends GitHubPrClient {
  _FakePrClient(this._prs) : super(Dio());

  final List<GitHubPullRequest> _prs;

  @override
  Future<PaginatedPullRequests> listOpenPullRequestsPage(
    String owner,
    String repo, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    return PaginatedPullRequests(items: List.of(_prs), hasMore: false);
  }
}

class _ErrorPrClient extends GitHubPrClient {
  _ErrorPrClient() : super(Dio());

  @override
  Future<PaginatedPullRequests> listOpenPullRequestsPage(
    String owner,
    String repo, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    throw Exception('Network error');
  }
}

class _FakeGitHubClient extends GitHubApiClient {
  _FakeGitHubClient(this._fakePr) : super(Dio());

  final GitHubPrClient _fakePr;

  @override
  GitHubPrClient get pr => _fakePr;
}

// ── Helpers ────────────────────────────────────────────────────────────

GitHubPullRequest _makePr(
  int number, {
  String title = 'PR',
  String login = 'dev',
}) {
  return GitHubPullRequest(
    number: number,
    title: title,
    body: '',
    state: 'open',
    isDraft: false,
    userLogin: login,
    htmlUrl: 'https://github.com/acme/lib/pull/$number',
    nodeId: '',
  );
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('PrPollingService', () {
    test('first poll is baseline — no events emitted', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      final sub = eventBus.on<ExternalPrDetected>().listen(events.add);

      final prs = [_makePr(1), _makePr(2)];
      final client = _FakeGitHubClient(_FakePrClient(prs));
      final service = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'lib')],
        interval: const Duration(milliseconds: 50),
      );

      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      service.stop();

      expect(events, isEmpty);

      await sub.cancel();
      eventBus.dispose();
    });

    test('new PR in subsequent poll emits ExternalPrDetected', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      final sub = eventBus.on<ExternalPrDetected>().listen(events.add);

      final prs = [_makePr(1), _makePr(2)];
      final client = _FakeGitHubClient(_FakePrClient(prs));
      final service = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'lib')],
        interval: const Duration(milliseconds: 50),
      );

      // Start — first poll is baseline.
      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Add a new PR that the next poll will discover.
      prs.add(_makePr(3, title: 'New feature', login: 'alice'));

      // Wait for the next poll cycle to detect the new PR.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      service.stop();

      expect(events, isNotEmpty);
      expect(
        events.any((e) => e.prNumber == 3 && e.author == 'alice'),
        isTrue,
      );

      await sub.cancel();
      eventBus.dispose();
    });

    test('gracefully handles API errors', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      final sub = eventBus.on<ExternalPrDetected>().listen(events.add);

      final client = _FakeGitHubClient(_ErrorPrClient());
      final service = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'lib')],
        interval: const Duration(milliseconds: 50),
      );

      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      service.stop();

      // No events, no crash.
      expect(events, isEmpty);

      await sub.cancel();
      eventBus.dispose();
    });
  });
}
