import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';

/// Gap between each line box's bottom and the underline, as a fraction of
/// the font size.
const double _kUnderlineGapRatio = 0.1;

/// Underline thickness as a fraction of the font size.
const double _kUnderlineThicknessRatio = 0.06;

double _underlineGap(double fontSize) => fontSize * _kUnderlineGapRatio;

double _underlineThickness(double fontSize) =>
    (fontSize * _kUnderlineThicknessRatio).clamp(1.0, 2.0).toDouble();

/// Space reserved below the text so the offset stroke stays inside the
/// paint box. The stroke sits [gap] below the line box and extends
/// half its thickness past that, so the reserve is gap + thickness.
double _underlineReserve(double fontSize) =>
    _underlineGap(fontSize) + _underlineThickness(fontSize);

/// Link [Text] whose underline sits below the descent (Carbon-style; SDK has
/// no `text-underline-offset`). Strip [TextStyle.decoration]; colour from
/// decorationColor then color. Line: 10% of font size below each line box, 6%
/// thick. Measure x-span from laid-out [RenderParagraph] (not a parallel
/// [TextPainter] — ambient [DefaultTextStyle] vs platform default). Bottom
/// padding keeps the stroke inside the paint box. Display-only; taps stay with
/// the parent. Markdown uses cc_markdown's renderer instead.
class CcLinkText extends StatefulWidget {
  /// Creates a [CcLinkText].
  const CcLinkText(
    this.text, {
    super.key,
    required this.style,
    this.underlineColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textScaler,
  });

  /// The text to display.
  final String text;

  /// The link's text style (font, size, colour). Any
  /// [TextStyle.decoration] is ignored — the underline is custom-painted.
  final TextStyle style;

  /// Underline colour; defaults to the style's decorationColor, then color.
  final Color? underlineColor;

  /// How the text is aligned horizontally (affects segment offsets).
  final TextAlign? textAlign;

  /// An optional maximum number of lines (mirrors [Text.maxLines]).
  final int? maxLines;

  /// How visual overflow is handled (mirrors [Text.overflow]).
  final TextOverflow? overflow;

  /// The text scale (mirrors [Text.textScaler]).
  final TextScaler? textScaler;

  @override
  State<CcLinkText> createState() => _CcLinkTextState();
}

class _CcLinkTextState extends State<CcLinkText> {
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style.copyWith(
      decoration: TextDecoration.none,
    );
    final fontSize = (widget.textScaler ?? MediaQuery.textScalerOf(context))
        .scale(effectiveStyle.fontSize ?? 14.0);
    return CustomPaint(
      foregroundPainter: _CcLinkUnderlinePainter(
        textKey: _textKey,
        text: widget.text,
        underlineColor:
            widget.underlineColor ??
            widget.style.decorationColor ??
            widget.style.color,
        fontSize: fontSize,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: _underlineReserve(fontSize)),
        child: Text(
          widget.text,
          key: _textKey,
          style: effectiveStyle,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textScaler: widget.textScaler,
        ),
      ),
    );
  }
}

/// Paints the below-line underline for [CcLinkText] from the paragraph's
/// real boxes, so wrapping, ellipsis, scaling and the merged UI font all
/// track exactly. [BoxHeightStyle.max] keeps every line's stroke on the
/// same y — tight glyph boxes would drop only under descenders and leave
/// neighbouring labels looking misaligned.
class _CcLinkUnderlinePainter extends CustomPainter {
  _CcLinkUnderlinePainter({
    required this.textKey,
    required this.text,
    required this.underlineColor,
    required this.fontSize,
  });

  final GlobalKey textKey;
  final String text;
  final Color? underlineColor;
  final double fontSize;

  /// Depth-first search for the paragraph that lays out the keyed [Text].
  /// The key sits on a [Text], whose first render-object descendant is the
  /// paragraph itself UNLESS an interactive ancestor wraps it.
  static RenderParagraph? _findParagraph(RenderObject? node) {
    if (node is RenderParagraph) {
      return node;
    }
    RenderParagraph? found;
    node?.visitChildren((child) {
      found ??= _findParagraph(child);
    });
    return found;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) {
      return;
    }
    final paragraph = _findParagraph(
      textKey.currentContext?.findRenderObject(),
    );
    if (paragraph == null || !paragraph.hasSize) {
      return;
    }
    final plain = paragraph.text.toPlainText();
    if (plain.isEmpty) {
      return;
    }

    final gap = _underlineGap(fontSize);
    final thickness = _underlineThickness(fontSize);
    final paint = Paint()
      ..color = underlineColor ?? const Color(0xFF000000)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: plain.length),
      boxHeightStyle: BoxHeightStyle.max,
    );
    for (final box in boxes) {
      if (box.right - box.left < 1) {
        continue;
      }
      final y = box.bottom + gap;
      canvas.drawLine(Offset(box.left, y), Offset(box.right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CcLinkUnderlinePainter oldDelegate) =>
      !identical(oldDelegate.textKey, textKey) ||
      oldDelegate.text != text ||
      oldDelegate.underlineColor != underlineColor ||
      oldDelegate.fontSize != fontSize;
}
