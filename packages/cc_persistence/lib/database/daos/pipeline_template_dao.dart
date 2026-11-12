import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'pipeline_template_dao.g.dart';

/// DAO for [PipelineTemplatesTable].
@DriftAccessor(tables: [PipelineTemplatesTable])
class PipelineTemplateDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PipelineTemplateDaoMixin {
  /// Creates a [PipelineTemplateDao].
  PipelineTemplateDao(super.db);

  /// Watches every template in [workspaceId], built-ins first then alpha.
  Stream<List<PipelineTemplatesTableData>> watchForWorkspace(
    String workspaceId,
  ) {
    return (select(pipelineTemplatesTable)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isBuiltIn),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Returns all templates in [workspaceId] as a one-shot fetch.
  Future<List<PipelineTemplatesTableData>> forWorkspace(String workspaceId) {
    return (select(pipelineTemplatesTable)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isBuiltIn),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// Gets a template by its (workspaceId, templateId) tuple.
  Future<PipelineTemplatesTableData?> getById(
    String workspaceId,
    String templateId,
  ) {
    return (select(pipelineTemplatesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.equals(templateId),
        ))
        .getSingleOrNull();
  }

  /// Inserts a template row, or updates the existing row with the same id in
  /// place.
  ///
  /// Never `INSERT OR REPLACE`: a replace deletes the row first, which would
  /// fire the `ON DELETE` actions of every trigger and orchestration pointing
  /// at the template on each built-in re-seed.
  Future<void> upsert(PipelineTemplatesTableCompanion row) =>
      into(pipelineTemplatesTable).insertOnConflictUpdate(row);

  /// Deletes a template. Returns the number of rows removed.
  Future<int> deleteById(String workspaceId, String templateId) {
    return (delete(pipelineTemplatesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.equals(templateId),
        ))
        .go();
  }
}
