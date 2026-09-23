import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_filter_rail.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_runs_table.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// How many runs the queue paints before the next page. Newest first; the
/// window grows by this many as the reader nears the end of what is shown.
const int kPipelineRunsPageSize = 50;

/// Distance from the trailing edge, in logical pixels, at which the next page
/// is revealed. Matches the message feed's load-more threshold so a fling
/// does not run out of rows before the next page is in the tree.
const double _kPipelineRunsRevealDistance = 400;

/// The pipeline runs queue: the inbox's shape — a left rail of status filters
/// (all / running / failed, each with its live count) beside a table of runs.
///
/// The list is a list, paged. The rail's counts and each queued run's position
/// are taken from the full workspace list; only the table grows as you scroll.
/// Opening a run navigates to its own page ([pipelineRunRoute]) rather than
/// docking a detail pane here, so the run's graph gets the full width instead
/// of sharing it with a rail it never needed.
class PipelinesScreen extends ConsumerStatefulWidget {
  /// Creates a [PipelinesScreen].
  const PipelinesScreen({super.key});

  @override
  ConsumerState<PipelinesScreen> createState() => _PipelinesScreenState();
}

class _PipelinesScreenState extends ConsumerState<PipelinesScreen> {
  /// Width of the filter rail — the inbox / PR-queue rail width.
  static const double _railWidth = 224;

  PipelineRunFilter _filter = PipelineRunFilter.all;

  /// The row under the keyboard cursor. Never a selection: Enter opens the run
  /// and leaves the page.
  String? _focusedRunId;

  /// Moves the keyboard cursor [delta] rows within [visible].
  void _moveFocus(List<PipelineRun> visible, int delta) {
    if (visible.isEmpty) {
      return;
    }
    final current = visible.indexWhere((r) => r.id == _focusedRunId);
    final next = (current < 0 ? 0 : current + delta).clamp(
      0,
      visible.length - 1,
    );
    setState(() => _focusedRunId = visible[next].id);
  }

  void _openRun(PipelineRun run) =>
      context.go(pipelineRunRoute(run.workspaceId, run.id));

