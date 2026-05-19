import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:test/test.dart';

void main() {
  group('FilterListUpdateState', () {
    final now = DateTime(2026, 6, 1, 12, 0, 0);
    final later = DateTime(2026, 6, 1, 13, 0, 0);

    group('constructor', () {
      test(
        'sets all fields',
        timeout: const Timeout.factor(2),
        () {
          const state = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );

          expect(state.lastCheck, isNull);
          expect(state.lastSuccess, isNull);
          expect(state.isUpdating, isFalse);
          expect(state.errors, isEmpty);
          expect(state.cookieHidingRules, 0);
          expect(state.adHidingRules, 0);
          expect(state.networkBlockRules, 0);
          expect(state.removeParamsCount, 0);
        },
      );
    });

    group('copyWith', () {
      test(
        'preserves unchanged fields',
        timeout: const Timeout.factor(2),
        () {
          final state = FilterListUpdateState(
            lastCheck: now,
            lastSuccess: later,
            isUpdating: true,
            errors: ['e1'],
            cookieHidingRules: 5,
            adHidingRules: 10,
            networkBlockRules: 15,
            removeParamsCount: 20,
          );

          final copy = state.copyWith();

          expect(copy.lastCheck, now);
          expect(copy.lastSuccess, later);
          expect(copy.isUpdating, true);
          expect(copy.errors, ['e1']);
          expect(copy.cookieHidingRules, 5);
          expect(copy.adHidingRules, 10);
          expect(copy.networkBlockRules, 15);
          expect(copy.removeParamsCount, 20);
        },
      );

      test(
        'overrides individual fields',
        timeout: const Timeout.factor(2),
        () {
          final state = FilterListUpdateState(
            lastCheck: now,
            lastSuccess: later,
            isUpdating: true,
            errors: ['e1'],
            cookieHidingRules: 5,
            adHidingRules: 10,
            networkBlockRules: 15,
            removeParamsCount: 20,
          );

          final copy = state.copyWith(isUpdating: false);

          expect(copy.isUpdating, false);
          // All other fields unchanged.
          expect(copy.lastCheck, now);
          expect(copy.lastSuccess, later);
          expect(copy.errors, ['e1']);
          expect(copy.cookieHidingRules, 5);
          expect(copy.adHidingRules, 10);
          expect(copy.networkBlockRules, 15);
          expect(copy.removeParamsCount, 20);
        },
      );

      test(
        'overrides multiple fields',
        timeout: const Timeout.factor(2),
        () {
          final state = FilterListUpdateState(
            lastCheck: now,
            lastSuccess: later,
            isUpdating: true,
            errors: ['e1'],
            cookieHidingRules: 5,
            adHidingRules: 10,
            networkBlockRules: 15,
            removeParamsCount: 20,
          );

          final copy = state.copyWith(
            isUpdating: false,
            cookieHidingRules: 99,
            errors: ['e2', 'e3'],
          );

          expect(copy.isUpdating, false);
          expect(copy.cookieHidingRules, 99);
          expect(copy.errors, ['e2', 'e3']);
          // Unchanged fields.
          expect(copy.lastCheck, now);
          expect(copy.lastSuccess, later);
          expect(copy.adHidingRules, 10);
          expect(copy.networkBlockRules, 15);
          expect(copy.removeParamsCount, 20);
        },
      );

      test(
        'copyWith with null preserves original for nullable fields',
        timeout: const Timeout.factor(2),
        () {
          final state = FilterListUpdateState(
            lastCheck: now,
            lastSuccess: later,
            isUpdating: true,
            errors: ['e1'],
            cookieHidingRules: 5,
            adHidingRules: 10,
            networkBlockRules: 15,
            removeParamsCount: 20,
          );

          // Passing null should preserve the original (only for nullable fields).
          final copy = state.copyWith(lastCheck: null, lastSuccess: null);

          expect(copy.lastCheck, now);
          expect(copy.lastSuccess, later);
          // Non-nullable fields unchanged.
          expect(copy.isUpdating, true);
          expect(copy.errors, ['e1']);
        },
      );

      test(
        'copyWith with zero counts overrides correctly',
        timeout: const Timeout.factor(2),
        () {
          const state = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: [],
            cookieHidingRules: 5,
            adHidingRules: 10,
            networkBlockRules: 15,
            removeParamsCount: 20,
          );

          final copy = state.copyWith(
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );

          expect(copy.cookieHidingRules, 0);
          expect(copy.adHidingRules, 0);
          expect(copy.networkBlockRules, 0);
          expect(copy.removeParamsCount, 0);
        },
      );
    });

    group('equality', () {
      test(
        'same values are equal',
        timeout: const Timeout.factor(2),
        () {
          const stateA = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );
          const stateB = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );

          expect(stateA, equals(stateB));
        },
      );

      test(
        'different values are not equal',
        timeout: const Timeout.factor(2),
        () {
          const stateA = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );
          const stateB = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: true,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );

          expect(stateA, isNot(equals(stateB)));
        },
      );
    });

    group('immutability', () {
      test(
        'copyWith returns a new instance',
        timeout: const Timeout.factor(2),
        () {
          const state = FilterListUpdateState(
            lastCheck: null,
            lastSuccess: null,
            isUpdating: false,
            errors: <String>[],
            cookieHidingRules: 0,
            adHidingRules: 0,
            networkBlockRules: 0,
            removeParamsCount: 0,
          );

          final copy = state.copyWith();

          expect(identical(state, copy), isFalse);
        },
      );
    });
  });
}
