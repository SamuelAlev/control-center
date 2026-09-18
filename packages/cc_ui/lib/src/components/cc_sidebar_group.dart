import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/components/cc_sidebar_item.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// A labelled section of [CcSidebar] items.
///
/// Renders an optional mono uppercase eyebrow [label] (via [CcTypography.label]
/// + [CcFonts.code], colored `textTertiary`) above its [children]. When
/// [collapsible] the label becomes a tappable header with a rotating chevron
/// that expands/collapses the children through an [AnimatedSize]
/// ([CcMotion.moderate], reduced-motion aware).
///
/// Expanded and collapsed rows sit flush (no gutter between them) so the
/// pointer stays a click cursor while travelling the list. A 4px [SizedBox]
/// between rows is not a [CcTappable], and the cursor would snap back to
/// the default arrow in every gap.
///
/// Hover follows [CcFluidHoverTarget]: [CcSidebarItem]s wash on nearest-target
/// hover. A child that is not a target (a nested accordion, a popover-wrapped
/// row) is a boundary — hovering it does not highlight a neighbour, and the
/// nested interactive row keeps its own wash.
///
/// In the enclosing [CcSidebar]'s collapsed rail mode the label is hidden (the
/// group reduces to its icon-only items).
class CcSidebarGroup extends StatefulWidget {
  /// Creates a [CcSidebarGroup].
  const CcSidebarGroup({
    super.key,
    required this.children,
    this.label,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  /// The group's items (typically [CcSidebarItem]s).
  final List<Widget> children;

  /// Optional uppercase eyebrow label for the group.
  final String? label;

  /// Whether the header toggles the children's visibility.
  final bool collapsible;

  /// Initial expansion state when [collapsible].
  final bool initiallyExpanded;

  @override
  State<CcSidebarGroup> createState() => _CcSidebarGroupState();
}

class _CcSidebarGroupState extends State<CcSidebarGroup> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final railCollapsed = CcSidebarScope.collapsedOf(context) ?? false;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;

    // Rows sit flush in both modes so a gutter never drops the cursor to
    // the default arrow. The collapsed rail still wraps each item in a
    // 32px square; the squares stack without a separator.
    final body = CcFluidHover(
      mouseCursor: SystemMouseCursors.click,
      itemCount: widget.children.length,
      // Same contract as [CcSidebar]: only [CcFluidHoverTarget]s (typically
      // [CcSidebarItem]) are rows. A composite child — Tickets accordion,
      // Service status popover wrapper, a nested group — is a boundary so
      // hovering it does not wash a neighbour, and nested tappables keep
      // their own hover (see [CcFluidHover] item-scope wrapping).
      isItemBoundary: (index) => widget.children[index] is! CcFluidHoverTarget,
      isItemDisabled: (index) {
        final child = widget.children[index];
        if (child case final CcFluidHoverTarget target) {
          return !target.fluidHoverEnabled;
        }
        return true;
      },
      itemBuilder: (context, index) => widget.children[index],
      layoutBuilder: (context, items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            if (railCollapsed)
              Align(
                child: SizedBox(width: kCcSidebarItemExtent, child: items[i]),
              )
            else
              items[i],
        ],
      ),
    );

    // In the icon-only rail — and while the width is animating toward it —
    // there is no room for a header; show items only.
    if (railCollapsed || transitioning || widget.label == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: body,
      );
    }

    final expanded = !widget.collapsible || _expanded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _GroupHeader(
            label: widget.label!,
            collapsible: widget.collapsible,
            expanded: expanded,
            onToggle: widget.collapsible ? _toggle : null,
            color: t.textTertiary,
            family: context.ccTheme?.monoFontFamily,
          ),
          AnimatedSize(
            duration: CcMotion.resolve(context, CcMotion.moderate),
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: expanded
                ? body
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// The eyebrow header row for a [CcSidebarGroup]; tappable when collapsible.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.collapsible,
    required this.expanded,
    required this.onToggle,
    required this.color,
    this.family,
  });

  final String label;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;
  final Color color;
  final String? family;

  Widget _buildRow(BuildContext context) {
    final labelWidget = Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CcFonts.code(
        textStyle: CcTypography.label,
        family: family,
      ).copyWith(color: color),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: labelWidget),
          if (collapsible)
            AnimatedRotation(
              duration: CcMotion.resolve(context, CcMotion.moderate),
              curve: CcMotion.standard,
              turns: expanded ? 0 : -0.25,
              child: Icon(CcIcons.chevronDown, size: 14, color: color),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!collapsible || onToggle == null) {
      return _buildRow(context);
    }
    return Semantics(
      expanded: expanded,
      child: CcTappable(
        onPressed: onToggle,
        borderRadius: AppRadii.brSm,
        semanticLabel: label,
        builder: (context, states) => _buildRow(context),
      ),
    );
  }
}
