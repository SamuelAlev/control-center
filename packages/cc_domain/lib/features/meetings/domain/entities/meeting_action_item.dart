/// Aggregate counts of a meeting's action items (total + checked-off), used by
/// the list view's signal pills and the stats strip.
typedef MeetingActionItemStats = ({int total, int done});

/// An action item extracted from a meeting summary, persisted as its own row.
///
/// Produced by the `meeting_summary` pipeline's deterministic persist step from
/// the agent's structured output — never parsed out of the notes markdown.
class MeetingActionItem {
  /// Creates a [MeetingActionItem].
  MeetingActionItem({
    required this.id,
    required this.meetingId,
    required this.workspaceId,
    required this.content,
    required this.createdAt,
    this.owner,
    this.done = false,
    this.ticketId,
    this.sortOrder = 0,
    this.isManual = false,
  }) : assert(
          workspaceId.isNotEmpty,
          'MeetingActionItem workspaceId must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Parent meeting id.
  final String meetingId;

  /// Owning workspace.
  final String workspaceId;

  /// The action-item text.
  final String content;

  /// Optional owner / assignee.
  final String? owner;

  /// Whether the user checked it off (persisted).
  final bool done;

  /// The id / key of a ticket created from this item, if any.
  final String? ticketId;

  /// Ordering within the meeting.
  final int sortOrder;

  /// Whether the user authored or edited this item (vs. the agent extracting
  /// it). Manual items survive a "Re-run summary"; agent items are regenerated.
  final bool isManual;

  /// When the row was created.
  final DateTime createdAt;

  /// Returns a copy with the given overrides.
  MeetingActionItem copyWith({
    String? content,
    String? owner,
    bool? done,
    String? ticketId,
    int? sortOrder,
    bool? isManual,
  }) {
    return MeetingActionItem(
      id: id,
      meetingId: meetingId,
      workspaceId: workspaceId,
      content: content ?? this.content,
      owner: owner ?? this.owner,
      done: done ?? this.done,
      ticketId: ticketId ?? this.ticketId,
      sortOrder: sortOrder ?? this.sortOrder,
      isManual: isManual ?? this.isManual,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingActionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetingId == other.meetingId &&
          workspaceId == other.workspaceId &&
          content == other.content &&
          owner == other.owner &&
          done == other.done &&
          ticketId == other.ticketId &&
          sortOrder == other.sortOrder &&
          isManual == other.isManual;

  @override
  int get hashCode => Object.hash(
        id,
        meetingId,
        workspaceId,
        content,
        owner,
        done,
        ticketId,
        sortOrder,
        isManual,
      );
}
