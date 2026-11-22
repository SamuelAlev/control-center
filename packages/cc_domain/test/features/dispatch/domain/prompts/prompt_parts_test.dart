import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
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

Wake _wakeRow(String payload) => Wake(
  id: 'wk-1',
  workspaceId: 'ws-1',
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  reason: WakeReason.peerMessage,
  payload: payload,
  dedupKey: 'peer:wk-1',
  notBefore: DateTime.utc(2026, 5, 1, 9, 30),
  createdAt: DateTime.utc(2026, 5, 1, 9, 30),
);

final _wake = WakeContext.fromWakes([
  _wakeRow('turn-run-unique'),
], nonce: 'abcde123');

void main() {
  test('standing, current-turn and conversation data remain disjoint', () {
    final parts = const BuildAgentPromptUseCase().buildParts(
      hasRepl: false,
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

  group('wakes', () {
    AgentPromptParts parts(WakeContext wakeContext) =>
        const BuildAgentPromptUseCase().buildParts(
          hasRepl: false,
          prompt: wakeTurnInput,
          agent: _agent(),
          memoryContext: 'memory-fact-unique',
          wakeContext: wakeContext,
        );

    test('the cached prefix is the same with and without a wake', () {
      final person = parts(const WakeContext.userMessage());
      final woken = parts(_wake);
      final other = parts(
        WakeContext.fromWakes([
          _wakeRow('another payload'),
        ], nonce: 'zzzzz999'),
      );
      expect(woken.standing, person.standing);
      expect(other.standing, person.standing);
      expect(woken.standingRevision, person.standingRevision);
      // Only the per-turn half carries the wake.
      expect(woken.standing, isNot(contains('turn-run-unique')));
      expect(woken.turnContext, contains('turn-run-unique'));
      expect(woken.turnContext, contains('<wake-data id="abcde123">'));
      expect(person.turnContext, isNot(contains('wake-data id=')));
      // The full prompt is byte-identical up to the end of the standing half.
      final end =
          person.fullPrompt.indexOf(person.standing) + person.standing.length;
      expect(woken.fullPrompt.substring(0, end), person.fullPrompt.substring(0, end));
    });

    test('the standing paragraph is in every agent prompt, once', () {
      final standing = parts(const WakeContext.userMessage()).standing;
      expect(standing.split(wakeSystemParagraph), hasLength(2));
    });

    test('a person\'s run and a no-wake context render no wake section', () {
      for (final context in [
        const WakeContext.userMessage(),
        const WakeContext(
          wakeReason: WakeReason.goalContinuation,
          startedByRunId: null,
        ),
      ]) {
        expect(parts(context).turnContext, isNot(contains('[peer-message]')));
      }
    });
  });

  test('agent-free dispatch does not inherit another agent context', () {
    final parts = const BuildAgentPromptUseCase().buildParts(
      hasRepl: false,
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
