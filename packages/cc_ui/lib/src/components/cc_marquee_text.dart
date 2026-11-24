import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:flutter/widgets.dart';

/// Single-line text that ellipsizes at rest and, while [active], travels once
/// to show the part the ellipsis hid.
///
/// For the secondary line of a row a person is on (the selected row of a
/// menu): the row keeps its height, and the whole sentence still gets read.
///
/// Accessibility:
///  - The motion is one pass, never a loop: after a short rest on the row the
///    text travels to its end, holds there, then returns to the ellipsis. It
///    stops the moment [active] goes false, so moving off the row is the stop.
///  - With reduced motion ([CcMotion.reduced]) nothing moves. The active text
///    wraps onto up to [reducedMotionLines] lines instead, so the sentence is
///    still readable; at the default of one line it stays ellipsized.
///  - Assistive technology always gets the whole [text] as one stable label,
///    whatever is on screen.
class CcMarqueeText extends StatefulWidget {
  /// Creates a [CcMarqueeText].
  const CcMarqueeText(
    this.text, {
    super.key,
    required this.active,
    this.style,
    this.startDelay = const Duration(milliseconds: 700),
    this.endHold = const Duration(milliseconds: 1500),
    this.velocity = 40,
    this.reducedMotionLines = 1,
  }) : assert(reducedMotionLines >= 1, 'at least one line');

  /// The text.
  final String text;

  /// Whether the row is the one a person is on. Text that fits never moves.
  final bool active;

  /// Text style, merged over the ambient [DefaultTextStyle] (like [Text]).
  final TextStyle? style;

  /// How long the row must stay active before the text moves, so walking a
  /// list with the arrow keys sets nothing in motion.
  final Duration startDelay;

  /// How long the end of the text stays in view before the ellipsis returns.
  final Duration endHold;

  /// Travel speed in logical pixels per second.
  final double velocity;

  /// How many lines the active text may wrap onto when motion is reduced.
  ///
  /// More than one changes the row's height, so pass it only where the layout
  /// takes that and the row is not active because a pointer is over it: a row
  /// that grows under the pointer moves its neighbours out from under it.
  final int reducedMotionLines;

  @override
  State<CcMarqueeText> createState() => _CcMarqueeTextState();
}

class _CcMarqueeTextState extends State<CcMarqueeText>
    with SingleTickerProviderStateMixin {
  /// The edge fade's width while text is cut off on that side.
  static const double _fade = 12;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _rest = GlobalKey();
  late final AnimationController _pass = AnimationController(vsync: this)
    ..addListener(_onTick)
    ..addStatusListener(_onStatus);
  Timer? _delay;
  bool _travelling = false;
  bool? _reduced;
  double _extent = 0;
  double _travelShare = 1;

  double get _offset => math.min(_pass.value / _travelShare, 1) * _extent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = CcMotion.reduced(context);
    if (reduced != _reduced) {
      _reduced = reduced;
      _sync();
    }
  }

  @override
  void didUpdateWidget(CcMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active || oldWidget.text != widget.text) {
      _sync();
    }
  }

  /// Back to the ellipsis, then arm one pass if the row is active.
  void _sync() {
    _delay?.cancel();
    _delay = null;
    _pass
      ..stop()
      ..value = 0;
    _travelling = false;
    if (widget.active && _reduced == false) {
      _delay = Timer(widget.startDelay, _begin);
    }
  }

  void _begin() {
    if (!mounted || !_overflows()) {
      // Text that fits is left exactly as it is: no swap, no fade.
      return;
    }
    setState(() => _travelling = true);
    // The scroll view only knows how much text is hidden once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_travelling || !_scroll.hasClients) {
        return;
      }
      final extent = _scroll.position.maxScrollExtent;
      if (extent <= 0 || widget.velocity <= 0) {
        setState(() => _travelling = false);
        return;
      }
      final travel = Duration(
        microseconds: (extent / widget.velocity * 1e6).round(),
      );
      final total = travel + widget.endHold;
      _extent = extent;
      _travelShare = travel.inMicroseconds / total.inMicroseconds;
      _pass
        ..duration = total
        ..forward(from: 0);
    });
  }

  /// Whether the resting text is wider than the room it was given.
  bool _overflows() {
    final box = _rest.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return false;
    }
    // Half a pixel absorbs floating-point noise from text layout.
    return box.getMaxIntrinsicWidth(double.infinity) - box.size.width > 0.5;
  }

  void _onTick() {
    if (_travelling && _scroll.hasClients) {
      _scroll.jumpTo(_offset);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _travelling = false);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _pass.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget visual;
    if (_travelling) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      visual = LayoutBuilder(
        key: const ValueKey('travel'),
        builder: (context, constraints) => AnimatedBuilder(
          animation: _pass,
          builder: (context, child) {
            final width = constraints.maxWidth;
            if (!width.isFinite || width <= 0) {
              return child!;
            }
            final offset = _offset;
            // Fade only an edge that is cutting text off right now.
            final lead = math.min(_fade, offset) / width;
            final trail = math.min(_fade, _extent - offset) / width;
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
                end: rtl ? Alignment.centerLeft : Alignment.centerRight,
                colors: const [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0, lead, 1 - trail, 1],
              ).createShader(rect),
              child: child,
            );
          },
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            // Driven by the pass only; a wheel over it scrolls the list.
            physics: const NeverScrollableScrollPhysics(),
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      );
    } else {
      final lines = widget.active && _reduced == true
          ? widget.reducedMotionLines
          : 1;
      visual = KeyedSubtree(
        key: const ValueKey('rest'),
        child: Text(
          widget.text,
          key: _rest,
          style: widget.style,
          maxLines: lines,
          softWrap: lines > 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration: CcMotion.resolveFade(
            context,
            const Duration(milliseconds: 150),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [...previous, ?current],
          ),
          child: visual,
        ),
      ),
    );
  }
}
