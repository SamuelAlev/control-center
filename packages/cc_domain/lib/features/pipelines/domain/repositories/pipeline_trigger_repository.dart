import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// Repository interface for persisting pipeline triggers.
abstract class PipelineTriggerRepository {
  /// Inserts a new trigger.
  Future<void> insert(PipelineTrigger trigger);

  /// Updates an existing trigger.
  Future<void> update(PipelineTrigger trigger);

  /// Deletes a trigger by ID.
  Future<void> deleteById(String id);

  /// Gets all triggers for a workspace.
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId);

  /// Gets all enabled triggers for a given event type.
  Future<List<PipelineTrigger>> enabledForEvent(String eventType);

  /// Watches all triggers for a workspace.
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId);

  /// Gets a trigger by ID.
  Future<PipelineTrigger?> getById(String id);

  /// All enabled scheduled (time-based) triggers.
  Future<List<PipelineTrigger>> scheduled();

  /// Records that a scheduled trigger fired at [when].
  Future<void> markFired(String id, DateTime when);
}
