import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The expanded sidebar width.
const double _kExpandedWidth = 248;

/// The collapsed icon-only rail width.
const double _kCollapsedWidth = 64;

/// Propagates the sidebar's [collapsed] state down to descendant
/// [CcSidebarItem]s and [CcSidebarGroup]s via the element tree.
///
/// Items read this with [CcSidebarScope.collapsedOf] so a single `collapsed`
/// flag on [CcSidebar] flips every row into icon-only rail mode without each
/// call site threading the flag manually.
class CcSidebarScope extends InheritedWidget {
  /// Creates a [CcSidebarScope].
  const CcSidebarScope({
    required this.collapsed,
    required super.child,
    super.key,
  });

  /// Whether the enclosing sidebar is collapsed to the icon-only rail.
  final bool collapsed;

  /// The nearest sidebar's collapsed flag, or null when there is no
  /// [CcSidebarScope] ancestor.
  static bool? collapsedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CcSidebarScope>()?.collapsed;

  @override
  bool updateShouldNotify(CcSidebarScope oldWidget) =>
      collapsed != oldWidget.collapsed;
}

/// A vertical app-shell navigation container.
///
/// Stacks an optional [header], a scrolling body of [children] (typically
/// [CcSidebarGroup]s and [CcSidebarItem]s), and an optional pinned [footer]. The
/// surface fills with [background] (defaulting to the `sidebar` token) so items'
/// transparent rows read against it.
///
/// Setting [collapsed] animates the width down to a 64px icon-only rail
/// ([CcMotion.slow], reduced-motion aware) and publishes the collapsed state via
/// a [CcSidebarScope] so descendant items render icon-only.
class CcSidebar extends StatelessWidget {
  /// Creates a [CcSidebar].
  const CcSidebar({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.width = _kExpandedWidth,
    this.collapsed = false,
    this.background,
    this.trailingBorder,
  });

  /// Body content — usually [CcSidebarGroup]s and [CcSidebarItem]s.
  final List<Widget> children;

  /// Optional content pinned above the scrolling body (e.g. a workspace switch).
  final Widget? header;

  /// Optional content pinned to the bottom (e.g. an account row).
  final Widget? footer;

  /// The expanded width. Ignored when [collapsed] (the rail is a fixed 64px).
  final double width;

  /// Whether the sidebar is collapsed to the icon-only rail.
  final bool collapsed;

  /// The surface color. Defaults to the `sidebar` token.
  final Color? background;

  /// Optional hairline drawn on the sidebar's right edge. App-shell sidebars
  /// set this (a `borderPrimary` [BorderSide]) so the panel reads as a distinct
  /// surface against the content area; nested/resizable sidebars leave it null
  /// to avoid doubling an adjacent divider.
  final BorderSide? trailingBorder;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return CcSidebarScope(
      collapsed: collapsed,
      child: AnimatedContainer(
        duration: CcMotion.resolve(context, CcMotion.slow),
        curve: CcMotion.emphasized,
        width: collapsed ? _kCollapsedWidth : width,
        decoration: BoxDecoration(
          color: background ?? t.sidebar,
          border: trailingBorder == null
              ? null
              : Border(right: trailingBorder!),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              AppSpacing.vGapMd,
            ],
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: children,
              ),
            ),
            if (footer != null) ...[
              AppSpacing.vGapMd,
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
