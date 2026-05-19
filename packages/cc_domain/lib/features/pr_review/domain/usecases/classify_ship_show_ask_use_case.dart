import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/change_path_heuristics.dart';

/// Suggested lane from the Ship / Show / Ask framework (Martin Fowler, 2021).
enum ShipShowAskLane {
  /// Merge without review — trivial/safe change.
  ship,

  /// Merge but share with team for awareness.
  show,

  /// Get review before merging.
  ask,
}

/// Result of [ClassifyShipShowAskUseCase.classify].
class ShipShowAskResult {
  /// Creates a [ShipShowAskResult].
  const ShipShowAskResult({required this.lane, required this.reason});

  /// Suggested lane.
  final ShipShowAskLane lane;

  /// Human-readable rationale for the suggestion.
  final String reason;
}

// Path heuristics are shared with the cohort layer planner, the area risk
// score and the test-impact mapper — see `change_path_heuristics.dart`. They
// live there so a file that is "critical path" here is critical path there too.
const _criticalPathFragments = kCriticalPathFragments;
const _docExtensions = kDocExtensions;
const _testPathFragments = kTestPathFragments;

/// Pure heuristic classifier — no LLM, no network, no side-effects.
///
/// Inputs are always available on the PR detail screen (files are loaded for
/// the diff view; check runs for the checks tab). The classifier is advisory
/// only: it never merges or blocks a PR, it just surfaces a suggested lane
/// with a short explanation.
class ClassifyShipShowAskUseCase {
  /// ClassifyShipShowAskUseCase().
  const ClassifyShipShowAskUseCase();

  /// Returns a suggested [ShipShowAskLane] for the given PR metadata.
  ShipShowAskResult classify({
    required PullRequest pr,
    required List<PrFile> files,
    required List<CheckRun> checks,
  }) {
    if (pr.isDraft) {
      return const ShipShowAskResult(
        lane: ShipShowAskLane.ask,
        reason: 'Draft — not ready for merge',
      );
    }

    final ciOk = _allCiPassing(checks);
    final loc = files.fold(0, (s, f) => s + f.additions + f.deletions);
    final fileCount = files.length;
    final touchesCritical = _touchesCriticalPaths(files);

    if (!ciOk) {
      return const ShipShowAskResult(
        lane: ShipShowAskLane.ask,
        reason: 'CI failing — resolve checks before merging',
      );
    }

    if (touchesCritical) {
      return ShipShowAskResult(
        lane: ShipShowAskLane.ask,
        reason: 'Touches ${_criticalLabel(files)} — review recommended',
      );
    }

    if (loc > 100 || fileCount > 5) {
      return ShipShowAskResult(
        lane: ShipShowAskLane.ask,
        reason: '$loc LOC across $fileCount files — review recommended',
      );
    }

    if (_isDocOnly(files)) {
      return const ShipShowAskResult(
        lane: ShipShowAskLane.ship,
        reason: 'Documentation only — safe to merge',
      );
    }

    if (_isTestOnly(files)) {
      return const ShipShowAskResult(
        lane: ShipShowAskLane.ship,
        reason: 'Test-only change — safe to merge',
      );
    }

    if (loc <= 20 && fileCount <= 2) {
      return const ShipShowAskResult(
        lane: ShipShowAskLane.ship,
        reason: 'Small, low-risk change — safe to merge',
      );
    }

    return ShipShowAskResult(
      lane: ShipShowAskLane.show,
      reason: '$loc LOC — merge and share for awareness',
    );
  }

  bool _allCiPassing(List<CheckRun> checks) {
    final completed = checks.where((c) => c.isComplete).toList();
    if (completed.isEmpty) {
      return true;
    }
    return completed.every((c) => !c.isFailing);
  }

  bool _touchesCriticalPaths(List<PrFile> files) {
    return files.any(
      (f) => _criticalPathFragments.any((frag) => f.filename.contains(frag)),
    );
  }

  String _criticalLabel(List<PrFile> files) {
    for (final frag in _criticalPathFragments) {
      if (files.any((f) => f.filename.contains(frag))) {
        return frag.replaceAll('/', '');
      }
    }
    return 'critical paths';
  }

  bool _isDocOnly(List<PrFile> files) =>
      files.isNotEmpty &&
      files.every((f) => _docExtensions.contains(f.extension));

  bool _isTestOnly(List<PrFile> files) =>
      files.isNotEmpty &&
      files.every(
        (f) => _testPathFragments.any((frag) => f.filename.contains(frag)),
      );
}
