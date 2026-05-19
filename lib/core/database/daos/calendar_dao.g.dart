// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_dao.dart';

// ignore_for_file: type=lint
mixin _$CalendarDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $CalendarAccountsTableTable get calendarAccountsTable =>
      attachedDatabase.calendarAccountsTable;
  $CalendarEventsTableTable get calendarEventsTable =>
      attachedDatabase.calendarEventsTable;
  $MeetingsTableTable get meetingsTable => attachedDatabase.meetingsTable;
  $MeetingCalendarLinksTableTable get meetingCalendarLinksTable =>
      attachedDatabase.meetingCalendarLinksTable;
  CalendarDaoManager get managers => CalendarDaoManager(this);
}

class CalendarDaoManager {
  final _$CalendarDaoMixin _db;
  CalendarDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$CalendarAccountsTableTableTableManager get calendarAccountsTable =>
      $$CalendarAccountsTableTableTableManager(
        _db.attachedDatabase,
        _db.calendarAccountsTable,
      );
  $$CalendarEventsTableTableTableManager get calendarEventsTable =>
      $$CalendarEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.calendarEventsTable,
      );
  $$MeetingsTableTableTableManager get meetingsTable =>
      $$MeetingsTableTableTableManager(_db.attachedDatabase, _db.meetingsTable);
  $$MeetingCalendarLinksTableTableTableManager get meetingCalendarLinksTable =>
      $$MeetingCalendarLinksTableTableTableManager(
        _db.attachedDatabase,
        _db.meetingCalendarLinksTable,
      );
}
