import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';

/// A durable deliverable artifact attached to a task — the stable handle whose
/// content lives in versioned revisions ([currentRevisionId] points at head).
class WorkProduct {
  /// Creates a [WorkProduct].
  WorkProduct({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.artifactType = WorkProductType.document,
    this.ticketId,
    this.agentId,
    this.currentRevisionId,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(title != '', 'Work product title must not be empty');

  /// Unique work-product identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Short title.
  final String title;

  /// Artifact kind.
  final WorkProductType artifactType;

  /// Ticket this artifact is a deliverable of, if any.
  final String? ticketId;

  /// Authoring / owning agent, if any.
  final String? agentId;

  /// Head revision id, or null before the first revision.
  final String? currentRevisionId;

  /// When created.
  final DateTime createdAt;

  /// When last updated.
  final DateTime updatedAt;

  /// Whether at least one revision has been written.
  bool get hasContent => currentRevisionId != null;

  /// Returns a copy with the given fields replaced.
  WorkProduct copyWith({
    String? id,
    String? workspaceId,
    String? title,
    WorkProductType? artifactType,
    String? ticketId,
    bool removeTicketId = false,
    String? agentId,
    bool removeAgentId = false,
    String? currentRevisionId,
    bool removeCurrentRevisionId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkProduct(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      artifactType: artifactType ?? this.artifactType,
      ticketId: removeTicketId ? null : (ticketId ?? this.ticketId),
      agentId: removeAgentId ? null : (agentId ?? this.agentId),
      currentRevisionId: removeCurrentRevisionId
          ? null
          : (currentRevisionId ?? this.currentRevisionId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          artifactType == other.artifactType &&
          ticketId == other.ticketId &&
          agentId == other.agentId &&
          currentRevisionId == other.currentRevisionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    artifactType,
    ticketId,
    agentId,
    currentRevisionId,
    createdAt,
    updatedAt,
  );
}

/// One immutable version of a work product's content.
class WorkProductRevision {
  /// Creates a [WorkProductRevision].
  const WorkProductRevision({
    required this.id,
    required this.workProductId,
    required this.workspaceId,
    required this.revisionNumber,
    required this.content,
    this.baseRevisionId,
    this.authorType = 'agent',
    this.authorId,
    this.summary,
    required this.createdAt,
  });

  /// Unique revision identifier.
  final String id;

  /// Work product this revision belongs to.
  final String workProductId;

  /// Owning workspace.
  final String workspaceId;

  /// 1-based monotonic revision number.
  final int revisionNumber;

  /// The full revision content.
  final String content;

  /// The revision this one was edited from (optimistic-concurrency base).
  final String? baseRevisionId;

  /// Actor type that authored the revision.
  final String authorType;

  /// Identifier of the authoring actor, if known.
  final String? authorId;

  /// Optional short summary of what changed.
  final String? summary;

  /// When written.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkProductRevision &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workProductId == other.workProductId &&
          workspaceId == other.workspaceId &&
          revisionNumber == other.revisionNumber &&
          content == other.content &&
          baseRevisionId == other.baseRevisionId &&
          authorType == other.authorType &&
          authorId == other.authorId &&
          summary == other.summary &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workProductId,
    workspaceId,
    revisionNumber,
    content,
    baseRevisionId,
    authorType,
    authorId,
    summary,
    createdAt,
  );
}
