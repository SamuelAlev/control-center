import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/dispatch/run_cost_tally.dart';
import 'package:test/test.dart';

UsageEvent _usage(int micros, {UsageScope scope = UsageScope.request}) =>
    UsageEvent(
      usage: RunUsage(inputTokens: 10, costMicros: micros),
      scope: scope,
    );

/// The cost a run the session ends itself settles with, on any backend that
/// reports usage (Claude Code's turn deltas and run snapshots, an ACP
/// agent's reports).
void main() {
  test('nothing reported leaves the row its own cost', () {
    expect(RunCostTally().total, isNull);
  });

  test('additive reports sum', () {
    final tally = RunCostTally()
      ..add(_usage(100))
      ..add(_usage(250, scope: UsageScope.turn));

    expect(tally.total!.costMicros, 350);
    expect(tally.total!.inputTokens, 20);
  });

  test('a run snapshot replaces the total, and the last one wins', () {
    final tally = RunCostTally()
      ..add(_usage(100, scope: UsageScope.turn))
      ..add(_usage(300, scope: UsageScope.runCumulative))
      ..add(_usage(120, scope: UsageScope.turn))
      ..add(_usage(420, scope: UsageScope.runCumulative));

    expect(tally.total!.costMicros, 420);
  });

  test('a run that reported only zero usage still settles with zero', () {
    final tally = RunCostTally()..add(_usage(0));

    expect(tally.total, isNotNull);
    expect(tally.total!.costMicros, 0);
    expect(tally.total, isA<RunCost>());
  });
}
