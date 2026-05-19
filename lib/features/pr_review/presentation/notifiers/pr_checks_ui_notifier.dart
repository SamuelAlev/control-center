import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:flutter/material.dart' show TabController;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Group of check runs that share a parent workflow.
///
/// Resolution preference (most reliable first):
/// 1. [CheckRun.workflowName], populated by the repository from the
///    actions/runs API by joining on `check_suite_id`. This is the
///    actual workflow `name:` from the YAML (e.g. "Tests (Pull Request)").
/// 2. The substring of the check name before the first ` / ` separator
///    (some GitHub apps embed the workflow there, e.g.
///    "build-and-test / lint").
/// 3. The check name itself as a single-job group, for one-off external
///    checks that don't belong to a workflow.
class WorkflowGroup {
  /// Creates a [WorkflowGroup].
  const WorkflowGroup({required this.name, required this.jobs, this.runId});

  /// Workflow display name (e.g. `Build and test`).
  final String name;

  /// The backing workflow run when the group resolved one — the scoping
  /// anchor: two runs of the same workflow name (a `pull_request` trigger
  /// and a merge-queue trigger, or two workflow files sharing a `name:`)
  /// never merge into one card.
  final int? runId;

  /// Individual job runs that belong to this workflow.
  final List<CheckRun> jobs;

  /// Identity key for expansion state and scroll targeting. Includes the
  /// run id so same-named runs stay distinct; name-only for external
  /// (non-Actions) checks.
  String get key => runId == null ? name : '$name@$runId';

  /// Rolled-up status for the workflow:
  /// - [WorkflowStatus.running] if any job is still queued or in progress;
  /// - [WorkflowStatus.failure] otherwise if any job failed;
  /// - [WorkflowStatus.success] if every job succeeded;
  /// - [WorkflowStatus.neutral] when none of the above (cancelled, skipped,
  ///   neutral conclusions only).
  WorkflowStatus get status {
    var hasRunning = false;
    var hasFailure = false;
    var hasSuccess = false;
    for (final j in jobs) {
      if (!j.isComplete) {
        hasRunning = true;
      } else if (j.isFailing) {
        hasFailure = true;
      } else if (j.isSuccess) {
        hasSuccess = true;
      }
    }
    if (hasRunning) {
      return WorkflowStatus.running;
    }
    if (hasFailure) {
      return WorkflowStatus.failure;
    }
    if (hasSuccess) {
      return WorkflowStatus.success;
    }
    return WorkflowStatus.neutral;
  }

  /// Number of jobs in this workflow that have failed.
  int get failingCount => jobs.where((j) => j.isFailing).length;
}

/// Rolled-up status for a [WorkflowGroup].
enum WorkflowStatus {
  /// At least one job is still queued or in progress.
  running,

  /// All jobs completed and at least one job succeeded; none failed.
  success,

  /// At least one job failed.
  failure,

  /// Cancelled / skipped / neutral only.
  neutral,
}

/// Splits a flat list of [CheckRun]s into [WorkflowGroup]s, preserving the
/// original order of first appearance for both groups and jobs.
///
/// Grouping is scoped by workflow RUN: checks carrying a
/// [CheckRun.workflowRunId] group under `(workflow name, run id)`, so a
/// re-triggered or merge-queue twin of a workflow never leaks its jobs into
/// the same card (which used to duplicate nodes and break the per-job log
/// lookup). Checks without a run id (external apps, unresolved joins)
/// group by name as before.
List<WorkflowGroup> groupChecksByWorkflow(List<CheckRun> checks) {
  if (checks.isEmpty) {
    return const [];
  }
  final order = <String>[];
  final byKey = <String, ({String name, int? runId, List<CheckRun> jobs})>{};
  for (final c in checks) {
    final name = workflowNameFor(c);
    final runId = c.workflowRunId;
    final key = runId == null ? name : '$name@$runId';
    final entry = byKey.putIfAbsent(key, () {
      order.add(key);
      return (name: name, runId: runId, jobs: <CheckRun>[]);
    });
    entry.jobs.add(c);
  }
  return [
    for (final key in order)
      WorkflowGroup(
        name: byKey[key]!.name,
        runId: byKey[key]!.runId,
        jobs: List.unmodifiable(byKey[key]!.jobs),
      ),
  ];
}

/// Returns the workflow display name for a [CheckRun].
///
/// Prefers the explicit workflow name when the data layer was able to
/// resolve it (via the actions/runs join). Falls back to the substring
/// before the first ` / ` separator, then to the full check name.
String workflowNameFor(CheckRun c) {
  final explicit = c.workflowName;
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  final idx = c.name.indexOf(' / ');
  if (idx <= 0) {
    return c.name;
  }
  return c.name.substring(0, idx);
}

