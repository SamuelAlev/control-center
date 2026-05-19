import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/shared/domain/services/mention_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _makeAgent({
  required String id,
  required String name,
  String? reportsTo,
}) =>
    Agent(
      id: id,
      name: name,
      title: 'Test',
      agentMdPath: '/$id.md',
      workspaceId: 'ws',
      skills: AgentSkills(const []),
      reportsTo: reportsTo,
      createdAt: DateTime(2026),
    );

void main() {
  const resolver = MentionResolver();

  group('MentionResolver', () {
    test('resolves by exact name match', () {
      final agents = [
        _makeAgent(id: 'a1', name: 'Kara'),
        _makeAgent(id: 'a2', name: 'Sam'),
      ];
      final result = resolver.resolve('kara', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a1');
      expect(result.resolvedVia, 'name');
    });

    test('returns null for unknown mention', () {
      final agents = [
        _makeAgent(id: 'a1', name: 'Kara'),
      ];
      final result = resolver.resolve('nobody', agents);
      expect(result, isNull);
    });

    test('returns null for ambiguous name match', () {
      final agents = [
        _makeAgent(id: 'a1', name: 'Kara'),
        _makeAgent(id: 'a2', name: 'kara'),
      ];
      final result = resolver.resolve('kara', agents);
      expect(result, isNull);
    });

    test('case-insensitive name match', () {
      final agents = [
        _makeAgent(id: 'a1', name: 'Kara'),
      ];
      final result = resolver.resolve('KARA', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a1');
    });
  });
}
