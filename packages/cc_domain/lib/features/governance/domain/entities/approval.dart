import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';

/// A durable, reviewable governance gate for a high-stakes action.
///
/// Unlike a per-action confirmation prompt (resolved once, in the moment), an
/// approval is a persisted object with a decision state machine and a comment
/// history — the right primitive for plan-mode exits, merge decisions, release
/// gates and hires. Every approval belongs to exactly one workspace.
class Approval {
  /// Creates an [Approval].
  Approval({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.kind = ApprovalKind.custom,
    this.status = ApprovalStatus.pending,
    this.requestedByActorType = 'agent',
    this.requestedById,
    this.linkedTicketIds = const [],
    this.linkedEntityType,
    this.linkedEntityId,
    this.decidedByActorType,
    this.decidedById,
    this.decisionReason,
    required this.createdAt,
    this.decidedAt,
    required this.updatedAt,
  }) {
    if (title.isEmpty) {
      throw ArgumentError('Approval title must not be empty');
    }
  }

  /// Unique approval identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Short title of what is being approved.
  final String title;

  /// Optional longer description / rationale.
  final String? description;

  /// Kind of governed action.
  final ApprovalKind kind;

  /// Decision state.
  final ApprovalStatus status;

  /// Actor type that requested the approval.
  final String requestedByActorType;

  /// Identifier of the requesting actor, if known.
  final String? requestedById;

  /// Ticket ids this approval gates (multi-issue gate).
  final List<String> linkedTicketIds;

  /// Type of a single linked entity (e.g. `pull_request`), if any.
  final String? linkedEntityType;

  /// Identifier of the single linked entity, if any.
  final String? linkedEntityId;

  /// Actor type that made the decision, if decided.
  final String? decidedByActorType;

  /// Identifier of the deciding actor, if decided.
  final String? decidedById;

  /// Reason captured with the decision, if any.
  final String? decisionReason;

  /// When the approval was created.
  final DateTime createdAt;

  /// When a terminal decision was recorded, if decided.
  final DateTime? decidedAt;

  /// When the approval was last updated.
  final DateTime updatedAt;

  /// Whether a terminal decision has been reached.
  bool get isDecided => status.isTerminal;

  /// Whether the gated action is cleared to proceed.
  bool get isApproved => status.isApproved;

  /// Returns a copy with the given fields replaced.
  Approval copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    bool removeDescription = false,
    ApprovalKind? kind,
    ApprovalStatus? status,
    String? requestedByActorType,
    String? requestedById,
    bool removeRequestedById = false,
    List<String>? linkedTicketIds,
    String? linkedEntityType,
    bool removeLinkedEntityType = false,
    String? linkedEntityId,
    bool removeLinkedEntityId = false,
    String? decidedByActorType,
    bool removeDecidedByActorType = false,
    String? decidedById,
    bool removeDecidedById = false,
    String? decisionReason,
    bool removeDecisionReason = false,
    DateTime? createdAt,
    DateTime? decidedAt,
    bool removeDecidedAt = false,
    DateTime? updatedAt,
  }) {
    return Approval(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: removeDescription ? null : (description ?? this.description),
      kind: kind ?? this.kind,
      status: status ?? this.status,
      requestedByActorType: requestedByActorType ?? this.requestedByActorType,
      requestedById: removeRequestedById
          ? null
          : (requestedById ?? this.requestedById),
      linkedTicketIds: linkedTicketIds ?? this.linkedTicketIds,
      linkedEntityType: removeLinkedEntityType
          ? null
          : (linkedEntityType ?? this.linkedEntityType),
      linkedEntityId: removeLinkedEntityId
          ? null
          : (linkedEntityId ?? this.linkedEntityId),
      decidedByActorType: removeDecidedByActorType
          ? null
          : (decidedByActorType ?? this.decidedByActorType),
      decidedById: removeDecidedById ? null : (decidedById ?? this.decidedById),
      decisionReason: removeDecisionReason
          ? null
          : (decisionReason ?? this.decisionReason),
      createdAt: createdAt ?? this.createdAt,
      decidedAt: removeDecidedAt ? null : (decidedAt ?? this.decidedAt),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Approval &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          description == other.description &&
          kind == other.kind &&
          status == other.status &&
          requestedByActorType == other.requestedByActorType &&
          requestedById == other.requestedById &&
          _listEquals(linkedTicketIds, other.linkedTicketIds) &&
          linkedEntityType == other.linkedEntityType &&
          linkedEntityId == other.linkedEntityId &&
          decidedByActorType == other.decidedByActorType &&
          decidedById == other.decidedById &&
          decisionReason == other.decisionReason &&
          createdAt == other.createdAt &&
          decidedAt == other.decidedAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    description,
    kind,
    status,
    requestedByActorType,
    requestedById,
    Object.hashAll(linkedTicketIds),
    linkedEntityType,
    linkedEntityId,
    decidedByActorType,
    decidedById,
    decisionReason,
    createdAt,
    decidedAt,
    updatedAt,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
