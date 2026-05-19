import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
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
}
