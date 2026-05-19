import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// Repository interface for persisting pipeline triggers.
abstract class PipelineTriggerRepository {
  /// Inserts a new trigger.
  Future<void> insert(PipelineTrigger trigger);

  /// Updates an existing trigger.
  Future<void> update(PipelineTrigger trigger);

  /// Deletes a trigger by ID, scoped to [workspaceId]. A trigger owned by
  /// another workspace is not matched.
  Future<void> deleteById(String workspaceId, String id);

  /// Gets all triggers for a workspace.
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId);

  /// Gets all enabled triggers for a given event type, **across every
  /// workspace** — a domain event is published once and the dispatcher has to
  /// offer it to every workspace's triggers, filtering per event.
  Future<List<PipelineTrigger>> enabledForEvent(String eventType);

  /// Watches all triggers for a workspace.
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId);

  /// Gets a trigger by ID within [workspaceId], or null. The id resolves only
  /// inside that workspace.
  Future<PipelineTrigger?> getById(String workspaceId, String id);

  /// All enabled scheduled (time-based) triggers, **across every workspace** —
  /// the cron scheduler is one install-wide ticker.
  Future<List<PipelineTrigger>> scheduled();

  /// Records that a scheduled trigger in [workspaceId] fired at [when].
  Future<void> markFired(String workspaceId, String id, DateTime when);

  /// Persists a scheduled trigger's computed [nextRunAt] (and optional
  /// [lastFiredAt]), scoped to [workspaceId].
  Future<void> setSchedule(
    String workspaceId,
    String id, {
    DateTime? nextRunAt,
    DateTime? lastFiredAt,
  });

  /// Looks up the enabled webhook trigger bound to [token], across all
  /// workspaces (the inbound webhook URL carries only the token; the workspace
  /// is resolved from the matched trigger). Returns `null` when no enabled
  /// trigger matches.
  Future<PipelineTrigger?> byWebhookToken(String token);
}
