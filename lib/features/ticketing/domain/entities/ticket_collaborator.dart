/// A Control-Center participant invited to collaborate on a ticket.
///
/// Mirrors messaging's `ChannelParticipant` exactly: [agentId] is either an
/// agent UUID or the `'user'` sentinel for the human, with no foreign key to
/// the agents table (so the human sentinel and deleted-agent rows are tolerated
/// and cleaned up in application code).
class TicketCollaborator {
  /// Creates a [TicketCollaborator].
  TicketCollaborator({
    required this.id,
    required this.ticketId,
    required this.agentId,
    this.role = TicketCollaboratorRole.collaborator,
    required this.joinedAt,
  }) : assert(agentId.isNotEmpty, 'agentId must not be empty');

  /// Sentinel [agentId] for the human user.
  static const String userSentinel = 'user';

  /// Unique row id (UUID v4).
  final String id;

  /// Ticket this collaborator belongs to.
  final String ticketId;

  /// Agent UUID, or [userSentinel] for the human.
  final String agentId;

  /// The collaborator's role on the ticket.
  final TicketCollaboratorRole role;

  /// When they joined.
  final DateTime joinedAt;

  /// Whether this collaborator is the human user.
  bool get isUser => agentId == userSentinel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketCollaborator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketId == other.ticketId &&
          agentId == other.agentId &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, ticketId, agentId, role);
}

/// The role a [TicketCollaborator] plays on a ticket.
enum TicketCollaboratorRole {
  /// Primary owner of the work (in addition to the ticket's `assignedAgentId`).
  assignee,

  /// Invited to help.
  collaborator,

  /// Reviews the work.
  reviewer;

  /// Parses the persisted value. Unknown / null → [collaborator].
  static TicketCollaboratorRole fromStorage(String? raw) {
    for (final r in values) {
      if (r.name == raw) {
        return r;
      }
    }
    return TicketCollaboratorRole.collaborator;
  }

  /// Serializes for storage.
  String toStorageString() => name;
}
