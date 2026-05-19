import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_detail_actions.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_header_section.dart';
import 'package:control_center/features/pr_review/presentation/widgets/editable_pr_title.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_activity_timeline.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR-detail **Overview** tab: the PR title + actions, the description,
/// and the activity timeline (main column) beside a channel-style collapsible
/// sidebar (status, reviewers, assignees, checks, files). The title + actions
/// live here — at the top of the tab — rather than in a page header above the
/// tabs. Wide layouts split the main column and sidebar into a draggable
/// two-pane row; narrow layouts stack the sidebar under the description in
/// one scroll.
class PrOverviewTab extends ConsumerWidget {
  /// Creates a [PrOverviewTab].
  const PrOverviewTab({
    super.key,
    required this.pr,
    required this.prNumber,
    required this.onOpenFileInDiff,
  });

  /// The pull request being shown.
  final PullRequest pr;

  /// The PR number (data lookups).
  final int prNumber;

  /// Called with a changed file's tree-order index when its sidebar row is
  /// tapped, so the detail screen can focus the Diff tab and jump to it.
  final ValueChanged<int> onOpenFileInDiff;

  /// Default width of the Overview sidebar pane (wide layout, ephemeral).
  static const double _sidebarWidth = 300;

  /// Breakpoint below which the sidebar stacks under the description.
  static const double _wideBreakpoint = 880;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final checks =
        ref.watch(prCheckRunsProvider(prNumber)).value ?? const <CheckRun>[];
    final canEdit = ref.watch(prCanEditProvider(prNumber));
    final optimisticMyState = ref.watch(
      prOptimisticReviewStateProvider,
    )[prNumber];

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _OverviewHeader(pr: pr, prNumber: prNumber, canEdit: canEdit),
        const SizedBox(height: 16),
        PrHeaderSection(pr: pr, prNumber: prNumber),
        const SizedBox(height: 24),
        const CcDivider(),
        const SizedBox(height: 20),
        PrActivityTimeline(
          pr: pr,
          prNumber: prNumber,
          onOpenFileInDiff: onOpenFileInDiff,
        ),
      ],
    );
    final sidebar = PrSidebar(
      pr: pr,
      checks: checks,
      canEdit: canEdit,
      optimisticMyState: optimisticMyState,
      onOpenFileInDiff: onOpenFileInDiff,
    );

    return ColoredBox(
      color: t.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          if (!wide) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: main,
                  ),
                  const CcDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: sidebar,
                  ),
                ],
              ),
            );
          }
          return CcResizable(
            axis: Axis.horizontal,
            regions: [
              CcResizableRegion(
                initialExtent: constraints.maxWidth - _sidebarWidth,
                minExtent: 420,
                builder: (context) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: main,
                ),
              ),
              CcResizableRegion(
                initialExtent: _sidebarWidth,
                minExtent: 240,
                maxExtent: 380,
                builder: (context) => ColoredBox(
                  color: t.bgSecondary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: sidebar,
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

/// The Overview tab's top row: the (editable) PR title on the left and the
/// PR-level actions on the right. Wraps to two lines on narrow widths.
class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.pr,
    required this.prNumber,
    required this.canEdit,
  });

  final PullRequest pr;
  final int prNumber;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = EditablePrTitle(pr: pr, canEdit: canEdit);
        final actions = PrDetailActions(pr: pr, prNumber: prNumber);
        // Below ~560px the title + action cluster can't share a row without
        // squeezing; stack them instead.
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}
