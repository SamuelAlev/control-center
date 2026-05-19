import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A single segment in a [CcBreadcrumb] trail.
@immutable
class CcBreadcrumbItem {
  /// Creates a [CcBreadcrumbItem].
  const CcBreadcrumbItem({
    required this.child,
    this.onPress,
    this.current = false,
  });

  /// The segment content (usually a `Text`, but any widget is allowed).
  final Widget child;

  /// Tap handler for a link segment. When null (or [current]) the segment is
  /// inert.
  final VoidCallback? onPress;

  /// Whether this is the active (final) segment — rendered emphasized and
  /// non-interactive.
  final bool current;
}

/// A horizontal breadcrumb trail.
///
/// Draws [children] separated by a chevron. The [CcBreadcrumbItem.current]
/// segment renders in `textPrimary` (medium weight); the rest render in
/// `textTertiary` and, when they carry an `onPress`, become hoverable
/// [CcTappable] links.
class CcBreadcrumb extends StatelessWidget {
  /// Creates a [CcBreadcrumb].
  const CcBreadcrumb({super.key, required this.children});

  /// The ordered trail segments.
  final List<CcBreadcrumbItem> children;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        row.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              CcIcons.chevronRight,
              size: 14,
              color: t.fgQuaternary,
            ),
          ),
        );
      }
      row.add(_segment(t, children[i]));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: row);
  }

  Widget _segment(DesignSystemTokens t, CcBreadcrumbItem item) {
    final color = item.current ? t.textPrimary : t.textTertiary;
    final styled = DefaultTextStyle.merge(
      style: CcTypography.bodySm.copyWith(
        color: color,
        fontWeight: item.current ? FontWeight.w600 : FontWeight.w400,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 14),
        child: item.child,
      ),
    );

    if (item.onPress == null || item.current) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: styled,
      );
    }

    return CcTappable(
      onPressed: item.onPress,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : const Color(0x00000000),
            borderRadius: AppRadii.brSm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: styled,
          ),
        );
      },
    );
  }
}
