import 'dart:async';

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The expanded sidebar width.
const double _kExpandedWidth = 248;

/// The collapsed icon-only rail width. 54px puts the centered 32px item
/// squares on the same x=27 line the expanded rows pin their icon centers
/// to, so toggling the rail never moves an icon.
const double _kCollapsedWidth = 54;

/// Propagates the sidebar's [collapsed] state down to descendant
/// [CcSidebarItem]s and [CcSidebarGroup]s via the element tree.
///
/// Items read this with [CcSidebarScope.collapsedOf] so a single `collapsed`
/// flag on [CcSidebar] flips every row into icon-only rail mode without each
/// call site threading the flag manually.
///
/// [transitioning] is true while the sidebar's width is animating between the
/// two modes. It is published separately from [collapsed] so content can keep
/// its expanded geometry while labels and badges are out of the way — that is
/// what makes the toggle blend smoothly.
class CcSidebarScope extends InheritedWidget {
  /// Creates a [CcSidebarScope].
  const CcSidebarScope({
    required this.collapsed,
    this.transitioning = false,
    required super.child,
    super.key,
  });

  /// Whether the enclosing sidebar is collapsed to the icon-only rail.
  final bool collapsed;

  /// Whether the sidebar is mid-animation between expanded and collapsed.
  final bool transitioning;

  /// The nearest sidebar's collapsed flag, or null when there is no
  /// [CcSidebarScope] ancestor.
  static bool? collapsedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CcSidebarScope>()?.collapsed;

  /// The nearest sidebar's transitioning flag, or null when there is no
  /// [CcSidebarScope] ancestor.
  static bool? transitioningOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CcSidebarScope>()
      ?.transitioning;

  @override
  bool updateShouldNotify(CcSidebarScope oldWidget) =>
      collapsed != oldWidget.collapsed ||
      transitioning != oldWidget.transitioning;
}

/// A vertical app-shell navigation container.
///
/// Stacks an optional [header], a scrolling body of [children] (typically
/// [CcSidebarGroup]s and [CcSidebarItem]s), and an optional pinned [footer]. The
/// surface fills with [background] (defaulting to the `sidebar` token) so items'
/// transparent rows read against it.
///
/// Setting [collapsed] animates the width down to a 54px icon-only rail
/// ([CcMotion.slow], reduced-motion aware) and publishes the collapsed state via
/// a [CcSidebarScope] so descendant items render icon-only.
///
/// The scope flip is deliberately deferred from the width animation so the
/// toggle blends without layout shift: when collapsing, descendants keep their
/// expanded geometry (with labels faded out and badges removed) until the rail
/// width arrives, then swap to the centered squares; when expanding, the swap
/// happens up front. Both modes place icon centers on the same x=27 line
/// (the expanded row's 10px visual left inset aligns the icon with the group
/// header text AND centers it on that line), so no icon ever moves — the
/// animation reads as labels appearing/disappearing while the panel narrows
/// or grows.
class CcSidebar extends StatefulWidget {
  /// Creates a [CcSidebar].
  const CcSidebar({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.headerGap = AppSpacing.md,
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

  /// Vertical space between the [header] and the scrolling body. Defaults to
  /// [AppSpacing.md]; app-shell sidebars with a tall header (e.g. one carrying
  /// a window-chrome strip) tighten it so the first group doesn't drift.
  final double headerGap;

  /// The expanded width. Ignored when [collapsed] (the rail is a fixed 54px).
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
  State<CcSidebar> createState() => _CcSidebarState();
}

class _CcSidebarState extends State<CcSidebar> {
  /// The collapsed flag published to descendants. Trails [CcSidebar.collapsed]
  /// when collapsing (so rows hold their expanded geometry while the width
  /// animates) and matches it immediately when expanding.
  late bool _scopeCollapsed = widget.collapsed;

  /// Published while the width animation is in flight.
  bool _transitioning = false;

  Timer? _settleTimer;

  @override
  void didUpdateWidget(covariant CcSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed == widget.collapsed) {
      return;
    }
    _settleTimer?.cancel();
    final duration = CcMotion.resolve(context, CcMotion.slow);
    if (duration == Duration.zero) {
      // Reduced motion: no animation, so nothing to blend — flip immediately.
      setState(() {
        _scopeCollapsed = widget.collapsed;
        _transitioning = false;
      });
      return;
    }
    setState(() {
      // Expanding flips the rows in up front (their icon x matches the rail
      // square's); collapsing keeps the expanded geometry until the rail
      // width arrives.
      if (!widget.collapsed) {
        _scopeCollapsed = false;
      }
      _transitioning = true;
    });
    _settleTimer = Timer(duration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _scopeCollapsed = widget.collapsed;
        _transitioning = false;
      });
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return CcSidebarScope(
      collapsed: _scopeCollapsed,
      transitioning: _transitioning,
      child: AnimatedContainer(
        duration: CcMotion.resolve(context, CcMotion.slow),
        curve: CcMotion.emphasized,
        width: widget.collapsed ? _kCollapsedWidth : widget.width,
        decoration: BoxDecoration(
          color: widget.background ?? t.sidebar,
          border: widget.trailingBorder == null
              ? null
              : Border(right: widget.trailingBorder!),
        ),
        // Horizontal inset lives on the ListView's own padding (and explicit
        // wrappers around header/footer), NOT on this container: the desktop
        // scrollbar inserted by the scroll behavior draws at the viewport
        // edge, so the viewport must span the full sidebar width for the
        // thumb to sit flush against the container side instead of
        // overlapping the items. The right inset additionally loses
        // [trailingBorder]'s width to the border itself (a decoration border
        // insets its child), so subtracting it here keeps the content
        // centered — the rail's icons land on the exact horizontal center of
        // the 54px rail instead of half a pixel off.
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Builder(
          builder: (context) {
            final rightInset =
                AppSpacing.sm - (widget.trailingBorder?.width ?? 0);
            final contentPadding = EdgeInsets.only(
              left: AppSpacing.sm,
              right: rightInset,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.header != null) ...[
                  Padding(padding: contentPadding, child: widget.header!),
                  SizedBox(height: widget.headerGap),
                ],
                Expanded(
                  child: ListView(
                    padding: contentPadding,
                    children: widget.children,
                  ),
                ),
                if (widget.footer != null) ...[
                  AppSpacing.vGapMd,
                  Padding(padding: contentPadding, child: widget.footer!),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
