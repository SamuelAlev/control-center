import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_divergence_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

/// Plan-drift detection (PRD 17 §6): cost above estimate high bound, or files outside declared refs.
///
/// Markers in [PlanDivergenceRepository]; under `stopAndAsk` holds the step
/// until continue/cancel.
class PlanDriftService {
  /// Creates the service.
  PlanDriftService({
    required this._orchestrations,
    required this._runLogs,
    required this._divergences,
    required this._messaging,
    required this._conversationChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final OrchestrationRepository _orchestrations;
  final AgentRunLogRepository _runLogs;
  final PlanDivergenceRepository _divergences;
  final DateTime Function() _now;
  final MessagingRepository _messaging;
  final Future<List<PrFile>> Function(String workspaceId, String spaceId)
  _conversationChanges;

  /// The resume-listener drift gate: evaluates a just-finished step and
  /// returns true to HOLD it (stop-and-ask divergence).
  Future<bool> evaluate({
    required String workspaceId,
    required String pipelineRunId,
    required String stepId,
  }) async {
    if (!stepId.startsWith('sub_')) {
      return false;
    }
    final orchestration = await _orchestrations.forPipelineRun(
      workspaceId,
      pipelineRunId,
    );
    if (orchestration == null) {
      return false;
    }
    final nodeKey = stepId.substring('sub_'.length);
    ProposedSubTicket? node;
    for (final t in orchestration.proposal.subTickets) {
      if (t.key == nodeKey) {
        node = t;
        break;
      }
    }
    if (node == null) {
      return false;
    }

    final reasons = <String>[];
    final runs = await _runLogs.forPipelineStep(
      workspaceId,
      pipelineRunId,
      stepId,
    );

    // Cost band (only a real band can be overrun).
    final estimate = node.estimate;
    if (estimate != null &&
        estimate.hasHistory &&
        estimate.costMicrosHigh != null) {
      var actualMicros = 0;
      for (final run in runs) {
        actualMicros += run.totalCostMicrosWithChildren;
      }
      if (actualMicros > estimate.costMicrosHigh!) {
        reasons.add(
          'Cost ${formatUsdMicros(actualMicros)} exceeded the estimate band '
          '(≤ ${formatUsdMicros(estimate.costMicrosHigh!)}, n=${estimate.sampleSize}).',
        );
      }
    }

    // Blast radius (only when the node declared file provenance).
    final declaredFiles = {
      for (final ref in node.provenance)
        if (ref.kind == 'file') ref.ref,
    };
    if (declaredFiles.isNotEmpty && runs.isNotEmpty) {
      // Worktrees are SPACE-scoped (every conversation in a room shares one
      // checkout), so the lookup takes the run's space. Preferring the
      // conversation id matched no worktree and drift never fired.
      final spaceId = runs.first.spaceId;
      if (spaceId != null && spaceId.isNotEmpty) {
        try {
          final files = await _conversationChanges(workspaceId, spaceId);
          final outside = [
            for (final f in files)
              if (!declaredFiles.contains(f.filename)) f.filename,
          ];
          if (outside.isNotEmpty) {
            final sample = outside.take(6).join(', ');
            final more = outside.length > 6
                ? ' and ${outside.length - 6} more'
                : '';
            reasons.add(
              '${outside.length} file(s) touched outside the declared blast '
              'radius: $sample$more.',
            );
          }
        } catch (_) {
          // Worktree diff unavailable — never fabricate a divergence.
        }
      }
    }

    if (reasons.isEmpty) {
      return false;
    }

    final hold =
        orchestration.proposal.driftPolicy == PlanDriftPolicy.stopAndAsk;
    await _recordMarker(
      workspaceId: workspaceId,
      orchestrationId: orchestration.id,
      nodeKey: nodeKey,
      reasons: reasons,
      held: hold,
    );

    final spaceId = orchestration.spaceId;
    if (spaceId != null && spaceId.isNotEmpty) {
      await _messaging.sendMessage(
        workspaceId: workspaceId,
        spaceId: spaceId,
        content:
            'Plan node "${node.title}" diverged from its declared '
            'scope:\n${reasons.map((r) => '- $r').join('\n')}'
            '${hold ? '\nExecution paused at this node (stop-and-ask policy) — resume or cancel from Plan Studio.' : ''}',
        senderId: 'system',
        senderType: 'system',
        messageType: 'system',
      );
    }
    return hold;
  }

  /// The divergence markers for one orchestration
  /// (`{nodeKey: {reasons[], at, held}}`), or empty.
  Future<Map<String, dynamic>> markers(
    String workspaceId,
    String orchestrationId,
  ) async => {
    for (final entry in (await _divergences.forOrchestration(
      workspaceId,
      orchestrationId,
    )).entries)
      entry.key: entry.value.toWire(),
  };

  /// Clears a node's `held` flag after the operator resumed it.
  Future<void> markResumed(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  ) => _divergences.markResumed(workspaceId, orchestrationId, nodeKey);

  Future<void> _recordMarker({
    required String workspaceId,
    required String orchestrationId,
    required String nodeKey,
    required List<String> reasons,
    required bool held,
  }) => _divergences.record(
    workspaceId,
    orchestrationId,
    PlanDivergence(nodeKey: nodeKey, reasons: reasons, at: _now(), held: held),
  );
}
