import 'package:cc_domain/features/dispatch/domain/persona/agent_persona.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('read-only tool classification', () {
    test('recognizes canonical read-only tools case-insensitively', () {
      expect(isReadOnlyTool('read'), isTrue);
      expect(isReadOnlyTool('READ'), isTrue);
      expect(isReadOnlyTool('Grep'), isTrue);
      expect(isReadOnlyTool('web_fetch'), isTrue);
      expect(isReadOnlyTool('WEB_SEARCH'), isTrue);
    });

    test('rejects mutating tools', () {
      expect(isReadOnlyTool('write'), isFalse);
      expect(isReadOnlyTool('edit'), isFalse);
      expect(isReadOnlyTool('bash'), isFalse);
      expect(isReadOnlyTool('apply_patch'), isFalse);
    });

    test('isReadOnlyToolset is true only when every tool is read-only', () {
      expect(isReadOnlyToolset(['read', 'grep', 'ls']), isTrue);
      expect(isReadOnlyToolset(['read', 'WRITE']), isFalse);
      expect(isReadOnlyToolset(['bash']), isFalse);
    });

    test('isReadOnlyToolset treats an empty toolset as read-only', () {
      expect(isReadOnlyToolset(const []), isTrue);
    });
  });

  group('AgentPersona defaults', () {
    test('applies sensible defaults', () {
      final persona = AgentPersona(name: 'reviewer', description: 'Reviews');

      expect(persona.tools, isEmpty);
      expect(persona.spawns, '');
      expect(persona.models, isEmpty);
      expect(persona.model, isNull);
      expect(persona.thinkingLevel, isNull);
      expect(persona.blocking, isFalse);
      expect(persona.readSummarize, isTrue);
      expect(persona.autoloadSkills, isEmpty);
      expect(persona.systemPrompt, '');
      expect(persona.source, AgentPersonaSource.bundled);
      expect(persona.filePath, isNull);
    });

    test('asserts a non-empty name', () {
      expect(
        () => AgentPersona(name: '', description: 'x'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AgentPersona model normalization', () {
    test('model returns the first of multiple models', () {
      final persona = AgentPersona(
        name: 'a',
        description: 'd',
        models: const ['primary', 'fallback'],
      );

      expect(persona.model, 'primary');
      expect(persona.models, const ['primary', 'fallback']);
    });

    test('model is null when models is empty', () {
      final persona = AgentPersona(name: 'a', description: 'd');

      expect(persona.model, isNull);
    });

    test('model returns the sole model', () {
      final persona = AgentPersona(
        name: 'a',
        description: 'd',
        models: const ['only'],
      );

      expect(persona.model, 'only');
    });
  });

  group('AgentPersona equality', () {
    AgentPersona build() {
      return AgentPersona(
        name: 'reviewer',
        description: 'Reviews code',
        tools: const ['read', 'grep'],
        spawns: '*',
        models: const ['m1', 'm2'],
        thinkingLevel: 'high',
        blocking: true,
        readSummarize: false,
        autoloadSkills: const ['skill-a'],
        systemPrompt: 'You review.',
        source: AgentPersonaSource.project,
        filePath: '/p/.cc/agents/reviewer.md',
      );
    }

    test('equal personas compare equal and share a hashCode', () {
      final a = build();
      final b = build();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing name breaks equality', () {
      final a = build();
      final b = AgentPersona(
        name: 'other',
        description: 'Reviews code',
        tools: const ['read', 'grep'],
        spawns: '*',
        models: const ['m1', 'm2'],
        thinkingLevel: 'high',
        blocking: true,
        readSummarize: false,
        autoloadSkills: const ['skill-a'],
        systemPrompt: 'You review.',
        source: AgentPersonaSource.project,
        filePath: '/p/.cc/agents/reviewer.md',
      );

      expect(a, isNot(equals(b)));
    });

    test('differing source breaks equality', () {
      final a = build();
      final b = AgentPersona(
        name: 'reviewer',
        description: 'Reviews code',
        tools: const ['read', 'grep'],
        spawns: '*',
        models: const ['m1', 'm2'],
        thinkingLevel: 'high',
        blocking: true,
        readSummarize: false,
        autoloadSkills: const ['skill-a'],
        systemPrompt: 'You review.',
        source: AgentPersonaSource.user,
        filePath: '/p/.cc/agents/reviewer.md',
      );

      expect(a, isNot(equals(b)));
    });

    test('differing model list breaks equality', () {
      final a = build();
      final b = AgentPersona(
        name: 'reviewer',
        description: 'Reviews code',
        tools: const ['read', 'grep'],
        spawns: '*',
        models: const ['m1'],
        thinkingLevel: 'high',
        blocking: true,
        readSummarize: false,
        autoloadSkills: const ['skill-a'],
        systemPrompt: 'You review.',
        source: AgentPersonaSource.project,
        filePath: '/p/.cc/agents/reviewer.md',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
