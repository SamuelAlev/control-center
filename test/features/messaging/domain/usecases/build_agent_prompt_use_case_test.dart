import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _createAgent({
  String? persona,
  String? systemPrompt,
  List<String> skills = const [],
}) {
  return Agent(
    id: 'agent-1',
    name: 'kilo',
    title: 'Kilo Agent',
    agentMdPath: '/path',
    workspaceId: 'ws-1',
    skills: AgentSkills(skills),
    persona: persona,
    systemPrompt: systemPrompt,
    createdAt: DateTime(2025),
  );
}

void main() {
  const useCase = BuildAgentPromptUseCase();

  group('BuildAgentPromptUseCase', () {
    test('returns prompt unchanged when agent is null', () {
      final result = useCase.execute(prompt: 'Hello world', agent: null);
      expect(result, 'Hello world');
    });

    test('wraps prompt in context when agent has no systemPrompt or persona', () {
      final agent = _createAgent();
      final result = useCase.execute(prompt: 'Hello world', agent: agent);
      expect(result, contains('Hello world'));
      expect(result, contains('## Memory Management'));
    });

    test('prepends systemPrompt before the prompt', () {
      final agent = _createAgent(systemPrompt: 'You are helpful.');
      final result = useCase.execute(prompt: 'Hello', agent: agent);
      expect(result, contains('You are helpful.'));
      expect(result, contains('Hello'));
      expect(result, contains('<context>'));
    });

    test('prepends persona before the prompt', () {
      final agent = _createAgent(persona: 'Friendly helper');
      final result = useCase.execute(prompt: 'Task', agent: agent);
      expect(result, contains('## Persona'));
      expect(result, contains('Friendly helper'));
      expect(result, contains('Task'));
    });

    test('prepends skills before the prompt', () {
      final agent = _createAgent(skills: ['dart', 'flutter']);
      final result = useCase.execute(prompt: 'Build app', agent: agent);
      expect(result, contains('## Skills'));
      expect(result, contains('dart, flutter'));
      expect(result, contains('Build app'));
    });

    test('prepends systemPrompt, persona, and skills together', () {
      final agent = _createAgent(
        systemPrompt: 'You are a senior developer.',
        persona: 'Precise and thorough',
        skills: ['dart', 'architecture'],
      );
      final result = useCase.execute(prompt: 'Review PR', agent: agent);
      expect(result, contains('You are a senior developer.'));
      expect(result, contains('## Persona'));
      expect(result, contains('Precise and thorough'));
      expect(result, contains('## Skills'));
      expect(result, contains('dart, architecture'));
      expect(result, contains('Review PR'));
    });

    test('does not include persona section when persona is empty', () {
      final agent = _createAgent(
        persona: '',
        systemPrompt: 'System prompt',
      );
      final result = useCase.execute(prompt: 'Task', agent: agent);
      expect(result, isNot(contains('## Persona')));
    });

    test('does not include systemPrompt section when empty', () {
      final agent = _createAgent(
        systemPrompt: '',
        persona: 'Persona text',
      );
      final result = useCase.execute(prompt: 'Task', agent: agent);
      expect(result, isNot(contains('systemPrompt')));
    });

    test('does not include skills section when skills list is empty', () {
      final agent = _createAgent(
        skills: [],
        systemPrompt: 'System prompt',
      );
      final result = useCase.execute(prompt: 'Task', agent: agent);
      expect(result, isNot(contains('## Skills')));
    });

    test('prompt appears at the end when sections are present', () {
      final agent = _createAgent(systemPrompt: 'You are helpful.');
      final result = useCase.execute(prompt: 'Do this', agent: agent);
      expect(result, contains('Do this'));
      expect(result.indexOf('Do this') > result.indexOf('You are helpful.'), isTrue);
    });

    test('handles multiline prompt', () {
      final agent = _createAgent(systemPrompt: 'Be concise');
      final result = useCase.execute(
        prompt: 'Line 1\nLine 2\nLine 3',
        agent: agent,
      );
      expect(result, contains('Line 1\nLine 2\nLine 3'));
    });

    test('handles multiline persona', () {
      final agent = _createAgent(persona: 'Line A\nLine B');
      final result = useCase.execute(prompt: 'Test', agent: agent);
      expect(result, contains('Line A\nLine B'));
    });

    test('returns same result for same input (const use case)', () {
      final agent = _createAgent(systemPrompt: 'Test');
      final a = useCase.execute(prompt: 'P', agent: agent);
      final b = useCase.execute(prompt: 'P', agent: agent);
      expect(a, equals(b));
    });

    test('includes memory management instructions for every agent', () {
      final agent = _createAgent();
      final result = useCase.execute(prompt: 'Test', agent: agent);
      expect(result, contains('## Memory Management'));
      expect(result, contains('propose_fact'));
      expect(result, contains('search_memory'));
    });

    test('memory instructions appear before system prompt', () {
      final agent = _createAgent(systemPrompt: 'You are a coder.');
      final result = useCase.execute(prompt: 'Test', agent: agent);
      expect(
        result.indexOf('## Memory Management') <
            result.indexOf('You are a coder.'),
        isTrue,
      );
    });

    test('uses agent expertise prefix in skills', () {
      final agent = _createAgent(skills: ['rust']);
      final result = useCase.execute(prompt: 'Write code', agent: agent);
      expect(
        result,
        contains('## Skills'),
      );
    });
  });
}
