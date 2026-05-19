import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_persistence/database/daos/pipeline_template_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/pipeline_template_mappers.dart';

/// Drift-backed implementation of [PipelineTemplateRepository].
///
/// Templates are workspace-scoped, including the built-in seeds: each workspace
/// carries its own copy in its own database file, which the `workspaceId` on
/// each method (or on the [PipelineDefinition] being written) selects.
class PipelineTemplateRepositoryImpl implements PipelineTemplateRepository {
  /// Creates a [PipelineTemplateRepositoryImpl] over the per-workspace
  /// databases.
  PipelineTemplateRepositoryImpl(
    this._dbs, {
    PipelineValidator validator = const PipelineValidator(),
  }) : _validator = validator;

  final WorkspaceDatabaseManager _dbs;
  final PipelineValidator _validator;

  PipelineTemplateDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).pipelineTemplateDao;

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId)
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(pipelineDefinitionFromRow).toList());
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    final rows = await _dao(workspaceId).forWorkspace(workspaceId);
    return rows.map(pipelineDefinitionFromRow).toList();
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    final row = await _dao(workspaceId).getById(workspaceId, templateId);
    return row == null ? null : pipelineDefinitionFromRow(row);
  }

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    // Built-in seeds are trusted; user-authored / edited templates must pass
    // structural + data-flow validation so the editor can't persist a broken
    // graph that only fails at runtime.
    if (!definition.isBuiltIn) {
      final errors = _validator.errors(definition);
      if (errors.isNotEmpty) {
        throw PipelineValidationException(errors);
      }
    }

    final now = DateTime.now();
    final dao = _dao(definition.workspaceId);
    final existing = await dao.getById(
      definition.workspaceId,
      definition.templateId,
    );
    // Bump the version on every change so in-flight runs that pinned an older
    // version can detect drift; built-in re-seeds keep version 1.
    final nextVersion = definition.isBuiltIn
        ? 1
        : ((existing?.version ?? 0) + 1);
    final companion = pipelineDefinitionToCompanion(
      definition,
      updatedAt: now,
      createdAt: existing?.createdAt ?? now,
      version: nextVersion,
    );
    await dao.upsert(companion);
  }

  @override
  Future<int> deleteById(String workspaceId, String templateId) {
    return _dao(workspaceId).deleteById(workspaceId, templateId);
  }
}
