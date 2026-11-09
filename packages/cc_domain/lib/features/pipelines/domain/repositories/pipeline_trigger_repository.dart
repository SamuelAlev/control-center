import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// The workspace-scoped part of trigger persistence: what the pipeline editor
/// reads and writes, and everything a client may reach.
///
/// The cross-workspace reads the dispatcher and the cron scheduler need, and
/// the scheduler's own bookkeeping, are on [PipelineTriggerRepository] and stay
/// on the server: an enabled trigger row carries its webhook token, which is
/// both the inbound route and the HMAC secret.
abstract class PipelineTriggerConfigRepository {
  /// Inserts a new trigger.
  ///
  /// The server mints a webhook trigger's token itself and ignores one the
  /// caller supplied; scheduler-owned fields (`nextRunAt`, `lastFiredAt`) start
  /// empty.
  Future<void> insert(PipelineTrigger trigger);

  /// Updates an existing trigger.
  ///
  /// A trigger's identity — its event type, template and webhook token — is
  /// fixed at insert; an update changes only its configuration (enabled,
  /// schedule, timezone, filters, catch-up policy).
  Future<void> update(PipelineTrigger trigger);

  /// Deletes a trigger by ID, scoped to [workspaceId]. A trigger owned by
  /// another workspace is not matched.
  Future<void> deleteById(String workspaceId, String id);

  /// Gets all triggers for a workspace.
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId);

  /// Watches all triggers for a workspace.
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId);

  /// Gets a trigger by ID within [workspaceId], or null. The id resolves only
  /// inside that workspace.
  Future<PipelineTrigger?> getById(String workspaceId, String id);
}

/// Repository interface for persisting pipeline triggers — the server's full
/// surface, including the cross-workspace reads. See
/// [PipelineTriggerConfigRepository] for the client-reachable part.
abstract class PipelineTriggerRepository
    implements PipelineTriggerConfigRepository {
  /// Gets all enabled triggers for a given event type, **across every
  /// workspace** — a domain event is published once and the dispatcher offers
  /// it to the triggers of the event's own workspace.
  Future<List<PipelineTrigger>> enabledForEvent(String eventType);

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
