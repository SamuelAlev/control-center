import 'package:drift/drift.dart';

/// Drift table recording, per checkout partition, the repo-state fingerprint
/// observed at the last successful index run — the code indexer's boot-time
/// short-circuit.
///
/// One row per `(repoId, checkoutId)` partition. When a run starts, the
/// indexer probes the checkout (`git rev-parse HEAD` +
/// `git status --porcelain -z -uall` + a stat fold of the dirty paths) and
/// compares against this row; a full match means nothing observable changed
/// since the last successful run, so the whole run — file-state read, walk,
/// hashing, prune, reference resolution — is skipped. This is what makes an
/// unchanged repo near-free at boot.
///
/// A partition with no row is indexed in full on its next run, which is what
/// repopulates a `code_index.db` that was created empty.
@TableIndex(
  name: 'idx_code_index_checkpoints_partition',
  columns: {#repoId, #checkoutId},
)
class CodeIndexCheckpointsTable extends Table {
  /// Deterministic id of the partition (see `code_graph_ids`).
  TextColumn get id => text()();

  /// The repository (`repos.id` in `workspace.db`).
  TextColumn get repoId => text()();

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id.
  TextColumn get checkoutId => text().nullable()();

  /// `git rev-parse HEAD` at the last successful run ('' = unborn branch).
  TextColumn get headSha => text()();

  /// The `RepoStateFingerprint` digest at the last successful run.
  TextColumn get worktreeDigest => text()();

  /// Fingerprint of the extractor itself (extractor version + `.scm` queries
  /// + grammar libraries), so editing a query, installing a grammar, or
  /// changing extraction semantics invalidates every checkpoint.
  TextColumn get indexerFingerprint => text()();

  /// Bumped every run that actually changed rows (indexed or pruned files).
  /// Worktrees record the base partition's generation they indexed against
  /// ([baseGeneration]); a base re-index therefore invalidates their delta.
  IntColumn get generation => integer().withDefault(const Constant(0))();

  /// For a worktree row: the base (linked-checkout) partition's [generation]
  /// this delta was measured against. 0 for linked checkouts.
  IntColumn get baseGeneration => integer().withDefault(const Constant(0))();

  /// When the run that wrote the checkpoint started: what it proves holds as
  /// of then, so anything written while it ran is newer and re-checked.
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_index_checkpoints';

  @override
  Set<Column> get primaryKey => {id};
}
