import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/app_locale.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:control_center/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:test/test.dart';

// ── Helpers ──────────────────────────────────────────────────────────────

Agent _agent({
  String id = 'agent-1',
  String name = 'test-agent',
  String workspaceId = 'ws-1',
}) =>
    Agent(
      id: id,
      name: name,
      title: 'Test Agent',
      agentMdPath: '/fake/agent.md',
      workspaceId: workspaceId,
      skills: AgentSkills(const ['coding']),
      persona: 'helpful assistant',
      systemPrompt: 'Always be concise.',
      role: AgentRole.coder,
      createdAt: DateTime(2026),
    );

void main() {
  group('PromptBuilder', () {
    test('buildPersistentBrief returns empty string for fresh builder', () {
      final builder = PromptBuilder();

      expect(builder.buildPersistentBrief(), isEmpty);
    });

    test('identity section includes agent_id, agent_name, workspace_id', () {
      final result = PromptBuilder()
          .identity(_agent())
          .buildPersistentBrief();

      expect(result, contains('agent_id: agent-1'));
      expect(result, contains('agent_name: test-agent'));
      expect(result, contains('workspace_id: ws-1'));
    });

    test('systemPrompt with content includes it in output', () {
      final result = PromptBuilder()
          .systemPrompt('Always be concise.')
          .buildPersistentBrief();

      expect(result, contains('Always be concise.'));
    });

    test('systemPrompt with null returns this (no crash)', () {
      final result = PromptBuilder()
          .systemPrompt(null)
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('systemPrompt with empty string returns this (no addition)', () {
      final result = PromptBuilder()
          .systemPrompt('')
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('persona section includes persona text', () {
      final result = PromptBuilder()
          .persona('helpful assistant')
          .buildPersistentBrief();

      expect(result, contains('helpful assistant'));
    });

    test('persona section includes strategic posture and voice for role', () {
      final result = PromptBuilder()
          .persona('helpful assistant', role: AgentRole.coder)
          .buildPersistentBrief();

      // Strategic posture header followed by coder posture text.
      expect(result, contains('## Strategic posture'));
      // Voice and tone header.
      expect(result, contains('## Voice and tone'));
    });

    test('persona with null persona and role still works (just role sections)',
        () {
      final result = PromptBuilder()
          .persona(null, role: AgentRole.reviewer)
          .buildPersistentBrief();

      // No persona text header because persona was skipped.
      expect(result, isNot(contains('## Persona')));
      // But role sections are present.
      expect(result, contains('## Strategic posture'));
      expect(result, contains('## Voice and tone'));
    });

    test('skills section lists skills', () {
      final result = PromptBuilder()
          .skills(AgentSkills(const ['coding', 'testing']))
          .buildPersistentBrief();

      expect(result, contains('coding'));
      expect(result, contains('testing'));
    });

    test('skills with empty AgentSkills adds nothing', () {
      final result = PromptBuilder()
          .skills(AgentSkills(const []))
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('executionContract includes all rules', () {
      final result = PromptBuilder()
          .executionContract()
          .buildPersistentBrief();

      expect(result, contains('## Execution Contract'));
      expect(result, contains('1.'));
      expect(result, contains('2.'));
      expect(result, contains('7.'));
    });

    test('executionContract for chat includes memory instruction (rule 7)',
        () {
      final result = PromptBuilder()
          .executionContract(mode: ConversationMode.chat)
          .buildPersistentBrief();

      // Chat-mode rule 7 tells agent to save durable facts proactively.
      expect(result, contains('save durable facts'));
      expect(result, contains('do not wait to be asked'));
    });

    test('executionContract for review/plan omits memory-write instruction',
        () {
      final result = PromptBuilder()
          .executionContract(mode: ConversationMode.review)
          .buildPersistentBrief();

      // Review-mode rule 7 should NOT say "save durable facts".
      expect(result, isNot(contains('do not wait to be asked')));
      expect(result, isNot(contains('save durable facts')));
    });

    test('locale with english returns this (no change)', () {
      final base = PromptBuilder()
          .identity(_agent())
          .buildPersistentBrief();

      final withLocale = PromptBuilder()
          .identity(_agent())
          .locale(const AppLocale('en'))
          .buildPersistentBrief();

      expect(withLocale, equals(base));
    });

    test('locale with non-english adds language section', () {
      final result = PromptBuilder()
          .locale(const AppLocale('fr'))
          .buildPersistentBrief();

      expect(result, contains('## Language'));
      expect(result, contains('French'));
    });

    test('locale with null returns this', () {
      final result = PromptBuilder()
          .locale(null)
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('memoryContext appends content', () {
      final result = PromptBuilder()
          .memoryContext('Remember: always test your code.')
          .buildPersistentBrief();

      expect(result, contains('Remember: always test your code.'));
    });

    test('conversationContext appends content', () {
      final result = PromptBuilder()
          .conversationContext('User said: fix the bug.')
          .buildPersistentBrief();

      expect(result, contains('User said: fix the bug.'));
    });

    test('memoryContext with null returns this', () {
      final result = PromptBuilder()
          .memoryContext(null)
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('wakeContext includes runId, ticketId, wakeReason, channelId', () {
      const wc = WakeContext(
        runId: 'run-123',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        wakeReason: WakeReason.userMessage,
        ticketId: 'ticket-42',
        channelId: 'ch-general',
      );

      final result = PromptBuilder()
          .wakeContext(wc)
          .buildPersistentBrief();

      expect(result, contains('run-123'));
      expect(result, contains('ticket-42'));
      expect(result, contains('userMessage'));
      expect(result, contains('ch-general'));
    });

    test('wakeContext with null returns this', () {
      final result = PromptBuilder()
          .wakeContext(null)
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('mentions includes summonedBy and channel roster', () {
      const mc = MentionContext(
        summonedBy: 'boss-agent',
        channelRoster: [
          MentionRosterEntry(
            agentId: 'agent-2',
            name: 'reviewer',
            isTopLevel: false,
          ),
          MentionRosterEntry(
            agentId: 'agent-3',
            name: 'pm',
            isTopLevel: true,
          ),
        ],
      );

      final result = PromptBuilder()
          .mentions(mc, 'test-agent')
          .buildPersistentBrief();

      expect(result, contains('boss-agent'));
      expect(result, contains('@reviewer'));
      expect(result, contains('@pm'));
      expect(result, contains('top-level'));
      expect(result, contains('subordinate'));
    });

    test('mentions with null returns this', () {
      final result = PromptBuilder()
          .mentions(null, 'test-agent')
          .buildPersistentBrief();

      expect(result, isEmpty);
    });

    test('build() wraps content in <context> tags and appends prompt', () {
      final result = PromptBuilder()
          .identity(_agent())
          .build('Do the thing.');

      expect(result, contains('<context>'));
      expect(result, contains('</context>'));
      expect(result, contains('Do the thing.'));
      // The prompt should come after the closing tag.
      expect(
        result.indexOf('</context>'),
        lessThan(result.indexOf('Do the thing.')),
      );
    });

    test('build() with no content returns prompt directly', () {
      final result = PromptBuilder().build('Just the prompt.');

      expect(result, equals('Just the prompt.'));
      expect(result, isNot(contains('<context>')));
    });

    test(
        'buildPersistentBrief returns accumulated content without wrapping',
        () {
      final builder = PromptBuilder()
          .identity(_agent())
          .systemPrompt('Always be concise.');

      final brief = builder.buildPersistentBrief();
      final full = builder.build('Do the thing.');

      // The brief should NOT have <context> tags.
      expect(brief, isNot(contains('<context>')));
      expect(brief, contains('agent_id'));
      expect(brief, contains('Always be concise.'));

      // The full build SHOULD have <context> tags.
      expect(full, contains('<context>'));
    });

    test(
        'Chained calls accumulate content: identity→persona→skills produces combined output',
        () {
      final result = PromptBuilder()
          .identity(_agent())
          .persona('helpful assistant', role: AgentRole.coder)
          .skills(AgentSkills(const ['coding']))
          .buildPersistentBrief();

      // All three sections present.
      expect(result, contains('agent_id: agent-1'));
      expect(result, contains('helpful assistant'));
      expect(result, contains('coding'));
    });

    test(
        'resourceProtocols for chat includes memoryManagementInstructions',
        () {
      final result = PromptBuilder()
          .resourceProtocols(mode: ConversationMode.chat)
          .buildPersistentBrief();

      expect(result, contains('Memory Management'));
      expect(result, contains('propose_fact'));
    });

    test(
        'resourceProtocols for review does NOT include memoryManagementInstructions',
        () {
      final result = PromptBuilder()
          .resourceProtocols(mode: ConversationMode.review)
          .buildPersistentBrief();

      expect(result, contains('Resource Reading'));
      expect(result, contains('Search discipline'));
      // Memory Management section should NOT appear in review mode.
      expect(result, isNot(contains('Memory Management')));
    });
  });
}
