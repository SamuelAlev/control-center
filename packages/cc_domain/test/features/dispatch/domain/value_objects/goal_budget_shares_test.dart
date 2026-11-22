import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:test/test.dart';

AgentGoalRun _goal({required int cap, required int spent}) => AgentGoalRun(
  id: 'g-1',
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Ship it',
  costCapMicros: cap,
  costMicros: spent,
  createdAt: DateTime.utc(2026, 11, 19),
  updatedAt: DateTime.utc(2026, 11, 19),
);

void main() {
  test('a segment may spend what is left, at most 5 USD', () {
    expect(goalSegmentCapMicros(_goal(cap: 50000000, spent: 0)), 5000000);
    expect(goalSegmentCapMicros(_goal(cap: 3000000, spent: 1000000)), 2000000);
    expect(goalSegmentCapMicros(_goal(cap: 3000000, spent: 3000000)), 0);
    expect(goalSegmentCapMicros(_goal(cap: 3000000, spent: 4000000)), 0);
  });

  test('a review may spend what is left, at most 2 USD', () {
    expect(goalReviewCapMicros(_goal(cap: 50000000, spent: 0)), 2000000);
    expect(goalReviewCapMicros(_goal(cap: 1000000, spent: 400000)), 600000);
    expect(goalReviewCapMicros(_goal(cap: 1000000, spent: 1000000)), 0);
  });
}
