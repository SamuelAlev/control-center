import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [ImprovementProposal] and `improvement_proposals` rows. A
/// row the entity refuses reads as null and is left out of lists; malformed
/// evidence reads as empty.
class ImprovementProposalMapper {
  /// Creates an [ImprovementProposalMapper].
  const ImprovementProposalMapper();

  /// The proposal [row] holds, or null when it is not a valid proposal.
  ImprovementProposal? tryToDomain(ImprovementProposalsTableData row) {
    final kind = ImprovementKindWire.tryParse(row.kind);
    final scope = ImprovementScopeWire.tryParse(row.scope);
    final operation = ImprovementOperationWire.tryParse(row.operation);
    final status = ImprovementStatusWire.tryParse(row.status);
    final campaignState = ImprovementCampaignStateWire.tryParse(
      row.campaignState,
    );
    if (kind == null ||
        scope == null ||
        operation == null ||
        status == null ||
        campaignState == null) {
      return null;
    }
    try {
      return ImprovementProposal(
        id: row.id,
        workspaceId: row.workspaceId,
        agentId: row.agentId,
        spaceId: row.spaceId,
        conversationId: row.conversationId,
        goalId: row.goalId,
        reviewRunId: row.reviewRunId,
        kind: kind,
        scope: scope,
        scopeRefId: row.scopeRefId,
        operation: operation,
        targetRef: row.targetRef,
        change: row.change,
        evidence: ImprovementEvidence.tryParse(row.evidence),
        expected: row.expected,
        status: status,
        beforeText: row.beforeText,
        afterText: row.afterText,
        appliedRef: row.appliedRef,
        candidateRevisionId: row.candidateRevisionId,
        campaignId: row.campaignId,
        campaignState: campaignState,
        decidedByUserId: row.decidedByUserId,
        // Drift reads a stored time back as local time.
        decidedAt: row.decidedAt?.toUtc(),
        createdAt: row.createdAt.toUtc(),
        expiresAt: row.expiresAt.toUtc(),
      );
    } on ArgumentError {
      return null;
    }
  }

  /// The valid proposals among [rows], in order.
  List<ImprovementProposal> toDomainList(
    Iterable<ImprovementProposalsTableData> rows,
  ) => [for (final row in rows) ?tryToDomain(row)];

  /// Every column of [proposal].
  ImprovementProposalsTableCompanion toCompanion(
    ImprovementProposal proposal,
  ) => ImprovementProposalsTableCompanion(
    id: Value(proposal.id),
    workspaceId: Value(proposal.workspaceId),
    agentId: Value(proposal.agentId),
    spaceId: Value(proposal.spaceId),
    conversationId: Value(proposal.conversationId),
    goalId: Value(proposal.goalId),
    reviewRunId: Value(proposal.reviewRunId),
    kind: Value(proposal.kind.wire),
    scope: Value(proposal.scope.wire),
    scopeRefId: Value(proposal.scopeRefId),
    operation: Value(proposal.operation.wire),
    targetRef: Value(proposal.targetRef),
    change: Value(proposal.change),
    evidence: Value(proposal.evidence.encode()),
    expected: Value(proposal.expected),
    status: Value(proposal.status.wire),
    beforeText: Value(proposal.beforeText),
    afterText: Value(proposal.afterText),
    appliedRef: Value(proposal.appliedRef),
    candidateRevisionId: Value(proposal.candidateRevisionId),
    campaignId: Value(proposal.campaignId),
    campaignState: Value(proposal.campaignState.wire),
    decidedByUserId: Value(proposal.decidedByUserId),
    decidedAt: Value(proposal.decidedAt),
    createdAt: Value(proposal.createdAt),
    expiresAt: Value(proposal.expiresAt),
  );
}
