import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

class _AuthError implements Exception {
  const _AuthError();
  @override
  String toString() => 'HTTP 401 unauthorized';
}

class _OtherError implements Exception {
  const _OtherError();
  @override
  String toString() => 'connection reset';
}

void main() {
  const policy = AuthRetryPolicy();

  test('(a) initial attempt succeeds — no retries', () async {
    final resolves = <AuthResolveContext>[];
    final result = await policy.run<String>(
      resolve: (ctx) async {
        resolves.add(ctx);
        return 'key-1';
      },
      attempt: (key) async => 'ok:$key',
    );
    expect(result, 'ok:key-1');
    expect(resolves.length, 1);
    expect(resolves.single.isInitial, isTrue);
  });

  test('(b) auth error → force-refresh same account succeeds', () async {
    final keys = ['stale', 'refreshed'];
    var i = 0;
    final result = await policy.run<String>(
      resolve: (ctx) async => keys[i++],
      attempt: (key) async {
        if (key == 'stale') {
          throw const _AuthError();
        }
        return 'ok:$key';
      },
    );
    expect(result, 'ok:refreshed');
  });

  test('(c) refresh still fails → rotate to sibling', () async {
    final steps = <AuthResolveContext>[];
    final result = await policy.run<String>(
      resolve: (ctx) async {
        steps.add(ctx);
        if (ctx.isInitial) {
          return 'acct-a';
        }
        if (!ctx.lastChance) {
          return 'acct-a'; // refresh returns same → skipped
        }
        return 'acct-b'; // rotate
      },
      attempt: (key) async {
        if (key == 'acct-a') {
          throw const _AuthError();
        }
        return 'ok:$key';
      },
    );
    expect(result, 'ok:acct-b');
    // initial + refresh(false) + rotate(true)
    expect(steps.map((s) => s.lastChance), [false, false, true]);
  });

  test('non-auth error propagates immediately (no retry)', () async {
    var attempts = 0;
    await expectLater(
      policy.run<String>(
        resolve: (ctx) async => 'key',
        attempt: (key) async {
          attempts++;
          throw const _OtherError();
        },
      ),
      throwsA(isA<_OtherError>()),
    );
    expect(attempts, 1);
  });

  test(
    'a resolver that throws on refresh is a skipped step, not fatal',
    () async {
      // Initial key fails auth; the (b) refresh resolver throws (e.g. refresh
      // endpoint down) → treated as null/skip → (c) rotate succeeds.
      final result = await policy.run<String>(
        resolve: (ctx) async {
          if (ctx.isInitial) {
            return 'acct-a';
          }
          if (!ctx.lastChance) {
            throw Exception('refresh endpoint down');
          }
          return 'acct-b';
        },
        attempt: (key) async {
          if (key == 'acct-a') {
            throw const _AuthError();
          }
          return 'ok:$key';
        },
      );
      expect(result, 'ok:acct-b');
    },
  );

  test('no credential resolved → NoCredentialError', () async {
    await expectLater(
      policy.run<String>(
        resolve: (ctx) async => null,
        attempt: (key) async => 'ok',
      ),
      throwsA(isA<NoCredentialError>()),
    );
  });

  test('exhausting all steps rethrows the last auth error', () async {
    await expectLater(
      policy.run<String>(
        resolve: (ctx) async => ctx.isInitial
            ? 'a'
            : ctx.lastChance
            ? 'c'
            : 'b',
        attempt: (key) async => throw const _AuthError(),
      ),
      throwsA(isA<_AuthError>()),
    );
  });
}
