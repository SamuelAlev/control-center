/// The canonical, directional type of a [TicketLink] as it is stored. One row
/// is `source --type--> target`; the inverse views (blocked-by, duplicated-by)
/// are derived, never stored separately.
enum TicketLinkType {
  /// `source` blocks `target` (target cannot proceed until source is done).
  blocks,

  /// `source` and `target` are related (symmetric).
  relatesTo,

  /// `source` is a duplicate of `target`.
  duplicateOf;

  /// Parses a stored value.
  static TicketLinkType? fromStorage(String? value) => switch (value) {
        'blocks' => TicketLinkType.blocks,
        'relates_to' => TicketLinkType.relatesTo,
        'duplicate_of' => TicketLinkType.duplicateOf,
        _ => null,
      };

  /// The stored string form (snake_case).
  String toStorageString() => switch (this) {
        TicketLinkType.blocks => 'blocks',
        TicketLinkType.relatesTo => 'relates_to',
        TicketLinkType.duplicateOf => 'duplicate_of',
      };
}

/// How a link reads from one ticket's point of view. Derived from a
/// [TicketLink] plus which endpoint the subject ticket sits on, and from the
/// parent/sub-issue tree (`tickets.parent_ticket_id`). This is the vocabulary
/// the UI's "Relate to" menu and the relations card speak.
enum TicketRelationKind {
  /// The subject is blocked by the other ticket.
  blockedBy,

  /// The subject is blocking the other ticket.
  blocking,

  /// The two tickets are related (symmetric).
  relatedTo,

  /// The subject is a duplicate of the other ticket.
  duplicateOf,

  /// The other ticket is a duplicate of the subject.
  duplicatedBy,

  /// The subject's parent is the other ticket (subject is a sub-issue).
  subIssueOf,

  /// The other ticket is a child of the subject (subject is the parent).
  parentOf,
}

/// A directional dependency edge between two tickets. Parent/sub-issue links
/// are NOT represented here (they live on `tickets.parent_ticket_id`).
class TicketLink {
  /// Creates a [TicketLink].
  TicketLink({
    required this.id,
    required this.workspaceId,
    required this.sourceTicketId,
    required this.targetTicketId,
    required this.type,
    required this.createdAt,
  });

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// Origin ticket of the relationship.
  final String sourceTicketId;

  /// Destination ticket of the relationship.
  final String targetTicketId;

  /// Canonical relationship type.
  final TicketLinkType type;

  /// When the link was created.
  final DateTime createdAt;

  /// The relation as it reads from [subjectTicketId]'s perspective, plus the
  /// id of the ticket on the other end. Returns null if the subject is not an
  /// endpoint of this link.
  ({TicketRelationKind kind, String otherTicketId})? relationFor(
    String subjectTicketId,
  ) {
    final isSource = sourceTicketId == subjectTicketId;
    final isTarget = targetTicketId == subjectTicketId;
    if (!isSource && !isTarget) {
      return null;
    }
    final other = isSource ? targetTicketId : sourceTicketId;
    final kind = switch ((type, isSource)) {
      (TicketLinkType.blocks, true) => TicketRelationKind.blocking,
      (TicketLinkType.blocks, false) => TicketRelationKind.blockedBy,
      (TicketLinkType.relatesTo, _) => TicketRelationKind.relatedTo,
      (TicketLinkType.duplicateOf, true) => TicketRelationKind.duplicateOf,
      (TicketLinkType.duplicateOf, false) => TicketRelationKind.duplicatedBy,
    };
    return (kind: kind, otherTicketId: other);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketLink &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceTicketId == other.sourceTicketId &&
          targetTicketId == other.targetTicketId &&
          type == other.type;

  @override
  int get hashCode =>
      Object.hash(id, sourceTicketId, targetTicketId, type);
}
