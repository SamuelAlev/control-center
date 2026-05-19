import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_visuals.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_step_detail_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  static const double _nodeWidth = 180;
  static const double _nodeHeight = 68;

  Offset _panOffset = Offset.zero;
  String? _selectedStepId;

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
        child: Row(
          children: [
            // The pannable graph fills the space left of the detail sidebar.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final centerOffset = _centeringOffset(
                    renderable,
                    constraints.biggest,
                  );
                  final translate = centerOffset + _panOffset;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => setState(() => _panOffset += d.delta),
                    child: Container(
                      color: tokens.bgPrimary,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: PipelineCanvasBackground(
                                offset: _panOffset,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: PipelineEdgesPainter(
                                  steps: renderable,
                                  color: tokens.borderSecondary,
                                  nodeWidth: _nodeWidth,
                                  nodeHeight: _nodeHeight,
                                  offset: translate,
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
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Selecting a node docks its run detail here as a sidebar, rather
            // than floating over the graph. Only meaningful for an actual run.
            if (widget.runId != null && _selectedStepId != null)
              Container(
                width: 360,
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  border: Border(
                    left: BorderSide(color: tokens.borderSecondary),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: PipelineStepDetailPanel(
                    step: widget.definition.step(_selectedStepId!),
                    stepRun: latestByStepId[_selectedStepId!],
                    now: now,
                    onClose: () => setState(() => _selectedStepId = null),
                    elevated: false,
                  ),
                ),
              ),
          ],
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
  ) {
    final selected = step.id == _selectedStepId;
    final position = Offset(step.x ?? 0, step.y ?? 0) + translate;
    final status = stepRun?.status;
    final sc = status != null ? pipelineStepStatusColors(status, tokens) : null;
    final isTrigger = step.kind == StepKind.trigger;

    final fill =
        sc?.background ??
        (isTrigger ? tokens.bgBrandPrimary : tokens.bgPrimary);
    final dot =
        sc?.dot ?? (isTrigger ? tokens.fgBrandPrimary : tokens.fgQuaternary);
    final border = selected
        ? tokens.borderBrand
        : sc?.border ??
              (isTrigger ? tokens.borderBrand : tokens.borderSecondary);

    final Duration? duration;
    if (stepRun != null && status != PipelineStepStatus.pending) {
      duration = stepRun.finishedAt != null
          ? stepRun.finishedAt!.difference(stepRun.startedAt)
          : (stepRun.isTerminal
                ? Duration.zero
                : now.difference(stepRun.startedAt));
    } else {
      duration = null;
    }

    final l10n = AppLocalizations.of(context);
    final label = step.config.label ?? step.id;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _nodeWidth,
      height: _nodeHeight,
      child: Semantics(
        button: widget.runId != null,
        selected: selected,
        label: label,
        value: status != null ? _statusLabel(status, l10n) : null,
        child: FTappable.static(
          onPress: widget.runId == null
              ? null
              : () => setState(() => _selectedStepId = step.id),
          focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: border, width: selected ? 2 : 1),
              borderRadius: AppRadii.brMd,
            ),
            child: Row(
              children: [
                _statusGlyph(status, isTrigger, dot),
                AppSpacing.hGapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Step-run info on the card itself: the status in words
                      // (not glyph/color alone) plus the elapsed duration.
                      if (status != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _statusLabel(status, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: sc?.foreground ?? tokens.textTertiary,
                                ),
                              ),
                            ),
                            if (duration != null) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: tokens.textQuaternary,
                                ),
                              ),
                              Text(
                                formatPipelineDuration(duration),
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: tokens.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else if (duration != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          formatPipelineDuration(duration),
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Offset _centeringOffset(List<PipelineStepDefinition> nodes, Size viewport) {
    if (nodes.isEmpty) {
      return Offset.zero;
    }
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final n in nodes) {
      final x = n.x ?? 0;
      final y = n.y ?? 0;
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (x + _nodeWidth > maxX) {
        maxX = x + _nodeWidth;
      }
      if (y + _nodeHeight > maxY) {
        maxY = y + _nodeHeight;
      }
    }
    final width = maxX - minX;
    final height = maxY - minY;
    final dx = (viewport.width - width) / 2 - minX;
    final dy = (viewport.height - height) / 2 - minY;
    return Offset(dx, dy);
  }

  /// Status indicator for a node: a spinner while running, otherwise a glyph,
  /// so step state reads by shape and not color alone (Status-Never-Alone).
  Widget _statusGlyph(PipelineStepStatus? status, bool isTrigger, Color color) {
    if (status == PipelineStepStatus.running) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    final icon = status != null
        ? pipelineStepStatusIcon(status)
        : (isTrigger ? LucideIcons.zap : LucideIcons.circle);
    return Icon(icon, size: 14, color: color);
  }
}
