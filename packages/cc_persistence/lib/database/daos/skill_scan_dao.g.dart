// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_scan_dao.dart';

// ignore_for_file: type=lint
mixin _$SkillScanDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SkillScanResultsTableTable get skillScanResultsTable =>
      attachedDatabase.skillScanResultsTable;
  SkillScanDaoManager get managers => SkillScanDaoManager(this);
}

class SkillScanDaoManager {
  final _$SkillScanDaoMixin _db;
  SkillScanDaoManager(this._db);
  $$SkillScanResultsTableTableTableManager get skillScanResultsTable =>
      $$SkillScanResultsTableTableTableManager(
        _db.attachedDatabase,
        _db.skillScanResultsTable,
      );
}
