import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

/// The value of [name] on a captured request, matched case-insensitively.
String? _header(HttpRequest request, String name) {
  final headers = request.headers?.toMapList();
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value.first;
    }
  }
  return null;
}

void main() {
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
    final client = TestHttpClient(
      handler: (request) {
        expect(request.url, contains('monitor/usage/quota/limit'));
        // z.ai uses the raw key in Authorization (no Bearer prefix).
        expect(_header(request, 'authorization'), 'zai-secret');
        return httpTextResponse(request, {
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
      },
    );

    final svc = SubscriptionUsageService(
      httpClient: client,
      homeDir: home.path,
      environment: {'HOME': home.path},
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
      final client = TestHttpClient(
        handler: (request) => httpTextResponse(request, {
          'data': {
            'limits': [
              {'type': 'TOKENS_LIMIT', 'percentage': 80, 'unit': 6},
              {'type': 'TOKENS_LIMIT', 'percentage': 10, 'unit': 3},
            ],
          },
        }),
      );
      final svc = SubscriptionUsageService(
        httpClient: client,
        homeDir: home.path,
        environment: {'HOME': home.path},
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
    final client = TestHttpClient(
      handler: (request) => httpTextResponse(request, const {}),
    );

    final svc = SubscriptionUsageService(
      httpClient: client,
      homeDir: home.path,
      environment: {'HOME': home.path},
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();

    final zai = byId(result, 'zai');
    expect(zai.status, SubscriptionStatus.unconfigured);
    expect(client.requests, isEmpty);
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

      final client = TestHttpClient(
        handler: (request) {
          expect(Uri.parse(request.url).host, 'api.anthropic.com');
          expect(_header(request, 'authorization'), 'Bearer tok-abc');
          expect(_header(request, 'anthropic-beta'), 'oauth-2025-04-20');
          return httpTextResponse(request, {
            'five_hour': {
              'utilization': 68,
              'resets_at': '2030-01-01T00:00:00Z',
            },
            'seven_day': {
              'utilization': 20,
              'resets_at': '2030-01-02T00:00:00Z',
            },
          });
        },
      );

      final svc = SubscriptionUsageService(
        httpClient: client,
        homeDir: home.path,
        environment: {'HOME': home.path},
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
    final client = TestHttpClient(
      handler: (request) => httpTextResponse(request, const {}),
    );
    final svc = SubscriptionUsageService(
      httpClient: client,
      homeDir: home.path,
      environment: {'HOME': home.path},
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();

    final codex = byId(result, 'codex');
    expect(codex.status, SubscriptionStatus.unconfigured);
  });

  test('always returns one snapshot per provider', () async {
    final client = TestHttpClient(
      handler: (request) => httpTextResponse(request, const {}),
    );
    final svc = SubscriptionUsageService(
      httpClient: client,
      homeDir: home.path,
      environment: {'HOME': home.path},
      readClaudeKeychain: false,
    );
    final result = await svc.fetchAll();
    expect(result.map((p) => p.providerId).toSet(), {
      'claude',
      'codex',
      'zai',
      'kimi-code',
      'cursor',
    });
  });
}
