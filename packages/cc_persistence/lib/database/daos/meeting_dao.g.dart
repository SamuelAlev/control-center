// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_dao.dart';

// ignore_for_file: type=lint
mixin _$MeetingDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MeetingsTableTable get meetingsTable => attachedDatabase.meetingsTable;
  $MeetingTranscriptSegmentsTableTable get meetingTranscriptSegmentsTable =>
      attachedDatabase.meetingTranscriptSegmentsTable;
  $MeetingActionItemsTableTable get meetingActionItemsTable =>
      attachedDatabase.meetingActionItemsTable;
  $MeetingDecisionsTableTable get meetingDecisionsTable =>
      attachedDatabase.meetingDecisionsTable;
  $MeetingSpeakersTableTable get meetingSpeakersTable =>
      attachedDatabase.meetingSpeakersTable;
  MeetingDaoManager get managers => MeetingDaoManager(this);
}

class MeetingDaoManager {
  final _$MeetingDaoMixin _db;
  MeetingDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MeetingsTableTableTableManager get meetingsTable =>
      $$MeetingsTableTableTableManager(_db.attachedDatabase, _db.meetingsTable);
  $$MeetingTranscriptSegmentsTableTableTableManager
  get meetingTranscriptSegmentsTable =>
      $$MeetingTranscriptSegmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.meetingTranscriptSegmentsTable,
      );
  $$MeetingActionItemsTableTableTableManager get meetingActionItemsTable =>
      $$MeetingActionItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.meetingActionItemsTable,
      );
  $$MeetingDecisionsTableTableTableManager get meetingDecisionsTable =>
      $$MeetingDecisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.meetingDecisionsTable,
      );
  $$MeetingSpeakersTableTableTableManager get meetingSpeakersTable =>
      $$MeetingSpeakersTableTableTableManager(
        _db.attachedDatabase,
        _db.meetingSpeakersTable,
      );
}
