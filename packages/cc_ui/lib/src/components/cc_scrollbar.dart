import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The design-system scrollbar: a flat, square-cornered thumb drawn with the
/// `lineStrong` token (a translucent foreground overlay, so it reads on any
/// surface in both light and dark themes).
///
/// Squared geometry is the identity of the design system — zero radius on
/// every control — so the thumb is deliberately angular, never the rounded
/// Material/Cupertino capsule.
///
/// Wrapping a scrollable in [CcScrollbar] also suppresses the app-level
/// scrollbar that [CcScrollBehavior] injects for the subtree, so a surface
/// that needs explicit control (always-visible thumb, horizontal orientation,
/// custom thickness) never draws two overlapping thumbs.
class CcScrollbar extends StatelessWidget {
  /// Creates a [CcScrollbar].
  const CcScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thumbVisibility,
    this.thickness = 8,
    this.color,
    this.interactive,
    this.scrollbarOrientation,
  }) : _suppressAmbient = true;

  /// Used by [CcScrollBehavior] when decorating a scrollable itself: the
  /// ambient behavior must stay untouched so nested scrollables keep their
  /// own injected scrollbars.
  const CcScrollbar._injected({
    required this.child,
    this.controller,
    this.thumbVisibility,
  }) : thickness = 8,
       color = null,
       interactive = null,
       scrollbarOrientation = null,
       _suppressAmbient = false;

  /// The scrollable this scrollbar decorates.
  final Widget child;

  /// The controller shared with the scrollable; falls back to the ambient
  /// [PrimaryScrollController] when null.
  final ScrollController? controller;

  /// Whether the thumb stays visible at rest instead of fading out after a
  /// scroll. Defaults to the [RawScrollbar] fade behavior when null.
  final bool? thumbVisibility;

  /// Thumb thickness in logical pixels.
  final double thickness;

  /// Thumb color; defaults to the `lineStrong` token.
  final Color? color;

  /// Whether the thumb can be hovered and dragged.
  final bool? interactive;

  /// Which edge of the scrollable the thumb is pinned to; defaults to the
  /// trailing edge for the scroll axis.
  final ScrollbarOrientation? scrollbarOrientation;

  final bool _suppressAmbient;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    var content = child;
    if (_suppressAmbient) {
      content = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: content,
      );
    }
    // No `radius`/`shape`: RawScrollbar paints a square-cornered thumb by
    // default, which is exactly the design system's zero-radius geometry.
    return RawScrollbar(
      controller: controller,
      thumbVisibility: thumbVisibility,
      thumbColor: color ?? t.lineStrong,
      thickness: thickness,
      interactive: interactive,
      scrollbarOrientation: scrollbarOrientation,
      child: content,
    );
  }
}

/// The app-wide [ScrollBehavior]: decorates every vertical scrollable on
/// desktop platforms (and desktop web) with a [CcScrollbar] instead of the
/// rounded Material one, so scrollbars look design-system-native everywhere
/// without per-surface wiring.
///
/// Mirrors the Material behavior's semantics — vertical axis only, desktop
/// platforms only, thumb visible at rest — so installing it changes styling,
/// not which surfaces get a scrollbar. Install via
/// `MaterialApp(scrollBehavior: const CcScrollBehavior())`.
class CcScrollBehavior extends ScrollBehavior {
  /// Creates a [CcScrollBehavior].
  const CcScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
        // Horizontal scrollables opt in explicitly with [CcScrollbar]; an
        // injected thumb would collide with hand-rolled horizontal bars.
        return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return CcScrollbar._injected(
              controller: details.controller,
              thumbVisibility: true,
              child: child,
            );
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            return child;
        }
    }
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow/stretch chrome: overscroll decoration is a Material-ism the
    // design system deliberately drops (quiet surfaces, clamping physics on
    // desktop anyway).
    return child;
  }
}
