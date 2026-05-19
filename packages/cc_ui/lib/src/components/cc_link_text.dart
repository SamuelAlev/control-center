import 'package:flutter/widgets.dart';

/// Link-styled text whose underline sits just BELOW the descent line, full
/// width — Carbon-style — which the text engine cannot paint itself (no
/// `text-underline-offset` on the pinned SDK; its underline hugs the baseline
/// and strikes through descenders).
///
/// Drop-in for a plain [Text] link label: same layout, same wrapping, same
/// overflow — only the underline is custom-painted. The engine decoration is
/// stripped, so pass the link style WITHOUT [TextStyle.decoration] (any
/// decoration that IS set is ignored); the underline colour defaults to the
/// style's [TextStyle.decorationColor], then its [TextStyle.color].
///
/// Geometry: the line sits 10% of the font size below each line's descent
/// and is 6% thick. Ratio-based skip-ink (gaps at hardcoded glyph fractions)
/// was tried and rejected — without a glyph-outline API the windows can
/// never match the actual font, so the line either crossed descender ink or
/// dropped glyph tails. Below-descent clears every descender, for every
/// font, at full width.
///
/// Rich-text surfaces (markdown) get the same treatment inside cc_markdown's
/// renderer — this widget is for plain-[Text] link labels only. It is
/// display-only; tap handling stays with the parent (as before).
class CcLinkText extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveStyle = style.copyWith(decoration: TextDecoration.none);
    return CustomPaint(
      foregroundPainter: _CcSkipInkPainter(
        text: text,
        style: effectiveStyle,
        underlineColor:
            underlineColor ?? style.decorationColor ?? style.color,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textScaler: textScaler,
        textDirection: Directionality.maybeOf(context),
        locale: Localizations.maybeLocaleOf(context),
      ),
      child: Text(
        text,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textScaler: textScaler,
      ),
    );
  }
}

/// Paints the below-descent underline for [CcLinkText]. A single-style
/// mirror [TextPainter] is exact here (no rich spans, no widget
/// placeholders), and every line is painted — not just the first.
class _CcSkipInkPainter extends CustomPainter {
  _CcSkipInkPainter({
    required this.text,
    required this.style,
    required this.underlineColor,
    required this.textAlign,
    required this.maxLines,
    required this.overflow,
    required this.textScaler,
    required this.textDirection,
    required this.locale,
  });

  final String text;
  final TextStyle style;
  final Color? underlineColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final TextDirection? textDirection;
  final Locale? locale;

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) {
      return;
    }
    final fontSize = style.fontSize ?? 14.0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection ?? TextDirection.ltr,
      textScaler: textScaler ?? TextScaler.noScaling,
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '…' : null,
      locale: locale,
    )..layout(maxWidth: size.width);

    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) {
      return;
    }

    final gap = fontSize * 0.1;
    final thickness = (fontSize * 0.06).clamp(1.0, 2.0).toDouble();
    final paint = Paint()
      ..color = underlineColor ?? const Color(0xFF000000)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    // One full-width line per text line, just below the descent: it can
    // never cross a descender's ink and never reads truncated.
    for (final line in lines) {
      final y = line.baseline + line.descent + gap;
      canvas.drawLine(
        Offset(line.left, y),
        Offset(line.left + line.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CcSkipInkPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.underlineColor != underlineColor ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.maxLines != maxLines ||
      oldDelegate.overflow != overflow ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textDirection != textDirection;
}
