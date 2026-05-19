import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/infrastructure/provider_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks the app-wide Riverpod retry policy. The regression this guards is a
/// resubscribe storm: an unrecoverable subscription-stream error (a GitHub rate
/// limit surfaced as an RPC error) must NOT re-run the provider, or each rerun
/// opens a fresh `sub/subscribe` and hammers the server.
void main() {
  group('appProviderRetry', () {
    test('never retries an unrecoverable RPC error', () {
      for (final code in [
        RpcErrorCodes.rateLimited,
        RpcErrorCodes.unauthorized,
        RpcErrorCodes.validation,
        RpcErrorCodes.opUnknown,
        RpcErrorCodes.workspaceMismatch,
        RpcErrorCodes.noWorkspaceBound,
        RpcErrorCodes.tooManySubscriptions,
        RpcErrorCodes.notFound,
      ]) {
        expect(
          appProviderRetry(0, RemoteRpcException(code, 'x')),
          isNull,
          reason: 'code $code must not be retried',
        );
      }
    });

    test('retries a transient RPC internal error a few times, ≥1s floor', () {
      final e = RemoteRpcException(RpcErrorCodes.internalError, 'hiccup');
      // 1s, 2s, 4s — never the 200ms default floor.
      expect(appProviderRetry(0, e), const Duration(seconds: 1));
      expect(appProviderRetry(1, e), const Duration(seconds: 2));
      expect(appProviderRetry(2, e), const Duration(seconds: 4));
      // Then it gives up.
      expect(appProviderRetry(3, e), isNull);
    });

    test('never retries an unrecoverable NetworkException', () {
      expect(
        appProviderRetry(0, const NetworkException('rl', code: 'rate_limited')),
        isNull,
      );
      expect(
        appProviderRetry(0, const NetworkException('auth', code: 'auth_error')),
        isNull,
      );
    });

    test('defers to defaultRetry for an ordinary error', () {
      // A plain exception is retryable under the Riverpod default.
      expect(appProviderRetry(0, Exception('boom')), isNotNull);
      // An Error is not retried by the default (and neither are we).
      expect(appProviderRetry(0, StateError('nope')), isNull);
    });
  });

  // The actual regression: a subscription-stream error must not re-run the
  // provider, because each rerun opens a fresh `sub/subscribe`. These drive a
  // real Riverpod container and count provider builds.
  group('no resubscribe loop (end-to-end)', () {
    test('a rate-limit subscription error settles in AsyncError and never '
        'resubscribes', () async {
      var builds = 0;
      final provider = StreamProvider<int>((ref) {
        builds++;
        // Mirrors what RemoteRpcClient pushes on a `sub/error{rateLimited}`.
        return Stream<int>.error(
          RemoteRpcException(RpcErrorCodes.rateLimited, 'rate limited'),
        );
      });
      final container = ProviderContainer(retry: appProviderRetry);
      addTearDown(container.dispose);
      container.listen<AsyncValue<int>>(
        provider,
        (_, _) {},
        onError: (_, _) {},
      );

      // Wait well past the 200ms default retry floor: if a retry were going to
      // fire, it would have by now.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      expect(builds, 1, reason: 'the provider must be built exactly once');
      expect(container.read(provider), isA<AsyncError<int>>());
    });

    test(
      'WITHOUT the policy the same error DOES resubscribe (documents why the '
      'override exists)',
      () async {
        var builds = 0;
        final provider = StreamProvider<int>((ref) {
          builds++;
          return Stream<int>.error(
            RemoteRpcException(RpcErrorCodes.rateLimited, 'rate limited'),
          );
        });
        // Riverpod's default retry treats a RemoteRpcException as transient.
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen<AsyncValue<int>>(
          provider,
          (_, _) {},
          onError: (_, _) {},
        );

        await Future<void>.delayed(const Duration(milliseconds: 800));

        expect(
          builds,
          greaterThan(1),
          reason: 'the default retry re-runs the provider — the loop we fixed',
        );
      },
    );
  });
}
