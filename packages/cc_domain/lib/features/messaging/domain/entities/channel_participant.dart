import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// A participant in a messaging channel: an agent or a human user.
///
/// Humans are first-class participants ([participantType] ==
/// [PrincipalType.user] with [principalId] holding their user id) — there is
/// no sentinel value. Each human member keeps their own row (and therefore
/// their own read cursor) per channel.
class ChannelParticipant {
  /// Creates a new [ChannelParticipant].
  ChannelParticipant({
    required this.id,
    required this.channelId,
    required this.principalId,
    required this.participantType,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
  }) : assert(
         principalId.isNotEmpty,
         'ChannelParticipant principalId must not be empty',
       );

  /// Unique identifier.
  final String id;

  /// Parent channel identifier.
  final String channelId;

  /// Agent id or user id, per [participantType].
  final String principalId;

  /// Which kind of principal this participant is.
  final PrincipalType participantType;

  /// Participant role.
  final String role;

  /// When the participant joined.
  final DateTime joinedAt;

  /// When this participant last read the channel (their read cursor). Null
  /// until the channel is first opened — legacy/never-opened rows are treated
  /// as "nothing unseen yet". Drives the sidebar unread indicator: an agent
  /// message newer than this (while no run is in flight) surfaces a dot.
  final DateTime? lastReadAt;

  /// Whether this participant is a human user.
  bool get isUser => participantType == PrincipalType.user;

  /// The typed principal this participant represents.
  Principal get principal => Principal.of(participantType, principalId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          channelId == other.channelId &&
          principalId == other.principalId &&
          participantType == other.participantType &&
          role == other.role &&
          joinedAt == other.joinedAt &&
          lastReadAt == other.lastReadAt;

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    principalId,
    participantType,
    role,
    joinedAt,
    lastReadAt,
  );

  /// Returns a copy with optional overrides.
  ChannelParticipant copyWith({
    String? id,
    String? channelId,
    String? principalId,
    PrincipalType? participantType,
    String? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool clearLastReadAt = false,
  }) {
    return ChannelParticipant(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      principalId: principalId ?? this.principalId,
      participantType: participantType ?? this.participantType,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: clearLastReadAt ? null : (lastReadAt ?? this.lastReadAt),
    );
  }
}
