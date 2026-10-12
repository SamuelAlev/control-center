import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:test/test.dart';

Agent _agent() => Agent(
  id: 'agent-1',
  name: 'Ada',
  title: 'Engineer',
  agentMdPath: '/tmp/ada.md',
  workspaceId: 'ws-1',
  skills: AgentSkills(const []),
  systemPrompt: 'standing-policy-unique',
  persona: 'standing-persona-unique',
  createdAt: DateTime(2026),
);

const _wake = WakeContext(
  runId: 'turn-run-unique',
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  wakeReason: WakeReason.userMessage,
);

void main() {
  test('standing, current-turn and conversation data remain disjoint', () {
    final parts = const BuildAgentPromptUseCase().buildParts(
      prompt: 'current-request-unique',
      agent: _agent(),
      memoryContext: 'memory-fact-unique',
      conversationContext: 'conversation-history-unique',
      wakeContext: _wake,
    );
    for (final standing in [
      'standing-policy-unique',
      'standing-persona-unique',
    ]) {
      expect(parts.standing, contains(standing));
      expect(parts.turnContext, isNot(contains(standing)));
      expect(parts.resumePrompt, isNot(contains(standing)));
      expect(parts.fullPrompt.split(standing), hasLength(2));
    }
    for (final current in ['turn-run-unique', 'memory-fact-unique']) {
      expect(parts.turnContext, contains(current));
      expect(parts.standing, isNot(contains(current)));
      expect(parts.resumePrompt, contains(current));
      expect(parts.fullPrompt.split(current), hasLength(2));
    }
    expect(parts.conversationContext, contains('conversation-history-unique'));
    expect(parts.standing, isNot(contains('conversation-history-unique')));
    expect(parts.resumePrompt, isNot(contains('conversation-history-unique')));
    expect(parts.fullPrompt.split('conversation-history-unique'), hasLength(2));
    expect(parts.resumePrompt, contains('current-request-unique'));
  });

  test('a resume without new context sends only the current user request', () {
    final parts = PromptBuilder()
        .identity(_agent())
        .systemPrompt('standing-only-unique')
        .parts('new-request-unique');
    expect(parts.resumePrompt, 'new-request-unique');
    expect(parts.fullPrompt, contains('standing-only-unique'));
  });

  test('agent-free dispatch does not inherit another agent context', () {
    final parts = const BuildAgentPromptUseCase().buildParts(
      prompt: 'bare request',
      agent: null,
      memoryContext: 'another-agent-memory',
      conversationContext: 'another-agent-conversation',
    );
    expect(parts.fullPrompt, 'bare request');
    expect(parts.resumePrompt, 'bare request');
    expect(parts.hasContext, isFalse);
  });
}
