// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodic_edge_dao.dart';

// ignore_for_file: type=lint
mixin _$EpisodicEdgeDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $EpisodicEdgesTableTable get episodicEdgesTable =>
      attachedDatabase.episodicEdgesTable;
  EpisodicEdgeDaoManager get managers => EpisodicEdgeDaoManager(this);
}

class EpisodicEdgeDaoManager {
  final _$EpisodicEdgeDaoMixin _db;
  EpisodicEdgeDaoManager(this._db);
  $$EpisodicEdgesTableTableTableManager get episodicEdgesTable =>
      $$EpisodicEdgesTableTableTableManager(
        _db.attachedDatabase,
        _db.episodicEdgesTable,
      );
}
