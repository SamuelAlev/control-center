import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One editor-tab drag in flight, from pickup to release.
///
/// Created by the source `EditorTabBar`'s drag anchor (before the drag avatar
/// exists, so the very first hit test already sees it) and read by the ghost,
/// by every tab strip the drag crosses and, at release, by the landing flight.
/// One pointer drags one tab, so a single [current] session is enough — the
/// same shape as a hand on a mouse, not a piece of layout state.
class EditorTabDragSession extends ChangeNotifier {
  /// Creates an [EditorTabDragSession].
  EditorTabDragSession({
    required this.tab,
    required this.face,
    required this.grab,
    required this.size,
    required this.origin,
  });

  /// The drag currently in flight, or null between drags.
  static EditorTabDragSession? current;

  /// The tab being carried.
  final EditorTab tab;

  /// What the ghost (and later the landing flight) paints: the tab's own face.
  final Widget face;

  /// Where the pointer took hold of the tab, in the tab's local coordinates.
  /// The ghost keeps this point under the pointer, so the tab does not jump to
  /// hang off the cursor by its corner.
  final Offset grab;

  /// The tab cell's size at pickup.
  final Size size;

  /// The tab cell's global top-left at pickup.
  final Offset origin;

  Rect? _lane;
  Object? _laneOwner;

  /// Global rect of the tab strip the pointer is over, or null when the drag
  /// is over a pane body or nothing at all. While set, the ghost rides the
  /// strip instead of following the pointer freely.
  Rect? get lane => _lane;

  /// The strip that published [lane].
  Object? get laneOwner => _laneOwner;

  /// The ghost's last painted global top-left, or null before its first paint.
  Offset? ghostTopLeft;

  /// Where the ghost was last seen — the landing flight starts here.
  Offset get lastTopLeft => ghostTopLeft ?? origin;

  /// The pointer moved over [owner]'s strip, which covers [lane]. Notifies on
  /// every call (not only on change): a locked ghost repaints as the pointer
  /// slides along the strip.
  void enterLane(Object owner, Rect lane) {
    _laneOwner = owner;
    _lane = lane;
    notifyListeners();
  }

  /// The pointer left [owner]'s strip. A no-op when another strip has already
  /// claimed the lane (the avatar leaves the old target before it moves over
  /// the new one, but both happen inside one pointer event).
  void leaveLane(Object owner) {
    if (!identical(_laneOwner, owner)) {
      return;
    }
    _laneOwner = null;
    _lane = null;
    notifyListeners();
  }
}

/// The shadow a carried tab casts: a slight lift while it rides its strip,
/// the full floating shadow once it is torn out over the panes.
List<BoxShadow>? editorTabShadow(double lift, double inLane) =>
    BoxShadow.lerpList(
      null,
      BoxShadow.lerpList(CcElevation.floating, CcElevation.raised, inLane),
      lift,
    );

/// The tab-face decoration shared by the ghost and the landing flight: a
/// hairline all round (the face only draws its trailing edge) over [shadow].
Widget editorTabLiftedFace({
  required BuildContext context,
  required Widget face,
  required Size size,
  required List<BoxShadow>? shadow,
}) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  // Painted in the root overlay, so it brings its own complete text style
  // rather than inheriting the app's error fallback.
  return DefaultTextStyle(
    style: CcFonts.ui(
      textStyle: TextStyle(
        fontSize: 12,
        color: t.fg,
        decoration: TextDecoration.none,
      ),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(color: t.bgPrimary, boxShadow: shadow),
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: t.borderPrimary)),
        position: DecorationPosition.foreground,
        child: SizedBox.fromSize(size: size, child: face),
      ),
    ),
  );
}

/// The drag feedback for an editor tab: the tab itself, lifted.
///
/// Draggable positions its feedback with the pointer at the top-left (the bar
/// keeps the anchor at zero so every drop target still reads the pointer from
/// `details.offset`); this widget then paints the face so the grabbed point
/// stays under the pointer. Over a tab strip the face locks to that strip's
/// row and slides only along it, clamped to its ends; pulled off the strip it
/// eases free and follows the pointer in both axes — the tear-off. Reduced
/// motion snaps between the two.
class EditorTabGhost extends StatefulWidget {
  /// Creates an [EditorTabGhost] for [EditorTabDragSession.current].
  const EditorTabGhost({super.key});

  @override
  State<EditorTabGhost> createState() => _EditorTabGhostState();
}

