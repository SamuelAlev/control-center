import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/services/mention_resolver.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(String id, String name) => Agent(
      id: id,
      workspaceId: 'ws1',
      name: name,
      title: name,
      agentMdPath: '/tmp/$name.md',
      skills: AgentSkills([]),
      createdAt: DateTime(2025),
    );

void main() {
  group('MentionResolver', () {
    late MentionResolver resolver;
    late List<Agent> agents;

    setUp(() {
      resolver = const MentionResolver();
      agents = [
        _agent('a1', 'Alice'),
        _agent('a2', 'Bob'),
        _agent('a3', 'ceo'),
      ];
    });

    test('resolves by exact name', () {
      final result = resolver.resolve('Alice', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a1');
      expect(result.resolvedVia, 'name');
    });

    test('resolves case-insensitively', () {
      final result = resolver.resolve('aLiCe', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a1');
    });

    test('resolves all-lowercase', () {
      final result = resolver.resolve('bob', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a2');
    });

    test('resolves all-uppercase', () {
      final result = resolver.resolve('CEO', agents);
      expect(result, isNotNull);
      expect(result!.agent.id, 'a3');
    });

    test('returns null for unknown name', () {
      final result = resolver.resolve('Charlie', agents);
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = resolver.resolve('', agents);
      expect(result, isNull);
    });

    test('returns null for empty agent list', () {
      final result = resolver.resolve('Alice', []);
      expect(result, isNull);
    });

    test('returns null when multiple agents match (same name)', () {
      final dupes = [
        _agent('a1', 'Alice'),
        _agent('a2', 'Alice'),
      ];
      final result = resolver.resolve('Alice', dupes);
      expect(result, isNull);
    });

    test('returns null when no agents match (similar but not same)', () {
      final result = resolver.resolve('Alicee', agents);
      expect(result, isNull);
    });

    test('resolves single from many', () {
      final many = List.generate(50, (i) => _agent('a$i', 'Agent$i'));
      many.add(_agent('target', 'TargetBot'));
      final result = resolver.resolve('TargetBot', many);
      expect(result, isNotNull);
      expect(result!.agent.id, 'target');
    });

    test('leading/trailing whitespace in token does not match', () {
      final result = resolver.resolve(' Alice ', agents);
      expect(result, isNull);
    });
  });

  group('ResolvedMention', () {
    test('holds agent and resolvedVia', () {
      final agent = _agent('a1', 'Alice');
      final mention = ResolvedMention(agent: agent, resolvedVia: 'name');
      expect(mention.agent, same(agent));
      expect(mention.resolvedVia, 'name');
    });

    test('default resolvedVia', () {
      final agent = _agent('a1', 'Alice');
      final mention = ResolvedMention(agent: agent, resolvedVia: 'alias');
      expect(mention.resolvedVia, 'alias');
    });
  });
}
