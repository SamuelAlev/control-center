import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/services/mention_wake_policy.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(String id, String name) => Agent(
  id: id,
  name: name,
  title: 'Test $name',
  agentMdPath: '/agents/$id/agent.md',
  workspaceId: 'ws-1',
  skills: AgentSkills([]),
  createdAt: DateTime(2026),
);

void main() {
  group('MentionWakePolicy', () {
    const policy = MentionWakePolicy();
    final architect = _agent('a-1', 'architect');
    final builder = _agent('a-2', 'Builder');
    final self = _agent('a-3', 'indexer');

    List<MentionWakeTarget> resolve(
      List<String> tokens, {
      List<Agent>? candidates,
      MentionWakePolicy p = policy,
    }) => p.resolveTargets(
      tokens: tokens,
      candidates: candidates ?? [architect, builder, self],
      selfAgentId: self.id,
    );

    test('resolves an exact name', () {
      expect(resolve(['architect']).map((t) => t.agent.id), ['a-1']);
    });

    test('matches case-insensitively', () {
      expect(resolve(['builder']).map((t) => t.agent.id), ['a-2']);
    });

    test('drops an unknown name rather than guessing', () {
      expect(resolve(['archie']), isEmpty);
    });

    test('never prefix-matches', () {
      // The human composer path resolves "@arch" to architect; this one does
      // not — there is nobody watching to correct a wrong guess.
      expect(resolve(['arch']), isEmpty);
    });

    test('drops an ambiguous name', () {
      final twin = _agent('a-9', 'Architect');
      expect(
        resolve(['architect'], candidates: [architect, twin, self]),
        isEmpty,
      );
    });

    test('drops a self-mention', () {
      expect(resolve(['indexer']), isEmpty);
    });

    test('deduplicates by agent', () {
      expect(resolve(['architect', 'architect']).length, 1);
    });

    test('caps the number of wakes per turn', () {
      final many = [
        for (var i = 0; i < 6; i++) _agent('m-$i', 'agent$i'),
        self,
      ];
      final tokens = [for (var i = 0; i < 6; i++) 'agent$i'];
      expect(resolve(tokens, candidates: many).length, 3);
      expect(
        resolve(
          tokens,
          candidates: many,
          p: const MentionWakePolicy(maxWakesPerTurn: 5),
        ).length,
        5,
      );
    });

    test('preserves mention order', () {
      expect(resolve(['builder', 'architect']).map((t) => t.agent.id), [
        'a-2',
        'a-1',
      ]);
    });

    test('carries the token that resolved each target', () {
      expect(resolve(['builder']).single.token, 'builder');
    });
  });
}
