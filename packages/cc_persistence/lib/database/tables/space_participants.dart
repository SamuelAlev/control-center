import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Drift table definition for space participants.
///
/// A participant is a principal: an agent or a human user. [principalId]
/// holds the agent id when [participantType] is `agent`, or the user id when
/// it is `user` — humans are first-class rows, never a sentinel.
///
/// A principal joins a space once: `(space_id, principal_id)` is unique, and
/// the writes add a participant or move a read cursor with one
/// `INSERT … ON CONFLICT` on it.
@TableIndex(
  name: 'uq_space_participants_space_principal',
  columns: {#spaceId, #principalId},
  unique: true,
)
class SpaceParticipantsTable extends Table {
  /// Participant id.
  TextColumn get id => text()();

  /// Space id.
  TextColumn get spaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// Agent id or user id, per [participantType]. No foreign key: it names
  /// an agent or a user (in `global.db`) depending on [participantType];
  /// stale ids are cleaned up in application code when an agent or member is
  /// removed.
  TextColumn get principalId => text()();

  /// Which kind of principal this row is: `agent` or `user`
  /// (`PrincipalType.wireName`).
  TextColumn get participantType => text()
      .check(
        // ignore: recursive_getters
        participantType.isIn(SpacesStoredValues.principalType),
      )
      .withDefault(const Constant('agent'))();

  /// Role. Open set: a free label the domain carries as a string; every
  /// writer today leaves the default `member`.
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Joined at.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'space_participants';

  @override
  Set<Column> get primaryKey => {id};
}
