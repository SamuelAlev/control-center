import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// How long a reveal travels, open or shut.
///
/// Both directions share it, and the curve, so switching spaces is one
/// gesture: the card being left and the card being opened finish on the same
/// frame and the rows below slide by the height difference, smoothly.
const Duration kSpaceRevealDuration = CcMotion.slow;

/// Decelerating: most of the travel happens in the first frames, so the
/// press reads as answered at once, then the rows settle.
const Curve _kRevealCurve = CcMotion.emphasized;

/// The most one frame may advance the reveal: one 60Hz slice. At 120Hz a
/// frame is well under it; a hitch pauses the motion instead of jumping it.
const Duration _kMaxFrameStep = Duration(microseconds: 16667);

/// Clips [child] open and shut from the top.
///
/// Header and revealed child each sit on a [RepaintBoundary], so the clip
/// moves as a layer. The travel runs on its own clock: every frame advances
/// it by the real frame time, capped at one 60Hz slice, so it is as smooth
/// as the display (120Hz on ProMotion) and a late frame never spends its
/// stall on the clip.
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

  /// The child captured when a close starts. Null once the height is zero
  /// or the panel is open again.
  Widget? _closing;

  Ticker? _clock;
  Duration? _stamp;

  /// Clamped time spent on the current run.
  var _travelled = Duration.zero;

  /// Height factor the current run started from, and the one it ends at.
  var _from = 0.0;
  var _to = 0.0;
  var _snapScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kSpaceRevealDuration,
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
    _clock?.stop();
    _stamp = null;
    if (CcMotion.reduced(context)) {
      _closing = null;
      _controller.value = forward ? 1 : 0;
      return;
    }
    // A reversal mid-flight starts from where the clip is, so it never
    // jumps; the full duration from there keeps the pair in step.
    _from = _controller.value;
    _to = forward ? 1 : 0;
    _travelled = Duration.zero;
    _clock ??= createTicker(_tick);
    _clock!.start();
  }

  void _tick(Duration elapsed) {
    final previous = _stamp;
    _stamp = elapsed;
    if (previous == null || !mounted) {
      return;
    }
    var step = elapsed - previous;
    if (step <= Duration.zero) {
      return;
    }
    if (step > _kMaxFrameStep) {
      step = _kMaxFrameStep;
    }
    _travelled += step;
    final t = math.min(
      1.0,
      _travelled.inMicroseconds / kSpaceRevealDuration.inMicroseconds,
    );
    if (t >= 1) {
      _clock?.stop();
      _stamp = null;
      _controller.value = _to;
      return;
    }
    _controller.value = _from + (_to - _from) * _kRevealCurve.transform(t);
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
          child: IgnorePointer(ignoring: !widget.open, child: child),
        ),
      ),
    );
  }
}
