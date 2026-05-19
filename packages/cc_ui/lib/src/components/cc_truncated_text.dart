import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Single-line text that truncates with an ellipsis and — only when actually
/// truncated — discloses the full text in a [CcTooltip] on hover/focus.
///
/// Overflow-content guidance: never wrap a label (a tag, menu row, or select
/// option) to multiple lines; truncate with an ellipsis and reveal the full
/// text in a tooltip instead. Untruncated text renders as a plain [Text] with
/// no tooltip machinery, so this is safe to use on dense list rows and tag
/// groups.
///
/// Truncation is detected by a lightweight render proxy after layout (not a
/// [LayoutBuilder]), so the widget keeps working inside intrinsic-sizing
/// parents like `IntrinsicWidth` (the menu panel's shrink-wrap).
class CcTruncatedText extends StatefulWidget {
  /// Creates a [CcTruncatedText].
  const CcTruncatedText(
    this.text, {
    super.key,
    this.style,
    this.tooltipPlacement = CcTooltipPlacement.bottom,
  });

  /// The label text.
  final String text;

  /// Text style, merged over the ambient [DefaultTextStyle] (like [Text]).
  final TextStyle? style;

  /// Which side of the label the disclosure tooltip opens on.
  final CcTooltipPlacement tooltipPlacement;

  @override
  State<CcTruncatedText> createState() => _CcTruncatedTextState();
}

class _CcTruncatedTextState extends State<CcTruncatedText> {
  bool _truncated = false;

  void _onTruncationChanged(bool truncated) {
    if (!mounted || truncated == _truncated) {
      return;
    }
    setState(() => _truncated = truncated);
  }

  @override
  Widget build(BuildContext context) {
    final child = _TruncationDetector(
      onChanged: _onTruncationChanged,
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (!_truncated) {
      return child;
    }
    return CcTooltip(
      message: widget.text,
      placement: widget.tooltipPlacement,
      child: child,
    );
  }
}

/// Reports, after each layout, whether its child was given less width than
/// its natural (unconstrained) single-line width — i.e. whether the text
/// ellipsized.
class _TruncationDetector extends SingleChildRenderObjectWidget {
  const _TruncationDetector({required this.onChanged, required super.child});

  final ValueChanged<bool> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTruncationDetector(onChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTruncationDetector renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _RenderTruncationDetector extends RenderProxyBox {
  _RenderTruncationDetector(this.onChanged);

  ValueChanged<bool> onChanged;
  bool? _lastReported;

  @override
  void performLayout() {
    super.performLayout();
    final child = this.child;
    if (child == null) {
      return;
    }
    final naturalWidth = child.getMaxIntrinsicWidth(double.infinity);
    // Half-pixel tolerance absorbs floating-point noise from text layout.
    final truncated = naturalWidth - size.width > 0.5;
    if (truncated != _lastReported) {
      _lastReported = truncated;
      // Layout must not mutate the widget tree; notify after the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(truncated);
      });
    }
  }
}
