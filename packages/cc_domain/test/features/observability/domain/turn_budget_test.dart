import 'package:cc_domain/features/observability/domain/turn_budget.dart';
import 'package:test/test.dart';

void main() {
  group('TurnBudget value object', () {
    test('defaults to a soft budget', () {
      const budget = TurnBudget(200);
      expect(budget.total, 200);
      expect(budget.hard, isFalse);
    });

    test('structural equality and hashCode', () {
      expect(const TurnBudget(500000), const TurnBudget(500000));
      expect(
        const TurnBudget(500000).hashCode,
        const TurnBudget(500000).hashCode,
      );
      expect(const TurnBudget(500000), isNot(const TurnBudget(500001)));
      expect(
        const TurnBudget(500000, hard: true),
        isNot(const TurnBudget(500000)),
      );
      expect(
        const TurnBudget(500000, hard: true).hashCode,
        isNot(const TurnBudget(500000).hashCode),
      );
    });

    test('identical instance is equal', () {
      const budget = TurnBudget(10);
      expect(budget == budget, isTrue);
    });
  });

  group('parseTurnBudget', () {
    test('parses a k-suffixed soft budget', () {
      expect(parseTurnBudget('+500k'), const TurnBudget(500000));
    });

    test('parses a k-suffixed hard budget', () {
      expect(parseTurnBudget('+500k!'), const TurnBudget(500000, hard: true));
    });

    test('parses an m-suffixed decimal budget', () {
      expect(parseTurnBudget('+1.5m'), const TurnBudget(1500000));
    });

    test('parses a bare integer budget', () {
      expect(parseTurnBudget('+200'), const TurnBudget(200));
    });

    test('returns null when no directive is present', () {
      expect(parseTurnBudget('no directive'), isNull);
    });

    test('returns null for +0 (non-positive)', () {
      expect(parseTurnBudget('+0'), isNull);
    });

    test('returns null for +0.0', () {
      expect(parseTurnBudget('+0.0'), isNull);
    });

    test('returns null for +0k', () {
      expect(parseTurnBudget('+0k'), isNull);
    });

    test('extracts a directive embedded in a sentence', () {
      expect(parseTurnBudget('do X +500k please'), const TurnBudget(500000));
    });

    test('extracts a hard directive embedded in a sentence', () {
      expect(
        parseTurnBudget('please keep it tight +1.5m! thanks'),
        const TurnBudget(1500000, hard: true),
      );
    });

    test('parses a directive at the very start of the string', () {
      expect(parseTurnBudget('+200 do the thing'), const TurnBudget(200));
    });

    test('parses a directive at the very end of the string', () {
      expect(parseTurnBudget('do the thing +200'), const TurnBudget(200));
    });

    test('unit suffix is case-insensitive', () {
      expect(parseTurnBudget('+500K'), const TurnBudget(500000));
      expect(parseTurnBudget('+1.5M'), const TurnBudget(1500000));
      expect(parseTurnBudget('+2K!'), const TurnBudget(2000, hard: true));
    });

    test('rounds fractional results to the nearest token', () {
      // 1.2345k = 1234.5 -> rounds to 1235 (round-half-away-from-zero).
      expect(parseTurnBudget('+1.2345k'), const TurnBudget(1235));
      // 1.2344k = 1234.4 -> rounds down to 1234.
      expect(parseTurnBudget('+1.2344k'), const TurnBudget(1234));
    });

    test('does not match a directive glued to a preceding token', () {
      // No whitespace boundary before the '+', so the lookbehind fails.
      expect(parseTurnBudget('x+500k'), isNull);
    });

    test('does not match a directive with a trailing non-boundary char', () {
      // 'k' followed by a letter is not a valid unit boundary.
      expect(parseTurnBudget('+500kg'), isNull);
    });

    test('matches the first directive when several are present', () {
      expect(parseTurnBudget('+200 then later +500k'), const TurnBudget(200));
    });

    test('an isolated plus sign is not a budget', () {
      expect(parseTurnBudget('a + b'), isNull);
    });
  });

  group('TurnBudgetTracker — soft budget', () {
    test('stays none below the ceiling', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      expect(tracker.record(40), TurnBudgetDecision.none);
      expect(tracker.record(40), TurnBudgetDecision.none);
      expect(tracker.outputTokens, 80);
      expect(tracker.fraction, closeTo(0.8, 1e-9));
    });

    test('steers once on first crossing, then goes silent', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      expect(tracker.record(60), TurnBudgetDecision.none);
      // Crosses 100 -> steer (once).
      expect(tracker.record(50), TurnBudgetDecision.steer);
      expect(tracker.outputTokens, 110);
      // Already steered -> none thereafter, even when still over.
      expect(tracker.record(10), TurnBudgetDecision.none);
      expect(tracker.record(1000), TurnBudgetDecision.none);
    });

    test('steers when output exactly equals the ceiling', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      expect(tracker.record(100), TurnBudgetDecision.steer);
    });

    test('fraction can exceed 1 once over budget', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      tracker.record(150);
      expect(tracker.fraction, closeTo(1.5, 1e-9));
    });
  });

  group('TurnBudgetTracker — hard budget', () {
    test('reports exceeded on every call once over', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100, hard: true));
      expect(tracker.record(50), TurnBudgetDecision.none);
      expect(tracker.record(60), TurnBudgetDecision.exceeded);
      // Hard budgets keep reporting exceeded (no once-only suppression).
      expect(tracker.record(0), TurnBudgetDecision.exceeded);
      expect(tracker.record(5), TurnBudgetDecision.exceeded);
    });

    test('exceeded when output exactly equals the ceiling', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100, hard: true));
      expect(tracker.record(100), TurnBudgetDecision.exceeded);
    });

    test('never reports steer', () {
      final tracker = TurnBudgetTracker(const TurnBudget(10, hard: true));
      final decisions = <TurnBudgetDecision>[];
      for (var i = 0; i < 5; i++) {
        decisions.add(tracker.record(5));
      }
      expect(decisions, isNot(contains(TurnBudgetDecision.steer)));
    });
  });

  group('TurnBudgetTracker — edge cases', () {
    test('negative deltas are ignored', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      expect(tracker.record(-50), TurnBudgetDecision.none);
      expect(tracker.outputTokens, 0);
      expect(tracker.record(100), TurnBudgetDecision.steer);
      expect(tracker.record(-1000), TurnBudgetDecision.none);
      expect(tracker.outputTokens, 100);
    });

    test('zero delta does not cross a soft budget early', () {
      final tracker = TurnBudgetTracker(const TurnBudget(100));
      expect(tracker.record(0), TurnBudgetDecision.none);
      expect(tracker.outputTokens, 0);
    });

    test('non-positive total budget never fires and has 0 fraction', () {
      final tracker = TurnBudgetTracker(const TurnBudget(0, hard: true));
      expect(tracker.record(1000), TurnBudgetDecision.none);
      expect(tracker.fraction, 0);
    });
  });
}
