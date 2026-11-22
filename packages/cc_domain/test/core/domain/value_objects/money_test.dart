import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:test/test.dart';

void main() {
  group('units', () {
    test('a dollar is a million micros and a cent ten thousand', () {
      expect(microsPerDollar, 1000000);
      expect(microsPerCent, 10000);
    });

    test('a budget typed as dollars and one typed as cents store the same '
        'micros', () {
      expect(parseDollarsToMicros('5'), centsToMicros(500));
      expect(parseDollarsToMicros(r'$12.34'), centsToMicros(1234));
      expect(dollarsToMicros(0.07), centsToMicros(7));
      expect(parseDollarsToMicros('0.0042'), 4200);
    });

    test('a dollar input that is not a number parses to null', () {
      expect(parseDollarsToMicros('abc'), isNull);
      expect(parseDollarsToMicros(''), isNull);
      expect(parseDollarsToMicros('Infinity'), isNull);
    });
  });

  group('formatUsdMicros', () {
    test('renders cents precision, rounded to the nearest cent', () {
      expect(formatUsdMicros(0), r'$0.00');
      expect(formatUsdMicros(1234567), r'$1.23');
      expect(formatUsdMicros(50000000), r'$50.00');
      expect(formatUsdMicros(5000), r'$0.01');
      expect(formatUsdMicros(4999), r'$0.00');
      expect(formatUsdMicros(-1500000), r'-$1.50');
    });
  });

  group('sub-cent spend', () {
    test('a thousand calls of 42 micros each add up to 4.2 cents', () {
      var total = RunCost.zero;
      for (var i = 0; i < 1000; i++) {
        total = total + const RunCost(inputTokens: 1, costMicros: 42);
      }
      expect(total.costMicros, 42000);
    });

    test('many sub-cent runs reach a goal cost cap', () {
      var goal = AgentGoalRun(
        id: 'g',
        workspaceId: 'w',
        spaceId: 's',
        conversationId: 'c',
        agentId: 'a',
        userText: 'ship it',
        costCapMicros: centsToMicros(1),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      for (var i = 0; i < 3; i++) {
        goal = goal.copyWith(costMicros: goal.costMicros + 3000);
      }
      expect(goal.costCapReached, isFalse);
      goal = goal.copyWith(costMicros: goal.costMicros + 3000);
      expect(goal.costMicros, 12000);
      expect(goal.costCapReached, isTrue);
    });
  });
}
