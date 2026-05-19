import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// A Control-Center participant invited to collaborate on a ticket.
///
/// Mirrors messaging's `SpaceParticipant` exactly: [principalId] is an
/// agent id or a user id per [collaboratorType], with no foreign key (deleted
/// principals are tolerated and cleaned up in application code). Humans are
/// first-class rows — there is no sentinel.
class TicketCollaborator {
  /// Creates a [TicketCollaborator].
  TicketCollaborator({
    required this.id,
    required this.ticketId,
    required this.principalId,
    this.collaboratorType = PrincipalType.agent,
    this.role = TicketCollaboratorRole.collaborator,
    required this.joinedAt,
  }) {
    if (principalId.isEmpty) {
      throw ArgumentError('principalId must not be empty');
    }
  }

  /// Unique row id (UUID v4).
  final String id;

  /// Ticket this collaborator belongs to.
  final String ticketId;

  /// Agent id or user id, per [collaboratorType].
  final String principalId;

  /// Which kind of principal this collaborator is.
  final PrincipalType collaboratorType;

  /// The collaborator's role on the ticket.
  final TicketCollaboratorRole role;

  /// When they joined.
  final DateTime joinedAt;

  /// Whether this collaborator is a human user.
  bool get isUser => collaboratorType == PrincipalType.user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketCollaborator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketId == other.ticketId &&
          principalId == other.principalId &&
          collaboratorType == other.collaboratorType &&
          role == other.role;

  @override
  int get hashCode =>
      Object.hash(id, ticketId, principalId, collaboratorType, role);
}

/// The role a [TicketCollaborator] plays on a ticket.
enum TicketCollaboratorRole {
  /// Primary owner of the work (in addition to the ticket's `assignedAgentId`).
  assignee,

  /// Invited to help.
  collaborator,

  /// Reviews the work.
  reviewer;

  /// Parses the persisted value. A null value defaults to [collaborator]; an
  /// unknown value throws so a corrupt role surfaces loudly instead of being
  /// silently downgraded (which could grant the wrong permissions).
  static TicketCollaboratorRole fromStorage(String? raw) {
    if (raw == null) {
      return TicketCollaboratorRole.collaborator;
    }
    for (final r in values) {
      if (r.name == raw) {
        return r;
      }
    }
    throw ArgumentError('Unknown ticket collaborator role in storage: "$raw"');
  }

  /// Serializes for storage.
  String toStorageString() => name;
}
