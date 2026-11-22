import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:test/test.dart';

/// Every enum the wake, peer-ask, improvement and goal-verification model
/// persists: snake_case wire names that are unique, parse back, and refuse
/// anything else.
void main() {
  final snake = RegExp(r'^[a-z]+(_[a-z]+)*$');

  void pin<T>(
    String name,
    List<T> values,
    String Function(T) wire,
    T? Function(String?) parse,
    List<String> wireNames,
  ) {
    test('$name wire names', () {
      expect(wireNames, [for (final v in values) wire(v)]);
      expect(wireNames.toSet(), hasLength(values.length));
      for (final v in values) {
        expect(wire(v), matches(snake));
        expect(parse(wire(v)), v);
      }
      expect(parse(null), isNull);
      expect(parse(''), isNull);
      expect(parse('not_a_value'), isNull);
    });
  }

  pin(
    'WakeLane',
    WakeLane.values,
    (v) => v.wire,
    WakeLaneWire.tryParse,
    WakeLaneWire.wireNames,
  );
  pin(
    'WakeState',
    WakeState.values,
    (v) => v.wire,
    WakeStateWire.tryParse,
    WakeStateWire.wireNames,
  );
  pin(
    'WakeEventKind',
    WakeEventKind.values,
    (v) => v.wire,
    WakeEventKindWire.tryParse,
    WakeEventKindWire.wireNames,
  );
  pin(
    'WakeRuleStatus',
    WakeRuleStatus.values,
    (v) => v.wire,
    WakeRuleStatusWire.tryParse,
    WakeRuleStatusWire.wireNames,
  );
  pin(
    'WakeRuleEndReason',
    WakeRuleEndReason.values,
    (v) => v.wire,
    WakeRuleEndReasonWire.tryParse,
    WakeRuleEndReasonWire.wireNames,
  );
  pin(
    'WakeDeliver',
    WakeDeliver.values,
    (v) => v.wire,
    WakeDeliverWire.tryParse,
    WakeDeliverWire.wireNames,
  );
  pin(
    'WakeWhenBusy',
    WakeWhenBusy.values,
    (v) => v.wire,
    WakeWhenBusyWire.tryParse,
    WakeWhenBusyWire.wireNames,
  );
  pin(
    'WakeRuleOrigin',
    WakeRuleOrigin.values,
    (v) => v.wire,
    WakeRuleOriginWire.tryParse,
    WakeRuleOriginWire.wireNames,
  );
  pin(
    'PeerAskKind',
    PeerAskKind.values,
    (v) => v.wire,
    PeerAskKindWire.tryParse,
    PeerAskKindWire.wireNames,
  );
  pin(
    'PeerAskMode',
    PeerAskMode.values,
    (v) => v.wire,
    PeerAskModeWire.tryParse,
    PeerAskModeWire.wireNames,
  );
  pin(
    'PeerAskStatus',
    PeerAskStatus.values,
    (v) => v.wire,
    PeerAskStatusWire.tryParse,
    PeerAskStatusWire.wireNames,
  );
  pin(
    'ImprovementKind',
    ImprovementKind.values,
    (v) => v.wire,
    ImprovementKindWire.tryParse,
    ImprovementKindWire.wireNames,
  );
  pin(
    'ImprovementScope',
    ImprovementScope.values,
    (v) => v.wire,
    ImprovementScopeWire.tryParse,
    ImprovementScopeWire.wireNames,
  );
  pin(
    'ImprovementOperation',
    ImprovementOperation.values,
    (v) => v.wire,
    ImprovementOperationWire.tryParse,
    ImprovementOperationWire.wireNames,
  );
  pin(
    'ImprovementStatus',
    ImprovementStatus.values,
    (v) => v.wire,
    ImprovementStatusWire.tryParse,
    ImprovementStatusWire.wireNames,
  );
  pin(
    'ImprovementCampaignState',
    ImprovementCampaignState.values,
    (v) => v.wire,
    ImprovementCampaignStateWire.tryParse,
    ImprovementCampaignStateWire.wireNames,
  );
  pin(
    'GoalUnattendedPolicy',
    GoalUnattendedPolicy.values,
    (v) => v.wire,
    GoalUnattendedPolicyWire.tryParse,
    GoalUnattendedPolicyWire.wireNames,
  );
  pin(
    'GoalCheckLocation',
    GoalCheckLocation.values,
    (v) => v.wire,
    GoalCheckLocationWire.tryParse,
    GoalCheckLocationWire.wireNames,
  );
  pin(
    'GoalVerdictOutcome',
    GoalVerdictOutcome.values,
    (v) => v.wire,
    GoalVerdictOutcomeWire.tryParse,
    GoalVerdictOutcomeWire.wireNames,
  );
  pin(
    'GoalCriterionState',
    GoalCriterionState.values,
    (v) => v.wire,
    GoalCriterionStateWire.tryParse,
    GoalCriterionStateWire.wireNames,
  );

  test('the names other code relies on', () {
    expect(WakeLane.followUp.wire, 'follow_up');
    expect(ImprovementStatus.rolledBack.wire, 'rolled_back');
    expect(GoalVerdictOutcome.cannotVerify.wire, 'cannot_verify');
    expect(GoalCriterionState.cannotTell.wire, 'cannot_tell');
    expect(WakeEventKind.pipelineRun.wire, 'pipeline_run');
  });

  test('settled wake states', () {
    expect(
      {
        for (final s in WakeState.values)
          if (s.isSettled) s,
      },
      {
        WakeState.delivered,
        WakeState.skipped,
        WakeState.expired,
        WakeState.cancelled,
      },
    );
  });
}