  void _openFocused(List<PipelineRun> visible) {
    final run = visible.firstWhere(
      (r) => r.id == _focusedRunId,
      orElse: () => visible.first,
    );
    _openRun(run);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.pipelinesScreenTitle,
        subtitle: l10n.pipelinesScreenSubtitle,
        child: Center(child: Text(l10n.pipelinesNoActiveWorkspace)),
      );
    }
    final runsAsync = ref.watch(workspacePipelineRunsProvider(workspaceId));
    final isDemo = ref.watch(isDemoServerProvider);
    // Friendly names for the run rows: templateId → human-readable name.
    final templateNames = {
      for (final t
          in ref.watch(pipelineTemplatesProvider(workspaceId)).value ??
              const <PipelineDefinition>[])
        t.templateId: t.name,
    };
    ref.watch(pipelineClockProvider); // tick for live duration display

    return PageWrapper(
      title: l10n.pipelinesScreenTitle,
      subtitle: l10n.pipelinesScreenSubtitle,
      actions: [
        if (!isDemo)
          CcButton(
            onPressed: () => context.go(runPipelineRoute(workspaceId)),
            icon: AppIcons.play,
            size: CcButtonSize.sm,
            child: Text(l10n.pipelinesRunPipeline),
          ),
      ],
      child: runsAsync.when(
        loading: () => _RunsLoadingSkeleton(tokens: tokens),
        error: (e, _) =>
            Center(child: Text(l10n.pipelinesLoadError(e.toString()))),
        data: (runs) {
          if (runs.isEmpty) {
            return _EmptyState(l10n: l10n, tokens: tokens);
          }
          final visible = runs.where(_filter.matches).toList();
          // Numbered over every run, not `visible`: filtering to "running"
          // hides part of a queue, and renumbering what is left would promise
          // a "next" that is third in line.
          final queuePositions = pipelineQueuePositions(runs);
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _railWidth,
                  child: SingleChildScrollView(
                    child: PipelineRunFilterRail(
                      counts: {
                        for (final f in PipelineRunFilter.values)
                          f: runs.where(f.matches).length,
                      },
                      selected: _filter,
                      onSelect: (f) => setState(() => _filter = f),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyFilterState(l10n: l10n, tokens: tokens)
                      : _RunsPane(
                          filter: _filter,
                          visible: visible,
                          queuePositions: queuePositions,
                          focusedRunId: _focusedRunId,
                          templateNames: templateNames,
                          onMoveFocus: (delta) => _moveFocus(visible, delta),
                          onOpenFocused: () => _openFocused(visible),
                          onOpen: _openRun,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The scrolling runs table plus its keyboard scope: ↑/↓ (and j/k) walk the
/// rows, Enter opens the focused one. The table shows a prefix of [visible]
/// and grows it when the reader nears the end, or when the keyboard cursor
/// walks past what is painted.
class _RunsPane extends StatefulWidget {
  const _RunsPane({
    required this.filter,
    required this.visible,
    required this.queuePositions,
    required this.focusedRunId,
    required this.templateNames,
    required this.onMoveFocus,
    required this.onOpenFocused,
    required this.onOpen,
  });

  /// The active status filter. Changing it returns the window to the first
  /// page and the scroll offset to the top: a filter is a new list.
  final PipelineRunFilter filter;

  /// The filtered runs, newest first. Longer than the painted prefix while
  /// older pages are still hidden.
  final List<PipelineRun> visible;

  final Map<String, int> queuePositions;
  final String? focusedRunId;
  final Map<String, String> templateNames;
  final ValueChanged<int> onMoveFocus;
  final VoidCallback onOpenFocused;
  final ValueChanged<PipelineRun> onOpen;

  @override
  State<_RunsPane> createState() => _RunsPaneState();
}

class _RunsPaneState extends State<_RunsPane> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _focusedKey = GlobalKey();

  int _shown = kPipelineRunsPageSize;

  /// Set while a filter change resets the offset, so the clamp that lands the
  /// old offset on the new list's end is not read as "the reader reached the
  /// end" and the window does not immediately grow back.
  bool _suspendReveal = false;

  bool _revealQueued = false;

  @override
  void didUpdateWidget(_RunsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _shown = kPipelineRunsPageSize;
      _suspendReveal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (_scroll.hasClients) {
          _scroll.jumpTo(0);
        }
        _suspendReveal = false;
      });
    } else {
      final index = widget.focusedRunId == null
          ? -1
          : widget.visible.indexWhere((run) => run.id == widget.focusedRunId);
      if (index >= _shown) {
        final page = (index ~/ kPipelineRunsPageSize) + 1;
        final next = page * kPipelineRunsPageSize;
        _shown = next > widget.visible.length ? widget.visible.length : next;
      }
    }
    if (oldWidget.focusedRunId != widget.focusedRunId &&
        widget.focusedRunId != null &&
        oldWidget.filter == widget.filter) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onScrollNotification(Notification notification) {
    final ScrollMetrics metrics;
    final int depth;
    if (notification is ScrollUpdateNotification) {
      metrics = notification.metrics;
      depth = notification.depth;
    } else if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
      depth = notification.depth;
    } else {
      return false;
    }
    if (depth != 0 || metrics.axis != Axis.vertical) {
      return false;
    }
    _considerReveal(metrics);
    return false;
  }

  void _considerReveal(ScrollMetrics metrics) {
    if (_suspendReveal || _revealQueued || _shown >= widget.visible.length) {
      return;
    }
    // A scrollable that has not been laid out yet reports a zero viewport.
    // Revealing off that would grow the window before the first page's real
    // extent is known.
    if (metrics.viewportDimension <= 0) {
      return;
    }
    final remaining = metrics.maxScrollExtent - metrics.pixels;
    // A list that does not fill the viewport never produces a trailing edge
    // to approach, so it keeps revealing until it scrolls or runs out.
    final short = metrics.maxScrollExtent <= _kPipelineRunsRevealDistance;
    if (!short && remaining > _kPipelineRunsRevealDistance) {
      return;
    }
    _revealQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealQueued = false;
      if (!mounted || _shown >= widget.visible.length) {
        return;
      }
      setState(() {
        final next = _shown + kPipelineRunsPageSize;
        _shown = next > widget.visible.length ? widget.visible.length : next;
      });
    });
  }

  void _revealFocused() {
    final target = _focusedKey.currentContext;
    if (target == null || !target.mounted) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    Scrollable.ensureVisible(
      target,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown > widget.visible.length
        ? widget.visible.length
        : _shown;
    final page = widget.visible.take(shown).toList(growable: false);
    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              widget.onMoveFocus(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              widget.onMoveFocus(-1),
          const SingleActivator(LogicalKeyboardKey.keyJ): () =>
              widget.onMoveFocus(1),
          const SingleActivator(LogicalKeyboardKey.keyK): () =>
              widget.onMoveFocus(-1),
          const SingleActivator(LogicalKeyboardKey.enter): widget.onOpenFocused,
        },
        // Same scroll geometry as the PR queue and the inbox. The bottom
        // spacing sits OUTSIDE the scroll view (as margin, not padding) so
        // the viewport — and with it the scrollbar track — ends at the
        // table's box instead of stretching to the window edge; the right
        // inset sits INSIDE it so the table clears the overlaying scrollbar
        // and the thumb rides in the gutter beside the card rather than on
        // its border.
        //
        // The scroll hint fades the TRAILING edge only: the table's column
        // header is a PINNED sliver, so a leading fade would dim a header
        // that is not scrolling — the same false "there is more above"
        // signal the hint exists to avoid. Content sliding under the pinned
        // header already reads as scrolled.
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: CcScrollArea(
            fadeStart: false,
            child: NotificationListener<Notification>(
              onNotification: _onScrollNotification,
              child: CustomScrollView(
                key: const PageStorageKey('pipeline-runs-table'),
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.md,
                    ),
                    sliver: PipelineRunsTable(
                      runs: page,
                      queuePositions: widget.queuePositions,
                      now: DateTime.now(),
                      titleFor: (run) => widget.templateNames[run.templateId],
                      focusedRunId: widget.focusedRunId,
                      focusedRowKey: _focusedKey,
                      onOpen: widget.onOpen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state when no pipeline runs exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.tokens});

  final AppLocalizations l10n;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.gitBranch, size: 40, color: tokens.fgQuaternary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.pipelinesEmpty,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.pipelinesEmptyHint,
            style: TextStyle(color: tokens.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Shown in the content pane when the active filter matches no runs.
class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.l10n, required this.tokens});

  final AppLocalizations l10n;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            l10n.pipelineRunFilterEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textTertiary, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder: the rail's entries beside a few table rows.
class _RunsLoadingSkeleton extends StatelessWidget {
  const _RunsLoadingSkeleton({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 224,
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  _SkeletonBar(tokens: tokens, height: 14),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  _SkeletonBar(tokens: tokens, height: 36),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single rounded skeleton placeholder block.
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.tokens, required this.height});

  final DesignSystemTokens tokens;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
      ),
    );
  }
}
