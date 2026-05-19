import 'package:drift/drift.dart';

/// One monotonic sync counter per workspace (PRD 16 §6).
///
/// Allocated INSIDE the same SQLite transaction that commits a mutation —
/// the adopted tables carry `AFTER INSERT/UPDATE/DELETE` triggers (see
/// `AppDatabase.createSyncTriggers`) that bump this row and append to
/// [SyncChangesTable], so a delta's id and its data are atomic by
/// construction. "Last writer" is decided by server receipt order (this
/// counter), never client wall clocks.
class SyncSequencesTable extends Table {
  /// Workspace id.
  TextColumn get workspaceId => text()();

  /// The next sequence number to allocate.
  IntColumn get nextSeq => integer().withDefault(const Constant(1))();

  @override
  String get tableName => 'sync_sequences';

  @override
  Set<Column> get primaryKey => {workspaceId};
}

/// The per-workspace change feed behind delta subscriptions (PRD 16 §6).
///
/// Append-only, written exclusively by the SQLite triggers on the adopted
/// stores (`messaging`, `tickets`, `notes`). Rows carry NO payload — the
/// delta emitter loads the current row by primary key at emission time and
/// maps it with the same wire mappers the snapshot path uses, so there is
/// exactly one serialization of every entity. Pruned by retention (the
/// `sync.pull` op answers `snapshot_required` for ranges that fell off).
@TableIndex(name: 'idx_sync_changes_ws_seq', columns: {#workspaceId, #seq})
class SyncChangesTable extends Table {
  /// Workspace id.
  TextColumn get workspaceId => text()();

  /// The per-workspace monotonic sequence (from [SyncSequencesTable]).
  IntColumn get seq => integer()();

  /// The client-facing store this change belongs to (`messaging` | `tickets`
  /// | `notes`).
  TextColumn get store => text()();

  /// The concrete table (`channels`, `channel_messages`, …).
  TextColumn get tbl => text()();

  /// The changed row's primary key.
  TextColumn get pk => text()();

  /// `upsert` | `delete`.
  TextColumn get op => text()();

  /// Context id for child tables (the owning channel id for
  /// `channel_messages` / `channel_participants`), so clients can scope
  /// removals and refreshes without a lookup. Null for root tables.
  TextColumn get ctx => text().nullable()();

  /// Server receipt time (epoch ms) — diagnostics/retention only, never
  /// ordering (the seq is the order).
  IntColumn get createdAtMs => integer()();

  @override
  String get tableName => 'sync_changes';

  @override
  Set<Column> get primaryKey => {workspaceId, seq};
}
