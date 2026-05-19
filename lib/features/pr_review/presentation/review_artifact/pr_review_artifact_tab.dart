import 'dart:async';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_artifact_actions.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_findings_rail.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_stale_banner.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ask_ai_review_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR review tab: the review pipeline's live progress while it works, then
/// the artifact it published, with the actions on it.
///
/// One tab with two states rather than two surfaces, because they are the same
/// thing at two times: you press "Ask AI", you watch it work, you read what it
/// produced. The output is an ORDINARY conversation artifact — the consolidating
/// agent publishes it with `publish_artifact` into the review space — so this
/// renders it through the same [ArtifactDetailView] a chat bubble opens. There
/// is no review-shaped copy of the artifact system.
class PrReviewArtifactTab extends ConsumerWidget {
  /// Creates a [PrReviewArtifactTab].
  const PrReviewArtifactTab({super.key, required this.pr});

  /// The pull request under review.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keyed on repo + number, never on the PR's forge id: that field is empty
    // on everything the REST path returns, so an id-keyed lookup reported "no
    // review yet" for a pull request that had a finished one.
    final key = (repoFullName: pr.repoFullName, prNumber: pr.number);
    final assoc = ref.watch(prReviewAssociationProvider(key));
    final run = ref.watch(prReviewRunProvider(key));
    final artifact = ref.watch(prReviewArtifactProvider(assoc?.spaceId));
    // A start that has been asked for but has not produced a run yet. Pressing
    // "Ask AI" opens this tab immediately and the server does not answer until
    // the PR's worktree is provisioned, so this window is real and can be long.
    final starting = ref.watch(prReviewStarterProvider).contains(key);

    // The artifact is the point, so it wins as soon as one exists — including
    // while a LATER run is under way, where blanking the last review to show a
    // progress list would take away the thing being re-checked.
    if (artifact != null) {
      return _PublishedReview(
        pr: pr,
        workProductId: artifact.id,
        spaceId: assoc?.spaceId,
        // A re-review counts as under way from the press, not from the run
        // row — otherwise the actions bar keeps offering "Ask AI" through the
        // provisioning wait and a second press starts a second review.
        rerunning:
            starting || (run != null && run.status == PipelineRunStatus.running),
      );
    }
    if (run == null) {
      // Showing the never-reviewed CTA through the starting window would read
      // as "nothing happened" and invite that same second start.
      return starting ? const _Starting() : _NotStarted(pr: pr);
    }
    return _RunProgress(pr: pr, run: run);
  }
}

/// A review has been asked for and the run has not appeared yet: the server is
/// still preparing this pull request's worktree.
class _Starting extends StatelessWidget {
  const _Starting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcSpinner(size: 24),
            const SizedBox(height: 16),
            Text(
              l10n.prReviewStarting,
              style: CcTypography.title.copyWith(color: ds.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.prReviewStartingBody,
              textAlign: TextAlign.center,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

/// No review has run for this pull request yet.
class _NotStarted extends StatelessWidget {
  const _NotStarted({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.sparkles, size: 48, color: ds.textTertiary),
            const SizedBox(height: 16),
            Text(
              l10n.aiReview,
              style: CcTypography.title.copyWith(color: ds.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewHubIntroBody,
              textAlign: TextAlign.center,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
            const SizedBox(height: 24),
            AskAiReviewButton(pr: pr),
          ],
        ),
      ),
    );
  }
}

/// The review while it runs: the pipeline's own canvas, live.
///
/// The same surface the pipeline run screen shows, because it IS the same run —
/// clickable nodes carrying each step's status and duration, and the step
/// detail beside them. What was here before was a status badge over a list of
/// raw step ids ("trigger", "setup"), which told a waiting reader neither where
/// the review had got to nor what any of it meant.
class _RunProgress extends ConsumerWidget {
  const _RunProgress({required this.pr, required this.run});

  final PullRequest pr;
  final PipelineRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final templates = ref
        .watch(pipelineTemplatesProvider(run.workspaceId))
        .value;
    final definition = templates
        ?.where((t) => t.templateId == run.templateId)
        .firstOrNull;
    // Ticks the live durations on the nodes.
    ref.watch(pipelineClockProvider);
    // Land on whatever is running, so opening the tab mid-review shows the
    // step being waited on rather than an unselected graph.
    final steps =
        ref.watch(pipelineStepRunsForRunProvider(run.id)).value ??
        const <PipelineStepRun>[];
    final active = steps
        .where((s) => s.status == PipelineStepStatus.running)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              PipelineStatusBadge.forRun(status: run.status),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  run.status == PipelineRunStatus.failed
                      ? (run.errorMessage ?? l10n.prReviewFailed)
                      : l10n.prReviewRunning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(
                    color: run.status == PipelineRunStatus.failed
                        ? ds.fgErrorPrimary
                        : ds.textSecondary,
                  ),
                ),
              ),
              if (run.status != PipelineRunStatus.running)
                AskAiReviewButton(pr: pr),
            ],
          ),
        ),
        const CcDivider(),
        Expanded(
          child: definition == null
              ? const Center(child: CcSpinner())
              : PipelineCanvas(
                  definition: definition,
                  runId: run.id,
                  initialSelectedStepId: active?.stepId,
                ),
        ),
      ],
    );
  }
}

