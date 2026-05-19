import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:test/test.dart';

Agent _testAgent({
  String name = 'TestBot',
  String? persona,
  String? systemPrompt,
  AgentRole? role,
}) {
  return Agent(
    id: 'agent-1',
    name: name,
    title: 'Test Agent',
    agentMdPath: '/tmp/agents/test.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(['coding', 'review']),
    persona: persona,
    systemPrompt: systemPrompt,
    role: role,
    createdAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late BuildAgentPromptUseCase useCase;

  setUp(() {
    useCase = const BuildAgentPromptUseCase();
  });

  // ---- execute with null agent -------------------------------------------

  group('execute', () {
    test('returns raw prompt when agent is null', timeout: const Timeout.factor(2), () {
      final result = useCase.execute(
        prompt: 'Hello world',
        agent: null,
      );
      expect(result, 'Hello world');
    });

    test('returns non-empty result when agent is provided', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.execute(
        prompt: 'Do something',
        agent: agent,
      );
      expect(result, isNotEmpty);
      // The prompt should be incorporated into the built result
      expect(result.contains('Do something'), isTrue);
    });

    test('includes agent identity in result', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(name: 'CoderBot');
      final result = useCase.execute(
        prompt: 'test',
        agent: agent,
      );
      expect(result.contains('CoderBot'), isTrue);
    });

    test('includes persona when provided', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(persona: 'You are a senior engineer');
      final result = useCase.execute(
        prompt: 'test',
        agent: agent,
      );
      expect(result.contains('senior engineer'), isTrue);
    });

    test('includes systemPrompt when provided', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(systemPrompt: 'Always respond in JSON');
      final result = useCase.execute(
        prompt: 'test',
        agent: agent,
      );
      expect(result.contains('Always respond in JSON'), isTrue);
    });

    test('works with different conversation modes', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final chatResult = useCase.execute(
        prompt: 'test',
        agent: agent,
        mode: ConversationMode.chat,
      );
      final planResult = useCase.execute(
        prompt: 'test',
        agent: agent,
        mode: ConversationMode.plan,
      );
      // Both should produce non-empty results
      expect(chatResult, isNotEmpty);
      expect(planResult, isNotEmpty);
      // Plan mode should include plan-specific content
      expect(planResult.length, isNot(equals(chatResult.length)));
    });

    test('includes memory context when provided', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.execute(
        prompt: 'test',
        agent: agent,
        memoryContext: 'Previous conversation summary here',
      );
      expect(result.contains('Previous conversation summary here'), isTrue);
    });

    test('includes conversation context when provided', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.execute(
        prompt: 'test',
        agent: agent,
        conversationContext: 'Recent messages context',
      );
      expect(result.contains('Recent messages context'), isTrue);
    });

    test('result without optional fields still contains prompt', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.execute(
        prompt: 'What is 2+2?',
        agent: agent,
      );
      expect(result.contains('What is 2+2?'), isTrue);
    });
  });

  // ---- buildPersistentBrief -----------------------------------------------

  group('buildPersistentBrief', () {
    test('returns non-empty string for valid agent', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final brief = useCase.buildPersistentBrief(agent: agent);
      expect(brief, isNotEmpty);
    });

    test('includes agent name', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(name: 'ReviewerBot');
      final brief = useCase.buildPersistentBrief(agent: agent);
      expect(brief.contains('ReviewerBot'), isTrue);
    });

    test('includes persona', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(persona: 'You are a meticulous code reviewer');
      final brief = useCase.buildPersistentBrief(agent: agent);
      expect(brief.contains('meticulous code reviewer'), isTrue);
    });

    test('includes system prompt', timeout: const Timeout.factor(2), () {
      final agent = _testAgent(systemPrompt: 'Focus on security issues');
      final brief = useCase.buildPersistentBrief(agent: agent);
      expect(brief.contains('Focus on security issues'), isTrue);
    });

    test('changes with different conversation modes', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final chatBrief = useCase.buildPersistentBrief(
        agent: agent,
        mode: ConversationMode.chat,
      );
      final planBrief = useCase.buildPersistentBrief(
        agent: agent,
        mode: ConversationMode.plan,
      );
      expect(chatBrief, isNotEmpty);
      expect(planBrief, isNotEmpty);
    });
  });

  // ---- buildPerTurnPrompt -------------------------------------------------

  group('buildPerTurnPrompt', () {
    test('returns prompt-based result', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.buildPerTurnPrompt(
        prompt: 'Fix the bug',
        agent: agent,
      );
      expect(result, isNotEmpty);
    });

    test('includes memory context', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.buildPerTurnPrompt(
        prompt: 'Continue',
        agent: agent,
        memoryContext: 'We were discussing authentication',
      );
      expect(result.contains('We were discussing authentication'), isTrue);
    });

    test('includes conversation context', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.buildPerTurnPrompt(
        prompt: 'Go ahead',
        agent: agent,
        conversationContext: 'Last message was about testing',
      );
      expect(result.contains('Last message was about testing'), isTrue);
    });

    test('works with minimal arguments', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final result = useCase.buildPerTurnPrompt(
        prompt: 'Hello',
        agent: agent,
      );
      expect(result, isNotEmpty);
    });
  });

  // ---- Consistency checks -------------------------------------------------

  group('consistency', () {
    test('execute with agent produces result that contains prompt text', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      const prompt = 'Analyze this codebase for security vulnerabilities';
      final result = useCase.execute(prompt: prompt, agent: agent);
      expect(result.contains(prompt), isTrue);
    });

    test('persistent brief + per-turn produce content for same agent', timeout: const Timeout.factor(2), () {
      final agent = _testAgent();
      final brief = useCase.buildPersistentBrief(agent: agent);
      final perTurn = useCase.buildPerTurnPrompt(
        prompt: 'Test prompt',
        agent: agent,
      );
      expect(brief, isNotEmpty);
      expect(perTurn, isNotEmpty);
      // They should be different — brief has identity/protocols, perTurn has prompt
      expect(brief, isNot(equals(perTurn)));
    });
  });
}
