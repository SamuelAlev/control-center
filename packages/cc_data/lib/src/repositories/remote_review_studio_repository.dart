import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_dependency_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates the Review Studio surface (PRD 18) over the RPC client.
///
/// Backs the web build and the desktop in remote mode. The workspace is bound
/// server-side, so no `workspace_id` travels on the wire — the host injects
/// the authoritative one and enforces ownership. Mirrors the
/// `review_studio.*` ops + watch queries. The host sends each value object's
/// own JSON (`toJson`), so parsing is a straight `fromJson` — no separate DTO
/// layer.
class RemoteReviewStudioRepository {
  /// Creates a [RemoteReviewStudioRepository] over [_client].
  RemoteReviewStudioRepository(this._client);

  final RemoteRpcClient _client;

  Map<String, dynamic> _prArgs(String owner, String repo, int prNumber) => {
    'owner': owner,
    'repo': repo,
    'pr_number': prNumber,
  };

  // ── Cohorts (§1) ──

  /// Live semantic cohorts for a PR, in reading order.
  Stream<List<ReviewCohort>> watchCohorts(
    String owner,
    String repo,
    int prNumber,
  ) => _client
      .subscribe('review_studio.watchCohorts', _prArgs(owner, repo, prNumber))
      .map(_cohorts);

  /// The current semantic cohorts for a PR.
  Future<List<ReviewCohort>> cohorts(
    String owner,
    String repo,
    int prNumber,
  ) async {
    final data = await _client.call(
      'review_studio.cohorts',
      _prArgs(owner, repo, prNumber),
    );
    return _cohorts(data);
  }

  /// Triggers a server-side recompute of cohorts + deterministic axes for a PR
  /// (PRD 18: cohorts compute on PR open / head-SHA change). Returns the raw
  /// `{cohorts, axes}` payload.
  Future<Map<String, dynamic>> compute(
    String owner,
    String repo,
    int prNumber,
  ) => _client.call('review_studio.compute', _prArgs(owner, repo, prNumber));

  // ── API contract diffs (§5) ──

  /// Live API-contract diffs for a PR.
  Stream<List<ApiContractDiff>> watchContractDiffs(
    String owner,
    String repo,
    int prNumber,
  ) => _client
      .subscribe(
        'review_studio.watchContractDiffs',
        _prArgs(owner, repo, prNumber),
      )
      .map(_contractDiffs);

  /// Records a per-change approve/reject decision (feeds the merge gate, §5).
  Future<void> setContractDecision({
    required String diffId,
    required String changeId,
    required ApiChangeDecision decision,
  }) => _client.call('review_studio.setContractDecision', {
    'diff_id': diffId,
    'change_id': changeId,
    'decision': decision.wireName,
  });

  // ── Visual diffs (§4) ──

  /// Live UI visual-diff snapshots for a PR.
  Stream<List<VisualDiffSnapshot>> watchVisualDiffs(
    String owner,
    String repo,
    int prNumber,
  ) => _client
      .subscribe(
        'review_studio.watchVisualDiffs',
        _prArgs(owner, repo, prNumber),
      )
      .map(_visualDiffs);

  /// Sets a visual snapshot's approval status ("approve intended change", §4).
  Future<void> approveVisual({
    required String snapshotId,
    required VisualDiffStatus status,
  }) => _client.call('review_studio.approveVisual', {
    'snapshot_id': snapshotId,
    'status': status.wireName,
  });

  // ── Axis results (§7) ──

  /// Live per-axis results for a PR.
  Stream<List<ReviewAxisResult>> watchAxisResults(
    String owner,
    String repo,
    int prNumber,
  ) => _client
      .subscribe(
        'review_studio.watchAxisResults',
        _prArgs(owner, repo, prNumber),
      )
      .map(_axes);

  // ── Blast radius (§6) ──

  /// The beyond-the-diff blast radius for a changed [filePath] (raw graph
  /// payload: `{indexed, root, nodes, edges}`).
  Future<Map<String, dynamic>> blastRadius({
    required String owner,
    required String repo,
    required String filePath,
    int depth = 2,
  }) => _client.call('review_studio.blastRadius', {
    'owner': owner,
    'repo': repo,
    'file_path': filePath,
    'depth': depth,
  });

  // ── Review hub (merged Findings + Studio) ──

