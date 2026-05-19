import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat list row — the cc_ui replacement for Material's `ListTile`.
///
/// Lays out an optional [leading] (a [Widget], or an [IconData] via
/// [leadingIcon]), a required [title] (a [String] or any [Widget]), an optional
/// [subtitle], and an optional [trailing] widget. When [onTap] is non-null the
/// row becomes interactive via [CcTappable] — it gains hover/press washes, the
/// keyboard-only focus ring, and Enter/Space activation. A [selected] row reads
/// as the current selection through an `accentSoft` wash and an accent title.
class CcTile extends StatelessWidget {
  /// Creates a [CcTile].
  const CcTile({
    super.key,
    required this.title,
    this.leading,
    this.leadingIcon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
  });

  /// The title — pass a [String] (rendered with the primary text color) or any
  /// [Widget] for full control.
  final Object title;

  /// Optional leading widget. Takes precedence over [leadingIcon].
  final Widget? leading;

  /// Optional leading icon, rendered when [leading] is null.
  final IconData? leadingIcon;

  /// Optional secondary line below the title.
  final Widget? subtitle;

  /// Optional trailing widget (e.g. a chevron, badge, or action).
  final Widget? trailing;

  /// Tap handler. When null the tile is a static row (no interaction states).
  final VoidCallback? onTap;

  /// Whether the row is the current selection.
  final bool selected;

  /// Optional accessibility label override for the interactive row.
  final String? semanticLabel;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return selected ? t.accentSoft : t.hover;
    }
    if (selected) {
      return t.accentSoft;
    }
    return t.hover.withValues(alpha: 0);
  }

  Widget _buildRow(
    DesignSystemTokens t,
    Color background,
  ) {
    final titleColor = selected ? t.accent : t.textPrimary;

    final Widget titleWidget = title is Widget
        ? title as Widget
        : Text(
            title.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: titleColor,
            ),
          );

    return AnimatedContainer(
      duration: CcMotion.fast,
      curve: CcMotion.standard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppSpacing.hGapMd,
          ] else if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 18,
              color: selected ? t.accent : t.textSecondary,
            ),
            AppSpacing.hGapMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: t.textTertiary,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            AppSpacing.hGapMd,
            trailing!,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    if (onTap == null) {
      // Static row — selection still tints the background.
      final background = selected ? t.accentSoft : t.hover.withValues(alpha: 0);
      return _buildRow(t, background);
    }

    return CcTappable(
      onPressed: onTap,
      borderRadius: AppRadii.brSm,
      semanticLabel: semanticLabel,
      builder: (context, states) => _buildRow(t, _background(t, states)),
    );
  }
}
