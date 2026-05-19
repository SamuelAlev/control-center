/// A participant in a messaging channel.
class ChannelParticipant {
  /// Creates a new [ChannelParticipant].
  ChannelParticipant({
    required this.id,
    required this.channelId,
    required this.agentId,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
  }) : assert(
         agentId.isNotEmpty,
         'ChannelParticipant agentId must not be empty',
       );

  /// Unique identifier.
  final String id;
  /// Parent channel identifier.
  final String channelId;

  /// Agent id, or the sentinel `'user'` for the human user.
  final String agentId;
  /// Participant role.
  final String role;
  /// When the participant joined.
  final DateTime joinedAt;

  /// When this participant last read the channel (their read cursor). Null
  /// until the channel is first opened — legacy/never-opened rows are treated
  /// as "nothing unseen yet". Drives the sidebar unread indicator: an agent
  /// message newer than this (while no run is in flight) surfaces a dot.
  final DateTime? lastReadAt;

  /// Whether this participant represents the human user.
  bool get isUser => agentId == 'user';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          channelId == other.channelId &&
          agentId == other.agentId &&
          role == other.role &&
          joinedAt == other.joinedAt &&
          lastReadAt == other.lastReadAt;

  @override
  int get hashCode => Object.hash(id, channelId, agentId, role, joinedAt, lastReadAt);

  /// Returns a copy with optional overrides.
  ChannelParticipant copyWith({
    String? id,
    String? channelId,
    String? agentId,
    String? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool clearLastReadAt = false,
  }) {
    return ChannelParticipant(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      agentId: agentId ?? this.agentId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: clearLastReadAt ? null : (lastReadAt ?? this.lastReadAt),
    );
  }
}
