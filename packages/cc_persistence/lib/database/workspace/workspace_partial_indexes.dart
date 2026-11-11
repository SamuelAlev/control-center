// Partial and unique indexes a workspace database builds from `onCreate`.
//
// Partial indexes carry a `WHERE` clause, so they cannot be expressed as a
// `@TableIndex` on a table class and `createAll()` won't build them.

import 'package:drift/drift.dart';

/// Chat-bridge indexes, including a partial-unique DM index (SQLite NULLs are
/// distinct in UNIQUE, so conversation-level links need `WHERE`). Other
/// indexes repeated with `IF NOT EXISTS` for migration `createTable` paths.
Future<void> createChatIndexes(DatabaseConnectionUser db) async {
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS '
    'uq_chat_space_links_ws_provider_space_thread '
    'ON chat_space_links '
    '(workspace_id, provider, external_channel_id, external_thread_id)',
  );
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_chat_space_links_ccSpaceId '
    'ON chat_space_links (cc_space_id)',
  );
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS '
    'uq_chat_user_links_ws_provider_team_user '
    'ON chat_user_links '
    '(workspace_id, provider, external_team_id, external_user_id)',
  );
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_user_links_ws_provider_user '
    'ON chat_user_links (workspace_id, provider, user_id)',
  );
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_space_links_ws_provider_dm '
    'ON chat_space_links (workspace_id, provider, external_channel_id) '
    'WHERE external_thread_id IS NULL',
  );
}

/// Creates the unique index that makes a cron fire idempotent: at most one
/// `cron_executions` row may exist per `(trigger_id, planned_at)` slot, so a
/// re-fire of the same scheduled instant (after a restart, or from
/// overlapping ticks) is a no-op.
Future<void> createCronIndexes(DatabaseConnectionUser db) async {
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS uq_cron_executions_slot '
    'ON cron_executions (trigger_id, planned_at)',
  );
}

/// Creates the partial-unique index that enforces idempotency for
/// event-triggered pipeline runs: at most one non-terminal run may exist per
/// `(template_id, dedup_key)` tuple.
Future<void> createPipelineIndexes(DatabaseConnectionUser db) async {
  await db.customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS uq_pipeline_runs_active_dedup '
    'ON pipeline_runs (template_id, dedup_key) '
    'WHERE dedup_key IS NOT NULL '
    "AND status IN ('pending','queued','running','suspended')",
  );
  // Admission reads exactly this shape on every run completion: count the
  // slot holders of one template, then find its oldest queued row.
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_pipeline_runs_template_status '
    'ON pipeline_runs (workspace_id, template_id, status, started_at)',
  );
}
