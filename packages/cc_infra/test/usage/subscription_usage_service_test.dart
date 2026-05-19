import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/usage/subscription_usage_service.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Dio adapter that routes every request through [handler]. The handler can
/// inspect `RequestOptions` (path, headers) and return a [ResponseBody], or
/// throw a [DioException] to simulate a network/HTTP failure.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

typedef Handler = ResponseBody Function(RequestOptions options);

(SubscriptionUsageService, _FakeAdapter) build(
  Handler handler, {
  String? homeDir,
  Map<String, String>? environment,
  String codexExecutable = 'definitely-not-a-real-codex-binary',
  bool readClaudeKeychain = false,
}) {
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  final service = SubscriptionUsageService(
    dio: dio,
    homeDir: homeDir,
    environment: environment ?? const <String, String>{},
    codexExecutable: codexExecutable,
    readClaudeKeychain: readClaudeKeychain,
  );
  return (service, adapter);
}

/// Writes an executable shell script that fakes the `codex app-server`
/// JSON-RPC handshake enough to drive [SubscriptionUsageService]'s rate-limit
/// reader. It responds to `initialize` (id 1) then, after a short delay,
/// responds to nothing and instead emits the id-2 rateLimits result with
/// [limits]. Exits after emitting so stdout closes and the reader completes.
String writeFakeCodex(Directory dir, Map<String, dynamic> limits) {
  final script = File('${dir.path}/fake-codex.sh');
  script.writeAsStringSync('''
#!/bin/sh
# Drain stdin (the reader writes initialize/initialized/read requests).
cat > /dev/null &
CATPID=\$!
# Respond to the initialize handshake (id 1).
printf '%s\\n' '${jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': {}})}'
# Give the reader time to send `initialized` then the rateLimits read.
sleep 0.2
# Emit the rateLimits result (id 2).
printf '%s\\n' '${jsonEncode({
    'jsonrpc': '2.0',
    'id': 2,
    'result': {'rateLimits': limits},
  })}'
kill \$CATPID 2>/dev/null
''');
  // chmod +x for portability across temp-dir setups.
  Process.runSync('chmod', ['+x', script.path]);
  return script.path;
}

