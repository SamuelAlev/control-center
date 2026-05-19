import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A single selectable row in a [CcMenu].
@immutable
class CcMenuItem {
  /// Creates a [CcMenuItem].
  const CcMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// The row's text.
  final String label;

  /// Invoked when the row is selected (the menu closes first).
  final VoidCallback onSelected;

  /// Optional leading icon (a `lucide_icons_flutter` [IconData]).
  final IconData? icon;

  /// Whether this is a destructive action — rendered in the danger color.
  final bool destructive;

  /// Whether the row can be selected.
  final bool enabled;
}

/// A flat dropdown menu — the cc_ui replacement for Material's
/// `PopupMenuButton`.
///
/// Tapping [target] opens a floating panel (golden float, hairline border,
/// large radius) listing [items] as flat [CcTappable] rows with a hover wash.
/// Destructive rows render their label and icon in `t.danger`. Selecting a row
/// closes the menu, then calls the item's `onSelected`.
class CcMenu extends StatefulWidget {
  /// Creates a [CcMenu].
  const CcMenu({
    super.key,
    required this.target,
    required this.items,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 6),
    this.minWidth = 180,
    this.semanticLabel,
  });

  /// The trigger widget the menu anchors to.
  final Widget target;

  /// The menu rows.
  final List<CcMenuItem> items;

  /// Point on the target the panel aligns to.
  final Alignment targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the panel.
  final Offset offset;

  /// Minimum width of the menu panel.
  final double minWidth;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcMenu> createState() => _CcMenuState();
}

class _CcMenuState extends State<CcMenu> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(CcMenuItem item) {
    _controller.hide();
    item.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      target: CcTappable(
        onPressed: _controller.toggle,
        semanticLabel: widget.semanticLabel,
        builder: (context, states) => widget.target,
      ),
      overlayBuilder: _buildPanel,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.bg,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: card.border),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          // Scroll when the menu is taller than the viewport cap imposed by
          // [CcOverlayAnchor]; short menus still shrink-wrap to their rows.
          child: SingleChildScrollView(
            // Shrink-wrap to the widest row's natural width (like Material's
            // PopupMenu) instead of stretching to the overlay's full width.
            child: IntrinsicWidth(
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in widget.items)
                    _CcMenuRow(
                      item: item,
                      onSelected: () => _select(item),
                    ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CcMenuRow extends StatelessWidget {
  const _CcMenuRow({
    required this.item,
    required this.onSelected,
  });

  final CcMenuItem item;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = item.destructive ? t.danger : t.textPrimary;

    return CcTappable(
      onPressed: item.enabled ? onSelected : null,
      borderRadius: AppRadii.brSm,
      semanticLabel: item.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final disabled = states.contains(WidgetState.disabled);
        final wash = pressed
            ? t.hoverStrong
            : (hovered ? t.hover : const Color(0x00000000));
        final color = disabled ? t.textDisabled : fg;

        return DecoratedBox(
          decoration: BoxDecoration(color: wash),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: color),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: CcTypography.bodySm.copyWith(color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
