import 'dart:collection';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_ghost.dart';
import 'package:flutter/rendering.dart' show PipelineOwner, RenderProxyBox;
import 'package:flutter/widgets.dart';

/// A released tab's glide from where it was let go into the slot it ends up
/// in — the settle Flutter's reorderable lists do, for a drag that may also
/// have crossed panes.
///
/// Draggable drops its feedback the instant the pointer lifts, and the layout
/// mutation lands the tab in its new strip the same frame. Without this the
/// ghost would vanish and the tab pop in somewhere else. Instead a copy of the
/// face takes off from the ghost's last position in the root overlay, while
/// the real tab — wherever it was built: reordered in place, moved into
/// another pane, the first tab of a fresh split, or back home on a cancel —
/// claims the landing through [EditorTabLandingSlot] and stays invisible until
/// the copy reaches it. The target is resolved at paint time, so the flight
/// homes on a slot that is itself still sliding into place.
class EditorTabLanding extends ChangeNotifier {
  EditorTabLanding._(this.tab);

  static final Map<EditorTab, EditorTabLanding> _active =
      LinkedHashMap.identity();

  /// The landing in flight for [tab], or null.
  static EditorTabLanding? of(EditorTab tab) => _active[tab];

  /// Launches [session]'s tab from its ghost's last position. Skipped under
  /// reduced motion (the tab simply appears where it landed) and where no
  /// overlay exists.
  static void fly(BuildContext context, EditorTabDragSession session) {
    if (CcMotion.reduced(context)) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _active[session.tab]?._finish();
    final landing = EditorTabLanding._(session.tab);
    _active[session.tab] = landing;
    final entry = OverlayEntry(
      // The placement never hit-tests, so the flight cannot take a click.
      builder: (_) => _Flight(
        landing: landing,
        from: session.lastTopLeft,
        size: session.size,
        face: session.face,
        // A drop on a strip travels a few pixels; a drop on a pane travels
        // from mid-body up into a strip and earns the longer token.
        duration: session.lane != null ? CcMotion.moderate : CcMotion.slow,
        inLane: session.lane != null ? 1 : 0,
      ),
    );
    landing._entry = entry;
    overlay.insert(entry);
  }

  /// The tab this landing carries.
  final EditorTab tab;

  OverlayEntry? _entry;
  RenderBox? _target;
  bool _done = false;

  /// Whether the flight is still in the air.
  bool get inFlight => !_done;

  void _claim(RenderBox box) => _target = box;

  void _release(RenderBox box) {
    if (identical(_target, box)) {
      _target = null;
    }
  }

  /// The claimed slot's global top-left, when it is on screen.
  Offset? get _targetTopLeft {
    final box = _target;
    if (box == null || !box.attached || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero);
  }

  void _finish() {
    if (_done) {
      return;
    }
    _done = true;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    if (identical(_active[tab], this)) {
      _active.remove(tab);
    }
    notifyListeners();
  }

  /// The overlay went away under the flight (the app tree is being torn
  /// down): forget the landing without touching an overlay mid-unmount, and
  /// without notifying a slot that is likely unmounting too.
  void _abandon() {
    _done = true;
    _entry = null;
    if (identical(_active[tab], this)) {
      _active.remove(tab);
    }
  }
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.landing,
    required this.from,
    required this.size,
    required this.face,
    required this.duration,
    required this.inLane,
  });

  final EditorTabLanding landing;
  final Offset from;
  final Size size;
  final Widget face;
  final Duration duration;
  final double inLane;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);

  @override
  void initState() {
    super.initState();
    _t.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) {
      widget.landing._finish();
    }
  }

  Offset _place(Offset _) {
    final t = CcMotion.emphasized.transform(_t.value);
    final target = widget.landing._targetTopLeft;
    // Nowhere to land (the tab closed, or its strip scrolled it away): set
    // down where it was let go and fade out instead.
    return target == null ? widget.from : Offset.lerp(widget.from, target, t)!;
  }

  @override
  void dispose() {
    if (widget.landing.inFlight) {
      widget.landing._abandon();
    }
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RTL carve-out: the flight lives in overlay viewport coordinates; the
    // placement paints it at a global point, whatever the reading direction.
    return Positioned(
      left: 0,
      top: 0,
      child: EditorGlobalPlacement(
        place: _place,
        repaint: _t,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, child) {
            final t = CcMotion.standard.transform(_t.value);
            return Opacity(
              opacity: widget.landing._targetTopLeft == null ? 1 - t : 1,
              child: editorTabLiftedFace(
                context: context,
                face: child!,
                size: widget.size,
                // Set down: the lift drains away as the tab reaches its slot.
                shadow: editorTabShadow(1 - t, widget.inLane),
              ),
            );
          },
          child: widget.face,
        ),
      ),
    );
  }
}

/// Wraps the visible face of [tab] in its strip. While a landing for [tab] is
/// in flight the slot claims it as the flight's destination and paints
/// nothing (layout, semantics and hit testing are unchanged), so the tab
/// appears exactly when the flying copy arrives.
class EditorTabLandingSlot extends StatefulWidget {
  /// Creates an [EditorTabLandingSlot].
  const EditorTabLandingSlot({
    super.key,
    required this.tab,
    required this.child,
  });

  /// The tab whose face this slot shows.
  final EditorTab tab;

  /// The tab's face.
  final Widget child;

  @override
  State<EditorTabLandingSlot> createState() => _EditorTabLandingSlotState();
}

class _EditorTabLandingSlotState extends State<EditorTabLandingSlot> {
  EditorTabLanding? _landing;

  void _sync() {
    final next = EditorTabLanding.of(widget.tab);
    if (identical(next, _landing)) {
      return;
    }
    _landing?.removeListener(_onLanded);
    _landing = next;
    _landing?.addListener(_onLanded);
  }

  void _onLanded() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _landing?.removeListener(_onLanded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Looked up on every build: the landing is registered at release, before
    // the rebuild that puts the tab in its new slot.
    _sync();
    final landing = _landing;
    if (landing == null || !landing.inFlight) {
      return widget.child;
    }
    return _LandingMarker(
      landing: landing,
      child: Opacity(
        opacity: 0,
        alwaysIncludeSemantics: true,
        child: widget.child,
      ),
    );
  }
}

class _LandingMarker extends SingleChildRenderObjectWidget {
  const _LandingMarker({required this.landing, required super.child});

  final EditorTabLanding landing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLandingMarker(landing);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLandingMarker renderObject,
  ) {
    renderObject.landing = landing;
  }
}

class _RenderLandingMarker extends RenderProxyBox {
  _RenderLandingMarker(this._landing);

  EditorTabLanding _landing;
  set landing(EditorTabLanding value) {
    if (identical(value, _landing)) {
      return;
    }
    _landing._release(this);
    _landing = value;
    if (attached) {
      _landing._claim(this);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _landing._claim(this);
  }

  @override
  void detach() {
    _landing._release(this);
    super.detach();
  }
}
