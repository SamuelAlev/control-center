import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/focus_modality.dart';
import 'package:flutter/widgets.dart';

/// Draws a `:focus-visible`-style ring around [child] when [focusNode] gains
/// focus **via the keyboard**. Clicking into the field with the mouse focuses
/// it without the ring (see [FocusModality]).
///
/// The ring is painted as an overlay — a [Positioned.fill] border layered on
/// top of the child — rather than as part of the child's own box, so it never
/// changes the child's size. Toggling focus therefore can't shift the
/// surrounding layout the way a widening [Border] or
/// `InputDecoration.focusedBorder` would (the CSS content-box-vs-border-box
/// problem). The child keeps its own resting border; the ring overpaints the
/// outer edge while focused.
class FocusRing extends StatefulWidget {
  /// Creates a [FocusRing].
  const FocusRing({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(2)),
    this.width = 2,
    this.color,
    this.enabled = true,
  });

  /// The node whose keyboard focus arms the ring.
  final FocusNode focusNode;

  /// The wrapped field. Its own size is preserved exactly.
  final Widget child;

  /// Corner radius of the ring — match the child's own radius.
  final BorderRadius borderRadius;

  /// Stroke width of the ring.
  final double width;

  /// Ring color; defaults to the design system `focusRing` token.
  final Color? color;

  /// Set false to suppress the ring entirely (e.g. while the field is disabled).
  final bool enabled;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _visible = _shouldShow();
  }

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _onFocusChange();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  // Sampled only on the focus-gain edge, so a node focused by mouse stays
  // ringless even if the user then types — mirroring `:focus-visible`, which
  // locks its verdict at the moment focus moves.
  bool _shouldShow() =>
      widget.focusNode.hasFocus && FocusModality.instance.isKeyboard;

  void _onFocusChange() {
    final next = _shouldShow();
    if (next != _visible && mounted) {
      setState(() => _visible = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final color = widget.color ?? tokens.focusRing;
    return Stack(
      // passthrough forwards our constraints to the child unchanged, so wrapping
      // a field in a FocusRing lays it out identically to the bare child.
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_visible && widget.enabled)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  border: Border.all(color: color, width: widget.width),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
