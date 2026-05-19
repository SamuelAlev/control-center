import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:flutter_test/flutter_test.dart';

const _highEffort = 'high';
const _mediumEffort = 'medium';

void main() {
  final testCreatedAt = DateTime(2024, 1, 1);

  Agent createAgent({
    String id = 'agent-1',
    String name = 'code-explorer',
    String title = 'Code Explorer',
    String agentMdPath = '/agents/code-explorer.md',
    String? reportsTo,
    AgentSkills? skills,
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
      skills: skills ?? AgentSkills(['coding', 'search']),
      persona: persona,
      systemPrompt: systemPrompt,
      adapterId: adapterId,
      modelId: modelId,
      strictMode: strictMode,
      effort: effort,
      contextSize: contextSize,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  group('Agent', () {
    group('constructor', () {
      test('creates agent with required fields', () {
        final agent = Agent(
          id: 'agent-1',
          name: 'builder',
          title: 'Builder',
          agentMdPath: '/path.md',
          workspaceId: 'ws-1',
          skills: AgentSkills(['coding']),
          createdAt: testCreatedAt,
        );
        expect(agent.id, 'agent-1');
        expect(agent.name, 'builder');
        expect(agent.title, 'Builder');
        expect(agent.agentMdPath, '/path.md');
        expect(agent.skills, AgentSkills(['coding']));
        expect(agent.reportsTo, isNull);
        expect(agent.persona, isNull);
        expect(agent.systemPrompt, isNull);
        expect(agent.adapterId, isNull);
        expect(agent.modelId, isNull);
        expect(agent.strictMode, isFalse);
        expect(agent.effort, isNull);
        expect(agent.contextSize, isNull);
        expect(agent.createdAt, testCreatedAt);
      });

      test('creates agent with all fields', () {
        final agent = Agent(
          id: 'agent-full',
          name: 'reviewer',
          title: 'Code Reviewer',
          agentMdPath: '/agents/reviewer.md',
          workspaceId: 'ws-1',
          reportsTo: 'ceo',
          skills: AgentSkills(['review', 'lint']),
          persona: 'You are a strict code reviewer.',
          systemPrompt: 'Review carefully.',
          adapterId: 'openai',
          modelId: 'gpt-4',
          strictMode: true,
          effort: 'high',
          contextSize: 128000,
          createdAt: testCreatedAt,
        );
        expect(agent.id, 'agent-full');
        expect(agent.name, 'reviewer');
        expect(agent.title, 'Code Reviewer');
        expect(agent.reportsTo, 'ceo');
        expect(agent.persona, 'You are a strict code reviewer.');
        expect(agent.systemPrompt, 'Review carefully.');
        expect(agent.adapterId, 'openai');
        expect(agent.modelId, 'gpt-4');
        expect(agent.strictMode, isTrue);
        expect(agent.effort, 'high');
        expect(agent.contextSize, 128000);
      });

      test('strictMode defaults to false', () {
        final agent = Agent(
          id: 'agent-1',
          name: 'test',
          title: 'Test',
          agentMdPath: '/path.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          createdAt: testCreatedAt,
        );
        expect(agent.strictMode, isFalse);
      });

      test('constructor asserts name is not empty', () {
        expect(
          () => Agent(
            id: 'a',
            name: '',
            title: 'Test',
            agentMdPath: '/path.md',
            workspaceId: 'ws-1',
            skills: AgentSkills([]),
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('constructor asserts title is not empty', () {
        expect(
          () => Agent(
            id: 'a',
            name: 'test',
            title: '',
            agentMdPath: '/path.md',
            workspaceId: 'ws-1',
            skills: AgentSkills([]),
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('getters', () {
      test('hasPersona returns true when persona is set and non-empty', () {
        final agent = createAgent(persona: 'A helpful assistant');
        expect(agent.hasPersona, isTrue);
      });

      test('hasPersona returns false when persona is null', () {
        final agent = createAgent(persona: null);
        expect(agent.hasPersona, isFalse);
      });

      test('hasPersona returns false when persona is empty', () {
        final agent = createAgent(persona: '');
        expect(agent.hasPersona, isFalse);
      });

      test('isTopLevel returns true when reportsTo is null', () {
        final agent = createAgent(reportsTo: null);
        expect(agent.isTopLevel, isTrue);
      });

      test('isTopLevel returns false when reportsTo is set', () {
        final agent = createAgent(reportsTo: 'ceo');
        expect(agent.isTopLevel, isFalse);
      });

      test('hasSkill delegates to skills.hasSkill', () {
        final agent = createAgent(
          skills: AgentSkills(['coding', 'testing']),
        );
        expect(agent.hasSkill('coding'), isTrue);
        expect(agent.hasSkill('testing'), isTrue);
        expect(agent.hasSkill('unknown'), isFalse);
      });

      test('hasSkill is case-insensitive', () {
        final agent = createAgent(
          skills: AgentSkills(['CodeReview']),
        );
        expect(agent.hasSkill('codereview'), isTrue);
        expect(agent.hasSkill('CODEReview'), isTrue);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical agents', () {
        final a1 = createAgent();
        final a2 = createAgent();
        expect(a1, equals(a2));
      });

      test('== returns false for different id', () {
        expect(
          createAgent(id: 'a') == createAgent(id: 'b'),
          isFalse,
        );
      });

      test('== returns false for different name', () {
        expect(
          createAgent(name: 'a') == createAgent(name: 'b'),
          isFalse,
        );
      });

      test('== returns false for different title', () {
        expect(
          createAgent(title: 'A') == createAgent(title: 'B'),
          isFalse,
        );
      });

      test('== returns false for different agentMdPath', () {
        expect(
          createAgent(agentMdPath: '/a.md') == createAgent(agentMdPath: '/b.md'),
          isFalse,
        );
      });

      test('== returns false for different reportsTo', () {
        expect(
          createAgent(reportsTo: null) == createAgent(reportsTo: 'ceo'),
          isFalse,
        );
      });

      test('== returns false for different skills', () {
        expect(
          createAgent(skills: AgentSkills(['a'])) ==
              createAgent(skills: AgentSkills(['b'])),
          isFalse,
        );
      });

      test('== returns false for different persona', () {
        expect(
          createAgent(persona: 'a') == createAgent(persona: 'b'),
          isFalse,
        );
      });

      test('== returns false for different systemPrompt', () {
        expect(
          createAgent(systemPrompt: 'a') == createAgent(systemPrompt: 'b'),
          isFalse,
        );
      });

      test('== returns false for different adapterId', () {
        expect(
          createAgent(adapterId: 'a') == createAgent(adapterId: 'b'),
          isFalse,
        );
      });

      test('== returns false for different modelId', () {
        expect(
          createAgent(modelId: 'a') == createAgent(modelId: 'b'),
          isFalse,
        );
      });

      test('== returns false for different strictMode', () {
        expect(
          createAgent(strictMode: true) == createAgent(strictMode: false),
          isFalse,
        );
      });

      test('== returns false for different effort', () {
        expect(
          createAgent(effort: _highEffort) == createAgent(effort: 'low'),
          isFalse,
        );
      });

      test('== returns false for different contextSize', () {
        expect(
          createAgent(contextSize: 1000) == createAgent(contextSize: 2000),
          isFalse,
        );
      });

      test('== returns false for different createdAt', () {
        expect(
          createAgent(createdAt: DateTime(2024, 1, 1)) ==
              createAgent(createdAt: DateTime(2024, 2, 1)),
          isFalse,
        );
      });

      test('== (identical)', () {
        final agent = createAgent();
        expect(agent, equals(agent));
      });

      test('hashCode equal for identical agents', () {
        final a1 = createAgent();
        final a2 = createAgent();
        expect(a1.hashCode, equals(a2.hashCode));
      });

      test('hashCode differs for different agents', () {
        final a1 = createAgent(id: 'a');
        final a2 = createAgent(id: 'b');
        expect(a1.hashCode, isNot(equals(a2.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final agent = createAgent();
        final copy = agent.copyWith();
        expect(copy, equals(agent));
      });

      test('updates id', () {
        final copy = createAgent().copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
      });

      test('updates name', () {
        final copy = createAgent().copyWith(name: 'new-name');
        expect(copy.name, 'new-name');
      });

      test('updates title', () {
        final copy = createAgent().copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
      });

      test('updates agentMdPath', () {
        final copy = createAgent().copyWith(agentMdPath: '/new/path.md');
        expect(copy.agentMdPath, '/new/path.md');
      });

      test('updates reportsTo', () {
        final copy = createAgent().copyWith(reportsTo: 'ceo');
        expect(copy.reportsTo, 'ceo');
      });

      test('removes reportsTo via removeReportsTo flag', () {
        final agent = createAgent(reportsTo: 'ceo');
        final copy = agent.copyWith(removeReportsTo: true);
        expect(copy.reportsTo, isNull);
        expect(copy.isTopLevel, isTrue);
      });

      test('updates skills', () {
        final newSkills = AgentSkills(['debugging']);
        final copy = createAgent().copyWith(skills: newSkills);
        expect(copy.skills, newSkills);
      });

      test('updates persona', () {
        final copy = createAgent().copyWith(persona: 'new persona');
        expect(copy.persona, 'new persona');
        expect(copy.hasPersona, isTrue);
      });

      test('removes persona via removePersona flag', () {
        final agent = createAgent(persona: 'existing');
        final copy = agent.copyWith(removePersona: true);
        expect(copy.persona, isNull);
        expect(copy.hasPersona, isFalse);
      });

      test('updates systemPrompt', () {
        final copy = createAgent().copyWith(systemPrompt: 'new prompt');
        expect(copy.systemPrompt, 'new prompt');
      });

      test('removes systemPrompt via removeSystemPrompt flag', () {
        final agent = createAgent(systemPrompt: 'existing');
        final copy = agent.copyWith(removeSystemPrompt: true);
        expect(copy.systemPrompt, isNull);
      });

      test('updates adapterId', () {
        final copy = createAgent().copyWith(adapterId: 'anthropic');
        expect(copy.adapterId, 'anthropic');
      });

      test('removes adapterId via removeAdapterId flag', () {
        final agent = createAgent(adapterId: 'openai');
        final copy = agent.copyWith(removeAdapterId: true);
        expect(copy.adapterId, isNull);
      });

      test('updates modelId', () {
        final copy = createAgent().copyWith(modelId: 'claude-3');
        expect(copy.modelId, 'claude-3');
      });

      test('removes modelId via removeModelId flag', () {
        final agent = createAgent(modelId: 'gpt-4');
        final copy = agent.copyWith(removeModelId: true);
        expect(copy.modelId, isNull);
      });

      test('updates strictMode', () {
        final copy = createAgent(strictMode: false).copyWith(strictMode: true);
        expect(copy.strictMode, isTrue);
      });

      test('updates effort', () {
        final copy = createAgent().copyWith(effort: _mediumEffort);
        expect(copy.effort, _mediumEffort);
      });

      test('removes effort via removeEffort flag', () {
        final agent = createAgent(effort: _highEffort);
        final copy = agent.copyWith(removeEffort: true);
        expect(copy.effort, isNull);
      });

      test('updates contextSize', () {
        final copy = createAgent().copyWith(contextSize: 256000);
        expect(copy.contextSize, 256000);
      });

      test('removes contextSize via removeContextSize flag', () {
        final agent = createAgent(contextSize: 128000);
        final copy = agent.copyWith(removeContextSize: true);
        expect(copy.contextSize, isNull);
      });

      test('updates createdAt', () {
        final newDate = DateTime(2025, 1, 1);
        final copy = createAgent().copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('copyWith does not mutate original', () {
        final agent = createAgent(name: 'original');
        agent.copyWith(name: 'changed');
        expect(agent.name, 'original');
      });

      test('chaining copyWith calls', () {
        final agent = createAgent();
        final copy = agent
            .copyWith(name: 'builder-v2')
            .copyWith(strictMode: true)
            .copyWith(effort: _highEffort);
        expect(copy.name, 'builder-v2');
        expect(copy.strictMode, isTrue);
        expect(copy.effort, _highEffort);
      });

      test('copyWith preserves other fields unchanged', () {
        final agent = createAgent(
          id: 'agent-x',
          name: 'engineer',
          title: 'Engineer',
          reportsTo: 'ceo',
        );
        final copy = agent.copyWith(strictMode: true);
        expect(copy.id, 'agent-x');
        expect(copy.name, 'engineer');
        expect(copy.title, 'Engineer');
        expect(copy.reportsTo, 'ceo');
        expect(copy.strictMode, isTrue);
        expect(copy.skills, agent.skills);
      });
    });
  });
}
