import 'dart:async';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/usage/claude_cli_usage_probe.dart';
import 'package:cc_infra/src/usage/subscription_usage_service.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// [TestHttpClient] routes every request through `handler`. The handler can
/// inspect the captured [HttpRequest] (url, method, headers, additionalData)
/// and return an [HttpResponse], or throw an rhttp exception to simulate a
/// transport failure. Simulate an HTTP failure by returning a response with
/// that status: [TestHttpClient] throws `RhttpStatusCodeException` itself for
/// `statusCode >= 400`.
typedef Handler = FutureOr<HttpResponse> Function(HttpRequest request);

/// The first value of the header named [name] (case-insensitive), or null when
/// the request carries no such header.
String? header(HttpRequest request, String name) {
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

/// A machine without Claude Code: keeps these tests off the host's real login.
Future<ClaudeCliUsage?> noClaude({String? configDir}) async => null;

(SubscriptionUsageService, TestHttpClient) build(
  Handler handler, {
  ClaudeUsageReader claudeUsageReader = noClaude,
}) {
  final client = TestHttpClient(handler: handler);
  final service = SubscriptionUsageService(
    httpClient: client,
    claudeUsageReader: claudeUsageReader,
  );
  return (service, client);
}

/// A service whose Claude reading is [rateLimits]; any HTTP call fails, since
/// Claude usage must never reach the network from this process.
SubscriptionUsageService claudeReporting(Map<String, dynamic> rateLimits) =>
    build(
      (request) => fail('unexpected request to ${request.url}'),
      claudeUsageReader: ({configDir}) async => ClaudeCliUsage(
        available: true,
        signedOut: false,
        rateLimits: rateLimits,
      ),
    ).$1;

void main() {
  group('fetchAll with nothing configured', () {
    test(
      'returns an unconfigured snapshot per provider with no credentials',
      () async {
        // No Claude Code, no Codex auth dir, no z.ai key, no Kimi Code token,
        // no Cursor token, no Mistral key, no DeepSeek key.
        final (service, _) = build(
          (request) => httpTextResponse(request, const {}),
        );

        final results = await service.fetchAll();

        expect(results, hasLength(7));
        for (final usage in results) {
          expect(usage.status, SubscriptionStatus.unconfigured);
        }
        expect(results.map((u) => u.providerId).toSet(), {
          'claude',
          'codex',
          'zai',
          'kimi-code',
          'cursor',
          'mistral',
          'deepseek',
        });
        // Every unconfigured provider explains how to connect it, so the usage
        // card is never a bare blank. The wording is per provider (some name the
        // settings page, some just the sign-in), so this asserts the actionable
        // shape rather than one exact sentence.
        for (final id in [
          'claude',
          'codex',
          'zai',
          'kimi-code',
          'cursor',
          'mistral',
          'deepseek',
        ]) {
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
    SubscriptionUsage claudeOf(List<SubscriptionUsage> results) =>
        results.firstWhere((u) => u.providerId == 'claude');

    test('parses the 5-hour and 7-day windows the CLI reports', () async {
      final claude = claudeOf(
        await claudeReporting({
          'five_hour': {'utilization': 42, 'resets_at': '2030-01-01T00:00:00Z'},
          'seven_day': {'utilization': 18, 'resets_at': '2030-01-05T00:00:00Z'},
        }).fetchAll(),
      );

      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.windows.map((w) => w.id), ['5h', '7d']);
      expect(claude.windows.map((w) => w.label), ['Session', 'Weekly']);
      expect(claude.windows.first.usedFraction, closeTo(0.42, 1e-9));
      expect(claude.windows.first.resetsAt, DateTime.utc(2030));
    });

    test('an account with no windows still reports its credit spend', () async {
      final claude = claudeOf(
        await claudeReporting({
          'five_hour': null,
          'seven_day': null,
          'spend': {
            'used': {'amount_minor': 141, 'currency': 'USD', 'exponent': 2},
            'limit': {'amount_minor': 60000, 'currency': 'USD', 'exponent': 2},
          },
        }).fetchAll(),
      );

      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.windows, isEmpty);
      expect(claude.spend?.used, closeTo(1.41, 1e-9));
      expect(claude.spend?.limit, closeTo(600, 1e-9));
      expect(claude.spend?.currency, 'USD');
      expect(claude.spend?.usedFraction, closeTo(0.00235, 1e-6));
    });

    test('a PLAN account\'s uncapped spend is not a zero balance', () async {
      // The live shape: `used` is an amount, `limit` is null.
      final claude = claudeOf(
        await claudeReporting({
          'five_hour': {'utilization': 12},
          'spend': {
            'used': {'amount_minor': 0, 'currency': 'USD', 'exponent': 2},
            'limit': null,
            'percent': 0,
            'enabled': false,
          },
        }).fetchAll(),
      );

      expect(claude.status, SubscriptionStatus.ok);
      expect(claude.spend, isNull);
    });

    test('no windows AND no spend is still unconfigured', () async {
      final claude = claudeOf(
        await claudeReporting({'five_hour': null, 'spend': null}).fetchAll(),
      );

      expect(claude.status, SubscriptionStatus.unconfigured);
      expect(claude.error, 'No usage reported.');
    });

    test('clamps over-100 utilization to 1.0', () async {
      final claude = claudeOf(
        await claudeReporting({
          'five_hour': {'utilization': 140},
        }).fetchAll(),
      );

      expect(claude.windows.single.usedFraction, 1.0);
    });

    test('a signed-out CLI asks the operator to sign in', () async {
      final (service, _) = build(
        (request) => fail('unexpected request to ${request.url}'),
        claudeUsageReader: ({configDir}) async => ClaudeCliUsage.fromControl(
          init: const {
            'account': {'tokenSource': 'none', 'apiProvider': 'firstParty'},
          },
          usage: const {'rate_limits_available': false, 'rate_limits': null},
        ),
      );

      final claude = claudeOf(await service.fetchAll());

      expect(claude.status, SubscriptionStatus.unconfigured);
      expect(claude.error, contains('to see usage'));
    });

    test('a login with no plan limits reports no usage', () async {
      final (service, _) = build(
        (request) => fail('unexpected request to ${request.url}'),
        claudeUsageReader: ({configDir}) async => ClaudeCliUsage.fromControl(
          init: const {
            'account': {'apiProvider': 'bedrock'},
          },
          usage: const {'rate_limits_available': false, 'rate_limits': null},
        ),
      );

      final claude = claudeOf(await service.fetchAll());

      expect(claude.status, SubscriptionStatus.unconfigured);
      expect(claude.error, 'No usage reported.');
    });

    test('degrades to error when the CLI cannot be driven', () async {
      final (service, _) = build(
        (request) => fail('unexpected request to ${request.url}'),
        claudeUsageReader: ({configDir}) async =>
            throw StateError('claude exited mid-probe'),
      );

      final claude = claudeOf(await service.fetchAll());

      expect(claude.status, SubscriptionStatus.error);
      expect(claude.error, 'Unavailable');
    });

    test('a named account reads its own config dir, and only that', () async {
      final asked = <String?>[];
      final (service, _) = build(
        (request) => fail('unexpected request to ${request.url}'),
        claudeUsageReader: ({configDir}) async {
          asked.add(configDir);
          return const ClaudeCliUsage(
            available: true,
            signedOut: false,
            rateLimits: {
              'five_hour': {'utilization': 7},
            },
          );
        },
      );

      final usage = await service.fetchClaudeForConfigDir('/accounts/work');

      expect(usage.status, SubscriptionStatus.ok);
      expect(asked, ['/accounts/work']);
    });
  });

  group('Kimi Code', () {
    test('parses the plan windows and their reset times', () async {
      HttpResponse handler(HttpRequest request) {
        expect(request.url, endsWith('/usages'));
        expect(header(request, 'authorization'), 'Bearer plan-token');
        // The device identity the token was issued to rides along, exactly as
        // it does on every other Kimi call.
        expect(header(request, 'x-msh-device-id'), 'device-abc');
        return httpTextResponse(request, {
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
      HttpResponse handler(HttpRequest request) {
        // The 429 is declared expected, so the shared error interceptor keeps
        // it out of the error log — a spent plan is state, not a fault, and it
        // is re-read on every poll.
        expect(request.additionalData[expectedStatusesExtra], contains(429));
        return httpTextResponse(request, {
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
        }, statusCode: 429);
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
      HttpResponse handler(HttpRequest request) => httpTextResponse(request, {
        'code': 'resource_exhausted',
        'message': 'insufficient balance',
      }, statusCode: 429);

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
      HttpResponse handler(HttpRequest request) => httpTextResponse(
        request,
        const {'message': 'slow down'},
        statusCode: 429,
      );

      final (service, _) = build(handler);
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
      )).firstWhere((u) => u.providerId == 'kimi-code');

      expect(kimi.status, SubscriptionStatus.error);
      expect(kimi.error, 'HTTP 429');
    });

    test('a relative reset is resolved against now', () async {
      HttpResponse handler(HttpRequest request) => httpTextResponse(request, {
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
        final (service, client) = build(
          (request) => httpTextResponse(request, const {}),
        );
        final kimi = (await service.fetchAll()).firstWhere(
          (u) => u.providerId == 'kimi-code',
        );
        expect(kimi.status, SubscriptionStatus.unconfigured);
        expect(kimi.error, contains('Settings'));
        expect(client.requests.where((r) => r.url.contains('kimi')), isEmpty);
      },
    );

    test('the plan token is never sent to a non-Kimi host', () async {
      // A tampered base URL must not exfiltrate the credential.
      final (service, client) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'plan-token',
        kimiBaseUrl: 'https://evil.example/v1',
      )).firstWhere((u) => u.providerId == 'kimi-code');
      expect(kimi.status, SubscriptionStatus.error);
      expect(kimi.error, contains('Invalid'));
      expect(client.requests.where((r) => r.url.contains('evil')), isEmpty);
    });

    test('an unreadable payload degrades to an error, not a throw', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {'limits': <Object>[]}),
      );
      final kimi = (await service.fetchAll(
        kimiAccessToken: 'k',
      )).firstWhere((u) => u.providerId == 'kimi-code');
      expect(kimi.status, SubscriptionStatus.error);
    });

    test('an HTTP failure degrades that provider only', () async {
      final (service, _) = build((request) {
        if (request.url.contains('kimi')) {
          return httpTextResponse(request, const {}, statusCode: 500);
        }
        return httpTextResponse(request, const {});
      });
      final results = await service.fetchAll(kimiAccessToken: 'k');
      expect(
        results.firstWhere((u) => u.providerId == 'kimi-code').status,
        SubscriptionStatus.error,
      );
      // The batch still resolves for everyone else.
      expect(
        results.map((u) => u.providerId),
        containsAll(<String>['claude', 'codex', 'zai', 'cursor']),
      );
    });
  });

  group('Cursor', () {
    test(
      'parses period usage percentages, spend and billing-cycle reset',
      () async {
        HttpResponse handler(HttpRequest request) {
          expect(request.method, HttpMethod.post);
          expect(request.url, contains('GetCurrentPeriodUsage'));
          expect(header(request, 'authorization'), 'Bearer cursor-tok');
          expect(header(request, 'connect-protocol-version'), '1');
          return httpTextResponse(request, {
            'billingCycleEnd': '2030-02-01T00:00:00Z',
            'planUsage': {
              'totalSpend': 141,
              'includedSpend': 141,
              'limit': 2000,
              'totalPercentUsed': 7.05,
              'autoPercentUsed': 12,
              'apiPercentUsed': 40,
            },
          });
        }

        final (service, _) = build(handler);
        final cursor = (await service.fetchAll(
          cursorAccessToken: 'cursor-tok',
        )).firstWhere((u) => u.providerId == 'cursor');

        expect(cursor.status, SubscriptionStatus.ok);
        expect(cursor.displayName, 'Cursor');
        expect(cursor.windows.map((w) => w.id), ['total', 'auto', 'api']);
        expect(cursor.windows[0].usedFraction, closeTo(0.0705, 1e-9));
        expect(cursor.windows[1].label, 'Cursor models');
        expect(cursor.windows[1].usedFraction, closeTo(0.12, 1e-9));
        expect(cursor.windows[2].label, 'API');
        expect(cursor.windows[2].usedFraction, closeTo(0.40, 1e-9));
        expect(cursor.windows[0].resetsAt, DateTime.utc(2030, 2, 1));
        expect(cursor.spend, isNotNull);
        expect(cursor.spend!.usedMinor, 141);
        expect(cursor.spend!.limitMinor, 2000);
        expect(cursor.spend!.currency, 'USD');
      },
    );

    test(
      'reads percentages from individualUsage.plan when planUsage is absent',
      () async {
        HttpResponse handler(HttpRequest request) => httpTextResponse(request, {
          'billingCycleEnd': 1893456000,
          'individualUsage': {
            'plan': {
              'totalPercentUsed': 98.5,
              'autoPercentUsed': 98.1,
              'apiPercentUsed': 100,
            },
          },
        });

        final (service, _) = build(handler);
        final cursor = (await service.fetchAll(
          cursorAccessToken: 't',
        )).firstWhere((u) => u.providerId == 'cursor');

        expect(cursor.status, SubscriptionStatus.ok);
        expect(
          cursor.windows.singleWhere((w) => w.id == 'total').usedFraction,
          closeTo(0.985, 1e-9),
        );
        expect(
          cursor.windows.singleWhere((w) => w.id == 'api').usedFraction,
          1.0,
        );
        // Epoch seconds, not millis.
        expect(cursor.windows.first.resetsAt, DateTime.utc(2030, 1, 1));
      },
    );

    test(
      'falls back to GET /auth/usage when the period RPC has no quota',
      () async {
        HttpResponse handler(HttpRequest request) {
          if (request.url.contains('GetCurrentPeriodUsage')) {
            return httpTextResponse(request, {
              'billingCycleEnd': '2030-02-01T00:00:00Z',
            });
          }
          expect(request.method, HttpMethod.get);
          expect(request.url, endsWith('/auth/usage'));
          expect(header(request, 'authorization'), 'Bearer cursor-tok');
          return httpTextResponse(request, {
            'gpt-4': {'numRequests': 150, 'maxRequestUsage': 500},
            'startOfMonth': '2030-03-01T00:00:00.000Z',
          });
        }

        final (service, _) = build(handler);
        final cursor = (await service.fetchAll(
          cursorAccessToken: 'cursor-tok',
        )).firstWhere((u) => u.providerId == 'cursor');

        expect(cursor.status, SubscriptionStatus.ok);
        expect(cursor.windows, hasLength(1));
        expect(cursor.windows.single.id, 'gpt-4');
        expect(cursor.windows.single.usedFraction, closeTo(0.3, 1e-9));
        expect(cursor.windows.single.resetsAt, DateTime.utc(2030, 4, 1));
      },
    );

    test('falls back to request usage when the period RPC 404s', () async {
      HttpResponse handler(HttpRequest request) {
        if (request.url.contains('GetCurrentPeriodUsage')) {
          return httpTextResponse(request, const {
            'message': 'not found',
          }, statusCode: 404);
        }
        return httpTextResponse(request, {
          'gpt-4': {'numRequests': 1, 'maxRequestUsage': 10},
        });
      }

      final (service, _) = build(handler);
      final cursor = (await service.fetchAll(
        cursorAccessToken: 't',
      )).firstWhere((u) => u.providerId == 'cursor');
      expect(cursor.status, SubscriptionStatus.ok);
      expect(cursor.windows.single.usedFraction, closeTo(0.1, 1e-9));
    });

    test('a 401 on the period RPC is an error, not a second probe', () async {
      var gets = 0;
      HttpResponse handler(HttpRequest request) {
        if (request.url.contains('/auth/usage')) {
          gets++;
        }
        return httpTextResponse(request, const {
          'message': 'unauthorized',
        }, statusCode: 401);
      }

      final (service, _) = build(handler);
      final cursor = (await service.fetchAll(
        cursorAccessToken: 'stale',
      )).firstWhere((u) => u.providerId == 'cursor');
      expect(cursor.status, SubscriptionStatus.error);
      expect(cursor.error, 'HTTP 401');
      expect(gets, 0);
    });

    test('spend-only period usage still reports a reading', () async {
      HttpResponse handler(HttpRequest request) => httpTextResponse(request, {
        'billingCycleEnd': '2030-02-01T00:00:00Z',
        'planUsage': {'includedSpend': 141, 'limit': 2000},
      });

      final (service, _) = build(handler);
      final cursor = (await service.fetchAll(
        cursorAccessToken: 't',
      )).firstWhere((u) => u.providerId == 'cursor');
      expect(cursor.status, SubscriptionStatus.ok);
      expect(cursor.hasReading, isTrue);
      expect(cursor.windows.single.id, 'spend');
      expect(cursor.windows.single.usedFraction, closeTo(141 / 2000, 1e-9));
      expect(cursor.spend!.usedMinor, 141);
    });

    test(
      'without a token it reports unconfigured and makes no request',
      () async {
        final (service, client) = build(
          (request) => httpTextResponse(request, const {}),
        );
        final cursor = (await service.fetchAll()).firstWhere(
          (u) => u.providerId == 'cursor',
        );
        expect(cursor.status, SubscriptionStatus.unconfigured);
        expect(cursor.error, contains('Settings'));
        expect(client.requests.where((r) => r.url.contains('cursor')), isEmpty);
      },
    );

    test('the session token is never sent to a non-Cursor host', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final cursor = (await service.fetchAll(
        cursorAccessToken: 'secret',
        cursorBaseUrl: 'https://evil.example',
      )).firstWhere((u) => u.providerId == 'cursor');
      expect(cursor.status, SubscriptionStatus.error);
      expect(cursor.error, contains('Invalid'));
      expect(client.requests, isEmpty);
    });
  });

  group('z.ai', () {
    test('parses TOKENS_LIMIT windows keyed by unit discriminator', () async {
      HttpResponse handler(HttpRequest request) {
        expect(request.url, endsWith('/api/monitor/usage/quota/limit'));
        // Raw key in the Authorization header (tried first).
        expect(header(request, 'authorization'), 'sekret');
        return httpTextResponse(request, {
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
        (request) => httpTextResponse(request, {
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
      final (service, client) = build(
        (request) => httpTextResponse(request, {
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
      expect(client.requests.single.url, startsWith('https://api.z.ai/'));
    });

    test('accepts bigmodel.cn hosts and strips trailing slashes', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, {
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
        client.requests.single.url,
        startsWith('https://open.bigmodel.cn/api/monitor/'),
      );
    });

    test('retries with a Bearer prefix on a 401', () async {
      var call = 0;
      HttpResponse handler(HttpRequest request) {
        call++;
        if (call == 1) {
          return httpTextResponse(request, const {}, statusCode: 401);
        }
        expect(header(request, 'authorization'), 'Bearer k');
        return httpTextResponse(request, {
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
      final (service, _) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://evil.example.com',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Invalid z.ai base URL.');
    });

    test('returns an error when the base URL is not https', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'http://z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Invalid z.ai base URL.');
    });

    test('returns an error when no windows could be parsed', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
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
      HttpResponse handler(HttpRequest request) =>
          throw RhttpConnectionException(request, 'boom');
      final (service, _) = build(handler);
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Network error');
    });

    test('parses a response with no data map as no windows', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, const <String, dynamic>{}),
      );
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
    });
  });

  group('OpenAI Codex', () {
    test('reports unconfigured when no OAuth token is supplied', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final codex = (await service.fetchAll()).firstWhere(
        (u) => u.providerId == 'codex',
      );
      expect(codex.status, SubscriptionStatus.unconfigured);
      expect(client.requests, isEmpty);
    });

    test('refuses to send the token to a non-ChatGPT host', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final codex = (await service.fetchAll(
        codexAccessToken: 'tok',
        codexBaseUrl: 'https://evil.example/backend-api',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.status, SubscriptionStatus.error);
      expect(codex.error, 'Invalid Codex base URL.');
      expect(client.requests, isEmpty);
    });

    test('parses primary/secondary windows from /wham/usage', () async {
      final (service, client) = build((request) {
        expect(httpRequestUri(request).toString(), contains('/wham/usage'));
        expect(header(request, 'authorization'), 'Bearer plan-token');
        expect(header(request, 'chatgpt-account-id'), 'acct-1');
        return httpTextResponse(request, {
          'plan_type': 'plus',
          'rate_limit': {
            'primary_window': {'used_percent': 55, 'reset_at': 1700000000},
            'secondary_window': {
              'used_percent': 20,
              'reset_after_seconds': 86400,
            },
          },
        });
      });
      final codex = (await service.fetchAll(
        codexAccessToken: 'plan-token',
        codexAccountId: 'acct-1',
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
      expect(client.requests, hasLength(1));
    });

    test('labels windows from limit_window_seconds when present', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
          'rate_limit': {
            'primary_window': {
              'used_percent': 10,
              'limit_window_seconds': 18000,
            },
            'secondary_window': {
              'used_percent': 40,
              'limit_window_seconds': 604800,
            },
          },
        }),
      );
      final codex = (await service.fetchAll(
        codexAccessToken: 't',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.windows.map((w) => w.id), ['5h', '7d']);
      expect(codex.windows.map((w) => w.label), ['5 hours', '7 days']);
    });

    test('accepts camelCase usedPercent / resetsAt fields', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
          'rate_limit': {
            'primaryWindow': {'usedPercent': 80, 'resetsAt': 1700000000},
          },
        }),
      );
      final codex = (await service.fetchAll(
        codexAccessToken: 't',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.status, SubscriptionStatus.ok);
      expect(codex.windows.single.usedFraction, closeTo(0.8, 1e-9));
    });

    test('reports error when the payload has no windows', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, const <String, dynamic>{}),
      );
      final codex = (await service.fetchAll(
        codexAccessToken: 't',
      )).firstWhere((u) => u.providerId == 'codex');
      expect(codex.status, SubscriptionStatus.error);
      expect(codex.error, 'Could not read Codex usage.');
    });
  });

  group('multi-account fan-out', () {
    test('two Kimi logins return two stamped snapshots', () async {
      var n = 0;
      final (service, client) = build((request) {
        n += 1;
        expect(request.url, endsWith('/usages'));
        return httpTextResponse(request, {
          'usage': {'used': n * 10, 'limit': 100},
        });
      });
      final results = await service.fetchAll(
        accounts: const [
          SubscriptionUsageAccount(
            providerId: 'kimi-code',
            accountId: 'oauth:one@example.com',
            accountLabel: 'one@example.com',
            accessToken: 'tok-a',
            deviceId: 'dev-a',
          ),
          SubscriptionUsageAccount(
            providerId: 'kimi-code',
            accountId: 'oauth:two@example.com',
            accountLabel: 'two@example.com',
            accessToken: 'tok-b',
            deviceId: 'dev-b',
          ),
        ],
      );
      final kimi = [
        for (final u in results)
          if (u.providerId == 'kimi-code') u,
      ];
      expect(kimi, hasLength(2));
      expect(kimi.map((u) => u.accountId), [
        'oauth:one@example.com',
        'oauth:two@example.com',
      ]);
      expect(kimi.map((u) => u.accountLabel), [
        'one@example.com',
        'two@example.com',
      ]);
      expect(kimi.every((u) => u.status == SubscriptionStatus.ok), isTrue);
      expect(client.requests, hasLength(2));
      expect(
        results.map((u) => u.providerId),
        containsAll(<String>['claude', 'codex', 'zai', 'cursor']),
      );
    });

    test('a knownStatus Claude account is not fetched', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, const {}),
      );
      final results = await service.fetchAll(
        accounts: const [
          SubscriptionUsageAccount(
            providerId: 'claude',
            accountId: 'signed-out',
            accountLabel: 'old@example.com',
            knownStatus: SubscriptionStatus.signInRequired,
            knownReason: 'Sign in again.',
          ),
        ],
      );
      final claude = results.singleWhere((u) => u.providerId == 'claude');
      expect(claude.status, SubscriptionStatus.signInRequired);
      expect(claude.accountId, 'signed-out');
      expect(claude.error, 'Sign in again.');
      expect(
        client.requests.where((r) => r.url.contains('anthropic')),
        isEmpty,
      );
    });
  });

  group('z.ai error shape', () {
    test('maps a request timeout to "Timed out"', () async {
      HttpResponse handler(HttpRequest request) =>
          throw RhttpTimeoutException(request);
      final (service, _) = build(handler);
      final zai = (await service.fetchAll(
        zaiApiKey: 'k',
        zaiBaseUrl: 'https://api.z.ai',
      )).firstWhere((u) => u.providerId == 'zai');
      expect(zai.status, SubscriptionStatus.error);
      expect(zai.error, 'Timed out');
    });
  });

  group('Mistral', () {
    SubscriptionUsageAccount key(String id, {String? baseUrl}) =>
        SubscriptionUsageAccount(
          providerId: 'mistral',
          accountId: id,
          apiKey: 'key-$id',
          baseUrl: baseUrl,
        );

    List<SubscriptionUsage> mistralOf(List<SubscriptionUsage> all) => [
      for (final u in all)
        if (u.providerId == 'mistral') u,
    ];

    test('reads the monthly Vibe budget with a bearer key', () async {
      final (service, client) = build((request) {
        expect(header(request, 'authorization'), 'Bearer key-a');
        return httpTextResponse(request, {
          'vibe_budget': {
            'usage_percentage': 42.5,
            'initial_budget': 30,
            'reset_at': '2026-12-01T00:00:00Z',
            'payg_enabled': false,
          },
        });
      });

      final mistral = mistralOf(
        await service.fetchAll(
          accounts: [key('a', baseUrl: 'https://api.mistral.ai/v1')],
        ),
      ).single;

      expect(
        client.requests.single.url,
        'https://api.mistral.ai/v1/billing/budget',
      );
      expect(mistral.status, SubscriptionStatus.ok);
      expect(mistral.accountId, 'a');
      final window = mistral.windows.single;
      expect(window.id, 'month');
      expect(window.label, 'Monthly');
      expect(window.usedFraction, closeTo(0.425, 1e-9));
      expect(window.resetsAt, DateTime.utc(2026, 12));
    });

    test('a key without a plan collapses to one nameless unconfigured '
        'snapshot', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {'vibe_budget': null}),
      );

      final mistral = mistralOf(
        await service.fetchAll(accounts: [key('a'), key('b')]),
      );

      expect(mistral, hasLength(1));
      expect(mistral.single.status, SubscriptionStatus.unconfigured);
      // Nameless, so the pill drops it like any provider that is not set up.
      expect(mistral.single.accountId, isNull);
    });

    test('a zero allowance is no plan', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
          'vibe_budget': {'usage_percentage': 0, 'initial_budget': 0},
        }),
      );
      final mistral = mistralOf(
        await service.fetchAll(accounts: [key('a')]),
      ).single;
      expect(mistral.status, SubscriptionStatus.unconfigured);
    });

    test('only the keys that carry a plan are paged', () async {
      final (service, _) = build(
        (request) => httpTextResponse(
          request,
          header(request, 'authorization') == 'Bearer key-plan'
              ? {
                  'vibe_budget': {'usage_percentage': 10, 'initial_budget': 30},
                }
              : {'vibe_budget': null},
        ),
      );

      final mistral = mistralOf(
        await service.fetchAll(accounts: [key('metered'), key('plan')]),
      );

      expect(mistral.map((u) => u.accountId), ['plan']);
      expect(mistral.single.status, SubscriptionStatus.ok);
    });

    test('a spent allowance without pay-as-you-go is exhausted', () async {
      final (service, client) = build(
        (request) => httpTextResponse(request, {
          'vibe_budget': {
            'usage_percentage': 100,
            'initial_budget': 30,
            'payg_enabled': false,
          },
        }),
      );
      final mistral = mistralOf(
        await service.fetchAll(accounts: [key('a')]),
      ).single;
      expect(mistral.status, SubscriptionStatus.exhausted);
      // The budget answered the pay-as-you-go question itself.
      expect(client.requests, hasLength(1));
    });

    test('a spent allowance with pay-as-you-go on the subscription stays '
        'usable', () async {
      final (service, client) = build((request) {
        if (request.url.endsWith('/billing/subscription')) {
          return httpTextResponse(request, {
            'plan_name': 'TEAM',
            'vibe_payg_enabled': true,
          });
        }
        return httpTextResponse(request, {
          'vibe_budget': {'usage_percentage': 130, 'initial_budget': 30},
        });
      });
      final mistral = mistralOf(
        await service.fetchAll(accounts: [key('a')]),
      ).single;
      expect(mistral.status, SubscriptionStatus.ok);
      expect(mistral.windows.single.usedFraction, 1.0);
      expect(client.requests.map((r) => r.url), [
        'https://api.mistral.ai/v1/billing/budget',
        'https://api.mistral.ai/v1/billing/subscription',
      ]);
    });

    test(
      'a 403 says the usage is unreadable instead of hiding the plan',
      () async {
        final (service, _) = build(
          (request) => httpTextResponse(request, const {}, statusCode: 403),
        );
        final mistral = mistralOf(
          await service.fetchAll(accounts: [key('a')]),
        ).single;
        expect(mistral.status, SubscriptionStatus.error);
      },
    );

    test('the key is never sent to a non-Mistral host', () async {
      final (service, client) = build(
        (request) => fail('unexpected request to ${request.url}'),
      );
      final mistral = mistralOf(
        await service.fetchAll(
          accounts: [key('a', baseUrl: 'https://proxy.example.com/v1')],
        ),
      ).single;
      expect(client.requests, isEmpty);
      expect(mistral.status, SubscriptionStatus.unconfigured);
    });
  });

  group('DeepSeek', () {
    SubscriptionUsageAccount key(String id, {String? baseUrl}) =>
        SubscriptionUsageAccount(
          providerId: 'deepseek',
          accountId: id,
          apiKey: 'key-$id',
          baseUrl: baseUrl,
        );

    List<SubscriptionUsage> deepseekOf(List<SubscriptionUsage> all) => [
      for (final u in all)
        if (u.providerId == 'deepseek') u,
    ];

    test(
      'reads the balance left in every currency with a bearer key',
      () async {
        final (service, client) = build((request) {
          expect(header(request, 'authorization'), 'Bearer key-a');
          return httpTextResponse(request, {
            'is_available': true,
            'balance_infos': [
              {
                'currency': 'CNY',
                'total_balance': '110.05',
                'granted_balance': '10.00',
                'topped_up_balance': '100.05',
              },
              {'currency': 'USD', 'total_balance': '4.20'},
            ],
          });
        });

        final deepseek = deepseekOf(
          await service.fetchAll(
            accounts: [key('a', baseUrl: 'https://api.deepseek.com/v1')],
          ),
        ).single;

        expect(
          client.requests.single.url,
          'https://api.deepseek.com/user/balance',
        );
        expect(deepseek.status, SubscriptionStatus.ok);
        expect(deepseek.accountId, 'a');
        expect(deepseek.windows, isEmpty);
        expect(deepseek.hasReading, isTrue);
        expect(deepseek.balances, const [
          SubscriptionBalance(amountMinor: 11005, currency: 'CNY'),
          SubscriptionBalance(amountMinor: 420, currency: 'USD'),
        ]);
      },
    );

    test('a balance too low to pay for a call is a spent account', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
          'is_available': false,
          'balance_infos': [
            {'currency': 'USD', 'total_balance': '0.00'},
          ],
        }),
      );
      final deepseek = deepseekOf(
        await service.fetchAll(accounts: [key('a')]),
      ).single;
      expect(deepseek.status, SubscriptionStatus.exhausted);
      expect(deepseek.balances, isEmpty);
    });

    test('every key reports its own balance', () async {
      final (service, _) = build(
        (request) => httpTextResponse(request, {
          'is_available': true,
          'balance_infos': [
            {
              'currency': 'USD',
              'total_balance':
                  header(request, 'authorization') == 'Bearer key-a'
                  ? '1.00'
                  : '2.00',
            },
          ],
        }),
      );
      final deepseek = deepseekOf(
        await service.fetchAll(accounts: [key('a'), key('b')]),
      );
      expect(deepseek.map((u) => u.accountId), ['a', 'b']);
      expect(deepseek.map((u) => u.balances.single.amountMinor), [100, 200]);
    });

    test(
      'a rejected key is an error, and an answer with no balance too',
      () async {
        final (rejected, _) = build(
          (request) => httpTextResponse(request, const {}, statusCode: 401),
        );
        final refused = deepseekOf(
          await rejected.fetchAll(accounts: [key('a')]),
        ).single;
        expect(refused.status, SubscriptionStatus.error);
        expect(refused.error, 'HTTP 401');

        final (empty, _) = build(
          (request) => httpTextResponse(request, const {'is_available': true}),
        );
        expect(
          deepseekOf(await empty.fetchAll(accounts: [key('a')])).single.status,
          SubscriptionStatus.error,
        );
      },
    );

    test('the key is never sent to a non-DeepSeek host', () async {
      final (service, client) = build(
        (request) => fail('unexpected request to ${request.url}'),
      );
      for (final baseUrl in [
        'https://proxy.example.com/v1',
        'https://api.deepseek.com.example.com/v1',
        'http://api.deepseek.com/v1',
      ]) {
        final deepseek = deepseekOf(
          await service.fetchAll(accounts: [key('a', baseUrl: baseUrl)]),
        ).single;
        expect(
          deepseek.status,
          SubscriptionStatus.unconfigured,
          reason: baseUrl,
        );
      }
      expect(client.requests, isEmpty);
    });
  });
}