/// The finished review: its artifact, its findings, and what you can do with
/// them.
///
/// The artifact is the report; the findings below it are the anchored, actionable
/// half — each with its code, its thread and its own fix / comment / dismiss
/// actions. They are on ONE surface because acting on a finding while reading
/// the report about it is the whole job.
class _PublishedReview extends ConsumerStatefulWidget {
  const _PublishedReview({
    required this.pr,
    required this.workProductId,
    required this.spaceId,
    required this.rerunning,
  });

  final PullRequest pr;
  final String workProductId;
  final String? spaceId;

  /// A newer review is in flight over this artifact.
  final bool rerunning;

  @override
  ConsumerState<_PublishedReview> createState() => _PublishedReviewState();
}

class _PublishedReviewState extends ConsumerState<_PublishedReview> {
  final _accordion = ReviewAccordionController();
  final _scroll = ScrollController();

  /// Live anchor per finding, filled by the list as it builds rows. The rail
  /// scrolls to one of these.
  final _itemKeys = <String, GlobalKey>{};

  /// The finding the rail last pointed at — the rail's highlight only. The
  /// findings themselves all stay on screen; this is navigation, not a filter.
  String? _focusedId;

  /// Below this the rail stops earning its column and folds into the scroll.
  static const double _railBreakpoint = 900;
  static const double _railWidth = 260;

  @override
  void dispose() {
    _accordion.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Brings a finding into view.
  ///
  /// Two-step because the list is lazy: a finding far down has no element yet,
  /// so there is nothing to measure. Jump to an estimate first (which builds
  /// the rows around it), then land exactly on the next frame. One retry, not
  /// a loop — if the second pass still cannot find it the row was filtered
  /// out, and scrolling further would be guessing.
  void _revealFinding(String id) {
    setState(() => _focusedId = id);
    final ctx = _itemKeys[id]?.currentContext;
    if (ctx != null) {
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        ),
      );
      return;
    }
    final findings = ref.read(reviewArtifactFindingsProvider(widget.spaceId));
    final index = findings.indexWhere((f) => f.message.id == id);
    if (index < 0 || !_scroll.hasClients) {
      return;
    }
    final max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo((max * (index / findings.length)).clamp(0, max));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final settled = _itemKeys[id]?.currentContext;
      if (settled != null) {
        unawaited(
          Scrollable.ensureVisible(
            settled,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          ),
        );
      }
    });
  }

  /// Starts a fresh review at the workspace's default level.
  ///
  /// Deliberately not the level picker: someone acting on a staleness warning
  /// wants the review they already had, against the code as it stands now.
  Future<void> _rerunReview() async {
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.of(context);
    try {
      await ref.read(prReviewStarterProvider.notifier).start(pr: widget.pr);
      if (mounted) {
        toaster.show(l10n.reviewHubStarted, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (mounted) {
        toaster.show(
          l10n.failedToStartAiReview('$e'),
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaceId = widget.spaceId;
    final findings = ref.watch(reviewArtifactFindingsProvider(spaceId));
    final repo = ref.read(prReviewRepositoryProvider);
    // Anchored findings render their own code from the PR head. With no head
    // sha there is nothing to read them from, so the fetcher is simply absent.
    final fetcher = widget.pr.headSha.isEmpty
        ? null
        : (String path) => repo
              .watchFileContent(path, widget.pr.headSha)
              .first
              .timeout(const Duration(seconds: 15));

    final report = SliverToBoxAdapter(
      // The tab owns the ONE scroll the report and its findings share, so the
      // detail view must shrink-wrap into the sliver rather than expand its
      // own viewport into the sliver's unbounded height.
      child: ArtifactDetailView(
        workProductId: widget.workProductId,
        ownsScroll: false,
      ),
    );

    if (spaceId == null) {
      return CustomScrollView(slivers: [report]);
    }

    // ONE scroll for the whole review: the report, then what the reviewers
    // disagreed on, then every finding behind it. They are one reading order,
    // and stacking them in separate viewports is what made the tab read as
    // three unrelated widgets.
    final body = ReviewAccordionList(
      spaceId: spaceId,
      pr: widget.pr,
      fetchFileContent: fetcher,
      controller: _accordion,
      scrollController: _scroll,
      itemKeys: _itemKeys,
      leadingSlivers: [report],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Above the actions, because it changes what every one of them means:
        // publishing findings about code the author has already replaced is
        // worse than not publishing at all.
        ReviewStaleBanner(
          pr: widget.pr,
          spaceId: spaceId,
          rerunning: widget.rerunning,
          onRerun: _rerunReview,
        ),
        ReviewArtifactActions(
          pr: widget.pr,
          spaceId: spaceId,
          accordion: _accordion,
          rerunning: widget.rerunning,
        ),
        const CcDivider(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _railBreakpoint) {
                return body;
              }
              return CcResizable(
                axis: Axis.horizontal,
                regions: [
                  CcResizableRegion(
                    initialExtent: _railWidth,
                    minExtent: 200,
                    maxExtent: 360,
                    builder: (context) => ReviewFindingsRail(
                      spaceId: spaceId,
                      findings: findings,
                      selectedId: _focusedId,
                      onSelect: (id) {
                        if (id == null) {
                          setState(() => _focusedId = null);
                          if (_scroll.hasClients) {
                            unawaited(
                              _scroll.animateTo(
                                0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                              ),
                            );
                          }
                          return;
                        }
                        _revealFinding(id);
                      },
                    ),
                  ),
                  CcResizableRegion(
                    initialExtent: constraints.maxWidth - _railWidth,
                    minExtent: 420,
                    builder: (context) => body,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
