import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_graph_layout.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_node_visuals.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Node geometry — shared by the layout, the tiles and the edge painter.
///
/// Sized for the content plan nodes actually carry: titles are sentence-shaped
/// task names ("Add partial staging (hunk/line) to Source Control tab"), so the
/// tile is wide enough to run two lines of them above a meta row and an estimate
/// rather than clipping the title to one line inside a half-empty box.
const double _nodeWidth = 240;
const double _nodeHeight = 104;

/// How far past the graph bounds the canvas may be panned. Shared by the
/// viewer's own clamp and the wheel pan so both stop at the same place.
const double _boundaryMargin = 240;

/// An interactive, keyboard-first plan DAG canvas (PRD 17 §1).
///
/// Renders a [PlanGraph] with a deterministic layered layout, live per-node
/// state (icon + label, never colour alone), estimate badges and divergence
/// markers. Pans and zooms via [InteractiveViewer]. Every operation has a
/// keyboard path (acceptance bar: "every canvas edit is achievable
/// keyboard-only"): arrows move the selection along the DAG, `e` starts an
/// edge-connect, `x` cuts the selected node's newest dependency, `n` adds a
/// node, Delete removes the selected work node. Edits are gated to
/// [editable]; already-executed nodes are read-only.
class PlanCanvas extends StatefulWidget {
  /// Creates a [PlanCanvas].
  const PlanCanvas({
    super.key,
    required this.graph,
    required this.selectedKey,
    required this.onSelect,
    required this.runStateOf,
    this.estimateOf,
    this.divergedKeys = const {},
    this.readOnlyKeys = const {},
    this.editable = false,
    this.onConnect,
    this.onDisconnect,
    this.onAddNode,
    this.onDeleteNode,
  });

  /// The graph to render.
  final PlanGraph graph;

  /// The selected node key, or null.
  final String? selectedKey;

  /// Called when a node is selected (tap or keyboard).
  final ValueChanged<String> onSelect;

  /// Resolves a node's live run state.
  final PlanNodeRunState Function(String nodeKey) runStateOf;

  /// Resolves a node's estimate badge, or null.
  final PlanNodeEstimate? Function(String nodeKey)? estimateOf;

  /// Keys carrying a divergence marker (PRD 17 §6).
  final Set<String> divergedKeys;

  /// Keys whose step already ran — editing forks the plan, so the canvas
  /// blocks structural edits on them and marks them.
  final Set<String> readOnlyKeys;

  /// Whether structural edits (connect/cut/add/delete) are allowed.
  final bool editable;

  /// Adds a `from → to` dependency (to depends on from).
  final void Function(String from, String to)? onConnect;

  /// Removes a `from → to` dependency.
  final void Function(String from, String to)? onDisconnect;

  /// Adds a new work node (the caller opens naming UI).
  final VoidCallback? onAddNode;

  /// Deletes a work node.
  final ValueChanged<String>? onDeleteNode;

  @override
  State<PlanCanvas> createState() => _PlanCanvasState();
}

class _PlanCanvasState extends State<PlanCanvas> {
  final FocusNode _focus = FocusNode(debugLabel: 'plan-canvas');
  final TransformationController _transform = TransformationController();
  late final CanvasWheelPan _wheelPan = CanvasWheelPan(_transform);

  /// The viewport, captured by the canvas [LayoutBuilder] so the zoom controls
  /// can scale about its centre.
  Size _viewport = Size.zero;

  /// When non-null, a connect-edge gesture is in progress from this node; the
  /// next selected node becomes the dependency source.
  String? _connectFrom;

  @override
  void dispose() {
    _focus.dispose();
    _transform.dispose();
    super.dispose();
  }

  Map<String, Offset> get _positions => PlanGraphLayout.compute(
    widget.graph,
    nodeWidth: _nodeWidth,
    nodeHeight: _nodeHeight,
  );

