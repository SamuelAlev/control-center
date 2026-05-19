import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat horizontal progress bar.
///
/// Pass [value] in 0..1 for a determinate fill (clamped to the range). Pass
/// `null` for an indeterminate state: a short segment slides back and forth
/// across the track. The track and fill are pill-capped; per DESIGN.md the
/// indeterminate animation collapses to a static 30% bar when motion is reduced
/// so it never animates against an accessibility preference.
class CcProgressBar extends StatefulWidget {
  /// Creates a [CcProgressBar].
  const CcProgressBar({
    super.key,
    this.value,
    this.height = 4,
    this.color,
    this.trackColor,
    this.semanticLabel,
  });

  /// The progress fraction in 0..1, or `null` for an indeterminate bar.
  final double? value;

  /// The bar height, in logical pixels.
  final double height;

  /// The fill color. Defaults to the design-system accent.
  final Color? color;

  /// The track (background) color. Defaults to the tertiary background token.
  final Color? trackColor;

  /// An optional semantics label announced to assistive tech.
  final String? semanticLabel;

  @override
  State<CcProgressBar> createState() => _CcProgressBarState();
}

class _CcProgressBarState extends State<CcProgressBar>
    with SingleTickerProviderStateMixin {
  /// The fraction of the track width occupied by the sliding indeterminate
  /// segment.
  static const double _indeterminateExtent = 0.3;

  late final AnimationController _controller;

  bool get _isIndeterminate => widget.value == null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(CcProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate = _isIndeterminate && !CcMotion.reduced(context);
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else if (_controller.isAnimating) {
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = widget.color ?? t.accent;
    final trackColor = widget.trackColor ?? t.bgTertiary;
    _syncAnimation();

    final radius =
        BorderRadius.all(Radius.circular(widget.height / 2 < AppRadii.pill
            ? widget.height / 2
            : AppRadii.pill));

    Widget bar(Widget fill) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          height: widget.height,
          color: trackColor,
          child: fill,
        ),
      );
    }

    final Widget content;
    if (!_isIndeterminate) {
      final fraction = widget.value!.clamp(0.0, 1.0);
      content = bar(
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      );
    } else if (CcMotion.reduced(context)) {
      // Static fallback: a fixed 30% segment, no animation.
      content = bar(
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _indeterminateExtent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final segment = width * _indeterminateExtent;
          final travel = width - segment;
          return bar(
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      left: travel * _controller.value,
                      top: 0,
                      bottom: 0,
                      width: segment,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    }

    final label = widget.semanticLabel;
    if (label == null) {
      return content;
    }
    return Semantics(
      label: label,
      value: _isIndeterminate
          ? null
          : '${(widget.value!.clamp(0.0, 1.0) * 100).round()}%',
      child: content,
    );
  }
}
