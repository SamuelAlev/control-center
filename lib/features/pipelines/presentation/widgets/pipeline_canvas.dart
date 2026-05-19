import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_graph_layout.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_visuals.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_step_detail_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a [PipelineDefinition] as a pannable, centered node graph. When
/// [runId] is set, nodes recolor based on the latest step run status and
/// tapping a node opens a side sheet with its run details (status, duration,
/// error, input/output, branch index).
///
/// Uses a custom Flutter-native canvas so the look matches the editor.
class PipelineCanvas extends ConsumerStatefulWidget {
  /// Creates a [PipelineCanvas].
  const PipelineCanvas({
    super.key,
    required this.definition,
    this.runId,
    this.initialSelectedStepId,
  });

  /// The pipeline template to render.
  final PipelineDefinition definition;

  /// Optional pipeline run ID. When supplied, nodes recolor per step status
  /// and tapping a node opens its run details.
  final String? runId;

  /// Step whose detail panel should be open when the canvas first builds —
  /// used to land directly on the failed step of a failed run.
  final String? initialSelectedStepId;

  @override
  ConsumerState<PipelineCanvas> createState() => _PipelineCanvasState();
}

class _PipelineCanvasState extends ConsumerState<PipelineCanvas> {
  /// Node width adapts to the title: every node is at least 180px and a
  /// long title may widen its node (and, through [PipelineGraphLayout], only
  /// its own column) up to twice that; the card title wraps to two lines
  /// inside the widened node.
  static const double _nodeMinWidth = 180;
  static const double _nodeMaxWidth = 360;
  static const double _nodeHeight = 68;

  /// Bounds for the step sidebar, as a fraction-free pair: narrow enough to
  /// read a step's meta, wide enough to hold a JSON payload open.
  static const double _panelMinWidth = 280;
  static const double _panelMaxWidth = 620;

  Offset _panOffset = Offset.zero;
  String? _selectedStepId;

  /// The sidebar's current width, updated as the seam is dragged. Held here (not
  /// in the [CcResizable]'s controller) because the resizable is unmounted while
  /// no step is selected — this is what makes a dragged width survive
  /// closing and reopening the panel.
  double _panelWidth = 360;

  @override
  void initState() {
    super.initState();
    _selectedStepId = widget.initialSelectedStepId;
  }

