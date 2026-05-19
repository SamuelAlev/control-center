import 'package:cc_persistence/database/tables/isolated_repos.dart'
    show IsolatedReposTable;
import 'package:cc_persistence/database/tables/repos.dart' show ReposTable;
import 'package:drift/drift.dart';

/// Drift table recording, per checkout partition, the repo-state fingerprint
/// observed at the last successful index run — the code indexer's boot-time
/// short-circuit.
///
/// One row per `(workspaceId, repoId, checkoutId)` partition. When a run
/// starts, the indexer probes the checkout (`git rev-parse HEAD` +
/// `git status --porcelain -z -uall` + a stat fold of the dirty paths) and
/// compares against this row; a full match means nothing observable changed
/// since the last successful run, so the whole run — file-state read, walk,
/// hashing, prune, reference resolution — is skipped. This is what makes an
/// unchanged repo near-free at boot.
@TableIndex(
  name: 'idx_code_index_checkpoints_workspaceId',
  columns: {#workspaceId},
)
@TableIndex(name: 'idx_code_index_checkpoints_repoId', columns: {#repoId})
@TableIndex(
  name: 'idx_code_index_checkpoints_checkoutId',
  columns: {#checkoutId},
)
class CodeIndexCheckpointsTable extends Table {
  /// Deterministic id: hash(workspaceId | repoId) for the linked checkout;
  /// hash(workspaceId | repoId | checkoutId) for a worktree partition.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Owning repository.
  TextColumn get repoId =>
      text().references(ReposTable, #id, onDelete: KeyAction.cascade)();

  /// The checkout partition: NULL = the linked checkout, otherwise an
  /// `isolated_repos` row id. Cascades away with the worktree row.
  TextColumn get checkoutId => text().nullable().references(
    IsolatedReposTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

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

  /// When the checkpoint was written.
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_index_checkpoints';

  @override
  Set<Column> get primaryKey => {id};
}
