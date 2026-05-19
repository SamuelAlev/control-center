import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small horizontal audio level meter: a row of bars that jitter while
/// [active], and rest flat when paused/idle.
///
/// Purely cosmetic — the capture port doesn't expose real RMS levels, so the
/// meter reports "audio is flowing" (active vs. at-rest) rather than amplitude.
/// Honors the reduce-motion setting by staying flat.
class MeetingLevelMeter extends StatefulWidget {
  /// Creates a [MeetingLevelMeter].
  const MeetingLevelMeter({
    super.key,
    required this.active,
    required this.color,
    this.barCount = 5,
    this.height = 22,
    this.seed = 0,
  });

  /// Whether the meter is live (bars jitter) or at rest (bars flat).
  final bool active;

  /// Bar color.
  final Color color;

  /// Number of bars.
  final int barCount;

  /// Meter height (the tallest a bar can reach).
  final double height;

  /// Phase seed so two adjacent meters don't move in lockstep.
  final double seed;

  @override
  State<MeetingLevelMeter> createState() => _MeetingLevelMeterState();
}

class _MeetingLevelMeterState extends State<MeetingLevelMeter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MeetingLevelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double factor;
                if (!widget.active || reduceMotion) {
                  factor = 0.14;
                } else {
                  // Layered sines per bar give a lively, non-repeating jitter.
                  final t = _controller.value * 2 * math.pi;
                  final a = math.sin(t + widget.seed + i * 1.7);
                  final b = math.sin(t * 1.6 + widget.seed * 2 + i * 0.9);
                  factor = (0.5 + 0.32 * a + 0.18 * b).clamp(0.14, 1.0);
                }
                return Container(
                  width: 3,
                  height: math.max(3, widget.height * factor),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
