import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 3, 10, 14, 0);
  final skills = AgentSkills(['dart', 'flutter']);

  Agent createAgent({
    String id = 'agent-1',
    String name = 'kilo',
    String title = 'Kilo Agent',
    String agentMdPath = '/workspaces/ws-1/agents/kilo/AGENTS.md',
    String? reportsTo,
    AgentSkills? skillsParam,
    String? persona,
    String? systemPrompt,
    String? adapterId,
    String? modelId,
    bool strictMode = false,
    String? effort,
    int? contextSize,
    DateTime? createdAt,
  }) {
    return Agent(
      id: id,
      name: name,
      title: title,
      agentMdPath: agentMdPath,
      workspaceId: 'ws-1',
      reportsTo: reportsTo,
      skills: skillsParam ?? skills,
      persona: persona,
      systemPrompt: systemPrompt,
      adapterId: adapterId,
      modelId: modelId,
      strictMode: strictMode,
      effort: effort,
      contextSize: contextSize,
      createdAt: createdAt ?? now,
    );
  }

  group('Agent constructor', () {
    test('creates agent with required fields', () {
      final agent = createAgent();
      expect(agent.id, 'agent-1');
      expect(agent.name, 'kilo');
      expect(agent.title, 'Kilo Agent');
      expect(agent.skills, isA<AgentSkills>());
      expect(agent.strictMode, isFalse);
    });

    test('throws assertion error for empty name', () {
      expect(
        () => Agent(
          id: '1',
          name: '',
          title: 'Title',
          agentMdPath: '/path',
          workspaceId: 'ws-1',
          skills: skills,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error for empty title', () {
      expect(
        () => Agent(
          id: '1',
          name: 'name',
          title: '',
          agentMdPath: '/path',
          workspaceId: 'ws-1',
          skills: skills,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('stores optional fields', () {
      final agent = createAgent(
        persona: 'Friendly helper',
        systemPrompt: 'You are helpful.',
        adapterId: 'openai',
        modelId: 'gpt-4',
        strictMode: true,
      effort: 'high',
      contextSize: 4096,
    );
      expect(agent.persona, 'Friendly helper');
      expect(agent.systemPrompt, 'You are helpful.');
      expect(agent.adapterId, 'openai');
      expect(agent.modelId, 'gpt-4');
      expect(agent.strictMode, isTrue);
      expect(agent.effort, 'high');
      expect(agent.contextSize, 4096);
    });
  });

  group('Agent computed properties', () {
    test('hasPersona returns true when persona is set', () {
      expect(createAgent().hasPersona, isFalse);
      expect(createAgent(persona: 'Friendly').hasPersona, isTrue);
      expect(createAgent(persona: '').hasPersona, isFalse);
    });

    test('isTopLevel returns true when reportsTo is null', () {
      expect(createAgent().isTopLevel, isTrue);
      expect(createAgent(reportsTo: 'ceo').isTopLevel, isFalse);
    });

    test('hasSkill checks skill existence', () {
      final agent = createAgent();
      expect(agent.hasSkill('dart'), isTrue);
      expect(agent.hasSkill('flutter'), isTrue);
      expect(agent.hasSkill('java'), isFalse);
    });
  });

  group('Agent == and hashCode', () {
    test('identical agents are equal', () {
      final a = createAgent();
      final b = createAgent();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createAgent(id: 'a');
      final b = createAgent(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different name makes unequal', () {
      final a = createAgent(name: 'alice');
      final b = createAgent(name: 'bob');
      expect(a, isNot(equals(b)));
    });

    test('different skills make unequal', () {
      final a = createAgent();
      final b = createAgent(skillsParam: AgentSkills(['java']));
      expect(a, isNot(equals(b)));
    });

    test('different strictMode makes unequal', () {
      final a = createAgent(strictMode: false);
      final b = createAgent(strictMode: true);
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createAgent();
      expect(a, equals(a));
    });
  });

  group('Agent copyWith', () {
    test('returns new instance with updated name', () {
      final agent = createAgent();
      final updated = agent.copyWith(name: 'NewName');
      expect(updated.name, 'NewName');
      expect(updated.id, 'agent-1');
    });

    test('removeReportsTo sets reportsTo to null', () {
      final agent = createAgent(reportsTo: 'ceo');
      final updated = agent.copyWith(removeReportsTo: true);
      expect(updated.reportsTo, isNull);
      expect(updated.isTopLevel, isTrue);
    });

    test('removePersona sets persona to null', () {
      final agent = createAgent(persona: 'Friendly');
      final updated = agent.copyWith(removePersona: true);
      expect(updated.persona, isNull);
    });

    test('removeSystemPrompt sets systemPrompt to null', () {
      final agent = createAgent(systemPrompt: 'Be helpful');
      final updated = agent.copyWith(removeSystemPrompt: true);
      expect(updated.systemPrompt, isNull);
    });

    test('removeEffort sets effort to null', () {
      final agent = createAgent(effort: 'high');
      final updated = agent.copyWith(removeEffort: true);
      expect(updated.effort, isNull);
    });

    test('removeContextSize sets contextSize to null', () {
      final agent = createAgent(contextSize: 4096);
      final updated = agent.copyWith(removeContextSize: true);
      expect(updated.contextSize, isNull);
    });

    test('copyWith without changes returns equal agent', () {
      final agent = createAgent();
      final updated = agent.copyWith();
      expect(updated, equals(agent));
    });
  });
}
