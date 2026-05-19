import 'dart:async';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/usage/claude_usage_cache.dart';
import 'package:test/test.dart';

SubscriptionUsage _ok([double used = 0.4]) => SubscriptionUsage(
  providerId: 'claude',
  displayName: 'Claude',
  status: SubscriptionStatus.ok,
  windows: [
    SubscriptionWindow(id: '5h', label: 'Session', usedFraction: used),
  ],
);

const _throttled = SubscriptionUsage(
  providerId: 'claude',
  displayName: 'Claude',
  status: SubscriptionStatus.error,
  error: '429',
);

void main() {
  late DateTime clock;
  late int calls;

  setUp(() {
    clock = DateTime.utc(2026, 8, 24, 22);
    calls = 0;
  });

  ClaudeUsageCache build({
    SubscriptionUsage Function()? answer,
    Completer<SubscriptionUsage>? gate,
  }) => ClaudeUsageCache(
    now: () => clock,
    fetch: (_) {
      calls++;
      if (gate != null) {
        return gate.future;
      }
      return Future.value((answer ?? _ok)());
    },
  );

  test('a good reading is reused for the whole TTL', () async {
    final cache = build();
    await cache.get('/a');
    clock = clock.add(const Duration(minutes: 4));
    await cache.get('/a');
    expect(calls, 1);

    clock = clock.add(const Duration(minutes: 2));
    await cache.get('/a');
    expect(calls, 2, reason: 'past the TTL it refetches');
  });

  test('accounts are cached independently', () async {
    // The whole reason this class exists is a per-ACCOUNT fan-out, so one
    // account's reading must never answer for another's.
    final cache = build();
    await cache.get('/a');
    await cache.get('/b');
    await cache.get('/a');
    expect(calls, 2);
  });

  test('concurrent callers share one request', () async {
    // The pill opening while a dispatch resolves headroom is the normal case.
    final gate = Completer<SubscriptionUsage>();
    final cache = build(gate: gate);
    final a = cache.get('/a');
    final b = cache.get('/a');
    expect(calls, 1);
    gate.complete(_ok());
    expect(await a, await b);
  });

  test('a FAILED reading is cached too — that is the throttle guard', () async {
    // Retrying a 429 immediately is exactly what turns a brief throttle into a
    // sustained one, and the visible symptom is every account reporting no
    // usage at once.
    final cache = build(answer: () => _throttled);
    await cache.get('/a');
    clock = clock.add(const Duration(minutes: 1));
    await cache.get('/a');
    expect(calls, 1);

    // …but it is held for a SHORTER window than a good reading, so a brief
    // throttle does not blank the pill for five minutes.
    clock = clock.add(const Duration(minutes: 2));
    await cache.get('/a');
    expect(calls, 2);
  });

  test('invalidate forces a refetch', () async {
    // A stale reading taken with an old token must not outlive the credential.
    final cache = build();
    await cache.get('/a');
    cache.invalidate('/a');
    await cache.get('/a');
    expect(calls, 2);
  });
}
