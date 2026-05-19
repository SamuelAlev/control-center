import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// Plan-drift detection (PRD 17 §6): compares a finished plan node's actual
/// execution against its declared scope and records divergence markers.
///
/// Two honest signals, both derived from data the plan itself declared:
///  - **Cost band**: actual run cost above the node's estimate high bound
///    (only when the estimate had history — a "no history yet" node cannot
///    "overrun" a band it never had).
///  - **Blast radius**: files touched in the node's worktree outside the
///    node's `file` provenance refs (only when the node declared any — the
///    detector never infers scope from prose).
///
/// Markers land in the Caches table (kind [cacheKind], key = orchestration
/// id, value `{nodeKey: {reasons[], at, held}}`) — the Studio canvas renders
/// them as divergence badges. Under the plan's `stopAndAsk` policy the
/// detector also HOLDS the step (via the resume listener's drift gate): the
/// operator resumes with `orchestration.continueNode` or cancels.
class PlanDriftService {
  /// Creates the service.
  PlanDriftService({
    required OrchestrationRepository orchestrations,
    required AgentRunLogRepository runLogs,
    required WorkspaceDatabaseManager workspaceDbs,
    required MessagingRepository messaging,
    required Future<List<PrFile>> Function(String workspaceId, String channelId)
    conversationChanges,
  }) : _orchestrations = orchestrations,
       _runLogs = runLogs,
       _dbs = workspaceDbs,
       _messaging = messaging,
       _conversationChanges = conversationChanges;

  /// The Caches kind holding divergence markers (key = orchestration id).
  static const String cacheKind = 'plan_divergence';

  final OrchestrationRepository _orchestrations;
  final AgentRunLogRepository _runLogs;
  final WorkspaceDatabaseManager _dbs;
  final MessagingRepository _messaging;
  final Future<List<PrFile>> Function(String workspaceId, String channelId)
  _conversationChanges;

  /// Divergence markers live in the workspace's own database file, so each
  /// read/write resolves the cache from the workspace being evaluated.
  CacheDao _cache(String workspaceId) => _dbs.of(workspaceId).cacheDao;

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
        estimate.costCentsHigh != null) {
      var actualCents = 0;
      for (final run in runs) {
        actualCents += run.totalCostCentsWithChildren;
      }
      if (actualCents > estimate.costCentsHigh!) {
        reasons.add(
          'Cost ${_dollars(actualCents)} exceeded the estimate band '
          '(≤ ${_dollars(estimate.costCentsHigh!)}, n=${estimate.sampleSize}).',
        );
      }
    }

    // Blast radius (only when the node declared file provenance).
    final declaredFiles = {
      for (final ref in node.provenance)
        if (ref.kind == 'file') ref.ref,
    };
    if (declaredFiles.isNotEmpty && runs.isNotEmpty) {
      final conversationId = runs.first.conversationId ?? runs.first.channelId;
      if (conversationId != null && conversationId.isNotEmpty) {
        try {
          final files = await _conversationChanges(workspaceId, conversationId);
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

    final channelId = orchestration.channelId;
    if (channelId != null && channelId.isNotEmpty) {
      await _messaging.sendMessage(
        workspaceId: workspaceId,
        channelId: channelId,
        content:
            'Plan node "${node.title}" diverged from its declared '
            'scope:\n${reasons.map((r) => '- $r').join('\n')}'
            '${hold ? '\nExecution paused at this node (stop-and-ask policy) — resume or cancel from Plan Studio.' : ''}',
        senderId: 'system',
        senderType: 'agent',
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
  ) async {
    final raw = await _cache(
      workspaceId,
    ).read(workspaceId, cacheKind, orchestrationId);
    if (raw == null) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Clears a node's `held` flag after the operator resumed it.
  Future<void> markResumed(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  ) async {
    final all = Map<String, dynamic>.of(
      await markers(workspaceId, orchestrationId),
    );
    final marker = all[nodeKey];
    if (marker is Map) {
      all[nodeKey] = {...marker.cast<String, dynamic>(), 'held': false};
      await _cache(
        workspaceId,
      ).put(workspaceId, cacheKind, orchestrationId, jsonEncode(all));
    }
  }

  Future<void> _recordMarker({
    required String workspaceId,
    required String orchestrationId,
    required String nodeKey,
    required List<String> reasons,
    required bool held,
  }) async {
    final all = Map<String, dynamic>.of(
      await markers(workspaceId, orchestrationId),
    );
    all[nodeKey] = {
      'reasons': reasons,
      'at': DateTime.now().toIso8601String(),
      'held': held,
    };
    await _cache(
      workspaceId,
    ).put(workspaceId, cacheKind, orchestrationId, jsonEncode(all));
  }

  static String _dollars(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
}
