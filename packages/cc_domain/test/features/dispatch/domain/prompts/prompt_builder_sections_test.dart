import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:test/test.dart';

Agent _agent({AgentSkills? skills, String? systemPrompt, String? persona}) =>
    Agent(
      id: 'agent-1',
      name: 'Ada',
      title: 'Engineer',
      agentMdPath: '/tmp/ada.md',
      workspaceId: 'ws-1',
      skills: skills ?? AgentSkills(const []),
      persona: persona,
      systemPrompt: systemPrompt,
      createdAt: DateTime(2026),
    );

void main() {
  group('PromptBuilder.sections', () {
    test('every assembly step is attributed to its own span', () {
      final sections = PromptBuilder()
          .identity(_agent())
          .toolCatalog()
          .resourceProtocols()
          .workspaceLayout()
          .systemPrompt('Be thorough.')
          .persona('Calm and precise.')
          .team(const [], mode: Mode.chat)
          .skills(AgentSkills(const ['review']))
          .executionContract()
          .executionProcedure()
          .mode(Mode.chat)
          .memoryContext('## Agent Memory\n\n- remember this')
          .conversationContext('## Recent conversation\n\nhello')
          .sections();

      final labels = [for (final s in sections) s.label];
      // The contract: no step's bytes leak into a neighbouring span.
      expect(labels, contains(PromptBuilder.identityLabel));
      expect(labels, contains(PromptBuilder.toolCatalogLabel));
      expect(labels, contains(PromptBuilder.resourceProtocolsLabel));
      expect(labels, contains(PromptBuilder.workspaceLayoutLabel));
      expect(labels, contains(PromptBuilder.agentInstructionsLabel));
      expect(labels, contains(PromptBuilder.personaLabel));
      expect(labels, contains(PromptBuilder.skillsLabel));
      expect(labels, contains(PromptBuilder.executionContractLabel));
      expect(labels, contains(PromptBuilder.executionProcedureLabel));
      // Chat mode has no mode block by design; the mode span is asserted
      // separately below under plan mode.
      expect(labels, contains(PromptBuilder.memoryLabel));
      expect(labels, contains(PromptBuilder.conversationLabel));

      final memory = sections.singleWhere(
        (s) => s.label == PromptBuilder.memoryLabel,
      );
      expect(memory.text, contains('remember this'));
      // The memory span must NOT absorb the conversation block that follows
      // it in insertion order, nor leak into the preceding Mode span.
      expect(memory.text, isNot(contains('Recent conversation')));
      final contract = sections.singleWhere(
        (s) => s.label == PromptBuilder.executionContractLabel,
      );
      expect(contract.text, contains('Execution Contract'));
      // And the procedure that follows stays its own span.
      final procedure = sections.singleWhere(
        (s) => s.label == PromptBuilder.executionProcedureLabel,
      );
      expect(procedure.text, isNot(contains('Execution Contract')));
    });

    test('plan mode emits its own mode span', () {
      final sections = PromptBuilder()
          .identity(_agent())
          .mode(Mode.plan)
          .memoryContext('## Agent Memory\n\n- m')
          .sections();
      final mode = sections.singleWhere(
        (s) => s.label == PromptBuilder.modeLabel,
      );
      expect(mode.text, isNot(contains('- m')));
    });

    test('empty contributions drop their span entirely', () {
      final sections = PromptBuilder()
          .identity(_agent())
          .systemPrompt(null)
          .persona(null)
          .skills(AgentSkills(const []))
          .memoryContext(null)
          .sections();
      final labels = [for (final s in sections) s.label];
      expect(labels, isNot(contains(PromptBuilder.agentInstructionsLabel)));
      expect(labels, isNot(contains(PromptBuilder.personaLabel)));
      expect(labels, isNot(contains(PromptBuilder.skillsLabel)));
      expect(labels, isNot(contains(PromptBuilder.memoryLabel)));
    });
  });

  group('BuildAgentPromptUseCase.inspectSections', () {
    test('mirrors execute() minus the per-turn layers', () {
      final sections = const BuildAgentPromptUseCase().inspectSections(
        agent: _agent(systemPrompt: 'Be thorough.'),
        memoryContext: '## Agent Memory\n\n- a fact',
      );
      final labels = [for (final s in sections) s.label];
      expect(labels, contains(PromptBuilder.identityLabel));
      expect(labels, contains(PromptBuilder.agentInstructionsLabel));
      expect(labels, contains(PromptBuilder.executionContractLabel));
      expect(labels, contains(PromptBuilder.memoryLabel));
      // Never present at inspection time.
      expect(labels, isNot(contains(PromptBuilder.wakeContextLabel)));
      expect(labels, isNot(contains(PromptBuilder.summonsLabel)));
      expect(labels, isNot(contains(PromptBuilder.conversationLabel)));
    });
  });

  group('contextSegmentKindForSection', () {
    test('groups operator-authored prose as rules', () {
      expect(
        contextSegmentKindForSection(PromptBuilder.agentInstructionsLabel),
        ContextSegmentKind.rules,
      );
      expect(
        contextSegmentKindForSection(PromptBuilder.personaLabel),
        ContextSegmentKind.rules,
      );
      expect(
        contextSegmentKindForSection(PromptBuilder.strategicPostureLabel),
        ContextSegmentKind.rules,
      );
      expect(
        contextSegmentKindForSection(PromptBuilder.voiceAndToneLabel),
        ContextSegmentKind.rules,
      );
    });

    test('skills, memory and conversation map to their own kinds', () {
      expect(
        contextSegmentKindForSection(PromptBuilder.skillsLabel),
        ContextSegmentKind.skills,
      );
      expect(
        contextSegmentKindForSection(PromptBuilder.memoryLabel),
        ContextSegmentKind.memory,
      );
      expect(
        contextSegmentKindForSection(PromptBuilder.conversationLabel),
        ContextSegmentKind.conversation,
      );
    });

    test('framing sections fall through to the system prompt', () {
      for (final label in [
        PromptBuilder.preambleLabel,
        PromptBuilder.identityLabel,
        PromptBuilder.toolCatalogLabel,
        PromptBuilder.resourceProtocolsLabel,
        PromptBuilder.workspaceLayoutLabel,
        PromptBuilder.teamLabel,
        PromptBuilder.executionContractLabel,
        PromptBuilder.executionProcedureLabel,
        PromptBuilder.outputContractLabel,
        PromptBuilder.wakeContextLabel,
        PromptBuilder.summonsLabel,
        PromptBuilder.modeLabel,
        PromptBuilder.languageLabel,
      ]) {
        expect(
          contextSegmentKindForSection(label),
          ContextSegmentKind.systemPrompt,
          reason: label,
        );
      }
    });
  });

  group('ContextInspection wire round-trip', () {
    test('summary drops content, explorer keeps it', () {
      const inspection = ContextInspection(
        workspaceId: 'ws',
        spaceId: 'sp',
        agentId: 'ag',
        agentName: 'Ada',
        mode: 'chat',
        windowTokens: 1000,
        hasContent: true,
        segments: [
          ContextSegment(
            kind: ContextSegmentKind.skills,
            tokens: 10,
            chars: 38,
            parts: [
              ContextPart(
                id: 'skill:x',
                title: 'x',
                tokens: 10,
                chars: 38,
                content: 'body',
              ),
            ],
          ),
        ],
      );
      final restored = ContextInspection.fromJson(inspection.toJson());
      expect(restored.workspaceId, 'ws');
      expect(restored.hasContent, isTrue);
      expect(restored.windowTokens, 1000);
      expect(restored.segments, hasLength(1));
      expect(restored.segments.single.kind, ContextSegmentKind.skills);
      expect(restored.segments.single.parts.single.content, 'body');
      expect(restored.persistentTokens, 10);
      expect(
        restored.segmentFor(ContextSegmentKind.conversation),
        isNull,
        reason: 'the conversation segment is client-composed, never sent',
      );
    });

    test('an unknown segment kind is dropped, not fatal', () {
      final restored = ContextInspection.fromJson({
        'workspace_id': 'ws',
        'space_id': 'sp',
        'agent_id': 'ag',
        'agent_name': 'Ada',
        'mode': 'chat',
        'window_tokens': 1,
        'segments': [
          {'kind': 'fromTheFuture', 'tokens': 3, 'chars': 9, 'parts': []},
        ],
      });
      expect(restored.segments, isEmpty);
    });
  });
}
