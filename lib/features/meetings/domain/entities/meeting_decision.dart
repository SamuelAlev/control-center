/// A decision extracted from a meeting summary, persisted as its own row.
///
/// Produced by the `meeting_summary` pipeline's deterministic persist step from
/// the agent's structured output — never parsed out of the notes markdown.
class MeetingDecision {
  /// Creates a [MeetingDecision].
  MeetingDecision({
    required this.id,
    required this.meetingId,
    required this.workspaceId,
    required this.content,
    required this.createdAt,
    this.sortOrder = 0,
  }) : assert(
          workspaceId.isNotEmpty,
          'MeetingDecision workspaceId must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Parent meeting id.
  final String meetingId;

  /// Owning workspace.
  final String workspaceId;

  /// The decision text.
  final String content;

  /// Ordering within the meeting.
  final int sortOrder;

  /// When the row was created.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingDecision &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetingId == other.meetingId &&
          workspaceId == other.workspaceId &&
          content == other.content &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      Object.hash(id, meetingId, workspaceId, content, sortOrder);
}
