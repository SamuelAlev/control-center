import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that answers from a per-request handler — no real network.
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

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  // A binary name that will never resolve, so the Codex path never spawns.
  const noCodex = '__cc_no_such_codex_binary__';

  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('subs_usage_test');
  });

  tearDown(() {
    if (home.existsSync()) {
      home.deleteSync(recursive: true);
    }
  });

  SubscriptionUsage byId(List<SubscriptionUsage> list, String id) =>
      list.firstWhere((p) => p.providerId == id);

  test('z.ai TOKENS_LIMIT windows parse; TIME_LIMIT is ignored', () async {
    final resetMs = DateTime.utc(2030, 1, 1).millisecondsSinceEpoch;
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        expect(options.uri.toString(), contains('monitor/usage/quota/limit'));
        // z.ai uses the raw key in Authorization (no Bearer prefix).
        expect(options.headers['Authorization'], 'zai-secret');
        return _json({
          'data': {
            'level': 'pro',
            'limits': [
              {
                'type': 'TOKENS_LIMIT',
                'percentage': 40.5,
                'nextResetTime': resetMs,
              },
              {
                'type': 'TOKENS_LIMIT',
                'percentage': 52.0,
                'nextResetTime': resetMs,
              },
              {'type': 'TIME_LIMIT', 'percentage': 12.3},
            ],
          },
        });
      });

    final svc = SubscriptionUsageService(
      dio: dio,
      homeDir: home.path,
      environment: {'HOME': home.path},
      codexExecutable: noCodex,
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll(zaiApiKey: 'zai-secret');

    final zai = byId(result, 'zai');
    expect(zai.status, SubscriptionStatus.ok);
    expect(zai.windows.map((w) => w.label), ['Session', 'Weekly']);
    expect(zai.windows[0].usedFraction, closeTo(0.405, 1e-9));
    expect(zai.windows[1].usedFraction, closeTo(0.52, 1e-9));
    expect(zai.windows[0].resetsAt, DateTime.utc(2030, 1, 1));
  });

  test(
    'z.ai labels windows by the unit discriminator, not array order',
    () async {
      // Weekly (unit 6) returned BEFORE session (unit 3) — labels must follow
      // unit, not position.
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => _json({
            'data': {
              'limits': [
                {'type': 'TOKENS_LIMIT', 'percentage': 80, 'unit': 6},
                {'type': 'TOKENS_LIMIT', 'percentage': 10, 'unit': 3},
              ],
            },
          }),
        );
      final svc = SubscriptionUsageService(
        dio: dio,
        homeDir: home.path,
        environment: {'HOME': home.path},
        codexExecutable: noCodex,
        readClaudeKeychain: false,
      );
      final zai = byId(await svc.fetchAll(zaiApiKey: 'k'), 'zai');

      final weekly = zai.windows.firstWhere((w) => w.id == '7d');
      final session = zai.windows.firstWhere((w) => w.id == '5h');
      expect(weekly.label, 'Weekly');
      expect(weekly.usedFraction, closeTo(0.8, 1e-9));
      expect(session.label, 'Session');
      expect(session.usedFraction, closeTo(0.1, 1e-9));
    },
  );

  test('z.ai without a key reports unconfigured (no request made)', () async {
    var called = false;
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) {
        called = true;
        return _json(const {});
      });

    final svc = SubscriptionUsageService(
      dio: dio,
      homeDir: home.path,
      environment: {'HOME': home.path},
      codexExecutable: noCodex,
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();

    final zai = byId(result, 'zai');
    expect(zai.status, SubscriptionStatus.unconfigured);
    expect(called, isFalse);
  });

  test(
    'Claude usage parses five_hour/seven_day from the credentials file',
    () async {
      Directory('${home.path}/.claude').createSync(recursive: true);
      File('${home.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 'tok-abc'},
        }),
      );

      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) {
          expect(options.uri.host, 'api.anthropic.com');
          expect(options.headers['Authorization'], 'Bearer tok-abc');
          expect(options.headers['anthropic-beta'], 'oauth-2025-04-20');
          return _json({
            'five_hour': {
              'utilization': 68,
              'resets_at': '2030-01-01T00:00:00Z',
            },
            'seven_day': {
              'utilization': 20,
              'resets_at': '2030-01-02T00:00:00Z',
            },
          });
        });

      final svc = SubscriptionUsageService(
        dio: dio,
        homeDir: home.path,
        environment: {'HOME': home.path},
        codexExecutable: noCodex,
        readClaudeKeychain: false,
      );
      final result = await svc.fetchAll();

      final claude = byId(result, 'claude');
      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.windows.length, 2);
      expect(claude.peakUsedFraction, closeTo(0.68, 1e-9));
      expect(claude.windows.first.resetsAt, DateTime.utc(2030, 1, 1));
    },
  );

  test('Codex without auth.json reports unconfigured (no spawn)', () async {
    final dio = Dio()..httpClientAdapter = _FakeAdapter((_) => _json(const {}));
    final svc = SubscriptionUsageService(
      dio: dio,
      homeDir: home.path,
      environment: {'HOME': home.path},
      codexExecutable: noCodex,
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();

    final codex = byId(result, 'codex');
    expect(codex.status, SubscriptionStatus.unconfigured);
  });

  test('always returns one snapshot per provider', () async {
    final dio = Dio()..httpClientAdapter = _FakeAdapter((_) => _json(const {}));
    final svc = SubscriptionUsageService(
      dio: dio,
      homeDir: home.path,
      environment: {'HOME': home.path},
      codexExecutable: noCodex,
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();
    expect(result.map((p) => p.providerId).toSet(), {
      'claude',
      'codex',
      'zai',
      'kimi-code',
    });
  });
}
