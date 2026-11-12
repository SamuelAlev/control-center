import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:uuid/uuid.dart';

/// Drives board approvals through their decision state machine and records the
/// comment history. Every mutation is workspace-scoped and audited.
class ApprovalWorkflowService {
  /// Creates an [ApprovalWorkflowService].
  ApprovalWorkflowService({
    required this._repository,
    ActivityLogger? activityLogger,
  }) : _audit = activityLogger;

  final ApprovalRepository _repository;
  final ActivityLogger? _audit;

  static const _uuid = Uuid();

  /// Opens a new approval in the `pending` state.
  Future<Approval> createApproval({
    required String workspaceId,
    required String title,
    String? description,
    ApprovalKind kind = ApprovalKind.custom,
    String requestedByActorType = 'agent',
    String? requestedById,
    List<String> linkedTicketIds = const [],
    String? linkedEntityType,
    String? linkedEntityId,
    String? id,
  }) async {
    final now = DateTime.now();
    final approval = Approval(
      id: id ?? _uuid.v4(),
      workspaceId: workspaceId,
      title: title,
      description: description,
      kind: kind,
      requestedByActorType: requestedByActorType,
      requestedById: requestedById,
      linkedTicketIds: linkedTicketIds,
      linkedEntityType: linkedEntityType,
      linkedEntityId: linkedEntityId,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(approval);
    _audit?.log(
      actorType: requestedByActorType,
      actorId: requestedById,
      action: 'approval_requested',
      entityType: 'approval',
      entityId: approval.id,
      workspaceId: workspaceId,
      details: title,
    );
    return approval;
  }

  /// Applies [decision] to the approval [approvalId], enforcing the state
  /// machine. Throws [InvalidApprovalTransitionException] for an illegal
  /// transition and [NotFoundException] when the approval is missing (the
  /// workspace-scoped read returns null for a foreign approval).
  ///
  /// The write names the status the decision was checked against, so two
  /// deciders racing on one approval produce exactly one decision: the loser
  /// reloads and gets the transition error for the state the winner left.
  Future<Approval> decide(
    String approvalId, {
    required String workspaceId,
    required ApprovalDecision decision,
    String decidedByActorType = 'user',
    String? decidedById,
    String? reason,
  }) async {
    final current = await _load(workspaceId, approvalId, decision);
    final now = DateTime.now();
    final resulting = decision.resultingStatus;
    final updated = current.copyWith(
      status: resulting,
      decidedByActorType: resulting == ApprovalStatus.pending
          ? null
          : decidedByActorType,
      removeDecidedByActorType: resulting == ApprovalStatus.pending,
      decidedById: resulting == ApprovalStatus.pending ? null : decidedById,
      removeDecidedById: resulting == ApprovalStatus.pending,
      decisionReason: reason,
      removeDecisionReason: reason == null,
      decidedAt: resulting.isTerminal ? now : null,
      removeDecidedAt: !resulting.isTerminal,
      updatedAt: now,
    );
    if (!await _repository.recordDecision(updated, expected: current.status)) {
      // Another decision landed between the read and the write. Report the
      // state it left; a decision still valid from there was not what this
      // decider saw, so it is refused rather than applied on top.
      final latest = await _load(workspaceId, approvalId, decision);
      throw InvalidApprovalTransitionException(
        'Cannot ${decision.name} an approval that is ${latest.status.label}: '
        'it was decided concurrently.',
      );
    }
    _audit?.log(
      actorType: decidedByActorType,
      actorId: decidedById,
      action: 'approval_${decision.name}',
      entityType: 'approval',
      entityId: approvalId,
      workspaceId: workspaceId,
      details: reason,
    );
    return updated;
  }

  /// Reads the approval and checks that [decision] may apply to it.
  Future<Approval> _load(
    String workspaceId,
    String approvalId,
    ApprovalDecision decision,
  ) async {
    final current = await _repository.getById(workspaceId, approvalId);
    if (current == null) {
      throw NotFoundException('Approval $approvalId not found.');
    }
    if (!decision.isValidFrom(current.status)) {
      throw InvalidApprovalTransitionException(
        'Cannot ${decision.name} an approval that is ${current.status.label}.',
      );
    }
    return current;
  }

  /// Adds a comment to an approval's review discussion.
  Future<ApprovalComment> comment(
    String approvalId, {
    required String workspaceId,
    required String body,
    String authorType = 'user',
    String? authorId,
    String? id,
  }) async {
    final current = await _repository.getById(workspaceId, approvalId);
    if (current == null) {
      throw NotFoundException('Approval $approvalId not found.');
    }
    final comment = ApprovalComment(
      id: id ?? _uuid.v4(),
      approvalId: approvalId,
      workspaceId: workspaceId,
      authorType: authorType,
      authorId: authorId,
      body: body,
      createdAt: DateTime.now(),
    );
    await _repository.addComment(comment);
    _audit?.log(
      actorType: authorType,
      actorId: authorId,
      action: 'approval_commented',
      entityType: 'approval',
      entityId: approvalId,
      workspaceId: workspaceId,
    );
    return comment;
  }
}
