import 'dart:async';

import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

/// Unit tests for [PauseGate] — the turn-boundary pause primitive the built-in
/// harness loop checks at the top of each turn. Covers idempotent pause/resume,
/// the `waitWhilePaused` blocking behavior and the `onPaused` callback that
/// fires exactly when the loop actually holds (not when a pause is merely
/// requested).
void main() {
  group('PauseGate', () {
    test('starts unpaused', () {
      final gate = PauseGate();
      expect(gate.isPaused, isFalse);
    });

    test('pause flips isPaused to true', () {
      final gate = PauseGate()..pause();
      expect(gate.isPaused, isTrue);
    });

    test('resume flips isPaused back to false', () {
      final gate = PauseGate()
        ..pause()
        ..resume();
      expect(gate.isPaused, isFalse);
    });

    test('pause is idempotent', () {
      final gate = PauseGate()
        ..pause()
        ..pause();
      expect(gate.isPaused, isTrue);
    });

    test('resume is idempotent (no-op when not paused)', () {
      final gate = PauseGate()..resume();
      expect(gate.isPaused, isFalse);
    });

    test('waitWhilePaused completes immediately when not paused', () async {
      final gate = PauseGate();
      // Should return promptly — no blocking.
      await gate.waitWhilePaused().timeout(const Duration(seconds: 1));
      expect(gate.isPaused, isFalse);
    });

    test(
      'waitWhilePaused blocks while paused and completes on resume',
      () async {
        final gate = PauseGate()..pause();
        final pausedFlags = <bool>[];

        final waitFuture = gate
            .waitWhilePaused(onPaused: () => pausedFlags.add(gate.isPaused))
            .timeout(const Duration(seconds: 2));

        // Give the loop a tick to enter the wait.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(gate.isPaused, isTrue);

        gate.resume();

        // Must not throw (resolves cleanly on resume).
        await waitFuture;
        expect(gate.isPaused, isFalse);
        expect(pausedFlags, contains(true));
      },
    );

    test('onPaused fires exactly once per blocked wait', () async {
      final gate = PauseGate()..pause();
      var fired = 0;

      final waitFuture = gate
          .waitWhilePaused(onPaused: () => fired++)
          .timeout(const Duration(seconds: 2));

      await Future<void>.delayed(const Duration(milliseconds: 20));
      gate.resume();
      await waitFuture;

      expect(fired, 1);
    });

    test(
      'pause then resume then pause again blocks on the second pause',
      () async {
        final gate = PauseGate();
        gate.pause();
        gate.resume();
        gate.pause();

        final waitFuture = gate.waitWhilePaused().timeout(
          const Duration(seconds: 2),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        gate.resume();
        await waitFuture;
        expect(gate.isPaused, isFalse);
      },
    );

    test('resume before any pause is a no-op that does not throw', () {
      final gate = PauseGate();
      expect(gate.resume, returnsNormally);
    });
  });
}
