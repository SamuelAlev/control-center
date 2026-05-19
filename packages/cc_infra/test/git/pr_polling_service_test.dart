import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_infra/src/git/pr_polling_service.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

List<Map<String, dynamic>> _prs(List<int> numbers) => [
  for (final n in numbers)
    {
      'number': n,
      'title': 'PR $n',
      'user': {'login': 'user$n'},
      'head': {'ref': 'b$n'},
      'base': {'ref': 'main'},
    },
];

/// Builds a [GitHubApiClient] whose PR list endpoint returns [pages] in order,
/// then an empty page forever after.
GitHubApiClient _client(List<List<Map<String, dynamic>>> pages) {
  var call = 0;
  final fake = _FakeAdapter((options) {
    final page = call < pages.length ? pages[call] : const [];
    call++;
    return _json(page);
  });
  final dio = Dio()..httpClientAdapter = fake;
  return GitHubApiClient(dio);
}

GitHubApiClient _throwingClient(Object Function() error) {
  final fake = _FakeAdapter((_) {
    throw error();
  });
  final dio = Dio()..httpClientAdapter = fake;
  return GitHubApiClient(dio);
}

const _interval = Duration(milliseconds: 30);

void main() {
  group('PrPollingService', () {
    test('baseline poll records PRs without emitting events', () async {
      final eventBus = DomainEventBus();
      final events = <DomainEvent>[];
      eventBus.on<DomainEvent>().listen(events.add);

      final client = _client([
        _prs([1, 2]),
      ]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'widget')],
        interval: _interval,
      )..start();

      // Let the baseline poll complete.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      svc.stop();

      expect(events, isEmpty);
    });

    test('subsequent poll emits ExternalPrDetected for new PRs only', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      eventBus.on<ExternalPrDetected>().listen(events.add);

      final client = _client([
        _prs([1, 2]), // baseline
        _prs([1, 2, 3]), // +new PR 3
      ]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'widget')],
        interval: _interval,
      )..start();

      // Wait for baseline + at least one periodic tick.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      svc.stop();

      expect(events, hasLength(1));
      expect(events.single.prNumber, 3);
      expect(events.single.prTitle, 'PR 3');
      expect(events.single.author, 'user3');
      expect(events.single.repoOwner, 'acme');
      expect(events.single.repoName, 'widget');
      expect(events.single.workspaceId, isNull);
    });

    test('does not re-emit PRs that remained known across polls', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      eventBus.on<ExternalPrDetected>().listen(events.add);

      final client = _client([
        _prs([1]), // baseline: PR 1
        _prs([1, 2]), // +PR 2 (new)
        _prs([1, 2, 3]), // +PR 3 (new)
      ]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'widget')],
        interval: _interval,
      )..start();

      // baseline + 2 periodic ticks.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      svc.stop();

      final numbers = events.map((e) => e.prNumber).toList()..sort();
      expect(numbers, [2, 3]);
    });

    test('polls multiple repos; emits per repo', () async {
      final eventBus = DomainEventBus();
      final events = <ExternalPrDetected>[];
      eventBus.on<ExternalPrDetected>().listen(events.add);

      final client = _client([
        _prs([10]), // acme/widget baseline
        _prs([20]), // acme/gadget baseline
        _prs([10, 11]), // acme/widget notify (11 new)
        _prs([20, 21]), // acme/gadget notify (21 new)
      ]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [
          (owner: 'acme', name: 'widget'),
          (owner: 'acme', name: 'gadget'),
        ],
        interval: _interval,
      )..start();

      // baseline poll iterates both repos, then periodic tick iterates both
      // again. Need enough wall time for both full sweeps.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      svc.stop();

      final byRepo = {
        for (final e in events) '${e.repoOwner}/${e.repoName}': e.prNumber,
      };
      expect(byRepo['acme/widget'], 11);
      expect(byRepo['acme/gadget'], 21);
    });

    test('a failed poll is swallowed (no crash, no events)', () async {
      final eventBus = DomainEventBus();
      final events = <DomainEvent>[];
      eventBus.on<DomainEvent>().listen(events.add);

      final client = _throwingClient(
        () => DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'widget')],
        interval: _interval,
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      svc.stop();

      expect(events, isEmpty);
    });

    test('empty repos list emits nothing', () async {
      final eventBus = DomainEventBus();
      final client = _client([]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [],
        interval: _interval,
      )..start();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      svc.stop();
    });

    test('start/stop controls the timer; isRunning reflects state', () {
      final eventBus = DomainEventBus();
      final client = _client([]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [(owner: 'acme', name: 'widget')],
        interval: const Duration(minutes: 30),
      );

      expect(svc.isRunning, isFalse);
      svc.start();
      expect(svc.isRunning, isTrue);
      svc.stop();
      expect(svc.isRunning, isFalse);

      svc.dispose();
    });

    test('start is idempotent', () {
      final eventBus = DomainEventBus();
      final client = _client([]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [],
      );
      svc.start();
      svc.start();
      expect(svc.isRunning, isTrue);
      svc.dispose();
    });

    test('dispose stops the timer', () {
      final eventBus = DomainEventBus();
      final client = _client([]);
      final svc = PrPollingService(
        githubClient: client,
        eventBus: eventBus,
        repos: const [],
      )..start();
      svc.dispose();
      expect(svc.isRunning, isFalse);
    });
  });
}
