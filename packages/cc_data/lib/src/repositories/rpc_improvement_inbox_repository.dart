import 'dart:convert';

import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_inbox_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_evaluation_summary.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_rpc/cc_rpc.dart';

DateTime? _at(Object? raw) => raw is String ? DateTime.parse(raw) : null;

T _enum<T>(T? value, Object? raw, String what) =>
    value ?? (throw FormatException('unknown $what $raw'));

/// Decodes one `improvements.*` proposal row. Throws on a row the client
/// cannot read (an unknown kind, scope, operation or status), which
/// `decodeRows` drops.
ImprovementProposal improvementProposalFromWire(Map<String, dynamic> w) =>
    ImprovementProposal(
      id: w['id'] as String,
      workspaceId: w['workspace_id'] as String,
      agentId: w['agent_id'] as String,
      spaceId: w['space_id'] as String?,
      conversationId: w['conversation_id'] as String?,
      goalId: w['goal_id'] as String?,
      reviewRunId: w['review_run_id'] as String?,
      kind: _enum(
        ImprovementKindWire.tryParse(w['kind'] as String?),
        w['kind'],
        'kind',
      ),
      scope: _enum(
        ImprovementScopeWire.tryParse(w['scope'] as String?),
        w['scope'],
        'scope',
      ),
      scopeRefId: w['scope_ref_id'] as String?,
      operation: _enum(
        ImprovementOperationWire.tryParse(w['operation'] as String?),
        w['operation'],
        'operation',
      ),
      targetRef: w['target_ref'] as String?,
      change: w['change'] as String,
      evidence: ImprovementEvidence.tryParse(
        w['evidence'] == null ? null : jsonEncode(w['evidence']),
      ),
      expected: w['expected'] as String,
      status: _enum(
        ImprovementStatusWire.tryParse(w['status'] as String?),
        w['status'],
        'status',
      ),
      beforeText: w['before_text'] as String?,
      afterText: w['after_text'] as String?,
      appliedRef: w['applied_ref'] as String?,
      candidateRevisionId: w['candidate_revision_id'] as String?,
      campaignId: w['campaign_id'] as String?,
      campaignState:
          ImprovementCampaignStateWire.tryParse(
            w['campaign_state'] as String?,
          ) ??
          ImprovementCampaignState.none,
      decidedByUserId: w['decided_by_user_id'] as String?,
      decidedAt: _at(w['decided_at']),
      createdAt: DateTime.parse(w['created_at'] as String),
      expiresAt: DateTime.parse(w['expires_at'] as String),
    );

/// Decodes one proposal row with the server's `needs_admin` (absent reads
/// as not needing an admin; the server still refuses a member).
ImprovementProposalView improvementProposalViewFromWire(
  Map<String, dynamic> w,
) => ImprovementProposalView(
  proposal: improvementProposalFromWire(w),
  needsAdmin: w['needs_admin'] == true,
  evaluation: switch (w['evaluation']) {
    final Map<String, dynamic> e => improvementEvaluationFromWire(e),
    _ => null,
  },
);

/// Decodes a skill change's `evaluation` (its campaign report's numbers).
/// An absent `verdict` or `plan_violations` reads as null; an absent count
/// as zero.
ImprovementEvaluationSummary improvementEvaluationFromWire(
  Map<String, dynamic> e,
) {
  int count(Object? v) => v is num ? v.toInt() : 0;
  final regressions = switch (e['regressions']) {
    final Map<String, dynamic> r => r,
    _ => const <String, dynamic>{},
  };
  final violations = e['plan_violations'];
  return ImprovementEvaluationSummary(
    pairedRuns: count(e['paired_runs']),
    candidateSolved: count(e['candidate_solved']),
    baselineSolved: count(e['baseline_solved']),
    verdict: switch (e['verdict']) {
      final String v => ImprovementVerdictWire.tryParse(v),
      _ => null,
    },
    qualityLosses: count(regressions['quality_loss']),
    costRegressions: count(regressions['cost_regression']),
    harnessErrors: count(regressions['harness_error']),
    coverageComplete: e['coverage_complete'] == true,
    planViolations: violations is num ? violations.toInt() : null,
  );
}

/// [ImprovementInboxRepository] over the `improvements.*` RPC ops.
class RpcImprovementInboxRepository implements ImprovementInboxRepository {
  /// Creates the repository over [_client].
  RpcImprovementInboxRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<ImprovementProposalView>> watchForWorkspace(
    String workspaceId, {
    required ImprovementStatus? status,
  }) => _client
      .subscribe('improvements.watchForWorkspace', {
        'workspace_id': workspaceId,
        'status': ?status?.wire,
      })
      .map(
        (data) => decodeRows(
          [
            for (final row in (data['proposals'] as List?) ?? const [])
              if (row is Map) row.cast<String, dynamic>(),
          ],
          improvementProposalViewFromWire,
          what: 'improvement proposal',
        ),
      );

  Future<ImprovementProposalView> _decision(
    String op,
    String workspaceId,
    String proposalId, [
    Map<String, Object?> extra = const {},
  ]) async {
    final data = await _client.call(op, {
      'workspace_id': workspaceId,
      'proposal_id': proposalId,
      ...extra,
    });
    return improvementProposalViewFromWire(
      (data['proposal'] as Map).cast<String, dynamic>(),
    );
  }

  @override
  Future<ImprovementProposalView> get(
    String workspaceId,
    String proposalId,
  ) => _decision('improvements.get', workspaceId, proposalId);

  @override
  Future<ImprovementProposalView> accept(
    String workspaceId,
    String proposalId,
  ) => _decision('improvements.accept', workspaceId, proposalId);

  @override
  Future<ImprovementProposalView> reject(
    String workspaceId,
    String proposalId,
  ) => _decision('improvements.reject', workspaceId, proposalId);

  @override
  Future<ImprovementProposalView> rollback(
    String workspaceId,
    String proposalId,
  ) => _decision('improvements.rollback', workspaceId, proposalId);

  @override
  Future<ImprovementProposalView> startCampaign(
    String workspaceId,
    String proposalId, {
    required String corpusId,
    required String providerId,
    required String modelId,
    required int repetitions,
    required int budgetMicros,
  }) => _decision('improvements.startCampaign', workspaceId, proposalId, {
    'corpus_id': corpusId,
    'provider_id': providerId,
    'model_id': modelId,
    'repetitions': repetitions,
    'budget_micros': budgetMicros,
  });
}
