import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The flat status card every left-to-right run graph (PR workflow checks,
/// pipeline runs) draws its nodes with: a quiet surface, status carried by
/// the leading glyph (shape + color, never color alone), the name in bold,
/// an optional status line under it and an optional right-aligned meta (a
/// duration, a job count).
///
/// GitHub-style: the card itself stays neutral — only selection (brand
/// border) and hover (secondary wash) change its surface. Callers that need
/// a tinted variant (the pipeline's trigger node) pass [fill]/[border].
class GraphNodeCard extends StatelessWidget {
  /// Creates a [GraphNodeCard].
  const GraphNodeCard({
    super.key,
    required this.glyph,
    required this.title,
    required this.selected,
    this.subtitle,
    this.subtitleColor,
    this.trailing,
    this.trailingColor,
    this.fill,
    this.border,
    this.hovered = false,
  });

  /// Leading status glyph (icon or spinner), sized by the caller.
  final Widget glyph;

  /// Node display name (bold, up to two lines, ellipsized).
  final String title;

  /// Optional second line under the title (a status word, a job count).
  final String? subtitle;

  /// Color override for [subtitle]; defaults to `textTertiary`.
  final Color? subtitleColor;

  /// Optional right-aligned meta (a duration like `4m 14s`, a status word).
  final String? trailing;

  /// Color override for [trailing]; defaults to `textTertiary`.
  final Color? trailingColor;

  /// Whether the node is the graph's selected one (brand border, 2px).
  final bool selected;

  /// Tinted surface override; null = the quiet default (`bgPrimary`, washed
  /// to `bgSecondary` on hover).
  final Color? fill;

  /// Border color override; null = `borderSecondary` (`borderBrand` when
  /// [selected]).
  final Color? border;

  /// Whether the pointer is over the card (hover wash on the quiet variant).
  final bool hovered;

  /// Horizontal card padding on each side.
  static const double horizontalPadding = 12;

  /// The rendered title style, exposed so callers laying out around the card
  /// (a canvas measuring titles to size its nodes) measure the exact width
  /// the card will render.
  static TextStyle titleStyle({required Color color}) => TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// The rendered trailing-meta style, exposed for the same measurement
  /// reason as [titleStyle].
  static TextStyle metaStyle({required Color color}) =>
      TextStyle(fontSize: 11, height: 1.2, color: color);

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final background =
        fill ?? (hovered ? tokens.bgSecondary : tokens.bgPrimary);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: selected
              ? tokens.borderBrand
              : (border ?? tokens.borderSecondary),
          width: selected ? 2 : 1,
        ),
        borderRadius: AppRadii.brMd,
      ),
      child: Row(
        children: [
          glyph,
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: titleStyle(color: tokens.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor ?? tokens.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: metaStyle(color: trailingColor ?? tokens.textTertiary),
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
