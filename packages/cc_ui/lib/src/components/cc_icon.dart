import 'package:flutter/widgets.dart';

/// Phosphor Regular `dots-three` (also `moreHorizontal` / `ellipsis`).
const int _kDotsThree = 0xe1fe;

/// Phosphor Regular `dots-three-vertical` (also `moreVertical`).
const int _kDotsThreeVertical = 0xe208;

/// A Phosphor [Icon] that keeps `dots-three` / `dots-three-vertical`
/// looking like phosphoricons.com.
///
/// The site paints Regular's SVG (`viewBox="0 0 256 256"`, `r=12`
/// circles) at 32 px in the grid and 64 px in the detail card. Flutter's
/// TTF rasterizer drops those circles at toolbar sizes. We paint the
/// same SVG paths — not a restyle — at the size the caller asked for.
/// Other codepoints go through [Icon].
class CcIcon extends StatelessWidget {
  /// Creates a [CcIcon].
  const CcIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
  });

  /// The glyph to paint.
  final IconData icon;

  /// Layout slot in logical pixels. Defaults to the ambient [IconTheme].
  final double? size;

  /// Glyph colour. Defaults to the ambient [IconTheme].
  final Color? color;

  /// Announced by assistive tech; not shown.
  final String? semanticLabel;

  /// Text direction for [IconData.matchTextDirection] glyphs.
  final TextDirection? textDirection;

  /// Whether [MediaQuery] text scaling applies. Defaults to the ambient
  /// [IconTheme].
  final bool? applyTextScaling;

  /// Whether [icon] is Phosphor Regular's three-dot overflow glyph.
  static bool isDotsThree(IconData icon) =>
      icon.codePoint == _kDotsThree || icon.codePoint == _kDotsThreeVertical;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final applyScaling = applyTextScaling ?? theme.applyTextScaling ?? false;
    final tentative = size ?? theme.size ?? kDefaultFontSize;
    final layoutSize = applyScaling
        ? MediaQuery.textScalerOf(context).scale(tentative)
        : tentative;

    if (!isDotsThree(icon)) {
      return Icon(
        icon,
        size: layoutSize,
        color: color,
        semanticLabel: semanticLabel,
        textDirection: textDirection,
        applyTextScaling: false,
      );
    }

    final opacity = theme.opacity ?? 1.0;
    var iconColor =
        color ?? theme.color ?? DefaultTextStyle.of(context).style.color;
    iconColor ??= const Color(0xFF000000);
    if (opacity != 1.0) {
      iconColor = iconColor.withValues(alpha: iconColor.a * opacity);
    }

    // Same layout as [Icon]: a [SizedBox] of [layoutSize] whose child
    // paints at that size even when a parent tightens the box (a 22 px
    // sidebar chip, a 32 px [CcIconButton]). Filling the parent would
    // scale the SVG with the chip instead of matching sibling 16 px
    // glyphs.
    final Widget glyph = SizedBox(
      width: layoutSize,
      height: layoutSize,
      child: Center(
        child: CustomPaint(
          size: Size.square(layoutSize),
          painter: _PhosphorRegularDotsPainter(
            color: iconColor,
            vertical: icon.codePoint == _kDotsThreeVertical,
          ),
        ),
      ),
    );
    if (semanticLabel == null) {
      return glyph;
    }
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

/// Phosphor Regular v2.1 `dots-three` / `dots-three-vertical`.
///
/// Copied from `@phosphor-icons/core` `assets/regular/*.svg`
/// (`viewBox="0 0 256 256"`, circle `r=12`). Same paths the website
/// paints; not a restyle.
class _PhosphorRegularDotsPainter extends CustomPainter {
  const _PhosphorRegularDotsPainter({
    required this.color,
    required this.vertical,
  });

  final Color color;
  final bool vertical;

  static const double _view = 256;
  static const double _radius = 12;
  static const Offset _mid = Offset(128, 128);
  static const Offset _horizontalStart = Offset(60, 128);
  static const Offset _horizontalEnd = Offset(196, 128);
  static const Offset _verticalStart = Offset(128, 60);
  static const Offset _verticalEnd = Offset(128, 196);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.save();
    canvas.scale(size.width / _view, size.height / _view);
    final a = vertical ? _verticalStart : _horizontalStart;
    final b = vertical ? _verticalEnd : _horizontalEnd;
    canvas
      ..drawCircle(a, _radius, paint)
      ..drawCircle(_mid, _radius, paint)
      ..drawCircle(b, _radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PhosphorRegularDotsPainter old) =>
      old.color != color || old.vertical != vertical;
}
