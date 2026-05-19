import 'package:control_center/core/database/daos/pipeline_template_dao.dart';
import 'package:control_center/features/pipelines/data/mappers/pipeline_template_mappers.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_validator.dart';

/// Drift-backed implementation of [PipelineTemplateRepository].
class PipelineTemplateRepositoryImpl implements PipelineTemplateRepository {
  /// Creates a [PipelineTemplateRepositoryImpl].
  PipelineTemplateRepositoryImpl(
    this._dao, {
    PipelineValidator validator = const PipelineValidator(),
  }) : _validator = validator;

  final PipelineTemplateDao _dao;
  final PipelineValidator _validator;

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) {
    return _dao
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(pipelineDefinitionFromRow).toList());
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    final rows = await _dao.forWorkspace(workspaceId);
    return rows.map(pipelineDefinitionFromRow).toList();
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    final row = await _dao.getById(workspaceId, templateId);
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
    final existing = await _dao.getById(
      definition.workspaceId,
      definition.templateId,
    );
    // Bump the version on every change so in-flight runs that pinned an older
    // version can detect drift; built-in re-seeds keep version 1.
    final nextVersion =
        definition.isBuiltIn ? 1 : ((existing?.version ?? 0) + 1);
    final companion = pipelineDefinitionToCompanion(
      definition,
      updatedAt: now,
      createdAt: existing?.createdAt ?? now,
      version: nextVersion,
    );
    await _dao.upsert(companion);
  }

  @override
  Future<int> deleteById(String workspaceId, String templateId) {
    return _dao.deleteById(workspaceId, templateId);
  }
}
