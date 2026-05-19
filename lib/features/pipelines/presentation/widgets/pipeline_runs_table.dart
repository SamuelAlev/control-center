import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/widgets.dart';

/// The runs list's content pane: one bordered card holding a column header over
/// divided [PipelineRunRow]s — the same table the inbox and the PR queue use, so
/// a run reads like every other work item in the app.
///
/// Built as a SLIVER GROUP (it must sit in a `CustomScrollView`'s slivers): the
/// column header is a pinned [SliverPersistentHeader] — the same sticky header
/// the PR queue's table uses — so the labels stay at the top of the viewport
/// while the rows scroll beneath. The card's frame splits across the two
/// slivers: the header paints the top edge and the hairline under the labels,
/// the body the side and bottom edges.
class PipelineRunsTable extends StatelessWidget {
  /// Creates a [PipelineRunsTable].
  const PipelineRunsTable({
    super.key,
    required this.runs,
    required this.now,
    required this.titleFor,
    required this.onOpen,
    this.focusedRunId,
    this.queuePositions = const {},
  });

  /// The runs to render, in display order.
  final List<PipelineRun> runs;

  /// Queue position per run id for the `queued` rows (1 = admitted next), from
  /// [pipelineQueuePositions]. Computed over the UNFILTERED run list so a
  /// status filter cannot renumber a partly-hidden queue.
  final Map<String, int> queuePositions;

  /// Current time for live durations / relative starts.
  final DateTime now;

  /// Resolves a run's friendly pipeline name (null → the row falls back to the
  /// template id).
  final String? Function(PipelineRun run) titleFor;

  /// Opens a run's page.
  final ValueChanged<PipelineRun> onOpen;

  /// The run under the keyboard cursor, if any.
  final String? focusedRunId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return SliverMainAxisGroup(
      slivers: [
        const SliverPersistentHeader(
          pinned: true,
          delegate: _ColumnHeaderDelegate(child: _ColumnHeaderRow()),
        ),
        SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.panel,
              border: Border(
                left: BorderSide(color: tokens.borderSecondary),
                right: BorderSide(color: tokens.borderSecondary),
                bottom: BorderSide(color: tokens.borderSecondary),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < runs.length; i++) ...[
                  if (i > 0) CcDivider(color: tokens.borderSoft),
                  PipelineRunRow(
                    run: runs[i],
                    now: now,
                    title: titleFor(runs[i]),
                    focused: runs[i].id == focusedRunId,
                    queuePosition: queuePositions[runs[i].id],
                    onOpen: () => onOpen(runs[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The pinned column header of the runs table, with the PR queue header's exact
/// geometry: the 16px [CcTypography.caption] line inside 11px vertical padding
/// (the PR header's 8px row padding plus its sort row's 3px, so the label sits
/// at the same height and the box at the same 40px), framed by the card's 1px
/// top border and the 1px hairline that separates the labels from the rows —
/// the cut the rows scroll beneath once the header is pinned.
class _ColumnHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ColumnHeaderDelegate({required this.child});

  /// The column header content (the aligned labels).
  final Widget child;

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // See [PinnedHeaderBleedGuard]: the ClipRect keeps the header's content
    // inside its box, the guard covers the partial device pixel above the top
    // border where the row scrolling beneath would otherwise show through.
    return PinnedHeaderBleedGuard(
      child: ClipRect(
        child: SizedBox(
          height: _extent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.panel,
              border: Border.all(color: tokens.borderSecondary),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ColumnHeaderDelegate old) => old.child != child;
}

/// The column header, aligned to [PipelineRunRowMetrics] and styled like the
/// inbox / PR-queue headers ([CcTypography.caption]). The status column is
/// deliberately unlabelled — its pills read for themselves and a "Status"
/// header would be the widest thing in a column of 11px chips.
class _ColumnHeaderRow extends StatelessWidget {
  const _ColumnHeaderRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: tokens.idle,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PipelineRunRowMetrics.hPad,
        // 11 = the PR header's 8px row padding plus its sort row's 3px, so the
        // label line box sits at the same height as the PR queue's headers.
        vertical: 11,
      ),
      child: Row(
        children: [
          // Reserve the row's trigger-glyph slot so the name column lines up.
          const SizedBox(width: PipelineRunRowMetrics.trigger + AppSpacing.sm),
          Expanded(child: Text(l10n.pipelineRunColumnPipeline, style: style)),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: PipelineRunRowMetrics.status),
          SizedBox(
            width: PipelineRunRowMetrics.duration,
            child: Text(
              l10n.pipelineRunColumnDuration,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
          SizedBox(
            width: PipelineRunRowMetrics.started,
            child: Text(
              l10n.pipelineRunColumnStarted,
              textAlign: TextAlign.right,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
