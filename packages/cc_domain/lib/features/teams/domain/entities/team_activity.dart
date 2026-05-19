/// The outcome a team leader records when it evaluates a routed request.
enum TeamActivityKind {
  /// The leader delegated (or re-delegated) the request to a member.
  action,

  /// The leader decided nothing further is needed (work complete, out of
  /// scope, or no member fits). A `no_action` row for a ticket suppresses
  /// further leader re-triggers for that ticket.
  noAction,

  /// The request could not be completed by the chosen member.
  failed;

  /// Storage string for this kind.
  String toStorageString() => switch (this) {
    TeamActivityKind.action => 'action',
    TeamActivityKind.noAction => 'no_action',
    TeamActivityKind.failed => 'failed',
  };

  /// Parses a [TeamActivityKind] from its storage string.
  static TeamActivityKind fromString(String value) => switch (value) {
    'action' => TeamActivityKind.action,
    'failed' => TeamActivityKind.failed,
    _ => TeamActivityKind.noAction,
  };
}

/// One leader evaluation of a routed request, recorded against a ticket.
///
/// The activity log is both an audit trail of leader decisions and the
/// dedup substrate for the re-trigger loop: a [TeamActivityKind.noAction]
/// entry for a `(teamId, ticketId)` pair stops the leader from being re-woken
/// for that ticket again (see
/// `TeamActivityRepository.hasNoActionEvaluationForTicket`).
class TeamActivity {
  /// Creates a [TeamActivity].
  TeamActivity({
    required this.id,
    required this.workspaceId,
    required this.teamId,
    required this.ticketId,
    required this.kind,
    this.leaderId,
    this.memberId,
    this.summary,
    required this.createdAt,
  });

  /// Unique identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The team whose leader recorded this evaluation.
  final String teamId;

  /// The ticket the evaluation is about.
  final String ticketId;

  /// The recorded outcome.
  final TeamActivityKind kind;

  /// The leader agent that recorded it, if known.
  final String? leaderId;

  /// The member the leader delegated to (for [TeamActivityKind.action]), if any.
  final String? memberId;

  /// A short human-readable note about the decision.
  final String? summary;

  /// When the evaluation was recorded.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamActivity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
