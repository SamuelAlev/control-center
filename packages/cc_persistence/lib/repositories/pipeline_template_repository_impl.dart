import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_persistence/database/daos/pipeline_template_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart'
    show PipelineTemplatesTableData;
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
  ///
  /// `knownBodyKeys` answers which step bodies this host registered. It is a
  /// callback because the body registry is assembled after the repository
  /// (the engine needs both); until it answers non-empty, unknown bodies are
  /// not checked.
  PipelineTemplateRepositoryImpl(
    this._dbs, {
    this._validator = const PipelineValidator(),
    this._knownBodyKeys,
  });

  final WorkspaceDatabaseManager _dbs;
  final PipelineValidator _validator;
  final Iterable<String> Function()? _knownBodyKeys;

  /// [_validator] with the host's registered bodies, so a save naming a body
  /// this host cannot run is refused instead of failing at run time.
  PipelineValidator get _saveValidator {
    final keys = _knownBodyKeys?.call().toSet() ?? const <String>{};
    if (keys.isEmpty) {
      return _validator;
    }
    return PipelineValidator(
      renderer: _validator.renderer,
      reducers: _validator.reducers,
      knownBodyKeys: {..._validator.knownBodyKeys, ...keys},
      schemaValidator: _validator.schemaValidator,
    );
  }

  PipelineTemplateDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).pipelineTemplateDao;

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) {
    return _dao(workspaceId).watchForWorkspace(workspaceId).map(_decodeAll);
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async {
    return _decodeAll(await _dao(workspaceId).forWorkspace(workspaceId));
  }

  /// Decodes every row this build can read. A row it cannot (a step kind it
  /// does not know) is left out of the list rather than failing it; reading
  /// that template by id raises the decode error.
  List<PipelineDefinition> _decodeAll(List<PipelineTemplatesTableData> rows) {
    final definitions = <PipelineDefinition>[];
    for (final row in rows) {
      try {
        definitions.add(pipelineDefinitionFromRow(row));
      } on ArgumentError {
        continue;
      }
    }
    return definitions;
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
      final errors = _saveValidator.errors(definition);
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