  /// The merged impact subgraph for a whole cohort (deep-dive view; raw graph
  /// payload: `{indexed, cohort_key, roots, nodes, edges}`).
  Future<Map<String, dynamic>> cohortImpact({
    required String owner,
    required String repo,
    required int prNumber,
    required String cohortKey,
    int depth = 2,
  }) => _client.call('review_studio.cohortImpact', {
    'owner': owner,
    'repo': repo,
    'pr_number': prNumber,
    'cohort_key': cohortKey,
    'depth': depth,
  });

  /// Starts the AI review (the "Ask AI" action): the server runs the
  /// `pr_review` pipeline. Returns `{status, space_id, pr_external_id}` plus a
  /// `pipeline_run_id` when a run was started; progress streams through the
  /// review space and the association status.
  /// [level] overrides the workspace's default review level for this run only;
  /// omit it to use the workspace default.
  Future<Map<String, dynamic>> startReview({
    required String owner,
    required String repo,
    required int prNumber,
    ReviewLevel? level,
  }) => _client.call('review_hub.start', {
    ..._prArgs(owner, repo, prNumber),
    if (level != null) 'level': level.wireName,
  });

  /// Aggregated review-effectiveness counters for the bound workspace:
  /// `{findings_total, resolved, dismissed, still_open, addressed}`.
  Future<Map<String, dynamic>> reviewStats() =>
      _client.call('review_hub.stats', const {});

  /// Structured failure signals from the PR's failing CI jobs, correlated to
  /// its changed files. Raw payload: `{available, failing_count, jobs}`.
  Future<Map<String, dynamic>> ciSignals({
    required String owner,
    required String repo,
    required int prNumber,
  }) => _client.call('review_studio.ciSignals', _prArgs(owner, repo, prNumber));

  /// The PR's dependency lockfile diffs.
  Future<List<PrDependencyDiff>> dependencyDiffs({
    required String owner,
    required String repo,
    required int prNumber,
  }) async {
    final data = await _client.call(
      'review_studio.dependencyDiffs',
      _prArgs(owner, repo, prNumber),
    );
    return _dependencyDiffs(data);
  }

  /// Live dependency lockfile diffs for a PR.
  Stream<List<PrDependencyDiff>> watchDependencyDiffs(
    String owner,
    String repo,
    int prNumber,
  ) => _client
      .subscribe(
        'review_studio.watchDependencyDiffs',
        _prArgs(owner, repo, prNumber),
      )
      .map(_dependencyDiffs);

  // ── Parsers ──

  List<ReviewCohort> _cohorts(Map<String, dynamic> data) =>
      ((data['cohorts'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ReviewCohort.fromJson(m.cast<String, dynamic>()))
          .toList();

  List<ApiContractDiff> _contractDiffs(Map<String, dynamic> data) =>
      ((data['diffs'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ApiContractDiff.fromJson(m.cast<String, dynamic>()))
          .toList();

  List<VisualDiffSnapshot> _visualDiffs(Map<String, dynamic> data) =>
      ((data['snapshots'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => VisualDiffSnapshot.fromJson(m.cast<String, dynamic>()))
          .toList();

  List<ReviewAxisResult> _axes(Map<String, dynamic> data) =>
      ((data['axes'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => ReviewAxisResult.fromJson(m.cast<String, dynamic>()))
          .toList();

  /// A row whose diff blob is unreadable is skipped rather than failing the
  /// whole panel — one malformed lockfile must not hide the others.
  List<PrDependencyDiff> _dependencyDiffs(Map<String, dynamic> data) {
    final out = <PrDependencyDiff>[];
    for (final raw in (data['diffs'] as List? ?? const [])) {
      if (raw is! Map) {
        continue;
      }
      final row = raw.cast<String, dynamic>();
      final filePath = row['file_path'];
      if (filePath is! String) {
        continue;
      }
      final ecosystem =
          LockfileEcosystem.fromName(row['ecosystem'] as String?) ??
          LockfileEcosystem.pub;
      final diffRaw = row['diff'];
      final diff = diffRaw is Map
          ? DependencyDiff.fromJson(diffRaw.cast<String, dynamic>())
          : null;
      out.add(
        PrDependencyDiff(
          id: row['id'] as String? ?? filePath,
          // Workspace + PR are bound server-side; the client never sends or
          // needs them, so the local entity carries the coordinates it has.
          workspaceId: '',
          prExternalId: '',
          filePath: filePath,
          diff: diff ?? DependencyDiff(ecosystem: ecosystem),
          baseSha: row['base_sha'] as String?,
          headSha: row['head_sha'] as String?,
        ),
      );
    }
    return out;
  }
}