  @override
  void didUpdateWidget(covariant PipelineCanvas old) {
    super.didUpdateWidget(old);
    // When the screen switches to a different run, re-land on that run's
    // initial (failed/last) step rather than keeping the prior run's
    // selection, which would point at a step the new run never executed.
    if (old.runId != widget.runId) {
      _selectedStepId = widget.initialSelectedStepId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final renderable = widget.definition.steps
        .where((s) => s.kind != StepKind.terminal)
        .toList();

    if (renderable.isEmpty) {
      return Center(
        child: Text(
          l10n.pipelinesNoSteps,
          style: TextStyle(color: tokens.textTertiary),
        ),
      );
    }

    final stepRunsAsync = widget.runId == null
        ? const AsyncValue<List<PipelineStepRun>>.data([])
        : ref.watch(pipelineStepRunsForRunProvider(widget.runId!));

    final latestByStepId = <String, PipelineStepRun>{};
    stepRunsAsync.whenData((runs) {
      for (final sr in runs) {
        final prev = latestByStepId[sr.stepId];
        if (prev == null || sr.startedAt.isAfter(prev.startedAt)) {
          latestByStepId[sr.stepId] = sr;
        }
      }
    });
    ref.watch(pipelineClockProvider); // tick for live duration display
    final now = DateTime.now();

    // Each node's rendered width: measured from its title (and trailing
    // duration) so a long name widens the node up to the 2x cap instead of
    // ellipsizing on one line.
    final widths = {
      for (final step in renderable)
        step.id: _nodeWidthFor(step, latestByStepId[step.id], now, tokens),
    };

    final graph = LayoutBuilder(
      builder: (context, constraints) {
        // Read-only run view: derive a layered left-to-right layout from the
        // graph (trigger leftmost, columns spaced so tiles never overlap)
        // rather than trusting the stored editor coordinates.
        final layout = PipelineGraphLayout.compute(
          renderable,
          nodeWidths: widths,
          nodeHeight: _nodeHeight,
        );
        final baseOffset = _baseOffset(layout, constraints.biggest, widths);
        final translate = baseOffset + _panOffset;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => setState(() => _panOffset += d.delta),
          child: Container(
            color: tokens.bgPrimary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: PipelineCanvasBackground(offset: _panOffset),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: PipelineEdgesPainter(
                        steps: renderable,
                        color: tokens.borderSecondary,
                        nodeWidths: widths,
                        nodeHeight: _nodeHeight,
                        offset: translate,
                        positions: layout,
                      ),
                    ),
                  ),
                ),
                for (final step in renderable)
                  _buildNode(
                    step,
                    latestByStepId[step.id],
                    tokens,
                    translate,
                    now,
                    layout[step.id] ?? Offset.zero,
                    widths[step.id] ?? _nodeMinWidth,
                  ),
              ],
            ),
          ),
        );
      },
    );

    final selectedStepId = _selectedStepId;
    final panelOpen = widget.runId != null && selectedStepId != null;

    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_selectedStepId != null) {
              setState(() => _selectedStepId = null);
            }
          },
        },
        child: !panelOpen
            ? graph
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Selecting a node docks its run detail as a resizable
                  // sidebar, flush against the graph: CcResizable's hairline is
                  // the only seam, so the panel reads as part of the page
                  // instead of a card floating in a padded gutter.
                  final total = constraints.maxWidth;
                  final panelWidth = _panelWidth.clamp(
                    _panelMinWidth,
                    total <= _panelMinWidth
                        ? _panelMinWidth
                        : (total * 0.6).clamp(_panelMinWidth, _panelMaxWidth),
                  );
                  return CcResizable(
                    axis: Axis.horizontal,
                    onResize: (extents) => _panelWidth = extents[1],
                    regions: [
                      CcResizableRegion(
                        initialExtent: total - panelWidth,
                        minExtent: 200,
                        builder: (context) => graph,
                      ),
                      CcResizableRegion(
                        initialExtent: panelWidth,
                        minExtent: _panelMinWidth,
                        maxExtent: _panelMaxWidth,
                        builder: (context) => ColoredBox(
                          color: tokens.bgPrimary,
                          child: PipelineStepDetailPanel(
                            step: widget.definition.step(selectedStepId),
                            stepRun: latestByStepId[selectedStepId],
                            now: now,
                            onClose: () =>
                                setState(() => _selectedStepId = null),
                            elevated: false,
                            bordered: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNode(
    PipelineStepDefinition step,
    PipelineStepRun? stepRun,
    DesignSystemTokens tokens,
    Offset translate,
    DateTime now,
    Offset layoutPosition,
    double width,
  ) {
    final selected = step.id == _selectedStepId;
    final position = layoutPosition + translate;
    final status = stepRun?.status;
    final sc = status != null ? pipelineStepStatusColors(status, tokens) : null;
    final isTrigger = step.kind == StepKind.trigger;

    final dot =
        sc?.dot ?? (isTrigger ? tokens.fgBrandPrimary : tokens.fgQuaternary);

    final duration = _durationFor(stepRun, now);

    final l10n = AppLocalizations.of(context);
    final label = step.config.label ?? step.id;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: _nodeHeight,
      child: Semantics(
        button: widget.runId != null,
        selected: selected,
        label: label,
        value: status != null ? _statusLabel(status, l10n) : null,
        child: CcTappable(
          onPressed: widget.runId == null
              ? null
              : () => setState(() => _selectedStepId = step.id),
          builder: (context, states) => GraphNodeCard(
            glyph: _statusGlyph(status, isTrigger, dot),
            title: label,
            // The status in words under the name (not glyph/color alone);
            // the duration sits right-aligned in the trailing meta.
            subtitle: status != null ? _statusLabel(status, l10n) : null,
            subtitleColor: sc?.foreground,
            trailing: duration != null
                ? formatPipelineDuration(duration)
                : null,
            selected: selected,
            fill: isTrigger ? tokens.bgBrandPrimary : null,
            border: isTrigger ? tokens.borderBrand : null,
            hovered: states.contains(WidgetState.hovered),
          ),
        ),
      ),
    );
  }

  /// A step run's duration: finished runs report their wall clock, a running
  /// one ticks against [now]; pending or never-run steps have none (the node
  /// renders no trailing meta then).
  static Duration? _durationFor(PipelineStepRun? stepRun, DateTime now) {
    if (stepRun == null || stepRun.status == PipelineStepStatus.pending) {
      return null;
    }
    return stepRun.finishedAt != null
        ? stepRun.finishedAt!.difference(stepRun.startedAt)
        : (stepRun.isTerminal
              ? Duration.zero
              : now.difference(stepRun.startedAt));
  }

  /// The node's rendered width: the title's single-line width plus the card's
  /// fixed chrome (horizontal padding, the 14px glyph + its gap and the
  /// trailing duration when present), clamped to [_nodeMinWidth]..
  /// [_nodeMaxWidth] — the 2x cap the two-line title wraps within.
  static double _nodeWidthFor(
    PipelineStepDefinition step,
    PipelineStepRun? stepRun,
    DateTime now,
    DesignSystemTokens tokens,
  ) {
    final label = step.config.label ?? step.id;
    var w =
        GraphNodeCard.horizontalPadding * 2 +
        14 +
        AppSpacing.sm +
        _measure(label, GraphNodeCard.titleStyle(color: tokens.textPrimary));
    final duration = _durationFor(stepRun, now);
    if (duration != null) {
      w +=
          AppSpacing.sm +
          _measure(
            formatPipelineDuration(duration),
            GraphNodeCard.metaStyle(color: tokens.textTertiary),
          );
    }
    return w.clamp(_nodeMinWidth, _nodeMaxWidth).toDouble();
  }

  /// Single-line rendered width of [text] in [style] (the exact styles
  /// [GraphNodeCard] renders with, so the measurement matches the pixels).
  static double _measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// Localized status word for a node's screen-reader value, so the status a
  /// sighted operator reads from the glyph is also announced.
  String _statusLabel(PipelineStepStatus status, AppLocalizations l10n) {
    return switch (status) {
      PipelineStepStatus.pending => l10n.pipelineStatusPending,
      PipelineStepStatus.running => l10n.pipelineStatusRunning,
      PipelineStepStatus.suspended => l10n.pipelineStatusSuspended,
      PipelineStepStatus.completed => l10n.pipelineStatusCompleted,
      PipelineStepStatus.failed => l10n.pipelineStatusFailed,
      PipelineStepStatus.skipped => l10n.pipelineStatusSkipped,
      PipelineStepStatus.cancelled => l10n.pipelineStatusCancelled,
    };
  }

  /// Left margin between the viewport edge and the trigger column at rest.
  static const double _leftPadding = 48;

  /// Base translation before the user's pan: center the graph vertically and
  /// center it horizontally too when the whole graph fits the viewport —
  /// otherwise pin the leftmost (trigger) column near the left edge so the
  /// roots stay visible and the operator pans right to follow the flow.
  Offset _baseOffset(
    Map<String, Offset> positions,
    Size viewport,
    Map<String, double> widths,
  ) {
    if (positions.isEmpty) {
      return Offset.zero;
    }
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final e in positions.entries) {
      final p = e.value;
      final w = widths[e.key] ?? _nodeMinWidth;
      if (p.dx < minX) {
        minX = p.dx;
      }
      if (p.dx + w > maxX) {
        maxX = p.dx + w;
      }
      if (p.dy < minY) {
        minY = p.dy;
      }
      if (p.dy + _nodeHeight > maxY) {
        maxY = p.dy + _nodeHeight;
      }
    }
    final width = maxX - minX;
    final height = maxY - minY;
    final fits = width + 2 * _leftPadding <= viewport.width;
    final dx = fits ? (viewport.width - width) / 2 - minX : _leftPadding - minX;
    final dy = (viewport.height - height) / 2 - minY;
    return Offset(dx, dy);
  }

  /// Status indicator for a node: a spinner while running, otherwise a glyph,
  /// so step state reads by shape and not color alone (Status-Never-Alone).
  Widget _statusGlyph(PipelineStepStatus? status, bool isTrigger, Color color) {
    if (status == PipelineStepStatus.running) {
      return CcSpinner(size: 14, color: color);
    }
    final icon = status != null
        ? pipelineStepStatusIcon(status)
        : (isTrigger ? AppIcons.zap : AppIcons.circle);
    return Icon(icon, size: 14, color: color);
  }
}
