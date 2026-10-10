import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart';

/// Fraction of the pane (per edge) within which a drop splits rather than moves.
const double _edgeBand = 0.25;

/// Resolves where a tab dropped at [local] within a pane of [size] should land.
///
/// The pane is divided into four edge bands ([_edgeBand] deep) and a center. A
/// drop nearest an edge (and within its band) splits toward that edge; anywhere
/// else (including the middle and corners outside every band) is a move into
/// the pane ([DropEdge.center]). Corners resolve to whichever edge is closest.
DropEdge computeDropEdge(Offset local, Size size) {
  if (size.width <= 0 || size.height <= 0) {
    return DropEdge.center;
  }
  final fx = (local.dx / size.width).clamp(0.0, 1.0);
  final fy = (local.dy / size.height).clamp(0.0, 1.0);
  final dLeft = fx;
  final dRight = 1 - fx;
  final dTop = fy;
  final dBottom = 1 - fy;
  final nearest = [dLeft, dRight, dTop, dBottom].reduce(math.min);
  if (nearest > _edgeBand) {
    return DropEdge.center;
  }
  if (nearest == dLeft) {
    return DropEdge.left;
  }
  if (nearest == dRight) {
    return DropEdge.right;
  }
  if (nearest == dTop) {
    return DropEdge.top;
  }
  return DropEdge.bottom;
}

/// A translucent preview of the region a dragged tab will occupy on drop.
///
/// Shows the half (or full pane, for a center move) that the resolved [edge]
/// targets, sliding between regions as the pointer crosses bands. When the
/// drag leaves, the preview fades out where it was rather than sliding back
/// to the full pane. Always non-interactive — it sits above the pane body
/// purely as feedback.
class EditorDropOverlay extends StatefulWidget {
  /// Creates an [EditorDropOverlay].
  const EditorDropOverlay({super.key, required this.edge, this.snap = false});

  /// The resolved drop target, or null when no drag is hovering this pane.
  final DropEdge? edge;

  /// Hide at once instead of fading: the drop was just accepted and
  /// [EditorPaneLandingWash] takes over the same look on the pane the tab
  /// landed in, so a fading preview would double it.
  final bool snap;

  @override
  State<EditorDropOverlay> createState() => _EditorDropOverlayState();
}

class _EditorDropOverlayState extends State<EditorDropOverlay> {
  /// The region last previewed, held while the preview fades out.
  DropEdge? _shown;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final edge = widget.edge;
    final region = edge ?? _shown;
    final duration = widget.snap
        ? Duration.zero
        : CcMotion.resolve(context, CcMotion.fast);
    final fade = widget.snap
        ? Duration.zero
        : CcMotion.resolveFade(
            context,
            edge == null ? CcMotion.fastExit : CcMotion.fast,
          );
    // A fresh drag starts from where it enters, not from where the previous
    // one left the preview.
    final travel = _shown == null ? Duration.zero : duration;
    _shown = edge ?? (widget.snap ? null : _shown);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rect = _regionFor(
            region,
            constraints.maxWidth,
            constraints.maxHeight,
          );
          return Stack(
            children: [
              AnimatedPositioned(
                duration: travel,
                curve: CcMotion.standard,
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: AnimatedOpacity(
                  duration: fade,
                  curve: CcMotion.standard,
                  opacity: edge == null ? 0 : 1,
                  onEnd: () {
                    if (widget.edge == null && _shown != null) {
                      setState(() => _shown = null);
                    }
                  },
                  child: _DropRegion(tokens: t),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Rect _regionFor(DropEdge? edge, double w, double h) {
    switch (edge) {
      case null:
      case DropEdge.center:
        return Rect.fromLTWH(0, 0, w, h);
      case DropEdge.left:
        return Rect.fromLTWH(0, 0, w / 2, h);
      case DropEdge.right:
        return Rect.fromLTWH(w / 2, 0, w / 2, h);
      case DropEdge.top:
        return Rect.fromLTWH(0, 0, w, h / 2);
      case DropEdge.bottom:
        return Rect.fromLTWH(0, h / 2, w, h / 2);
    }
  }
}

/// The drop-preview look: an accent wash inside a 2px accent rim.
class _DropRegion extends StatelessWidget {
  const _DropRegion({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        border: Border.all(color: tokens.accent, width: 2),
      ),
    );
  }
}

// Which pane a dropped tab just landed in, for [EditorPaneLandingWash].
//
// A drop on a pane body either moves the tab into that pane or splits it,
// and in the split case the receiving pane does not exist yet when the drop
// is accepted — it mounts in the next frame. So the drop records the pane
// here, and the pane's wash claims it when it builds. A mark lives for one
// frame: whatever has not claimed it by then is not landing now.
final ValueNotifier<_PaneMark?> _paneMark = ValueNotifier(null);
int _paneMarkSeq = 0;

/// Records that a dropped tab landed in [leafId] of [layout].
void markEditorPaneLanding(Object layout, String leafId) {
  final mark = _PaneMark(layout, leafId, ++_paneMarkSeq);
  _paneMark.value = mark;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (identical(_paneMark.value, mark)) {
      _paneMark.value = null;
    }
  });
  SchedulerBinding.instance.scheduleFrame();
}

class _PaneMark {
  _PaneMark(this.layout, this.leafId, this.seq);

  final Object layout;
  final String leafId;
  final int seq;
}

/// The settle after a drop on a pane body: the drop preview's wash, now
/// covering the pane the tab landed in — the new half of a split, or the
/// whole pane for a move — fades out, so the preview reads as having become
/// the pane. A state-signaling fade, so it survives reduced motion at the
/// short fade token.
class EditorPaneLandingWash extends StatefulWidget {
  /// Creates an [EditorPaneLandingWash] for [leafId] of [layout].
  const EditorPaneLandingWash({
    super.key,
    required this.layout,
    required this.leafId,
  });

  /// The layout controller owning the pane (leaf ids are only unique within
  /// one controller).
  final Object layout;

  /// The pane's leaf id.
  final String leafId;

  @override
  State<EditorPaneLandingWash> createState() => _EditorPaneLandingWashState();
}

class _EditorPaneLandingWashState extends State<EditorPaneLandingWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wash = AnimationController(vsync: this);
  int _played = -1;

  @override
  void initState() {
    super.initState();
    _paneMark.addListener(_check);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A split's new pane mounts in the frame after the drop marked it.
    _check();
  }

  void _check() {
    final mark = _paneMark.value;
    if (!mounted ||
        mark == null ||
        mark.seq == _played ||
        !identical(mark.layout, widget.layout) ||
        mark.leafId != widget.leafId) {
      return;
    }
    _played = mark.seq;
    _wash.duration = CcMotion.resolveFade(context, CcMotion.slow);
    _wash.forward(from: 0);
  }

  @override
  void dispose() {
    _paneMark.removeListener(_check);
    _wash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _wash,
        builder: (context, child) {
          if (!_wash.isAnimating) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: 1 - CcMotion.standard.transform(_wash.value),
            child: child,
          );
        },
        child: _DropRegion(tokens: t),
      ),
    );
  }
}
