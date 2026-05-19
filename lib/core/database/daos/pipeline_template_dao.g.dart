// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_template_dao.dart';

// ignore_for_file: type=lint
mixin _$PipelineTemplateDaoMixin on DatabaseAccessor<AppDatabase> {
  $PipelineTemplatesTableTable get pipelineTemplatesTable =>
      attachedDatabase.pipelineTemplatesTable;
  PipelineTemplateDaoManager get managers => PipelineTemplateDaoManager(this);
}

class PipelineTemplateDaoManager {
  final _$PipelineTemplateDaoMixin _db;
  PipelineTemplateDaoManager(this._db);
  $$PipelineTemplatesTableTableTableManager get pipelineTemplatesTable =>
      $$PipelineTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTemplatesTable,
      );
}
