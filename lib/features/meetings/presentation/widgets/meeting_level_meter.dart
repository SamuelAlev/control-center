import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small horizontal audio level meter: a row of bars driven by the real mic
/// amplitude ([level]) while [active], resting flat when paused/idle.
///
/// When [level] is provided the bars scale with the live RMS (a quiet mic reads
/// low, a loud one fills the meter); when it is null the meter falls back to a
/// cosmetic "audio is flowing" jitter. Honors reduce-motion by staying flat.
class MeetingLevelMeter extends StatefulWidget {
  /// Creates a [MeetingLevelMeter].
  const MeetingLevelMeter({
    super.key,
    required this.active,
    required this.color,
    this.level,
    this.barCount = 5,
    this.height = 22,
    this.seed = 0,
  });

  /// Whether the meter is live (bars jitter) or at rest (bars flat).
  final bool active;

  /// Real mic input level in 0..1. When null the meter is cosmetic-only.
  final double? level;

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
                  // At rest, or with reduce-motion, show the real level as a
                  // flat fill (or the resting floor when there's no signal).
                  factor = (widget.level ?? 0).clamp(0.14, 1.0);
                } else if (widget.level != null) {
                  // Amplitude-driven: the live RMS sets the height, with a light
                  // per-bar shimmer so the meter still feels alive.
                  final t = _controller.value * 2 * math.pi;
                  final shimmer = 0.85 + 0.15 * math.sin(t + widget.seed + i * 1.7);
                  factor = (widget.level! * shimmer).clamp(0.14, 1.0);
                } else {
                  // Cosmetic fallback: layered sines give a lively jitter.
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
