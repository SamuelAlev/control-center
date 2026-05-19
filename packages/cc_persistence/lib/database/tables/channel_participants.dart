import 'package:drift/drift.dart';

@TableIndex(name: 'idx_channel_participants_channelId', columns: {#channelId})
/// Drift table definition for channel participants.
class ChannelParticipantsTable extends Table {
  /// Participant id.
  TextColumn get id => text()();

  /// Channel id.
  TextColumn get channelId => text().customConstraint(
    'NOT NULL REFERENCES channels (id) ON DELETE CASCADE',
  )();

  // No FK to agents: the sentinel value 'user' represents the human user and
  // has no agents row. Cleanup of stale agent_ids is handled in application
  // code when an agent is deleted.

  /// Agent id, or 'user' for the human participant.
  TextColumn get agentId => text()();

  /// Role.
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Joined at.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  /// When this participant last read the channel (their read cursor). Null
  /// until the channel is first opened under this participant, so legacy rows
  /// are treated as "nothing unseen yet" rather than "everything unseen".
  ///
  /// Drives the sidebar's unread indicator: an agent message newer than this
  /// timestamp (while no run is in flight) surfaces a notification dot.
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  @override
  String get tableName => 'channel_participants';

  @override
  Set<Column> get primaryKey => {id};
}
