import 'package:drift/drift.dart';

@TableIndex(name: 'idx_space_participants_spaceId', columns: {#spaceId})
/// Drift table definition for space participants.
///
/// A participant is a principal: an agent or a human user. [principalId]
/// holds the agent id when [participantType] is `agent`, or the user id when
/// it is `user` — humans are first-class rows, never a sentinel.
class SpaceParticipantsTable extends Table {
  /// Participant id.
  TextColumn get id => text()();

  /// Space id.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  // No FK: principalId points at agents OR users depending on
  // participantType. Cleanup of stale ids is handled in application code when
  // an agent or member is removed.

  /// Agent id or user id, per [participantType].
  TextColumn get principalId => text()();

  /// Which kind of principal this row is: `agent` or `user`.
  TextColumn get participantType =>
      text().withDefault(const Constant('agent'))();

  /// Role.
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Joined at.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  /// When this participant last read the space (their read cursor). Null
  /// until the space is first opened under this participant, so legacy rows
  /// are treated as "nothing unseen yet" rather than "everything unseen".
  ///
  /// Drives the sidebar's unread indicator: an agent message newer than this
  /// timestamp (while no run is in flight) surfaces a notification dot.
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  @override
  String get tableName => 'space_participants';

  @override
  Set<Column> get primaryKey => {id};
}
