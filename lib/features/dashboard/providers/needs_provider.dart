import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/dashboard/providers/dashboard_priority_reviews_provider.dart';
import 'package:control_center/features/dashboard/providers/fleet_state_provider.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual weight of a "needs you" item, also its display order (accent first).
enum NeedSeverity {
  /// The promoted, brand-coloured ask (reviews waiting).
  accent,

  /// A warning ask (a blocked agent).
  warn,

  /// A failure ask (a failed pipeline).
  danger,

  /// A quiet ask (a stale PR).
  neutral,
}

/// An item demanding the operator's attention, surfaced in both the greeting
/// pill (as a count) and the "Needs you now" panel (rendered with l10n). The
/// provider returns structured data only — text is localized at the widget.
sealed class DashboardNeed {
  const DashboardNeed();

  /// Severity / display order.
  NeedSeverity get severity;
}

/// Pull requests awaiting the operator's review.
class ReviewsNeed extends DashboardNeed {
  /// Creates a [ReviewsNeed].
  const ReviewsNeed({required this.count, required this.overTwoDays});

  /// Number of reviews awaiting.
  final int count;

  /// How many of them are older than two days.
  final int overTwoDays;

  @override
  NeedSeverity get severity => NeedSeverity.accent;
}

/// An agent blocked awaiting confirmation.
class BlockedAgentNeed extends DashboardNeed {
  /// Creates a [BlockedAgentNeed].
  const BlockedAgentNeed({required this.agentName});

  /// Display name of the blocked agent.
  final String agentName;

  @override
  NeedSeverity get severity => NeedSeverity.warn;
}

/// A pipeline run that failed.
class FailedPipelineNeed extends DashboardNeed {
  /// Creates a [FailedPipelineNeed].
  const FailedPipelineNeed({
    required this.pipelineName,
    required this.failedAt,
    required this.runId,
  });

  /// Friendly pipeline (template) name.
  final String pipelineName;

  /// When it failed.
  final DateTime failedAt;

  /// The failed run's id.
  final String runId;

  @override
  NeedSeverity get severity => NeedSeverity.danger;
}

/// A pull request that has gone stale.
class StalePrNeed extends DashboardNeed {
  /// Creates a [StalePrNeed].
  const StalePrNeed({required this.prNumber, required this.htmlUrl});

  /// Display number (e.g. `#16523`).
  final String prNumber;

  /// URL of the PR on GitHub.
  final String htmlUrl;

  @override
  NeedSeverity get severity => NeedSeverity.neutral;
}

const _staleThreshold = Duration(days: 14);
const _attentionThreshold = Duration(days: 2);

/// The active workspace's "needs you" items, ordered by [NeedSeverity]. Derived
/// from awaiting reviews, blocked agents, failed pipelines and stale PRs.
final dashboardNeedsProvider = Provider<List<DashboardNeed>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final needs = <DashboardNeed>[];

  // Reviews awaiting + the oldest stale PR among them.
  final reviews =
      ref.watch(dashboardPriorityReviewsProvider).asData?.value ?? const [];
  if (reviews.isNotEmpty) {
    final overTwo =
        reviews.where((r) => r.age > _attentionThreshold).length;
    needs.add(ReviewsNeed(count: reviews.length, overTwoDays: overTwo));

    final stale = reviews.where((r) => r.age > _staleThreshold).toList()
      ..sort((a, b) => b.age.compareTo(a.age));
    if (stale.isNotEmpty) {
      final s = stale.first;
      needs.add(StalePrNeed(prNumber: '#${s.pr.number}', htmlUrl: s.pr.htmlUrl));
    }
  }

  // Blocked agents.
  for (final f in ref.watch(dashboardFleetProvider)) {
    if (f.state == AgentLiveState.blocked) {
      needs.add(BlockedAgentNeed(agentName: f.agent.name));
    }
  }

  // Failed pipeline runs (most recent first, capped).
  if (workspaceId != null) {
    final runs =
        ref.watch(workspacePipelineRunsProvider(workspaceId)).asData?.value ??
        const [];
    final templates =
        ref.watch(pipelineTemplatesProvider(workspaceId)).asData?.value ??
        const [];
    final failed = runs
        .where((r) => r.status == PipelineRunStatus.failed)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    for (final r in failed.take(2)) {
      final name = templates
              .firstWhereOrNull((t) => t.templateId == r.templateId)
              ?.name ??
          r.templateId;
      needs.add(
        FailedPipelineNeed(
          pipelineName: name,
          failedAt: r.finishedAt ?? r.startedAt,
          runId: r.id,
        ),
      );
    }
  }

  needs.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return needs;
});
