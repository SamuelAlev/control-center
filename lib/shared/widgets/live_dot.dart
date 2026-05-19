import 'package:flutter/material.dart';

/// A small dot that gently breathes to signal live agent activity, per
/// DESIGN.md's Living Status Rule. Honours `prefers-reduced-motion`
/// ([MediaQueryData.disableAnimations]) by holding a static, fully-visible dot
/// instead of pulsing — never a blank or disappearing indicator.
///
/// Shared between the dashboard's active-agents section and the agents roster
/// so "live" reads identically wherever an agent is running.
class LiveDot extends StatefulWidget {
  /// Creates a [LiveDot].
  const LiveDot({super.key, required this.color, this.size = 8});

  /// The dot color — the agent's live-state tone.
  final Color color;

  /// Diameter in logical pixels.
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final opacity = 0.5 + 0.5 * t;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.30 * opacity),
                blurRadius: 5,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}
