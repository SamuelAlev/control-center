import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// A participant in a messaging space: an agent or a human user.
///
/// Humans are first-class participants ([participantType] ==
/// [PrincipalType.user] with [principalId] holding their user id) — there is
/// no sentinel value. Each human member keeps their own row (and therefore
/// their own read cursor) per space.
class SpaceParticipant {
  /// Creates a new [SpaceParticipant].
  SpaceParticipant({
    required this.id,
    required this.spaceId,
    required this.principalId,
    required this.participantType,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
  }) {
    if (principalId.isEmpty) {
      throw ArgumentError('SpaceParticipant principalId must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Parent space identifier.
  final String spaceId;

  /// Agent id or user id, per [participantType].
  final String principalId;

  /// Which kind of principal this participant is.
  final PrincipalType participantType;

  /// Participant role.
  final String role;

  /// When the participant joined.
  final DateTime joinedAt;

  /// When this participant last read the space (their read cursor). Null
  /// until the space is first opened — legacy/never-opened rows are treated
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
      other is SpaceParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          spaceId == other.spaceId &&
          principalId == other.principalId &&
          participantType == other.participantType &&
          role == other.role &&
          joinedAt == other.joinedAt &&
          lastReadAt == other.lastReadAt;

  @override
  int get hashCode => Object.hash(
    id,
    spaceId,
    principalId,
    participantType,
    role,
    joinedAt,
    lastReadAt,
  );

  /// Returns a copy with optional overrides.
  SpaceParticipant copyWith({
    String? id,
    String? spaceId,
    String? principalId,
    PrincipalType? participantType,
    String? role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    bool clearLastReadAt = false,
  }) {
    return SpaceParticipant(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      principalId: principalId ?? this.principalId,
      participantType: participantType ?? this.participantType,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastReadAt: clearLastReadAt ? null : (lastReadAt ?? this.lastReadAt),
    );
  }
}
