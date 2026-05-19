import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:test/test.dart';

void main() {
  group('StepProcessRegistry', () {
    late StepProcessRegistry registry;

    setUp(() {
      registry = StepProcessRegistry();
    });

    // ---------------------------------------------------------------------------
    // Initialization
    // ---------------------------------------------------------------------------

    group('initialization', () {
      test(
        'isLive returns false for any key on a fresh registry',
        timeout: const Timeout.factor(2),
        () {
          expect(registry.isLive('any-key'), isFalse);
          expect(registry.isLive('another'), isFalse);
        },
      );

      test(
        'kill returns false for any key on a fresh registry',
        timeout: const Timeout.factor(2),
        () async {
          expect(await registry.kill('any-key'), isFalse);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // Register
    // ---------------------------------------------------------------------------

    group('register', () {
      test(
        'adds a callback and isLive returns true',
        timeout: const Timeout.factor(2),
        () {
          var called = false;
          registry.register('step-1', () => called = true);
          expect(registry.isLive('step-1'), isTrue);
          expect(called, isFalse); // callback not invoked on register
        },
      );

      test(
        'replaces an existing callback for the same key',
        timeout: const Timeout.factor(2),
        () async {
          registry.register('step-1', () {});
          expect(registry.isLive('step-1'), isTrue);

          var replaced = false;
          registry.register('step-1', () => replaced = true);

          // Still live after replacement.
          expect(registry.isLive('step-1'), isTrue);

          // Kill to verify the replacement took effect.
          await registry.kill('step-1');
          expect(replaced, isTrue);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // Unregister
    // ---------------------------------------------------------------------------

    group('unregister', () {
      test(
        'removes the callback and isLive returns false',
        timeout: const Timeout.factor(2),
        () {
          registry.register('step-1', () {});
          expect(registry.isLive('step-1'), isTrue);

          registry.unregister('step-1');
          expect(registry.isLive('step-1'), isFalse);
        },
      );

      test(
        'is a no-op when no registration exists for the key',
        timeout: const Timeout.factor(2),
        () {
          // Should not throw.
          registry.unregister('no-such-key');
          expect(registry.isLive('no-such-key'), isFalse);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // Kill
    // ---------------------------------------------------------------------------

    group('kill', () {
      test(
        'invokes callback, returns true, and removes registration',
        timeout: const Timeout.factor(2),
        () async {
          var called = false;
          registry.register('step-1', () => called = true);

          final result = await registry.kill('step-1');

          expect(result, isTrue);
          expect(called, isTrue);
          expect(registry.isLive('step-1'), isFalse);
        },
      );

      test(
        'returns false when no registration exists',
        timeout: const Timeout.factor(2),
        () async {
          final result = await registry.kill('no-such-key');
          expect(result, isFalse);
        },
      );

      test(
        'awaits async callback completion',
        timeout: const Timeout.factor(2),
        () async {
          final completer = Completer<void>();
          var asyncDone = false;

          registry.register('step-1', () async {
            await completer.future;
            asyncDone = true;
          });

          final killFuture = registry.kill('step-1');

          // Callback should not be done yet — it's awaiting the completer.
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(asyncDone, isFalse);

          completer.complete();
          final result = await killFuture;

          expect(result, isTrue);
          expect(asyncDone, isTrue);
        },
      );

      test(
        'callback exception propagates',
        timeout: const Timeout.factor(2),
        () {
          registry.register('step-1', () => throw StateError('boom'));

          expect(
            () => registry.kill('step-1'),
            throwsA(isA<StateError>()),
          );
        },
      );

      test(
        'kill after unregister returns false',
        timeout: const Timeout.factor(2),
        () async {
          registry.register('step-1', () {});
          registry.unregister('step-1');

          final result = await registry.kill('step-1');
          expect(result, isFalse);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // State transitions
    // ---------------------------------------------------------------------------

    group('state transitions', () {
      test(
        'register → kill → isLive is false',
        timeout: const Timeout.factor(2),
        () async {
          registry.register('step-1', () {});
          expect(registry.isLive('step-1'), isTrue);

          await registry.kill('step-1');
          expect(registry.isLive('step-1'), isFalse);
        },
      );

      test(
        'register → unregister → isLive is false',
        timeout: const Timeout.factor(2),
        () {
          registry.register('step-1', () {});
          expect(registry.isLive('step-1'), isTrue);

          registry.unregister('step-1');
          expect(registry.isLive('step-1'), isFalse);
        },
      );
    });

    // ---------------------------------------------------------------------------
    // Multiple concurrent registrations
    // ---------------------------------------------------------------------------

    group('multiple concurrent registrations', () {
      test(
        'different keys can have independent registrations',
        timeout: const Timeout.factor(2),
        () async {
          var killedA = false;
          var killedB = false;

          registry.register('step-a', () => killedA = true);
          registry.register('step-b', () => killedB = true);

          expect(registry.isLive('step-a'), isTrue);
          expect(registry.isLive('step-b'), isTrue);

          // Kill step-a only.
          await registry.kill('step-a');
          expect(killedA, isTrue);
          expect(killedB, isFalse);
          expect(registry.isLive('step-a'), isFalse);
          expect(registry.isLive('step-b'), isTrue);
        },
      );

      test(
        'independent unregister does not affect others',
        timeout: const Timeout.factor(2),
        () {
          registry.register('step-a', () {});
          registry.register('step-b', () {});

          registry.unregister('step-a');

          expect(registry.isLive('step-a'), isFalse);
          expect(registry.isLive('step-b'), isTrue);
        },
      );
    });
  });
}
