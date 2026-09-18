import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A thin draggable horizontal scrollbar for the diff's code area (scroll
/// mode). Stateless about the offset — it reads [offset] each build (the
/// overlay rebuilds after every paint) and reports pans via [onPan]; drag delta
/// is accumulated from the drag's start offset to avoid stale-value jitter.
class DiffHScrollbar extends StatefulWidget {
  const DiffHScrollbar({
    super.key,
    required this.offset,
    required this.maxOffset,
    required this.viewportWidth,
    required this.onPan,
  });

  /// Current horizontal offset.
  final double offset;

  /// Maximum horizontal offset (content width − viewport width).
  final double maxOffset;

  /// Visible code width (the scrollbar track width).
  final double viewportWidth;

  /// Called with the new absolute offset as the thumb is dragged.
  final ValueChanged<double> onPan;

  @override
  State<DiffHScrollbar> createState() => DiffHScrollbarState();
}

class DiffHScrollbarState extends State<DiffHScrollbar> {
  double _dragStartOffset = 0;
  double _dragAccum = 0;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final double content = widget.viewportWidth + widget.maxOffset;
    final double thumbW = content <= 0
        ? widget.viewportWidth
        : (widget.viewportWidth / content * widget.viewportWidth).clamp(
            28.0,
            widget.viewportWidth,
          );
    final double travel = widget.viewportWidth - thumbW;
    final double thumbLeft = widget.maxOffset <= 0
        ? 0
        : (widget.offset / widget.maxOffset).clamp(0.0, 1.0) * travel;
    final double gain = travel <= 0 ? 0 : widget.maxOffset / travel;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragStartOffset = widget.offset;
          _dragAccum = 0;
        },
        onHorizontalDragUpdate: (d) {
          _dragAccum += d.delta.dx;
          widget.onPan(_dragStartOffset + _dragAccum * gain);
        },
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: thumbLeft),
            child: Container(
              width: thumbW,
              height: _hovered ? 8 : 6,
              color: tokens.textTertiary.withValues(
                alpha: _hovered ? 0.6 : 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
