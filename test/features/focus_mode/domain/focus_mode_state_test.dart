import 'package:control_center/features/focus_mode/domain/focus_mode_state.dart';
import 'package:test/test.dart';

void main() {
  group('FocusModeState', () {
    test('default values are correct', () {
      const state = FocusModeState(active: false);
      expect(state.active, isFalse);
      expect(state.sessionStartedAt, isNull);
      expect(state.sessionDurationMinutes, equals(50));
      expect(state.goal, isNull);
      expect(state.compactMode, isFalse);
      expect(state.blockNotifications, isTrue);
      expect(state.pausedAt, isNull);
    });

    group('isPaused', () {
      test('returns false when pausedAt is null', () {
        const state = FocusModeState(active: true, pausedAt: null);
        expect(state.isPaused, isFalse);
      });

      test('returns true when pausedAt is set', () {
        final state = FocusModeState(
          active: true,
          pausedAt: DateTime(2026, 6, 10, 12, 0),
        );
        expect(state.isPaused, isTrue);
      });
    });

    group('elapsed', () {
      test('returns zero when not active', () {
        const state = FocusModeState(active: false);
        expect(state.elapsed, equals(Duration.zero));
      });

      test('returns zero when active but no sessionStartedAt', () {
        const state = FocusModeState(active: true);
        expect(state.elapsed, equals(Duration.zero));
      });

      test('computes elapsed from sessionStartedAt when active and not paused', () {
        final now = DateTime.now();
        final startedAt = now.subtract(const Duration(minutes: 5));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.elapsed.inMinutes, greaterThanOrEqualTo(5));
        expect(state.elapsed.inMinutes, lessThanOrEqualTo(6));
      });

      test('freezes elapsed when paused (uses pausedAt instead of DateTime.now)', () {
        final startedAt = DateTime(2026, 6, 10, 10, 0);
        final pausedAt = DateTime(2026, 6, 10, 10, 10);
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
          pausedAt: pausedAt,
        );
        expect(state.elapsed, equals(const Duration(minutes: 10)));
      });
    });

    group('minutesRemaining', () {
      test('returns full duration when elapsed is zero', () {
        const state = FocusModeState(active: false);
        expect(state.minutesRemaining, equals(50));
      });

      test('returns clamped value when elapsed exceeds duration', () {
        final startedAt = DateTime.now().subtract(const Duration(minutes: 60));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.minutesRemaining, equals(0));
      });

      test('returns remaining minutes when within session', () {
        final startedAt = DateTime.now().subtract(const Duration(minutes: 20));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        final remaining = state.minutesRemaining;
        expect(remaining, greaterThanOrEqualTo(29));
        expect(remaining, lessThanOrEqualTo(30));
      });

      test('respects custom sessionDurationMinutes when active', () {
        final startedAt = DateTime.now().subtract(const Duration(minutes: 5));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
          sessionDurationMinutes: 25,
        );
        expect(state.minutesRemaining, greaterThanOrEqualTo(19));
        expect(state.minutesRemaining, lessThanOrEqualTo(20));
      });

      test('returns full custom duration when elapsed is zero', () {
        const state = FocusModeState(
          active: false,
          sessionDurationMinutes: 30,
        );
        expect(state.minutesRemaining, equals(30));
      });
    });

    group('secondsRemaining', () {
      test('returns full seconds when not active', () {
        const state = FocusModeState(active: false, sessionDurationMinutes: 1);
        expect(state.secondsRemaining, equals(60));
      });

      test('clamps to zero when elapsed exceeds session', () {
        final startedAt = DateTime.now().subtract(const Duration(hours: 1));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
          sessionDurationMinutes: 1,
        );
        expect(state.secondsRemaining, equals(0));
      });

      test('calculates remaining seconds when within session', () {
        final startedAt = DateTime.now().subtract(const Duration(seconds: 30));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
          sessionDurationMinutes: 1,
        );
        expect(state.secondsRemaining, greaterThanOrEqualTo(29));
        expect(state.secondsRemaining, lessThanOrEqualTo(30));
      });
    });

    group('sessionProgress', () {
      test('returns 0 when not active', () {
        const state = FocusModeState(active: false);
        expect(state.sessionProgress, equals(0.0));
      });

      test('returns 0 when duration is zero', () {
        final state = FocusModeState(
          active: true,
          sessionDurationMinutes: 0,
          sessionStartedAt: DateTime.now(),
        );
        expect(state.sessionProgress, equals(0.0));
      });

      test('returns 0 when session just started', () {
        final state = FocusModeState(
          active: true,
          sessionStartedAt: DateTime.now(),
        );
        expect(state.sessionProgress, equals(0.0));
      });

      test('returns 1.0 when session is over', () {
        final startedAt = DateTime.now().subtract(const Duration(hours: 1));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.sessionProgress, equals(1.0));
      });

      test('computes fractional progress mid-session', () {
        final startedAt = DateTime.now().subtract(const Duration(minutes: 25));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.sessionProgress, greaterThanOrEqualTo(0.49));
        expect(state.sessionProgress, lessThanOrEqualTo(0.51));
      });
    });

    group('withinSession', () {
      test('returns false when not active', () {
        const state = FocusModeState(active: false);
        expect(state.withinSession, isFalse);
      });

      test('returns false when session has expired', () {
        final startedAt = DateTime.now().subtract(const Duration(hours: 1));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.withinSession, isFalse);
      });

      test('returns true when within session duration', () {
        final startedAt = DateTime.now().subtract(const Duration(minutes: 10));
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        expect(state.withinSession, isTrue);
      });

      test('boundary case - exactly at session duration', () {
        final startedAt = DateTime.now().subtract(
          const Duration(minutes: 50),
        );
        final state = FocusModeState(
          active: true,
          sessionStartedAt: startedAt,
        );
        // exactly at 50 min elapsed is >= 50, so withinSession is false
        expect(state.withinSession, isFalse);
      });
    });

    group('copyWith', () {
      test('creates identical copy with no changes', () {
        final original = FocusModeState(
          active: true,
          sessionStartedAt: DateTime(2026, 6, 10, 10, 0),
          sessionDurationMinutes: 30,
          goal: 'Focus on testing',
          compactMode: true,
          blockNotifications: false,
          pausedAt: DateTime(2026, 6, 10, 10, 15),
        );
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('replaces active', () {
        final copy = const FocusModeState(active: false).copyWith(active: true);
        expect(copy.active, isTrue);
      });

      test('replaces sessionStartedAt', () {
        final dt = DateTime(2026, 6, 10);
        final copy = const FocusModeState(active: true).copyWith(
          sessionStartedAt: dt,
        );
        expect(copy.sessionStartedAt, equals(dt));
      });

      test('replaces sessionDurationMinutes', () {
        final copy = const FocusModeState(active: true).copyWith(
          sessionDurationMinutes: 25,
        );
        expect(copy.sessionDurationMinutes, equals(25));
      });

      test('replaces goal', () {
        final copy = const FocusModeState(active: true).copyWith(goal: 'Study');
        expect(copy.goal, equals('Study'));
      });

      test('replaces compactMode', () {
        final copy = const FocusModeState(active: true).copyWith(compactMode: true);
        expect(copy.compactMode, isTrue);
      });

      test('replaces blockNotifications', () {
        final copy = const FocusModeState(active: true).copyWith(
          blockNotifications: false,
        );
        expect(copy.blockNotifications, isFalse);
      });

      test('replaces pausedAt', () {
        final dt = DateTime(2026, 6, 10);
        final copy = const FocusModeState(active: true).copyWith(pausedAt: dt);
        expect(copy.pausedAt, equals(dt));
      });

      test('clears sessionStartedAt when clearStartedAt is true', () {
        final original = FocusModeState(
          active: true,
          sessionStartedAt: DateTime(2026),
        );
        final copy = original.copyWith(clearStartedAt: true);
        expect(copy.sessionStartedAt, isNull);
      });

      test('clears goal when clearGoal is true', () {
        const original = FocusModeState(active: true, goal: 'old goal');
        final copy = original.copyWith(clearGoal: true);
        expect(copy.goal, isNull);
      });

      test('clears pausedAt when clearPausedAt is true', () {
        final original = FocusModeState(
          active: true,
          pausedAt: DateTime(2026),
        );
        final copy = original.copyWith(clearPausedAt: true);
        expect(copy.pausedAt, isNull);
      });

      test('clear flags take precedence over new values', () {
        const original = FocusModeState(active: true);
        final copy = original.copyWith(
          clearGoal: true,
          goal: 'rewrite',
        );
        expect(copy.goal, isNull);
      });

      test('preserves unmentioned fields', () {
        const original = FocusModeState(
          active: true,
          compactMode: true,
          blockNotifications: false,
          sessionDurationMinutes: 30,
        );
        final copy = original.copyWith(active: false);
        expect(copy.compactMode, isTrue);
        expect(copy.blockNotifications, isFalse);
        expect(copy.sessionDurationMinutes, equals(30));
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        const a = FocusModeState(active: true, goal: 'test');
        const b = FocusModeState(active: true, goal: 'test');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different active makes them unequal', () {
        const a = FocusModeState(active: true);
        const b = FocusModeState(active: false);
        expect(a, isNot(equals(b)));
      });

      test('different sessionStartedAt makes them unequal', () {
        final a = FocusModeState(
          active: true,
          sessionStartedAt: DateTime(2026, 6, 10),
        );
        final b = FocusModeState(
          active: true,
          sessionStartedAt: DateTime(2026, 6, 11),
        );
        expect(a, isNot(equals(b)));
      });

      test('different pausedAt makes them unequal', () {
        final a = FocusModeState(
          active: true,
          pausedAt: DateTime(2026, 6, 10),
        );
        final b = FocusModeState(
          active: true,
          pausedAt: DateTime(2026, 6, 11),
        );
        expect(a, isNot(equals(b)));
      });

      test('different sessionDurationMinutes makes them unequal', () {
        const a = FocusModeState(active: true, sessionDurationMinutes: 50);
        const b = FocusModeState(active: true, sessionDurationMinutes: 25);
        expect(a, isNot(equals(b)));
      });

      test('different goal makes them unequal', () {
        const a = FocusModeState(active: true, goal: 'A');
        const b = FocusModeState(active: true, goal: 'B');
        expect(a, isNot(equals(b)));
      });

      test('different compactMode makes them unequal', () {
        const a = FocusModeState(active: true, compactMode: false);
        const b = FocusModeState(active: true, compactMode: true);
        expect(a, isNot(equals(b)));
      });

      test('different blockNotifications makes them unequal', () {
        const a = FocusModeState(active: true, blockNotifications: true);
        const b = FocusModeState(active: true, blockNotifications: false);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
