import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';

/// Repository interface for persisting pipeline templates.
///
/// Templates carry the graph shape (nodes + edges + per-node config). All
/// methods are workspace-scoped because per-node config references
/// workspace-owned agent IDs.
abstract class PipelineTemplateRepository {
  /// Watches every template for [workspaceId]; built-ins first, then alpha.
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId);

  /// One-shot fetch of every template in [workspaceId].
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId);

  /// Returns a template by id, or null if absent.
  Future<PipelineDefinition?> getById(String workspaceId, String templateId);

  /// Inserts or replaces a template. Caller is responsible for setting
  /// `isBuiltIn` on built-in seeds.
  Future<void> upsert(PipelineDefinition definition);

  /// Deletes a template by id. Returns the number of rows removed.
  Future<int> deleteById(String workspaceId, String templateId);
}