  Size _canvasSize(Map<String, Offset> positions) {
    var maxX = 0.0;
    var maxY = 0.0;
    var minY = 0.0;
    for (final p in positions.values) {
      maxX = p.dx > maxX ? p.dx : maxX;
      maxY = p.dy > maxY ? p.dy : maxY;
      minY = p.dy < minY ? p.dy : minY;
    }
    return Size(maxX + _nodeWidth + 80, (maxY - minY) + _nodeHeight + 80);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final selected = widget.selectedKey;
    final positions = _positions;

    // Directional selection movement along the layout.
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final next = _neighbour(selected, key, positions);
      if (next != null) {
        widget.onSelect(next);
      }
      return KeyEventResult.handled;
    }
    if (selected == null) {
      return KeyEventResult.ignored;
    }
    // `e` — begin/complete a connect-edge.
    if (key == LogicalKeyboardKey.keyE && widget.editable) {
      if (_connectFrom == null) {
        setState(() => _connectFrom = selected);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && _connectFrom != null) {
      final from = _connectFrom!;
      if (from != selected && widget.editable) {
        widget.onConnect?.call(from, selected);
      }
      setState(() => _connectFrom = null);
      return KeyEventResult.handled;
    }
    // `x` — cut the selected node's newest inbound dependency.
    if (key == LogicalKeyboardKey.keyX && widget.editable) {
      final node = widget.graph.node(selected);
      if (node != null && node.dependsOn.isNotEmpty) {
        widget.onDisconnect?.call(node.dependsOn.last, selected);
      }
      return KeyEventResult.handled;
    }
    // `n` — add a node.
    if (key == LogicalKeyboardKey.keyN && widget.editable) {
      widget.onAddNode?.call();
      return KeyEventResult.handled;
    }
    // Delete — remove the selected work node.
    if ((key == LogicalKeyboardKey.delete ||
            key == LogicalKeyboardKey.backspace) &&
        widget.editable) {
      final node = widget.graph.node(selected);
      if (node != null &&
          node.isWork &&
          !widget.readOnlyKeys.contains(selected)) {
        widget.onDeleteNode?.call(selected);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _connectFrom != null) {
      setState(() => _connectFrom = null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The nearest node in the arrow direction, by centre geometry.
  String? _neighbour(
    String? from,
    LogicalKeyboardKey dir,
    Map<String, Offset> positions,
  ) {
    if (positions.isEmpty) {
      return null;
    }
    if (from == null) {
      // Pick the top-left node.
      final entries = positions.entries.toList()
        ..sort((a, b) {
          final byX = a.value.dx.compareTo(b.value.dx);
          return byX != 0 ? byX : a.value.dy.compareTo(b.value.dy);
        });
      return entries.first.key;
    }
    final origin = positions[from];
    if (origin == null) {
      return positions.keys.first;
    }
    final horizontal =
        dir == LogicalKeyboardKey.arrowRight ||
        dir == LogicalKeyboardKey.arrowLeft;
    final forward =
        dir == LogicalKeyboardKey.arrowRight ||
        dir == LogicalKeyboardKey.arrowDown;
    String? best;
    var bestScore = double.infinity;
    for (final e in positions.entries) {
      if (e.key == from) {
        continue;
      }
      final d = e.value - origin;
      final primary = horizontal ? d.dx : d.dy;
      final cross = horizontal ? d.dy : d.dx;
      if (forward ? primary <= 0 : primary >= 0) {
        continue;
      }
      // Prefer the closest node in the travel axis, penalizing cross drift.
      final score = primary.abs() + cross.abs() * 2;
      if (score < bestScore) {
        bestScore = score;
        best = e.key;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final positions = _positions;
    final size = _canvasSize(positions);
    // Shift so the topmost node sits at y = 40 (positions are centred on 0).
    var minY = 0.0;
    for (final p in positions.values) {
      minY = p.dy < minY ? p.dy : minY;
    }
    final shift = Offset(40, 40 - minY);

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: _focus.requestFocus,
        child: Stack(
          // Both layers fill the viewport: the grid must not stop at the graph
          // bounds and the viewer must not size itself to its unbounded child.
          fit: StackFit.expand,
          children: [
            // The backdrop every node canvas in the app shares (pipelines, the
            // memory knowledge graph). Painted outside the viewer and driven off
            // the transform so it fills the viewport rather than stopping at the
            // graph bounds and rebuilt on its own so panning does not
            // invalidate the tiles.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _transform,
                builder: (context, _) {
                  final m = _transform.value;
                  return DotGridBackground(
                    offset: Offset(m.getTranslation().x, m.getTranslation().y),
                    scale: m.getMaxScaleOnAxis(),
                  );
                },
              ),
            ),
            LayoutBuilder(
              // The viewport size, needed to clamp a wheel pan the same way the
              // viewer clamps a drag.
              builder: (context, constraints) {
                _viewport = constraints.biggest;
                return Listener(
                  onPointerSignal: (event) => _wheelPan.onPointerSignal(
                    event,
                    viewport: constraints.biggest,
                    canvas: size,
                    boundaryMargin: _boundaryMargin,
                  ),
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: 0.4,
                    maxScale: 2.0,
                    boundaryMargin: const EdgeInsets.all(_boundaryMargin),
                    // Snapshots the transform before the viewer changes it — the
                    // wheel rewrite needs the pre-zoom matrix.
                    onInteractionStart: (_) => _wheelPan.beginInteraction(),
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PlanEdgePainter(
                                graph: widget.graph,
                                positions: positions,
                                shift: shift,
                                color: ds.lineStrong,
                                accent: ds.accent,
                                selectedKey: widget.selectedKey,
                                nodeWidth: _nodeWidth,
                                nodeHeight: _nodeHeight,
                              ),
                            ),
                          ),
                          for (final node in widget.graph.nodes)
                            if (positions[node.key] != null)
                              Positioned(
                                left: positions[node.key]!.dx + shift.dx,
                                top: positions[node.key]!.dy + shift.dy,
                                width: _nodeWidth,
                                height: _nodeHeight,
                                child: _PlanNodeTile(
                                  node: node,
                                  selected: node.key == widget.selectedKey,
                                  connectSource: node.key == _connectFrom,
                                  runState: widget.runStateOf(node.key),
                                  estimate: widget.estimateOf?.call(node.key),
                                  diverged: widget.divergedKeys.contains(
                                    node.key,
                                  ),
                                  readOnly: widget.readOnlyKeys.contains(
                                    node.key,
                                  ),
                                  onTap: () {
                                    _focus.requestFocus();
                                    if (_connectFrom != null &&
                                        _connectFrom != node.key &&
                                        widget.editable) {
                                      widget.onConnect?.call(
                                        _connectFrom!,
                                        node.key,
                                      );
                                      setState(() => _connectFrom = null);
                                    } else {
                                      widget.onSelect(node.key);
                                    }
                                  },
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Zoom is otherwise gesture-only, which is invisible on a trackpad
            // and impossible on a mouse without a modifier.
            Positioned(
              right: kCanvasControlInset,
              bottom: kCanvasControlInset,
              child: CanvasZoomControls(
                controller: _transform,
                viewport: () => _viewport,
                minScale: 0.4,
                maxScale: 2.0,
                onReset: () => _transform.value = Matrix4.identity(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanNodeTile extends StatelessWidget {
  const _PlanNodeTile({
    required this.node,
    required this.selected,
    required this.connectSource,
    required this.runState,
    required this.estimate,
    required this.diverged,
    required this.readOnly,
    required this.onTap,
  });

  final PlanNode node;
  final bool selected;
  final bool connectSource;
  final PlanNodeRunState runState;
  final PlanNodeEstimate? estimate;
  final bool diverged;
  final bool readOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final type = planNodeTypeVisual(node.type);
    final state = planNodeStateVisual(runState, ds);
    final borderColor = connectSource || selected
        ? ds.accent
        : diverged
        ? ds.textWarningPrimary
        : ds.borderPrimary;
    // A failed node is tinted (DESIGN.md, DAG nodes: "failed node tinted
    // danger-soft"). State outranks selection for the fill so a selected
    // failure still reads as failed; selection keeps the 2px accent ring.
    final fill = runState == PlanNodeRunState.failed
        ? ds.dangerSoft
        : selected
        ? ds.accentSoft
        : ds.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: fill,
          // Square, like every other surface in the system (all radius tokens
          // are 0); DESIGN.md specifies square DAG nodes.
          borderRadius: AppRadii.brMd,
          border: Border.all(
            color: borderColor,
            width: selected || connectSource ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    node.title.isEmpty ? node.key : node.title,
                    // Two lines: a plan title is a task sentence and clipping
                    // it to one loses the only thing the tile is for.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: ds.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                // Markers pair every colour cue with a shape, so the accent
                // ring and the warning border are never the sole signal.
                if (connectSource) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.link, size: 12, color: ds.accent),
                ],
                if (diverged) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.triangleAlert,
                    size: 12,
                    color: ds.textWarningPrimary,
                  ),
                ],
                if (readOnly) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.lock, size: 12, color: ds.textTertiary),
                ],
              ],
            ),
            const Spacer(),
            // Kind is always shown, so the meta row never renders empty on a
            // structural node with no run and no role.
            Row(
              children: [
                Icon(type.icon, size: 12, color: ds.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ds.textTertiary,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (state.label.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(state.icon, size: 12, color: state.color),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    state.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: state.color,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
                if (node.roleKey != null && node.roleKey!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      node.roleKey!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: ds.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            _EstimateBadge(estimate: estimate),
          ],
        ),
      ),
    );
  }
}

/// A compact, HONEST estimate badge (PRD 17 §3): a cost range with sample
/// size, or "no history yet" — never a fabricated point value.
class _EstimateBadge extends StatelessWidget {
  const _EstimateBadge({required this.estimate});

  final PlanNodeEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final e = estimate;
    final String text;
    if (e == null) {
      text = '';
    } else if (!e.hasHistory) {
      text = 'no history yet';
    } else {
      final lo = ((e.costCentsLow ?? 0) / 100).toStringAsFixed(2);
      final hi = ((e.costCentsHigh ?? 0) / 100).toStringAsFixed(2);
      final blast = e.blastRadiusFiles != null
          ? ' · ${e.blastRadiusFiles} files'
          : '';
      text = '\$$lo–$hi (n=${e.sampleSize})$blast';
    }
    if (text.isEmpty) {
      // Nothing to say: collapse rather than reserving a blank line, so the
      // meta row above it settles on the tile's bottom edge.
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// Draws cubic-bezier dependency edges behind the node tiles.
class _PlanEdgePainter extends CustomPainter {
  _PlanEdgePainter({
    required this.graph,
    required this.positions,
    required this.shift,
    required this.color,
    required this.accent,
    required this.selectedKey,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final PlanGraph graph;
  final Map<String, Offset> positions;
  final Offset shift;
  final Color color;
  final Color accent;
  final String? selectedKey;
  final double nodeWidth;
  final double nodeHeight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from == null || to == null) {
        continue;
      }
      final start = Offset(
        from.dx + shift.dx + nodeWidth,
        from.dy + shift.dy + nodeHeight / 2,
      );
      final end = Offset(to.dx + shift.dx, to.dy + shift.dy + nodeHeight / 2);
      final highlighted = edge.from == selectedKey || edge.to == selectedKey;
      final paint = Paint()
        ..color = highlighted ? accent : color
        ..strokeWidth = highlighted ? 2 : 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dx = (end.dx - start.dx).abs().clamp(40, 160) * 0.5;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + dx, start.dy, end.dx - dx, end.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
      // An arrowhead, not a dot: dependency edges are directed and the app's
      // other DAG surfaces (PipelineEdgesPainter) already terminate this way.
      const headLen = 8.0;
      final back = Offset(end.dx - headLen, end.dy);
      canvas.drawLine(end, back + const Offset(0, -4), paint);
      canvas.drawLine(end, back + const Offset(0, 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanEdgePainter old) =>
      old.positions != positions ||
      old.selectedKey != selectedKey ||
      old.graph != graph;
}
