// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodic_edge_dao.dart';

// ignore_for_file: type=lint
mixin _$EpisodicEdgeDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $EpisodicEdgesTableTable get episodicEdgesTable =>
      attachedDatabase.episodicEdgesTable;
  EpisodicEdgeDaoManager get managers => EpisodicEdgeDaoManager(this);
}

class EpisodicEdgeDaoManager {
  final _$EpisodicEdgeDaoMixin _db;
  EpisodicEdgeDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$EpisodicEdgesTableTableTableManager get episodicEdgesTable =>
      $$EpisodicEdgesTableTableTableManager(
        _db.attachedDatabase,
        _db.episodicEdgesTable,
      );
}
