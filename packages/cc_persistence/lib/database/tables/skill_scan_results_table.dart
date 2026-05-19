import 'package:drift/drift.dart';

/// Cached skill scan results, keyed by content hash (PRD 23 §2, §3).
///
/// A scan verdict is expensive (Layer 3 rides dispatch), so results are cached
/// by `(workspaceId, contentHash, rulesVersion)`: identical bytes scanned under
/// the same rules are never re-scanned. This table is the scan cache + audit
/// trail; `skills-lock.json` stays the file-based source of truth for what is
/// installed. Workspace-scoped.
@TableIndex(name: 'idx_skill_scan_results_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_skill_scan_results_hash', columns: {#contentHash})
class SkillScanResultsTable extends Table {
  @override
  String get tableName => 'skill_scan_results';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// SHA-256 over the scanned bundle bytes (the TOCTOU-locked hash).
  TextColumn get contentHash => text()();

  /// The static-rules table version this verdict was produced under (§6
  /// staleness check compares this against the current rules version).
  IntColumn get rulesVersion => integer().withDefault(const Constant(1))();

  /// Aggregate verdict: `pass` / `warn` / `quarantine`.
  TextColumn get verdict => text().withDefault(const Constant('quarantine'))();

  /// JSON array of `SkillScanFinding`s (per-pattern, with file + line).
  TextColumn get findingsJson => text().withDefault(const Constant('[]'))();

  /// JSON-encoded `SkillCapabilityManifest` (union across bundle files).
  TextColumn get manifestJson => text().withDefault(const Constant('{}'))();

  /// Whether the Layer 3 LLM review completed (`false` ⇒ `llmReview: skipped`).
  BoolColumn get llmReviewed => boolean().withDefault(const Constant(false))();

  /// The skill slug/coordinate scanned (for the audit surface).
  TextColumn get skillRef => text().nullable()();

  /// Scan time.
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, contentHash, rulesVersion},
  ];
}
