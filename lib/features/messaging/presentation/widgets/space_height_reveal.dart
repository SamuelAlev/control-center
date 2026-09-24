import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Pixel speed of the reveal, matched to the sidebar wash: a row of travel
/// in [CcMotion.fast] is about a pixel per millisecond.
const double _kRevealPxPerMs = 1;

/// One 60Hz slice. A late frame keeps this instead of spending the hitch on
/// the clip, which is what deletes a whole conversation between paints.
const double _kRevealMaxPxPerFrame = 16;

/// Clips [child] open and shut from the top.
///
/// Header and revealed child each sit on a [RepaintBoundary], so the clip
/// moves as a layer. The travel is paced in pixels, not a fixed duration: a
/// tall list would otherwise drop a whole row between frames. A hitch does
/// not get added to the next step.
///
/// The widget has to stay in the tree while closed. A space that mounts its
/// panel already open has no previous height to grow from, so switching from
/// space A to space B only animates when both cards were already built: A
/// reverses, B forwards.
///
/// A close keeps the last open child mounted until the height reaches zero.
/// Swapping in an empty box would collapse a gap after the rows had already
/// vanished. Reduced motion snaps, including a change of preference
/// mid-flight.
class SpaceHeightReveal extends StatefulWidget {
  /// Creates a [SpaceHeightReveal].
  const SpaceHeightReveal({
    super.key,
    required this.open,
    required this.child,
    this.header,
    this.selected = false,
    this.fillColor,
  });

  /// Whether [child] should be fully expanded.
  final bool open;

  /// The panel that grows and shrinks. Ignored while a close is in flight;
  /// the reveal keeps the child from the last open frame.
  final Widget child;

  /// Stays at full height above the clipping panel. The space title.
  final Widget? header;

  /// Paints [fillColor] while the card is the open space, and through the
  /// close, so the surface shrinks with the list instead of blinking off.
  final bool selected;

  /// Card color for the open space. Null paints nothing.
  final Color? fillColor;

  @override
  State<SpaceHeightReveal> createState() => _SpaceHeightRevealState();
}

class _SpaceHeightRevealState extends State<SpaceHeightReveal>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  final _panelKey = GlobalKey();

  /// The child captured when a close starts. Null once the height is zero
  /// or the panel is open again.
  Widget? _closing;

  Ticker? _clock;
  Duration? _stamp;
  var _towardOpen = false;
  var _token = 0;
  var _snapScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CcMotion.moderate,
      value: widget.open ? 1 : 0,
    );
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || _closing == null || !mounted) {
      return;
    }
    setState(() => _closing = null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A preference change mid-flight has to rebuild after this method.
    // Clearing the frozen child here leaves it mounted at height zero.
    // A close that has not started its clock yet is still in flight.
    final target = widget.open ? 1.0 : 0.0;
    final settled =
        _controller.value == target &&
        _closing == null &&
        _clock?.isActive != true;
    if (!CcMotion.reduced(context) || settled || _snapScheduled) {
      return;
    }
    _snapScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _snapScheduled = false;
      if (!mounted || !CcMotion.reduced(context)) {
        return;
      }
      _clock?.stop();
      _stamp = null;
      setState(() {
        _closing = null;
        _controller.value = widget.open ? 1 : 0;
      });
    });
  }

  @override
  void didUpdateWidget(SpaceHeightReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open) {
      _closing = null;
      if (!oldWidget.open) {
        _run(forward: true);
      }
    } else if (oldWidget.open) {
      _closing = oldWidget.child;
      _run(forward: false);
    }
  }

  void _run({required bool forward}) {
    _towardOpen = forward;
    _clock?.stop();
    _stamp = null;
    if (CcMotion.reduced(context)) {
      _closing = null;
      _controller.value = forward ? 1 : 0;
      return;
    }
    // Start after this frame. The selection rebuild is what made the first
    // tick late, and the controller then skipped a row to catch up.
    final token = ++_token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _token || widget.open != forward) {
        return;
      }
      _clock ??= createTicker(_tick);
      _stamp = null;
      _clock!.start();
    });
  }

  void _tick(Duration elapsed) {
    final previous = _stamp;
    _stamp = elapsed;
    if (previous == null || !mounted) {
      return;
    }
    final dtMs = (elapsed - previous).inMicroseconds / 1000;
    if (dtMs <= 0) {
      return;
    }
    final px = _panelHeight();
    if (px < 1) {
      _controller.value = _towardOpen ? 1 : 0;
      _clock?.stop();
      _stamp = null;
      return;
    }
    final pxStep = math.min(_kRevealMaxPxPerFrame, dtMs * _kRevealPxPerMs);
    final step = pxStep / px;
    final next = _towardOpen
        ? math.min(1.0, _controller.value + step)
        : math.max(0.0, _controller.value - step);
    if (next == (_towardOpen ? 1.0 : 0.0)) {
      _clock?.stop();
      _stamp = null;
    }
    _controller.value = next;
  }

  double _panelHeight() {
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return 0;
    }
    return box.size.height;
  }

  @override
  void dispose() {
    _clock?.dispose();
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revealed = _revealed();
    if (widget.header == null && widget.fillColor == null) {
      return revealed;
    }
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) RepaintBoundary(child: widget.header!),
        revealed,
      ],
    );
    final fill = widget.fillColor;
    if (fill == null) {
      return column;
    }
    // Stable wrapper: inserting the box only while selected would remount
    // the title row and drop its in-flight inset animation.
    final showFill = widget.selected || _closing != null;
    return ColoredBox(
      color: showFill ? fill : const Color(0x00000000),
      child: column,
    );
  }

  Widget _revealed() {
    final child = widget.open ? widget.child : _closing;
    if (child == null) {
      return const SizedBox(width: double.infinity, height: 0);
    }
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, clipped) {
          return Align(
            alignment: AlignmentDirectional.topCenter,
            heightFactor: _controller.value.clamp(0.0, 1.0).toDouble(),
            child: clipped,
          );
        },
        child: RepaintBoundary(
          key: _panelKey,
          child: IgnorePointer(ignoring: !widget.open, child: child),
        ),
      ),
    );
  }
}
