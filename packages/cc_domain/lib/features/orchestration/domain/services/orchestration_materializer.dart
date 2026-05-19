import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Pure function that converts an approved [Orchestration] into a
/// [PipelineDefinition]. NO LLM, NO I/O — given the same proposal and resolved
/// role→agent map it always produces the same DAG, so the generated pipeline
/// inherits the engine's suspension/resume, crash recovery, cost rollup, and
/// run-detail UI for free.
class OrchestrationMaterializer {
  /// Creates an [OrchestrationMaterializer].
  const OrchestrationMaterializer();

  /// Builds the pipeline definition for [orchestration].
  ///
  /// [roleAgents] maps each `roleKey` to a resolved agent id (existing or just
  /// hired). [channelId], [parentTicketId], and [projectId] are threaded onto
  /// every generated sub-ticket so they share one room/project.
  PipelineDefinition buildDefinition(
    Orchestration orchestration, {
    required Map<String, String> roleAgents,
    required String channelId,
    required String parentTicketId,
    required String projectId,
  }) {
    final p = orchestration.proposal;
    final steps = <PipelineStepDefinition>[];
    const triggerId = 'trigger';
    var x = 0.0;

    steps.add(PipelineStepDefinition(
      id: triggerId,
      kind: StepKind.trigger,
      bodyKey: BuiltInBodyKeys.trigger,
      config: const PipelineNodeConfig(label: 'Start'),
      x: x,
      y: 0,
    ));
    x += 220;

    // ── Optional research phase ──────────────────────────────────────────
    String? researchId;
    if (p.research.enabled) {
      researchId = 'research';
      final roleKey = p.research.roleKey ?? p.synthesis.roleKey;
      steps.add(PipelineStepDefinition(
        id: researchId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.promptAgent,
        triggers: const [StepTrigger(sourceStepIds: [triggerId])],
        config: _agentConfig(
          label: 'Research',
          agentId: roleAgents[roleKey],
          prompt: '${p.research.prompt}\n\nGoal: ${p.goal}',
          outputKey: 'research',
          channelId: channelId,
          parentTicketId: parentTicketId,
          projectId: projectId,
        ),
        x: x,
        y: 0,
      ));
      x += 220;
    }

    // The gate that root (dependency-free) work waits on.
    final afterResearch = researchId != null ? [researchId] : [triggerId];

    // ── Optional discussion round (parallel position steps) ──────────────
    final discussionIds = <String>[];
    if (p.discussion.enabled) {
      var dy = 0.0;
      for (final role in p.roles) {
        final id = 'discuss_${role.roleKey}';
        discussionIds.add(id);
        steps.add(PipelineStepDefinition(
          id: id,
          kind: StepKind.listen,
          bodyKey: BuiltInBodyKeys.promptAgent,
          triggers: [StepTrigger(sourceStepIds: afterResearch)],
          config: _agentConfig(
            label: 'Discuss: ${role.title}',
            agentId: roleAgents[role.roleKey],
            prompt: '${p.discussion.prompt}\n\nGoal: ${p.goal}\n\n'
                'Post your approach for the team in the shared channel, then '
                'complete_ticket with your structured position.',
            outputKey: 'discussion_${role.roleKey}',
            outputSchema: _discussionSchema,
            channelId: channelId,
            parentTicketId: parentTicketId,
            projectId: projectId,
          ),
          x: x,
          y: dy,
        ));
        dy += 140;
      }
      x += 220;
    }

    // Root work waits on the discussion round (if any), else the research gate.
    final rootGate = discussionIds.isNotEmpty ? discussionIds : afterResearch;

    // ── Sub-ticket work DAG ──────────────────────────────────────────────
    final subTicketIds = <String>[];
    var sy = 0.0;
    for (final t in p.subTickets) {
      final id = 'sub_${t.key}';
      subTicketIds.add(id);
      final upstream = t.dependsOn.isEmpty
          ? rootGate
          : [for (final dep in t.dependsOn) 'sub_$dep'];
      steps.add(PipelineStepDefinition(
        id: id,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.promptAgent,
        triggers: [StepTrigger(sourceStepIds: upstream)],
        config: _agentConfig(
          label: t.title,
          agentId: roleAgents[t.roleKey],
          prompt: _subTicketPrompt(p, t),
          outputKey: 'out_${t.key}',
          outputSchema: t.expectedOutputSchema,
          continueOnFail: true,
          channelId: channelId,
          parentTicketId: parentTicketId,
          projectId: projectId,
        ),
        x: x,
        y: sy,
      ));
      sy += 140;
    }
    x += 220;

    // ── Join + phase marker ──────────────────────────────────────────────
    const markPhaseId = 'mark_phase';
    steps.add(PipelineStepDefinition(
      id: markPhaseId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.orchestrationMarkPhase,
      triggers: [StepTrigger(sourceStepIds: subTicketIds)],
      config: PipelineNodeConfig(
        label: 'Collect results',
        extras: {
          'orchestrationId': orchestration.id,
          'subTicketKeys': [for (final t in p.subTickets) t.key],
        },
      ),
      x: x,
      y: 0,
    ));
    x += 220;

    // ── Synthesis ────────────────────────────────────────────────────────
    const synthesisId = 'synthesis';
    steps.add(PipelineStepDefinition(
      id: synthesisId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [markPhaseId])],
      config: _agentConfig(
        label: 'Synthesize deliverable',
        agentId: roleAgents[p.synthesis.roleKey],
        prompt: _synthesisPrompt(p),
        outputKey: 'deliverable',
        outputSchema: p.synthesis.outputSchema,
        channelId: channelId,
        parentTicketId: parentTicketId,
        projectId: projectId,
      ),
      x: x,
      y: 0,
    ));
    x += 220;

    // ── Persist deliverable ──────────────────────────────────────────────
    const persistId = 'persist_deliverable';
    steps.add(PipelineStepDefinition(
      id: persistId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.orchestrationPersistDeliverable,
      triggers: const [StepTrigger(sourceStepIds: [synthesisId])],
      config: PipelineNodeConfig(
        label: 'Deliver',
        extras: {'orchestrationId': orchestration.id},
      ),
      x: x,
      y: 0,
    ));
    x += 220;

    // ── Terminal ─────────────────────────────────────────────────────────
    const terminalId = 'done';
    steps.add(PipelineStepDefinition(
      id: terminalId,
      kind: StepKind.terminal,
      bodyKey: '_terminal_$terminalId',
      triggers: const [StepTrigger(sourceStepIds: [persistId])],
      config: const PipelineNodeConfig(label: 'Done'),
      x: x,
      y: 0,
    ));

    return PipelineDefinition(
      templateId: 'orchestration_${orchestration.id}',
      workspaceId: orchestration.workspaceId,
      name: 'Orchestration: ${_short(p.goal)}',
      description: 'Generated from orchestration ${orchestration.id} — ${p.goal}',
      steps: steps,
    );
  }

  PipelineNodeConfig _agentConfig({
    required String label,
    required String? agentId,
    required String prompt,
    required String outputKey,
    Map<String, dynamic>? outputSchema,
    bool continueOnFail = false,
    required String channelId,
    required String parentTicketId,
    required String projectId,
  }) {
    return PipelineNodeConfig(
      label: label,
      agentId: agentId,
      prompt: prompt,
      outputKey: outputKey,
      outputSchema: outputSchema,
      continueOnFail: continueOnFail,
      extras: {
        'conversationMode': ConversationMode.review.name,
        'channelId': channelId,
        'parentTicketId': parentTicketId,
        'projectId': projectId,
        // Generated nodes must never silence unresolved placeholders — the
        // markPhase step guarantees every `out_<key>` exists before synthesis.
        'allowUnresolvedPlaceholders': false,
      },
    );
  }

  String _subTicketPrompt(OrchestrationProposal p, ProposedSubTicket t) {
    final buf = StringBuffer()
      ..writeln('Overall goal: ${p.goal}')
      ..writeln()
      ..writeln(t.description);
    if (p.discussion.enabled) {
      buf
        ..writeln()
        ..writeln('Team positions from the discussion round are available in '
            'the shared channel.');
    }
    for (final dep in t.dependsOn) {
      buf
        ..writeln()
        ..writeln('Result of upstream task "$dep" (truncate as needed; use '
            '`get_ticket` for the full payload):')
        ..writeln('{{out_$dep}}');
    }
    return buf.toString();
  }

  String _synthesisPrompt(OrchestrationProposal p) {
    final buf = StringBuffer()
      ..writeln(p.synthesis.prompt)
      ..writeln()
      ..writeln('Overall goal: ${p.goal}')
      ..writeln()
      ..writeln('Sub-task results (a failed task shows `{"failed": true}` — '
          'cover its gap in your `gaps` field):');
    for (final t in p.subTickets) {
      buf
        ..writeln()
        ..writeln('### ${t.title} (${t.key})')
        ..writeln('{{out_${t.key}}}');
    }
    buf
      ..writeln()
      ..writeln('Failed inputs: {{failed_inputs}}');
    return buf.toString();
  }

  static String _short(String s) =>
      s.length <= 60 ? s : '${s.substring(0, 57)}…';

  /// Schema for a discussion-round position.
  static const Map<String, dynamic> _discussionSchema = {
    'type': 'object',
    'required': ['position'],
    'properties': {
      'position': {'type': 'string'},
      'risks': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
  };
}
