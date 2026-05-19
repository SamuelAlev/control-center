// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_dao.dart';

// ignore_for_file: type=lint
mixin _$TeamDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeamsTableTable get teamsTable => attachedDatabase.teamsTable;
  $TeamMembersTableTable get teamMembersTable =>
      attachedDatabase.teamMembersTable;
  TeamDaoManager get managers => TeamDaoManager(this);
}

class TeamDaoManager {
  final _$TeamDaoMixin _db;
  TeamDaoManager(this._db);
  $$TeamsTableTableTableManager get teamsTable =>
      $$TeamsTableTableTableManager(_db.attachedDatabase, _db.teamsTable);
  $$TeamMembersTableTableTableManager get teamMembersTable =>
      $$TeamMembersTableTableTableManager(
        _db.attachedDatabase,
        _db.teamMembersTable,
      );
}
