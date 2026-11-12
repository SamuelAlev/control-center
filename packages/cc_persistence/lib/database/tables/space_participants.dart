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

  /// `created_at` of the newest message the participant had seen when they
  /// last read the space (their read cursor). Null until the space is first
  /// opened under this participant, which is treated as "nothing unseen yet"
  /// rather than "everything unseen".
  ///
  /// Drives the sidebar's unread indicator: an agent message after the
  /// cursor (while no run is in flight) surfaces a notification dot.
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  /// `rowid` of that message (0 when the space had none), so the cursor is
  /// the pair `(lastReadAt, lastReadSeq)`. `created_at` has whole-second
  /// resolution: a message landing later in the same second as the read
  /// compares after it by this column, not before.
  IntColumn get lastReadSeq => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'space_participants';

  @override
  Set<Column> get primaryKey => {id};
}
