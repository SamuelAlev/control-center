import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/pipeline_templates_table.dart';
import 'package:drift/drift.dart';

part 'pipeline_template_dao.g.dart';

/// DAO for [PipelineTemplatesTable].
@DriftAccessor(tables: [PipelineTemplatesTable])
class PipelineTemplateDao extends DatabaseAccessor<AppDatabase>
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
  Future<List<PipelineTemplatesTableData>> forWorkspace(
    String workspaceId,
  ) {
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
    return (select(pipelineTemplatesTable)
          ..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(templateId),
          ))
        .getSingleOrNull();
  }

  /// Inserts or replaces a template row.
  Future<void> upsert(PipelineTemplatesTableCompanion row) {
    return into(pipelineTemplatesTable)
        .insert(row, mode: InsertMode.insertOrReplace);
  }

  /// Deletes a template. Returns the number of rows removed.
  Future<int> deleteById(String workspaceId, String templateId) {
    return (delete(pipelineTemplatesTable)
          ..where(
            (t) => t.workspaceId.equals(workspaceId) & t.id.equals(templateId),
          ))
        .go();
  }
}