/// Returns the job display name for a [CheckRun].
///
/// When the workflow name is known from the actions/runs join, the check
/// name itself *is* the job name (the API doesn't prefix it). Only when
/// we fell back to the ` / ` heuristic do we strip the workflow prefix.
String jobNameFor(CheckRun c) {
  final explicit = c.workflowName;
  if (explicit != null && explicit.isNotEmpty) {
    return c.name;
  }
  final idx = c.name.indexOf(' / ');
  if (idx <= 0 || idx + 3 >= c.name.length) {
    return c.name;
  }
  return c.name.substring(idx + 3);
}

/// UI state for the PR detail's Actions tab + cross-component links to it
/// (sidebar workflow taps).
class PrChecksUiState {
  /// Creates a new [PrChecksUiState].
  const PrChecksUiState({
    this.expandedWorkflows = const <String>{},
    this.requestedTabIndex,
    this.scrollToWorkflow,
  });

  /// Keys of the workflow groups currently expanded in the Actions tab.
  final Set<String> expandedWorkflows;

  /// When non-null, the PR detail body should switch its [TabController] to
  /// this index. Consumed (set back to null) by the body once applied.
  final int? requestedTabIndex;

  /// When non-null, the Actions tab body should scroll the workflow group
  /// with this key into view. Consumed (set back to null) by the tab once
  /// applied.
  final String? scrollToWorkflow;

  /// Copies this state with the given overrides.
  PrChecksUiState copyWith({
    Set<String>? expandedWorkflows,
    int? requestedTabIndex,
    String? scrollToWorkflow,
    bool clearRequestedTabIndex = false,
    bool clearScrollToWorkflow = false,
  }) {
    return PrChecksUiState(
      expandedWorkflows: expandedWorkflows ?? this.expandedWorkflows,
      requestedTabIndex: clearRequestedTabIndex
          ? null
          : (requestedTabIndex ?? this.requestedTabIndex),
      scrollToWorkflow: clearScrollToWorkflow
          ? null
          : (scrollToWorkflow ?? this.scrollToWorkflow),
    );
  }
}

/// Notifier driving sidebar/tab interactions for the PR detail Actions tab.
class PrChecksUiNotifier extends Notifier<PrChecksUiState> {
  @override
  PrChecksUiState build() => const PrChecksUiState();

  /// Toggles whether [workflow] is expanded in the Actions tab.
  void toggleExpanded(String workflow) {
    final next = Set<String>.of(state.expandedWorkflows);
    if (!next.add(workflow)) {
      next.remove(workflow);
    }
    state = state.copyWith(expandedWorkflows: next);
  }

  /// Expands every group in [workflowKeys], preserving any manual state.
  /// The Actions tab seeds this once when checks first arrive so every
  /// workflow card starts open; groups arriving later (refetch, new runs)
  /// keep their manual collapsed state.
  void expandAll(Iterable<String> workflowKeys) {
    final next = Set<String>.of(state.expandedWorkflows)..addAll(workflowKeys);
    if (next.length != state.expandedWorkflows.length) {
      state = state.copyWith(expandedWorkflows: next);
    }
  }

  /// Requests switching the PR detail body to [index] without targeting a
  /// specific workflow. Used by the sidebar's checks summary when nothing has
  /// failed (so there's no failing workflow to expand).
  void requestTab(int index) {
    state = state.copyWith(requestedTabIndex: index);
  }

  /// Requests opening the Actions tab and expanding [workflow] inside it.
  /// Called by the sidebar when the user taps a workflow group.
  void openWorkflow(String workflow, {required int actionsTabIndex}) {
    final next = Set<String>.of(state.expandedWorkflows)..add(workflow);
    state = state.copyWith(
      expandedWorkflows: next,
      requestedTabIndex: actionsTabIndex,
      scrollToWorkflow: workflow,
    );
  }

  /// Acknowledges that the requested tab switch has been applied.
  void consumeTabRequest() {
    if (state.requestedTabIndex == null) {
      return;
    }
    state = state.copyWith(clearRequestedTabIndex: true);
  }

  /// Acknowledges that the requested scroll has been applied.
  void consumeScrollRequest() {
    if (state.scrollToWorkflow == null) {
      return;
    }
    state = state.copyWith(clearScrollToWorkflow: true);
  }
}

/// Provider for the PR detail Actions-tab UI state.
final prChecksUiProvider =
    NotifierProvider<PrChecksUiNotifier, PrChecksUiState>(
      PrChecksUiNotifier.new,
    );