class _EditorTabGhostState extends State<EditorTabGhost>
    with TickerProviderStateMixin {
  final EditorTabDragSession? _session = EditorTabDragSession.current;

  /// Lift on pickup: the shadow fades in under the face.
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: CcMotion.fast,
  );

  /// Travel between riding a strip and following the pointer. 1 = settled.
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: CcMotion.moderate,
    value: 1,
  );

  /// 1 while riding a strip, 0 while free; drives the shadow depth.
  late final AnimationController _inLane = AnimationController(
    vsync: this,
    duration: CcMotion.moderate,
  );

  /// Where the travel started from (global top-left), or null when settled.
  Offset? _from;
  Object? _owner;

  @override
  void initState() {
    super.initState();
    final session = _session;
    if (session != null) {
      _owner = session.laneOwner;
      _inLane.value = session.lane != null ? 1 : 0;
      session.addListener(_onSessionChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (CcMotion.reduced(context)) {
      _lift.value = 1;
    } else if (!_lift.isAnimating && _lift.value == 0) {
      _lift.forward();
    }
  }

  void _onSessionChanged() {
    final session = _session!;
    if (identical(session.laneOwner, _owner)) {
      return;
    }
    // The ghost changed lanes: torn out, dropped back onto a strip, or slid
    // straight across onto a neighbouring pane's strip. Travel from where it
    // was last painted to wherever the new lane puts it.
    _owner = session.laneOwner;
    final inLane = session.lane != null ? 1.0 : 0.0;
    if (CcMotion.reduced(context)) {
      _from = null;
      _travel.value = 1;
      _inLane.value = inLane;
      return;
    }
    _from = session.ghostTopLeft;
    _travel.forward(from: 0);
    _inLane.animateTo(inLane, curve: CcMotion.standard);
  }

  /// The global top-left to paint the face at, given the feedback's own global
  /// [origin] (which is the pointer: the drag anchor is zero).
  Offset _place(Offset origin) {
    final session = _session!;
    final free = origin - session.grab;
    final lane = session.lane;
    final target = lane == null
        ? free
        // RTL carve-out: physical viewport coordinates, not layout direction.
        : Offset(
            free.dx.clamp(
              lane.left,
              math.max(lane.left, lane.right - session.size.width),
            ),
            lane.top,
          );
    final from = _from;
    final t = CcMotion.emphasized.transform(_travel.value);
    final at = from == null || t >= 1 ? target : Offset.lerp(from, target, t)!;
    if (t >= 1) {
      _from = null;
    }
    session.ghostTopLeft = at;
    return at;
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _lift.dispose();
    _travel.dispose();
    _inLane.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return const SizedBox.shrink();
    }
    return EditorGlobalPlacement(
      place: _place,
      repaint: Listenable.merge([session, _travel]),
      child: AnimatedBuilder(
        animation: Listenable.merge([_lift, _inLane]),
        builder: (context, child) => editorTabLiftedFace(
          context: context,
          face: child!,
          size: session.size,
          shadow: editorTabShadow(
            CcMotion.standard.transform(_lift.value),
            _inLane.value,
          ),
        ),
        child: session.face,
      ),
    );
  }
}

/// Paints its child at the global top-left [place] returns for this box's own
/// global origin, resolved at paint time when every box on screen has been
/// laid out. Layout is untouched (the overlay keeps positioning the box);
/// only the paint, and the paint transform reported to descendants, are
/// shifted. Shared by the drag ghost (riding a strip) and the landing flight
/// (homing on a slot that may still be moving). Never takes the pointer.
class EditorGlobalPlacement extends SingleChildRenderObjectWidget {
  /// Creates an [EditorGlobalPlacement].
  const EditorGlobalPlacement({
    super.key,
    required this.place,
    required this.repaint,
    required super.child,
  });

  /// Resolves the global top-left to paint at from the box's global origin.
  final Offset Function(Offset origin) place;

  /// Repaints (and so re-resolves [place]) whenever it notifies.
  final Listenable repaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderGlobalPlacement(place, repaint);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGlobalPlacement renderObject,
  ) {
    renderObject
      ..place = place
      ..repaint = repaint;
  }
}

/// The render object behind [EditorGlobalPlacement].
class RenderGlobalPlacement extends RenderProxyBox {
  /// Creates a [RenderGlobalPlacement].
  RenderGlobalPlacement(this._place, this._repaint);

  Offset Function(Offset origin) _place;
  set place(Offset Function(Offset origin) value) {
    _place = value;
    markNeedsPaint();
  }

  Listenable _repaint;
  set repaint(Listenable value) {
    if (identical(value, _repaint)) {
      return;
    }
    if (attached) {
      _repaint.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _repaint = value;
    markNeedsPaint();
  }

  Offset _shift = Offset.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    final origin = localToGlobal(Offset.zero);
    _shift = _place(origin) - origin;
    context.paintChild(child, offset + _shift);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_shift.dx, _shift.dy, 0, 1);
  }

  // The ghost never takes the pointer; drop targets must see what is under it.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}
