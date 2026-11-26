import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_detail_actions.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/editable_pr_title.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_activity_timeline.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_conversation_composer.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sign_in_notice.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/widgets/confined_directional_focus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'pr_overview_header.dart';

/// The PR-detail Overview tab: the PR title + actions, the description,
/// and the activity timeline (main column) beside a space-style collapsible
/// sidebar (status, reviewers, assignees, checks, files). The title + actions
/// live here — at the top of the tab — rather than in a page header above the
/// tabs. Wide layouts split the main column and sidebar into a draggable
/// two-pane row; narrow layouts stack the sidebar under the description in
/// one scroll.
class PrOverviewTab extends ConsumerStatefulWidget {
  /// Creates a [PrOverviewTab].
  const PrOverviewTab({
    super.key,
    required this.pr,
    required this.prRef,
    this.pendingCommentAnchor,
    this.isVisible = true,
    required this.onOpenFileInDiff,
    required this.onOpenCommentInDiff,
    required this.onOpenCommit,
    required this.onOpenReview,
    this.onOpenEnvironment,
  });

  /// The pull request being shown.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number) for PR-keyed providers.
  final PrRef prRef;

  /// A comment (REST id) a permalink asked to reveal in the timeline.
  final ValueNotifier<int?>? pendingCommentAnchor;

  /// Whether this tab is currently the active visible pane.
  final bool isVisible;

  /// Called with a changed file's tree-order index when its sidebar row is
  /// tapped, so the detail screen can focus the Diff tab and jump to it.
  final ValueChanged<int> onOpenFileInDiff;

  /// Called with a review conversation's root comment id when the timeline's
  /// "view in diff" is pressed, so the detail screen can reveal that thread.
  final ValueChanged<int> onOpenCommentInDiff;

  /// Called with a commit SHA when that commit is tapped in the activity
  /// timeline, so the detail screen can focus the Diff tab on its changes.
  final ValueChanged<String> onOpenCommit;

  /// Focuses the PR review artifact tab (see [PrDetailActions.onOpenReview]).
  final VoidCallback onOpenReview;

  /// Focuses the PR's Environment tab.
  final VoidCallback? onOpenEnvironment;

  @override
  ConsumerState<PrOverviewTab> createState() => _PrOverviewTabState();
}

class _PrOverviewTabState extends ConsumerState<PrOverviewTab> {
  /// Default width of the Overview sidebar pane (wide layout, ephemeral).
  static const double _sidebarWidth = 300;

  /// Breakpoint below which the sidebar stacks under the description.
  static const double _wideBreakpoint = 880;

  // The narrow and wide layouts are different trees (one scroll vs a two-pane
  // row). Keyed, the header, timeline and sidebar REPARENT when the width
  // crosses the breakpoint instead of remounting — a remount re-ran the
  // description's markdown, every timeline card and the sidebar's lookups.
  final GlobalKey _headerKey = GlobalKey(debugLabel: 'pr-overview-header');
  final GlobalKey _timelineKey = GlobalKey(debugLabel: 'pr-overview-timeline');
  final GlobalKey _composerKey = GlobalKey(debugLabel: 'pr-overview-composer');
  final GlobalKey _sidebarKey = GlobalKey(debugLabel: 'pr-overview-sidebar');
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pr = widget.pr;
    final prRef = widget.prRef;
    final t = context.designSystem ?? DesignSystemTokens.light();
    final checksAsync = ref.watch(prCheckRunsProvider(prRef));
    // The last good list survives an error: a retried subscription error
    // used to blank the rail's checks between two identical snapshots.
    final checks = checksAsync.value ?? const <CheckRun>[];
    final canEdit = ref.watch(prCanEditProvider(prRef));
    final optimisticMyState = ref.watch(
      prOptimisticReviewStateProvider.select((m) => m[prRef]),
    );

    final header = Column(
      key: _headerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PrSignInNotice(prRef: prRef),
        _OverviewHeader(
          pr: pr,
          prRef: prRef,
          canEdit: canEdit,
          onOpenReview: widget.onOpenReview,
        ),
        const SizedBox(height: 16),
        PrHeaderSection(pr: pr, prRef: prRef),
        const SizedBox(height: 24),
        const CcDivider(),
        const SizedBox(height: 20),
      ],
    );
    final timeline = PrActivityTimeline(
      key: _timelineKey,
      pr: pr,
      prRef: prRef,
      pendingCommentAnchor: widget.pendingCommentAnchor,
      scrollController: _scrollController,
      isVisible: widget.isVisible,
      onOpenCommentInDiff: widget.onOpenCommentInDiff,
      onOpenCommit: widget.onOpenCommit,
    );
    final composer = PrConversationComposer(
      key: _composerKey,
      pr: pr,
      prRef: prRef,
    );
    final sidebar = PrSidebar(
      key: _sidebarKey,
      pr: pr,
      prRef: prRef,
      checks: checks,
      checksPending: !checksAsync.hasValue && !checksAsync.hasError,
      detailPending: ref.watch(prDetailPendingProvider(prRef)),
      canEdit: canEdit,
      optimisticMyState: optimisticMyState,
      onOpenFileInDiff: widget.onOpenFileInDiff,
      onOpenEnvironment: widget.onOpenEnvironment,
    );

    return ColoredBox(
      color: t.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          if (!wide) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  sliver: SliverToBoxAdapter(child: header),
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                  sliver: timeline,
                ),
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
                  sliver: SliverToBoxAdapter(child: composer),
                ),
                const SliverToBoxAdapter(child: CcDivider()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ConfinedDirectionalFocus(child: sidebar),
                  ),
                ),
              ],
            );
          }
          return CcResizable(
            axis: Axis.horizontal,
            regions: [
              CcResizableRegion(
                initialExtent: constraints.maxWidth - _sidebarWidth,
                minExtent: 420,
                // Each pane is its own focus region: Tab finishes the main
                // column before the sidebar instead of zig-zagging between
                // them by row, and arrow keys stay inside the pane.
                builder: (context) => ConfinedDirectionalFocus(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        sliver: SliverToBoxAdapter(child: header),
                      ),
                      SliverPadding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          24,
                          0,
                          24,
                          0,
                        ),
                        sliver: timeline,
                      ),
                      SliverPadding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          24,
                          0,
                          24,
                          24,
                        ),
                        sliver: SliverToBoxAdapter(child: composer),
                      ),
                    ],
                  ),
                ),
              ),
              CcResizableRegion(
                initialExtent: _sidebarWidth,
                minExtent: 240,
                maxExtent: 380,
                builder: (context) => ColoredBox(
                  color: t.bgSecondary,
                  child: ConfinedDirectionalFocus(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: sidebar,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
