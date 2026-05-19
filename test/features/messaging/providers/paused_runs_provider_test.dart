import 'package:control_center/features/messaging/providers/paused_runs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [PausedRunsNotifier] — the client-local, optimistic set of
/// runs the operator has paused. The pause gate itself lives server-side; this
/// set only tracks which rows show a "resume" affordance instead of "pause".
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('starts empty', () {
    expect(container.read(pausedRunsProvider), isEmpty);
  });

  group('markPaused', () {
    test('adds the run id to the set', () {
      container.read(pausedRunsProvider.notifier).markPaused('run-1');
      expect(container.read(pausedRunsProvider), {'run-1'});
    });

    test('is additive — preserves existing paused ids', () {
      container.read(pausedRunsProvider.notifier).markPaused('run-1');
      container.read(pausedRunsProvider.notifier).markPaused('run-2');
      expect(container.read(pausedRunsProvider), {'run-1', 'run-2'});
    });

    test('marking an already-paused run is idempotent', () {
      container.read(pausedRunsProvider.notifier).markPaused('run-1');
      container.read(pausedRunsProvider.notifier).markPaused('run-1');
      expect(container.read(pausedRunsProvider), {'run-1'});
    });
  });

  group('markResumed', () {
    test('removes the run id from the set', () {
      container.read(pausedRunsProvider.notifier).markPaused('run-1');
      container.read(pausedRunsProvider.notifier).markPaused('run-2');
      container.read(pausedRunsProvider.notifier).markResumed('run-1');
      expect(container.read(pausedRunsProvider), {'run-2'});
    });

    test('resuming an unknown id is a no-op (no throw)', () {
      container.read(pausedRunsProvider.notifier).markResumed('never-paused');
      expect(container.read(pausedRunsProvider), isEmpty);
    });

    test('resuming when the set is empty is a no-op', () {
      container.read(pausedRunsProvider.notifier).markResumed('run-1');
      expect(container.read(pausedRunsProvider), isEmpty);
    });
  });
}
