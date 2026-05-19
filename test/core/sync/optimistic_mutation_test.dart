import 'package:control_center/core/sync/optimistic_mutation.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 19 §6: the optimistic-mutation orchestration — success acks, failure
/// reverts AND surfaces (never silently). Exercised with a null store (sync
/// kill-switch off), where the ack/fail overlay is a no-op but the loud-failure
/// contract still holds; the overlay itself is covered by cc_data's
/// synced_store_test.
void main() {
  test(
    'a successful mutation applies and reports true, no error surfaced',
    () async {
      Object? surfaced;
      final ok = await runOptimistic(
        store: null,
        table: 'tickets',
        pk: 't1',
        overlay: const {'title': 'new'},
        mutate: () async {},
        onError: (e) => surfaced = e,
      );
      expect(ok, isTrue);
      expect(surfaced, isNull);
    },
  );

  test(
    'a failed mutation reports false and surfaces the error loudly',
    () async {
      Object? surfaced;
      final ok = await runOptimistic(
        store: null,
        table: 'tickets',
        pk: 't1',
        overlay: const {'title': 'new'},
        mutate: () async => throw StateError('server rejected'),
        onError: (e) => surfaced = e,
      );
      expect(ok, isFalse);
      // The failure was surfaced — immediacy never trades against truth.
      expect(surfaced, isA<StateError>());
    },
  );
}
