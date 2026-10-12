import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/workflow_matrix_names.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_graph_layout.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/canvas/graph_canvas_viewport.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rolls up the status of the check runs matched to one graph node, using
/// the same rule as `WorkflowGroup.status`: any unfinished run → running,
/// else any failing → failure, else any successful → success, else neutral.
/// A node with zero matched runs (skipped `if:`, reusable-workflow mismatch)
/// is neutral.
WorkflowStatus workflowNodeStatus(List<CheckRun> runs) {
  var hasRunning = false;
  var hasFailure = false;
  var hasSuccess = false;
  for (final r in runs) {
    if (!r.isComplete) {
      hasRunning = true;
    } else if (r.isFailing) {
      hasFailure = true;
    } else if (r.isSuccess) {
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

/// Digit-run-aware name compare: `Job (2)` sorts before `Job (10)`, which a
/// plain string sort gets wrong (matrix chips showed `3, 10, 1, 7, …`).
int compareCheckRunNamesNaturally(String a, String b) {
  var i = 0;
  var j = 0;
  bool isDigit(int c) => c >= 0x30 && c <= 0x39;
  while (i < a.length && j < b.length) {
    final ca = a.codeUnitAt(i);
    final cb = b.codeUnitAt(j);
    if (isDigit(ca) && isDigit(cb)) {
      var ia = i;
      var jb = j;
      while (ia < a.length && isDigit(a.codeUnitAt(ia))) {
        ia++;
      }
      while (jb < b.length && isDigit(b.codeUnitAt(jb))) {
        jb++;
      }
      final na = int.parse(a.substring(i, ia));
      final nb = int.parse(b.substring(j, jb));
      if (na != nb) {
        return na - nb;
      }
      i = ia;
      j = jb;
    } else {
      if (ca != cb) {
        return ca - cb;
      }
      i++;
      j++;
    }
  }
  return (a.length - i) - (b.length - j);
}

/// Joins check runs onto workflow graph nodes by display name: a check run
/// matches a node when its name equals the node's display name, carries the
/// matrix suffix form `name (variation)`, or fits the node's `${{ … }}` name
/// template once GitHub has substituted the matrix values. Check runs matching
/// no node (external checks, renamed jobs) come back in `unmatched`. A node's
/// children are naturally sorted so matrix chips read `1, 2, …, 10`.
({Map<String, List<CheckRun>> byNodeId, List<CheckRun> unmatched})
matchCheckRunsToGraphNodes(List<WorkflowJobNode> nodes, List<CheckRun> checks) {
  final byNodeId = <String, List<CheckRun>>{};
  final unmatched = <CheckRun>[];
  final exactByName = <String, WorkflowJobNode>{};
  for (final n in nodes) {
    exactByName.putIfAbsent(n.name, () => n);
  }
  final templates = <String, MatrixNameTemplate>{};
  for (final n in nodes) {
    final template = MatrixNameTemplate.parse(n.name);
    if (template != null) {
      templates[n.id] = template;
    }
  }
  for (final c in checks) {
    var node = exactByName[c.name];
    if (node == null) {
      for (final n in nodes) {
        if (c.name.startsWith('${n.name} (')) {
          node = n;
          break;
        }
      }
    }
    if (node == null && templates.isNotEmpty) {
      for (final n in nodes) {
        if (templates[n.id]?.variationOf(c.name) != null) {
          node = n;
          break;
        }
      }
    }
    if (node == null) {
      unmatched.add(c);
    } else {
      (byNodeId[node.id] ??= []).add(c);
    }
  }
  for (final list in byNodeId.values) {
    list.sort((x, y) => compareCheckRunNamesNaturally(x.name, y.name));
  }
  return (byNodeId: byNodeId, unmatched: unmatched);
}

/// Painter that draws cubic-bezier edges between workflow job nodes, from
/// each node's `needs` upstream ids. A retype of `PipelineEdgesPainter` on
/// [WorkflowJobNode] — the drawing is identical (bezier + 8px arrowhead).
class WorkflowEdgesPainter extends CustomPainter {
  /// Creates a [WorkflowEdgesPainter].
  WorkflowEdgesPainter({
    required this.nodes,
    required this.positions,
    required this.color,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.offset,
  });

  /// All job nodes in the rendered graph; the painter walks their `needs` to
  /// emit edges.
  final List<WorkflowJobNode> nodes;

  /// Per-node top-left positions from [WorkflowGraphLayout.compute].
  final Map<String, Offset> positions;

  /// Edge colour.
  final Color color;

  /// Width of each node tile.
  final double nodeWidth;

  /// Height of each node tile.
  final double nodeHeight;

  /// Translation applied to every node position before drawing edges, so the
  /// lines stay anchored to the rendered tiles when the canvas is centered or
  /// panned.
  final Offset offset;

  late final Path _path = _buildPath();

  Path _buildPath() {
    final path = Path();
    for (final node in nodes) {
      final end = positions[node.id];
      if (end == null) {
        continue;
      }
      final to = end + Offset(0, nodeHeight / 2);
      for (final need in node.needs) {
        final origin = positions[need];
        if (origin == null) {
          continue;
        }
        final from = origin + Offset(nodeWidth, nodeHeight / 2);
        path
          ..moveTo(from.dx, from.dy)
          ..cubicTo(from.dx + 60, from.dy, to.dx - 60, to.dy, to.dx, to.dy)
          ..moveTo(to.dx, to.dy)
          ..lineTo(to.dx - 8, to.dy - 4)
          ..moveTo(to.dx, to.dy)
          ..lineTo(to.dx - 8, to.dy + 4);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.drawPath(
      _path,
      Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorkflowEdgesPainter old) =>
      old.nodes != nodes ||
      old.color != color ||
      old.offset != offset ||
      old.nodeWidth != nodeWidth ||
      old.nodeHeight != nodeHeight ||
      !const MapEquality<String, Offset>().equals(old.positions, positions);
}

/// Renders one workflow run's jobs as a pannable left-to-right DAG (nodes +
/// bezier edges from `needs`), modelled on the pipeline run canvas. Tapping a
/// node reports it via [onSelect]; the selected node's steps render below the
/// graph (owned by the caller).
class WorkflowRunCanvas extends ConsumerStatefulWidget {
  /// Creates a [WorkflowRunCanvas].
  const WorkflowRunCanvas({
    super.key,
    required this.nodes,
    required this.checkRunsByNodeId,
    required this.selectedNodeId,
    required this.onSelect,
  });

  /// Graph job nodes (from the parsed workflow YAML).
  final List<WorkflowJobNode> nodes;

  /// Node id → the check runs matched to that node (matrix jobs match
  /// several children).
  final Map<String, List<CheckRun>> checkRunsByNodeId;

  /// Currently selected node id, if any.
  final String? selectedNodeId;

  /// Called when a node is tapped.
  final ValueChanged<String> onSelect;

  /// Node tile width.
  static const double nodeWidth = 180;

  /// Node tile height.
  static const double nodeHeight = 68;

  @override
  ConsumerState<WorkflowRunCanvas> createState() => _WorkflowRunCanvasState();
}

class _WorkflowRunCanvasState extends ConsumerState<WorkflowRunCanvas> {
  late Map<String, Offset> _layout;
  Rect _bounds = Rect.zero;

  @override
  void initState() {
    super.initState();
    _resolveLayout();
  }

  @override
  void didUpdateWidget(WorkflowRunCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.nodes, widget.nodes)) {
      _resolveLayout();
    }
  }

  void _resolveLayout() {
    _layout = WorkflowGraphLayout.compute(
      widget.nodes,
      nodeWidth: WorkflowRunCanvas.nodeWidth,
      nodeHeight: WorkflowRunCanvas.nodeHeight,
    );
    Rect? bounds;
    for (final position in _layout.values) {
      final rect =
          position &
          const Size(WorkflowRunCanvas.nodeWidth, WorkflowRunCanvas.nodeHeight);
      bounds = bounds?.expandToInclude(rect) ?? rect;
    }
    _bounds = bounds ?? Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return GraphCanvasViewport(
      bounds: _bounds,
      sceneBuilder: (shift) => Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: WorkflowEdgesPainter(
                    nodes: widget.nodes,
                    positions: _layout,
                    color: tokens.borderSecondary,
                    nodeWidth: WorkflowRunCanvas.nodeWidth,
                    nodeHeight: WorkflowRunCanvas.nodeHeight,
                    offset: shift,
                  ),
                ),
              ),
            ),
          ),
          for (final node in widget.nodes)
            _buildNode(node, tokens, shift, _layout[node.id]),
        ],
      ),
    );
  }

  Widget _buildNode(
    WorkflowJobNode node,
    DesignSystemTokens tokens,
    Offset translate,
    Offset? layoutPosition,
  ) {
    final l10n = AppLocalizations.of(context);
    final selected = node.id == widget.selectedNodeId;
    final position = (layoutPosition ?? Offset.zero) + translate;
    final runs = widget.checkRunsByNodeId[node.id] ?? const <CheckRun>[];
    final status = workflowNodeStatus(runs);
    final sc = _statusColors(status, tokens);
    final title = workflowNodeTitle(
      node,
      runs,
      matrixLabel: l10n.matrixJobLabel,
    );

    final statusWord = switch (status) {
      WorkflowStatus.running => l10n.running,
      WorkflowStatus.success => l10n.passed,
      WorkflowStatus.failure => l10n.failed,
      WorkflowStatus.neutral => l10n.neutral,
    };
    // Subtitle: a matrix node carries its child count.
    final subtitle = runs.length > 1 ? l10n.graphJobsCount(runs.length) : null;
    // Trailing meta: the node's duration (longest child — a matrix's wall
    // clock ≈ its slowest variation), falling back to the status word when
    // no timing was reported.
    final duration = _nodeDuration(runs);
    final trailing = duration != null
        ? formatPipelineDuration(duration)
        : statusWord;

    return Positioned(
      key: ValueKey(node.id),
      left: position.dx,
      top: position.dy,
      width: WorkflowRunCanvas.nodeWidth,
      height: WorkflowRunCanvas.nodeHeight,
      child: RepaintBoundary(
        child: Semantics(
          button: true,
          selected: selected,
          label: title,
          value: statusWord,
          child: CcTappable(
            onPressed: () => widget.onSelect(node.id),
            builder: (context, states) => GraphNodeCard(
              glyph: _statusGlyph(status, sc.dot),
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              trailingColor: duration == null ? sc.foreground : null,
              selected: selected,
              hovered: states.contains(WidgetState.hovered),
            ),
          ),
        ),
      ),
    );
  }

  /// The node's duration: the longest child duration (a matrix's wall clock
  /// is its slowest variation), live-ticking while a child runs. Null when
  /// no child reported a start.
  Duration? _nodeDuration(List<CheckRun> runs) {
    Duration? best;
    for (final r in runs) {
      final d = checkRunDuration(r);
      if (d != null && (best == null || d > best)) {
        best = d;
      }
    }
    return best;
  }

  /// Status indicator for a node: a spinner while running, otherwise a glyph,
  /// so job state reads by shape and not color alone (Status-Never-Alone).
  Widget _statusGlyph(WorkflowStatus status, Color color) {
    if (status == WorkflowStatus.running) {
      return CcSpinner(size: 14, color: color);
    }
    final icon = switch (status) {
      WorkflowStatus.success => AppIcons.checkCircle2,
      WorkflowStatus.failure => AppIcons.xCircle,
      _ => AppIcons.minusCircle,
    };
    return Icon(icon, size: 14, color: color);
  }

  /// Node color set keyed on the roll-up: the glyph dot and the status-word
  /// foreground (the card surface itself stays quiet — see [GraphNodeCard]).
  ({Color dot, Color foreground}) _statusColors(
    WorkflowStatus status,
    DesignSystemTokens tokens,
  ) {
    return switch (status) {
      WorkflowStatus.success => (
        dot: ReviewStatusColors.success,
        foreground: ReviewStatusColors.success,
      ),
      WorkflowStatus.failure => (
        dot: ReviewStatusColors.failure,
        foreground: ReviewStatusColors.failure,
      ),
      WorkflowStatus.running => (
        dot: ReviewStatusColors.running,
        foreground: ReviewStatusColors.running,
      ),
      WorkflowStatus.neutral => (
        dot: tokens.fgQuaternary,
        foreground: tokens.textTertiary,
      ),
    };
  }
}