void main() {
  group('fetchAll with nothing configured', () {
    test(
      'returns an unconfigured snapshot per provider with no credentials',
      () async {
        // Empty environment + null home → no Claude token, no Codex auth dir,
        // no z.ai key, no Kimi Code token.
        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: null,
          environment: const {},
        );

        final results = await service.fetchAll();

        expect(results, hasLength(4));
        for (final usage in results) {
          expect(usage.status, SubscriptionStatus.unconfigured);
        }
        expect(results.map((u) => u.providerId).toSet(), {
          'claude',
          'codex',
          'zai',
          'kimi-code',
        });
        // Every unconfigured provider explains how to connect it, so the usage
        // card is never a bare blank. The wording is per provider (some name the
        // settings page, some just the sign-in), so this asserts the actionable
        // shape rather than one exact sentence.
        for (final id in ['claude', 'codex', 'zai', 'kimi-code']) {
          expect(
            results.firstWhere((u) => u.providerId == id).error,
            contains('to see usage'),
            reason: id,
          );
        }
      },
    );
  });

  group('Claude Code', () {
    test(
      'parses five-hour and seven-day windows from a 200 response',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_claude_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        final claudeDir = Directory('${tmpHome.path}/.claude')..createSync();
        File('${claudeDir.path}/.credentials.json').writeAsStringSync(
          jsonEncode({
            'claudeAiOauth': {'accessToken': 'tok-123'},
          }),
        );

        ResponseBody handler(RequestOptions options) {
          expect(options.path, contains('api.anthropic.com'));
          expect(options.headers['Authorization'], 'Bearer tok-123');
          return _json({
            'five_hour': {
              'utilization': 42,
              'resets_at': '2024-01-02T00:00:00Z',
            },
            'seven_day': {'utilization': 7},
          });
        }

        final (service, _) = build(handler, homeDir: tmpHome.path);

        final results = await service.fetchAll(zaiApiKey: '');
        final claude = results.firstWhere((u) => u.providerId == 'claude');
        expect(claude.status, SubscriptionStatus.ok);
        expect(claude.windows, hasLength(2));
        final five = claude.windows.firstWhere((w) => w.id == '5h');
        expect(five.label, 'Session');
        expect(five.usedFraction, closeTo(0.42, 1e-9));
        expect(five.resetsAt, DateTime.utc(2024, 1, 2));
        final seven = claude.windows.firstWhere((w) => w.id == '7d');
        expect(seven.label, 'Weekly');
        expect(seven.usedFraction, closeTo(0.07, 1e-9));
        expect(seven.resetsAt, isNull);
      },
    );

    // A per-token (enterprise/API) seat reports NO windows — `five_hour` and
    // `seven_day` come back null — and a dollar balance instead. Reading only
    // the windows told the operator "no usage reported" for an account they
    // were actively spending on.
    test('an account with no windows still reports its credit spend', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_spend_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 'tok-123'},
        }),
      );

      ResponseBody handler(RequestOptions options) => _json({
        'five_hour': null,
        'seven_day': null,
        'spend': {
          'used': {'amount_minor': 141, 'currency': 'USD', 'exponent': 2},
          'limit': {'amount_minor': 60000, 'currency': 'USD', 'exponent': 2},
          'percent': 0,
        },
      });

      final (service, _) = build(handler, homeDir: tmpHome.path);
      final results = await service.fetchAll(zaiApiKey: '');
      final claude = results.firstWhere((u) => u.providerId == 'claude');

      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.windows, isEmpty);
      final spend = claude.spend!;
      expect(spend.used, closeTo(1.41, 1e-9));
      expect(spend.limit, closeTo(600, 1e-9));
      expect(spend.currency, 'USD');
      // 0.24%, which is why the dollars are what gets shown: the endpoint's
      // own `percent` rounds this to 0.
      expect(spend.usedFraction, closeTo(0.00235, 1e-5));
    });

    test('a PLAN account\'s empty spend block is not a zero balance', () async {
      // A plan account also carries `spend`, with null `used`/`limit`.
      // Rendering that as "$0.00 of $0.00" would invent a cap it does not have.
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_nospend_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 'tok-123'},
        }),
      );

      ResponseBody handler(RequestOptions options) => _json({
        'five_hour': {'utilization': 42},
        'spend': {'used': null, 'limit': null, 'percent': 0},
      });

      final (service, _) = build(handler, homeDir: tmpHome.path);
      final results = await service.fetchAll(zaiApiKey: '');
      final claude = results.firstWhere((u) => u.providerId == 'claude');
      expect(claude.spend, isNull);
      expect(claude.windows, hasLength(1));
    });

    test('no windows AND no spend is still unconfigured', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_none_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 'tok-123'},
        }),
      );
      ResponseBody handler(RequestOptions options) =>
          _json({'five_hour': null, 'seven_day': null});
      final (service, _) = build(handler, homeDir: tmpHome.path);
      final results = await service.fetchAll(zaiApiKey: '');
      final claude = results.firstWhere((u) => u.providerId == 'claude');
      expect(claude.status, SubscriptionStatus.unconfigured);
    });

    test('clamps over-100 utilization to 1.0', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_over_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 't'},
        }),
      );

      final (service, _) = build(
        (_) => _json({
          'five_hour': {'utilization': 250},
        }),
        homeDir: tmpHome.path,
      );
      final results = await service.fetchAll(zaiApiKey: '');
      final claude = results.firstWhere((u) => u.providerId == 'claude');
      expect(claude.windows.single.usedFraction, 1.0);
    });

    test(
      'reports unconfigured "No usage reported" when no windows parsed',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_claude_empty_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.claude').createSync();
        File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
          jsonEncode({
            'claudeAiOauth': {'accessToken': 't'},
          }),
        );

        // Both windows present but missing utilization → none parsed.
        final (service, _) = build(
          (_) => _json({
            'five_hour': {'resets_at': 'x'},
            'seven_day': <String, dynamic>{},
          }),
          homeDir: tmpHome.path,
        );
        final claude = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'claude');
        expect(claude.status, SubscriptionStatus.unconfigured);
        expect(claude.error, 'No usage reported.');
      },
    );

    test('degrades to error on a non-2xx response', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_err_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File('${tmpHome.path}/.claude/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 't'},
        }),
      );

      ResponseBody handler(_) => throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      );
      final (service, _) = build(handler, homeDir: tmpHome.path);
      final claude = (await service.fetchAll(
        zaiApiKey: '',
      )).firstWhere((u) => u.providerId == 'claude');
      expect(claude.status, SubscriptionStatus.error);
      expect(claude.error, 'HTTP 500');
    });

    test('honours CLAUDE_CONFIG_DIR over the default home path', () async {
      final cfgDir = Directory.systemTemp.createTempSync('cc_claude_cfg_');
      addTearDown(() => cfgDir.deleteSync(recursive: true));
      File('${cfgDir.path}/.credentials.json').writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {'accessToken': 'cfg-tok'},
        }),
      );

      final (service, _) = build(
        (_) => _json({
          'five_hour': {'utilization': 10},
        }),
        environment: {'CLAUDE_CONFIG_DIR': cfgDir.path},
      );
      final claude = (await service.fetchAll(
        zaiApiKey: '',
      )).firstWhere((u) => u.providerId == 'claude');
      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.windows.single.id, '5h');
    });

    test('ignores a credentials blob without an access token', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_claude_notok_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));
      Directory('${tmpHome.path}/.claude').createSync();
      File(
        '${tmpHome.path}/.claude/.credentials.json',
      ).writeAsStringSync(jsonEncode({'claudeAiOauth': <String, dynamic>{}}));

      final (service, _) = build((_) => _json(const {}), homeDir: tmpHome.path);
      final claude = (await service.fetchAll(
        zaiApiKey: '',
      )).firstWhere((u) => u.providerId == 'claude');
      expect(claude.status, SubscriptionStatus.unconfigured);
    });
  });

  group('Kimi Code', () {
    test('parses the plan windows and their reset times', () async {
      ResponseBody handler(RequestOptions options) {
        expect(options.path, endsWith('/usages'));
        expect(options.headers['Authorization'], 'Bearer plan-token');
        // The device identity the token was issued to rides along, exactly as
        // it does on every other Kimi call.
        expect(options.headers['X-Msh-Device-Id'], 'device-abc');
        return _json({
          'usage': {'used': 40, 'limit': 200},
          'limits': [
            {
              'window': {'duration': 5, 'timeUnit': 'HOURS'},
              'detail': {'used': 30, 'limit': 100, 'resetTime': 1700000000000},
            },
            {
              // "remaining" instead of "used" — Kimi spells it both ways.
              'window': {'duration': 7, 'timeUnit': 'DAYS'},
              'detail': {'remaining': 250, 'limit': 1000},
            },
          ],
        });
      }

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
        kimiDeviceId: 'device-abc',
      )).firstWhere((u) => u.providerId == 'kimi-code');

      expect(kimi.status, SubscriptionStatus.ok);
      expect(kimi.displayName, 'Kimi Code');
      expect(kimi.windows.map((w) => w.id), ['total', '5h', '7d']);
      expect(kimi.windows[0].usedFraction, closeTo(0.2, 1e-9));
      expect(kimi.windows[1].usedFraction, closeTo(0.3, 1e-9));
      // remaining 250 of 1000 means 75% used.
      expect(kimi.windows[2].usedFraction, closeTo(0.75, 1e-9));
      expect(kimi.windows[1].resetsAt, DateTime.utc(2023, 11, 14, 22, 13, 20));
      expect(kimi.windows[2].resetsAt, isNull);
    });

    // A spent plan answers 429, which is indistinguishable from ordinary
    // throttling at the status-code level. Reading the body is what turns
    // "usage unavailable" — which sends the operator hunting a broken
    // integration — into the fact they can act on.
    test('a 429 resource_exhausted reports the plan as spent, with the '
        "provider's own wording", () async {
      ResponseBody handler(RequestOptions options) {
        // The 429 is declared expected, so the shared error interceptor keeps
        // it out of the error log — a spent plan is state, not a fault, and it
        // is re-read on every poll.
        expect(options.extra[expectedStatusesExtra], contains(429));
        return _json({
          'code': 'resource_exhausted',
          'message': 'insufficient balance',
          'details': [
            {
              'type': 'common.error.v1.ErrorDetail',
              'debug': {
                'reason': 'REASON_QUOTA_EXCEEDED',
                'localizedMessage': {
                  'locale': 'en-US',
                  'message': 'Credits used up.',
                },
              },
            },
          ],
        }, status: 429);
      }

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
      )).firstWhere((u) => u.providerId == 'kimi-code');

      expect(kimi.status, SubscriptionStatus.exhausted);
      // The localized sentence, not the machine-facing "insufficient balance".
      expect(kimi.error, 'Credits used up.');
    });

    test('an exhaustion envelope with no localized detail falls back to the '
        'top-level message', () async {
      ResponseBody handler(RequestOptions options) => _json({
        'code': 'resource_exhausted',
        'message': 'insufficient balance',
      }, status: 429);

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
      )).firstWhere((u) => u.providerId == 'kimi-code');

      expect(kimi.status, SubscriptionStatus.exhausted);
      expect(kimi.error, 'insufficient balance');
    });

    test('a bare 429 stays an error — throttling is not exhaustion', () async {
      // Guessing "you are out of credits" at a plan that is merely being
      // rate-limited is a worse answer than admitting the reading failed.
      ResponseBody handler(RequestOptions options) =>
          _json(const {'message': 'slow down'}, status: 429);

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
      )).firstWhere((u) => u.providerId == 'kimi-code');

      expect(kimi.status, SubscriptionStatus.error);
      expect(kimi.error, 'HTTP 429');
    });

    test('a relative reset is resolved against now', () async {
      ResponseBody handler(RequestOptions options) => _json({
        'limits': [
          {
            'window': {'duration': 5, 'timeUnit': 'HOURS'},
            'detail': {'used': 1, 'limit': 2, 'reset_in': 600},
          },
        ],
      });

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'k',
      )).firstWhere((u) => u.providerId == 'kimi-code');
      final resets = kimi.windows.single.resetsAt!;
      expect(
        resets.difference(DateTime.now().toUtc()).inSeconds,
        closeTo(600, 30),
      );
    });

    test(
      'without a token it reports unconfigured and makes no request',
      () async {
        final (service, adapter) = build((_) => _json(const {}));
        final kimi = (await service.fetchAll()).firstWhere(
          (u) => u.providerId == 'kimi-code',
        );
        expect(kimi.status, SubscriptionStatus.unconfigured);
        expect(kimi.error, contains('Settings'));
        expect(adapter.requests.where((r) => r.path.contains('kimi')), isEmpty);
      },
    );

    test('the plan token is never sent to a non-Kimi host', () async {
      // A tampered base URL must not exfiltrate the credential.
      final (service, adapter) = build((_) => _json(const {}));
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
        kimiBaseUrl: 'https://evil.example/v1',
      )).firstWhere((u) => u.providerId == 'kimi-code');
      expect(kimi.status, SubscriptionStatus.error);
      expect(kimi.error, contains('Invalid'));
      expect(adapter.requests.where((r) => r.path.contains('evil')), isEmpty);
    });

    test('an unreadable payload degrades to an error, not a throw', () async {
      final (service, _) = build((_) => _json({'limits': <Object>[]}));
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'k',
      )).firstWhere((u) => u.providerId == 'kimi-code');
      expect(kimi.status, SubscriptionStatus.error);
    });

    test('an HTTP failure degrades that provider only', () async {
      final (service, _) = build((options) {
        if (options.path.contains('kimi')) {
          throw DioException(
            requestOptions: options,
            response: Response<void>(requestOptions: options, statusCode: 500),
          );
        }
        return _json(const {});
      });
      final results = await service.fetchAll(kimiAccessToken: 'k');
      expect(
        results.firstWhere((u) => u.providerId == 'kimi-code').status,
        SubscriptionStatus.error,
      );
      // The batch still resolves for everyone else.
      expect(
        results.map((u) => u.providerId),
        containsAll(<String>['claude', 'codex', 'zai']),
      );
    });
  });

  group('z.ai', () {
    test('parses TOKENS_LIMIT windows keyed by unit discriminator', () async {
      ResponseBody handler(RequestOptions options) {
        expect(options.path, endsWith('/api/monitor/usage/quota/limit'));
        // Raw key in the Authorization header (tried first).
        expect(options.headers['Authorization'], 'sekret');
        return _json({
          'data': {
            'limits': [
              {
                'type': 'TOKENS_LIMIT',
                'percentage': 60,
                'unit': 3,
                'nextResetTime': 1700000000000,
              },
              {'type': 'TOKENS_LIMIT', 'percentage': 30, 'unit': 6},
              // Non-token limits are ignored.
              {'type': 'REQUESTS_LIMIT', 'percentage': 99, 'unit': 3},
            ],
          },
        });
      }

      final (service, _) = build(handler);

      final results = await service.fetchAll(
        zaiApiKey: 'sekret',
        zaiBaseUrl: 'https://api.z.ai',
      );
      final zai = results.firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.ok);
      expect(zai.windows, hasLength(2));
      final five = zai.windows.firstWhere((w) => w.id == '5h');
      expect(five.label, 'Session');
      expect(five.usedFraction, closeTo(0.6, 1e-9));
      expect(five.resetsAt!.millisecondsSinceEpoch, 1700000000000);
      expect(zai.windows.last.id, '7d');
    });

    test('falls back to array position when unit is unrecognised', () async {
      final (service, _) = build(
        (_) => _json({
          'data': {
            'limits': [
              {'type': 'TOKENS_LIMIT', 'percentage': 10},
              {'type': 'TOKENS_LIMIT', 'percentage': 20},
              {'type': 'TOKENS_LIMIT', 'percentage': 30},
            ],
          },
        }),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.windows.map((w) => w.id).toList(), ['5h', '7d', 'w2']);
      expect(zai.windows[2].label, 'Window 3');
    });

    test('uses the default base URL when none is supplied', () async {
      final (service, adapter) = build(
        (_) => _json({
          'data': {
            'limits': [
              {'type': 'TOKENS_LIMIT', 'percentage': 5, 'unit': 3},
            ],
          },
        }),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.ok);
      expect(adapter.requests.single.path, startsWith('https://api.z.ai/'));
    });

    test('accepts bigmodel.cn hosts and strips trailing slashes', () async {
      final (service, adapter) = build(
        (_) => _json({
          'data': {
            'limits': [
              {'type': 'TOKENS_LIMIT', 'percentage': 5, 'unit': 3},
            ],
          },
        }),
      );
      await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://open.bigmodel.cn///',
      );
      expect(
        adapter.requests.single.path,
        startsWith('https://open.bigmodel.cn/api/monitor/'),
      );
    });

    test('retries with a Bearer prefix on a 401', () async {
      var call = 0;
      ResponseBody handler(RequestOptions options) {
        call++;
        if (call == 1) {
          throw DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 401,
            ),
          );
        }
        expect(options.headers['Authorization'], 'Bearer k');
        return _json({
          'data': {
            'limits': [
              {'type': 'TOKENS_LIMIT', 'percentage': 1, 'unit': 3},
            ],
          },
        });
      }

      final (service, _) = build(handler);
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.ok);
      expect(call, 2);
    });

    test('returns an error when the base URL is not a z.ai host', () async {
      final (service, _) = build((_) => _json(const {}));
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://evil.example.com',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Invalid z.ai base URL.');
    });

    test('returns an error when the base URL is not https', () async {
      final (service, _) = build((_) => _json(const {}));
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'http://z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Invalid z.ai base URL.');
    });

    test('returns an error when no windows could be parsed', () async {
      final (service, _) = build(
        (_) => _json({
          'data': {'limits': <Map<String, dynamic>>[]},
        }),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Could not read z.ai usage.');
    });

    test('returns an error on a network failure', () async {
      ResponseBody handler(_) => throw DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(),
      );
      final (service, _) = build(handler);
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Network error');
    });

    test('parses a response with no data map as no windows', () async {
      final (service, _) = build((_) => _json(const <String, dynamic>{}));
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
    });
  });

  group('OpenAI Codex', () {
    test('reports unconfigured when the auth file is absent', () async {
      final tmpHome = Directory.systemTemp.createTempSync('cc_codex_none_');
      addTearDown(() => tmpHome.deleteSync(recursive: true));

      final (service, _) = build((_) => _json(const {}), homeDir: tmpHome.path);
      final codex = (await service.fetchAll(
        zaiApiKey: '',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.status, SubscriptionStatus.unconfigured);
    });

    test(
      'reports error when auth.json exists but the CLI is unavailable',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync(
          'cc_codex_missing_',
        );
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.codex').createSync();
        File('${tmpHome.path}/.codex/auth.json').writeAsStringSync('{}');

        // codexExecutable is overridden to a binary that does not exist, so
        // Process.start throws and _readCodexRateLimits returns null.
        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: tmpHome.path,
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.error);
        expect(codex.error, 'Codex did not report limits.');
      },
    );

    test('honours CODEX_HOME over the default ~/.codex path', () async {
      final codexHome = Directory.systemTemp.createTempSync('cc_codex_home_');
      addTearDown(() => codexHome.deleteSync(recursive: true));
      File('${codexHome.path}/auth.json').writeAsStringSync('{}');

      final (service, _) = build(
        (_) => _json(const {}),
        environment: {'CODEX_HOME': codexHome.path},
      );
      final codex = (await service.fetchAll(
        zaiApiKey: '',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.status, SubscriptionStatus.error);
      expect(codex.error, 'Codex did not report limits.');
    });

    test(
      'reports unconfigured when home is null and CODEX_HOME is unset',
      () async {
        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: null,
          environment: const {},
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.unconfigured);
      },
    );

    test(
      'parses primary/secondary windows from a faked codex handshake',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_codex_fake_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.codex').createSync();
        File('${tmpHome.path}/.codex/auth.json').writeAsStringSync('{}');

        final fakeCodex = writeFakeCodex(tmpHome, {
          'primary': {'used_percent': 55, 'resets_at': 1700000000},
          'secondary': {'used_percent': 20, 'resets_in_seconds': 86400},
        });

        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: tmpHome.path,
          codexExecutable: fakeCodex,
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.ok);
        expect(codex.windows, hasLength(2));
        final five = codex.windows.firstWhere((w) => w.id == '5h');
        expect(five.label, 'Session');
        expect(five.usedFraction, closeTo(0.55, 1e-9));
        expect(five.resetsAt!.millisecondsSinceEpoch, 1700000000000);
        final seven = codex.windows.firstWhere((w) => w.id == '7d');
        expect(seven.usedFraction, closeTo(0.2, 1e-9));
        expect(seven.resetsAt, isNotNull);
      },
      skip: Platform.isWindows
          ? 'fake codex is a #!/bin/sh script; POSIX exec only'
          : false,
    );

    test(
      'accepts camelCase usedPercent / resetsAt codex fields',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_codex_camel_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.codex').createSync();
        File('${tmpHome.path}/.codex/auth.json').writeAsStringSync('{}');

        final fakeCodex = writeFakeCodex(tmpHome, {
          'primary': {'usedPercent': 80, 'resetsAt': 1700000000},
        });

        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: tmpHome.path,
          codexExecutable: fakeCodex,
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.ok);
        expect(codex.windows.single.usedFraction, closeTo(0.8, 1e-9));
      },
      skip: Platform.isWindows
          ? 'fake codex is a #!/bin/sh script; POSIX exec only'
          : false,
    );

    test(
      'reports error "No usage reported" when limits have no windows',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_codex_empty_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.codex').createSync();
        File('${tmpHome.path}/.codex/auth.json').writeAsStringSync('{}');

        // Handshake returns an empty rateLimits object → no windows parsed.
        final fakeCodex = writeFakeCodex(tmpHome, <String, dynamic>{});

        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: tmpHome.path,
          codexExecutable: fakeCodex,
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.error);
        expect(codex.error, 'No usage reported.');
      },
      skip: Platform.isWindows
          ? 'fake codex is a #!/bin/sh script; POSIX exec only'
          : false,
    );

    test(
      'returns null limits when the codex process exits without replying',
      () async {
        final tmpHome = Directory.systemTemp.createTempSync('cc_codex_silent_');
        addTearDown(() => tmpHome.deleteSync(recursive: true));
        Directory('${tmpHome.path}/.codex').createSync();
        File('${tmpHome.path}/.codex/auth.json').writeAsStringSync('{}');

        // `/usr/bin/true` starts, prints nothing, exits → onDone completes null.
        final (service, _) = build(
          (_) => _json(const {}),
          homeDir: tmpHome.path,
          codexExecutable: '/usr/bin/true',
        );
        final codex = (await service.fetchAll(
          zaiApiKey: '',
        )).firstWhere((u) => u.providerId == 'codex');
        expect(codex.status, SubscriptionStatus.error);
        expect(codex.error, 'Codex did not report limits.');
      },
    );
  });

  group('z.ai error shape', () {
    test('maps a connectionTimeout DioException to "Timed out"', () async {
      ResponseBody handler(_) => throw DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      );
      final (service, _) = build(handler);
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Timed out');
    });
  });
}
