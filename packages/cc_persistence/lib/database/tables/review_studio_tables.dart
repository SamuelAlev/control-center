import 'package:drift/drift.dart';

/// Semantic review cohorts for a PR (PRD 18 §1).
///
/// One row per cohort — a content-derived, push-stable bucket of changed
/// files that belong to the same bounded context / feature. Recomputed
/// server-side on PR open and every head-SHA change and replaced wholesale;
/// the stable [cohortKey] lets summaries and review progress survive a rebase.
/// Workspace-scoped; the `(prExternalId, cohortKey)` unique key enforces stable
/// identity.
@TableIndex(name: 'idx_review_cohorts_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_review_cohorts_pr', columns: {#prExternalId})
class ReviewCohortsTable extends Table {
  /// Unique cohort row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The PR (GitHub PR node id) this cohort belongs to.
  TextColumn get prExternalId => text()();

  /// Content-derived, push-stable cohort key.
  TextColumn get cohortKey => text()();

  /// Human-readable cohort title.
  TextColumn get title => text()();

  /// Cohort-level summary markdown (per-cohort AI summary, §2).
  TextColumn get summaryMarkdown => text().withDefault(const Constant(''))();

  /// Reading order among cohorts (0 = read first).
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// Blast-radius impact weight used to rank cohorts (§6).
  IntColumn get impactScore => integer().withDefault(const Constant(0))();

  /// How the cohort was derived: `graph` (semantic) or `path` (fallback).
  TextColumn get derivation => text().withDefault(const Constant('path'))();

  /// JSON array of the cohort's changed file paths.
  TextColumn get filePathsJson => text().withDefault(const Constant('[]'))();

  /// JSON array of `CohortLayer`s (the ordered reading path).
  TextColumn get layersJson => text().withDefault(const Constant('[]'))();

  /// JSON array of `ReviewDiagram`s (walkthrough diagrams, §3).
  TextColumn get diagramsJson => text().withDefault(const Constant('[]'))();

  /// JSON object of `CohortInsights` — the deterministic enrichments computed
  /// alongside the cohort (which symbols the diff touched, which test files
  /// cover them, and which partition the spans were read from).
  ///
  /// One blob rather than a column per signal: these are computed together,
  /// replaced together with the cohort, and read as a unit, so a new
  /// deterministic signal joins the same row without another migration.
  TextColumn get insightsJson => text().withDefault(const Constant('{}'))();

  /// Head SHA this cohort was computed against.
  TextColumn get headSha => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'review_cohorts';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {prExternalId, cohortKey},
  ];
}

/// API-contract diff snapshots for a PR (PRD 18 §5).
///
/// One row per changed spec file. `changesJson` is CC's own stable
/// `ApiContractChange` schema, so the underlying diff engine (a pinned
/// `oasdiff` binary, or our pure-Dart differ) can be swapped without touching
/// the UI or the gate. Repo-scoped by `(workspaceId, repoId)`.
@TableIndex(
  name: 'idx_api_contract_snapshots_workspace',
  columns: {#workspaceId},
)
@TableIndex(name: 'idx_api_contract_snapshots_pr', columns: {#prExternalId})
class ApiContractSnapshotsTable extends Table {
  /// Unique snapshot row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Owning repo (keyed `(workspaceId, repoId)`; no FK, mirrors code graph).
  TextColumn get repoId => text()();

  /// The PR (GitHub PR node id) this snapshot belongs to.
  TextColumn get prExternalId => text()();

  /// Repository-relative path of the changed spec file.
  TextColumn get specPath => text()();

  /// Raw before-spec JSON (base SHA), when captured.
  TextColumn get beforeJson => text().withDefault(const Constant('{}'))();

  /// Raw after-spec JSON (head SHA), when captured.
  TextColumn get afterJson => text().withDefault(const Constant('{}'))();

  /// JSON array of classified `ApiContractChange`s (with per-change decisions).
  TextColumn get changesJson => text().withDefault(const Constant('[]'))();

  /// Whether the contract was *derived* from handler code (advisory, never
  /// gates a merge).
  BoolColumn get derived => boolean().withDefault(const Constant(false))();

  /// Head SHA this diff was computed against.
  TextColumn get headSha => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'api_contract_snapshots';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {prExternalId, specPath},
  ];
}

/// UI component visual-diff snapshots for a PR (PRD 18 §4).
///
/// One row per Widgetbook use-case / component whose render changed. Image
/// bytes live under the server data dir and are served via `/proxy/media`;
/// this row carries only the media refs (in `variantsJson`) + status. Repo-
/// scoped by `(workspaceId, repoId)`.
@TableIndex(
  name: 'idx_visual_diff_snapshots_workspace',
  columns: {#workspaceId},
)
@TableIndex(name: 'idx_visual_diff_snapshots_pr', columns: {#prExternalId})
class VisualDiffSnapshotsTable extends Table {
  /// Unique snapshot row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Owning repo (keyed `(workspaceId, repoId)`; no FK, mirrors code graph).
  TextColumn get repoId => text()();

  /// The PR (GitHub PR node id) this snapshot belongs to.
  TextColumn get prExternalId => text()();

  /// Stable key of the Widgetbook use-case / component.
  TextColumn get componentKey => text()();

  /// Human-readable component name.
  TextColumn get componentTitle => text().withDefault(const Constant(''))();

  /// Aggregate status: added / changed / removed / approved / unchanged.
  TextColumn get status => text().withDefault(const Constant('changed'))();

  /// JSON array of `VisualDiffVariant`s (viewport × brightness, with refs).
  TextColumn get variantsJson => text().withDefault(const Constant('[]'))();

  /// Head SHA this snapshot was computed against.
  TextColumn get headSha => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'visual_diff_snapshots';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {prExternalId, componentKey},
  ];
}

/// Per-axis review results for a PR (PRD 18 §7).
///
/// One row per (PR, axis). Deterministic axes (contract, visual, perf) are
/// token-free; token axes (correctness, security, test-gap) carry a budget.
/// [gated] axes participate in the merge gate; a gated axis that could not
/// clear holds the verdict (absence of evidence never greens a gate).
@TableIndex(name: 'idx_review_axis_results_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_review_axis_results_pr', columns: {#prExternalId})
class ReviewAxisResultsTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The PR (GitHub PR node id) this result belongs to.
  TextColumn get prExternalId => text()();

  /// Axis wire name (`correctness`/`security`/`test_gap`/`performance`/
  /// `visual`/`api_contract`).
  TextColumn get axis => text()();

  /// Axis verdict (`pass`/`warn`/`fail`/`partial`/`unavailable`).
  TextColumn get verdict => text()();

  /// Number of findings the axis produced.
  IntColumn get findingsCount => integer().withDefault(const Constant(0))();

  /// Whether the axis participates in the merge gate.
  BoolColumn get gated => boolean().withDefault(const Constant(false))();

  /// Confidence in the axis result `[0, 1]`.
  RealColumn get confidence => real().withDefault(const Constant(1))();

  /// Human-readable qualifier (e.g. "partial — budget exhausted").
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'review_axis_results';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {prExternalId, axis},
  ];
}

/// Dependency lockfile diffs for a PR.
///
/// One row per changed lockfile, holding the computed added / removed /
/// upgraded package sets rather than the lockfile bodies — a `pnpm-lock.yaml`
/// is routinely megabytes and the review only ever needs the delta.
///
/// Computed entirely offline from the base and head file contents; no registry
/// or CVE lookup happens here (see `LockfileDiffer`).
@TableIndex(
  name: 'idx_review_dependency_diffs_workspace',
  columns: {#workspaceId},
)
@TableIndex(name: 'idx_review_dependency_diffs_pr', columns: {#prExternalId})
class ReviewDependencyDiffsTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The PR (forge PR node id) this diff belongs to.
  TextColumn get prExternalId => text()();

  /// Repository-relative path of the lockfile.
  TextColumn get filePath => text()();

  /// Ecosystem wire name (`pub`/`npm`/`pnpm`/`yarn`).
  TextColumn get ecosystem => text()();

  /// Base SHA the diff was computed from.
  TextColumn get baseSha => text().nullable()();

  /// Head SHA the diff was computed against.
  TextColumn get headSha => text().nullable()();

  /// JSON object of the `DependencyDiff` (added/removed/upgraded/bestEffort).
  TextColumn get diffJson => text().withDefault(const Constant('{}'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'review_dependency_diffs';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {prExternalId, filePath},
  ];
}

/// One finalized review pass over a PR — the snapshot that makes the NEXT
/// review delta-aware.
///
/// Without this, every manual re-review restates the whole finding list and a
/// reviewer cannot tell what they already dealt with. With it, a run can say
/// "3 resolved, 2 new, 4 still open" against the previous pass.
///
/// Deliberately keyed by `finalizedAt` rather than head SHA alone: two runs
/// against the same SHA (a re-review after fixing findings in place) are two
/// distinct passes and both are worth keeping.
@TableIndex(name: 'idx_review_run_snapshots_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_review_run_snapshots_pr', columns: {#prExternalId})
// The delta lookup is always "the newest pass for THIS PR", so the composite
// is what actually serves it; declared here so a fresh database gets it from
// `onCreate` and not only from the v12 upgrade path.
@TableIndex(
  name: 'idx_review_run_snapshots_pr_time',
  columns: {#workspaceId, #prExternalId, #finalizedAt},
)
class ReviewRunSnapshotsTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The PR (forge PR node id) this pass reviewed.
  TextColumn get prExternalId => text()();

  /// The review space the pass ran in.
  TextColumn get spaceId => text()();

  /// Head SHA the pass reviewed.
  TextColumn get headSha => text().nullable()();

  /// When the pass was finalized.
  DateTimeColumn get finalizedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// JSON object of the finalized `ReviewVerdict`.
  TextColumn get verdictJson => text().withDefault(const Constant('{}'))();

  /// JSON array of finding fingerprints carried by this pass.
  TextColumn get fingerprintsJson => text().withDefault(const Constant('[]'))();

  /// JSON object of the pass's counts (total / resolved / dismissed / open).
  TextColumn get statsJson => text().withDefault(const Constant('{}'))();

  @override
  String get tableName => 'review_run_snapshots';

  @override
  Set<Column> get primaryKey => {id};
}
