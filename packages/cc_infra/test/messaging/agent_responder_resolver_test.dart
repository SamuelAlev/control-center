import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_infra/src/messaging/agent_responder_resolver.dart';
import 'package:test/test.dart';

/// `AgentResponderResolver.resolveDefault` is pure logic — it picks which agent
/// should reply given the conversation's last sender, a lead hint and the
/// agents list. These pin the fallback chain.
void main() {
  Agent agent({required String id, String? reportsTo}) => Agent(
    id: id,
    name: id,
    title: id,
    agentMdPath: '/tmp/$id.md',
    workspaceId: 'w',
    skills: AgentSkills(const <String>[]),
    createdAt: DateTime.utc(2026, 1, 1),
    reportsTo: reportsTo,
  );

  group('AgentResponderResolver.resolveDefault', () {
    test('returns null when no agents are provided', () {
      expect(
        AgentResponderResolver.resolveDefault(agents: const <Agent>[]),
        isNull,
      );
    });

    test('returns the last sender when present in the agent list', () {
      final a = agent(id: 'a');
      final b = agent(id: 'b');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[a, b],
        lastAgentSenderId: 'b',
      );

      expect(result, same(b));
    });

    test('ignores lastAgentSenderId when not present in the list', () {
      final a = agent(id: 'a');
      final b = agent(id: 'b');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[a, b],
        lastAgentSenderId: 'gone',
      );

      // Falls back to first top-level agent.
      expect(result, same(a));
    });

    test('returns the lead hint when it is in the list', () {
      final a = agent(id: 'a');
      final b = agent(id: 'b');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[a, b],
        leadHint: b,
      );

      expect(result, same(b));
    });

    test('ignores lead hint not in the list', () {
      final a = agent(id: 'a');
      final outside = agent(id: 'outside');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[a],
        leadHint: outside,
      );

      expect(result, same(a));
    });

    test('prefers last sender over lead hint', () {
      final a = agent(id: 'a');
      final b = agent(id: 'b');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[a, b],
        lastAgentSenderId: 'a',
        leadHint: b,
      );

      expect(result, same(a));
    });

    test('prefers top-level agents over a child', () {
      final child = agent(id: 'child', reportsTo: 'parent');
      final top = agent(id: 'top');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[child, top],
      );

      expect(result, same(top));
    });

    test('falls back to the first agent when none are top-level', () {
      final child1 = agent(id: 'c1', reportsTo: 'p');
      final child2 = agent(id: 'c2', reportsTo: 'p');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[child1, child2],
      );

      expect(result, same(child1));
    });

    test('returns the sole agent for a single-agent channel', () {
      final sole = agent(id: 'only');
      final result = AgentResponderResolver.resolveDefault(
        agents: <Agent>[sole],
      );

      expect(result, same(sole));
    });
  });
}
