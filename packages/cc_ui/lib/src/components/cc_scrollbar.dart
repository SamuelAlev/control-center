import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// Desktop [ScrollView]s do not inherit [PrimaryScrollController] by default
/// (only Android/iOS/Fuchsia do). An explicit [CcScrollbar] that does not
/// pass a controller has to opt the subtree in on every platform, or the
/// thumb's hover path asserts that the primary controller has no clients.
const Set<TargetPlatform> _kInheritPrimaryOnAllPlatforms = {
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.iOS,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

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
class CcScrollbar extends StatefulWidget {
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

  /// The controller shared with the scrollable.
  ///
  /// When null on an explicit wrap, [CcScrollbar] owns a controller and
  /// exposes it as a [PrimaryScrollController] that every platform inherits.
  /// Pass an explicit controller when the child scrollable already has one —
  /// both must share it.
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
  State<CcScrollbar> createState() => _CcScrollbarState();
}

class _CcScrollbarState extends State<CcScrollbar> {
  ScrollController? _owned;

  bool get _ownsController =>
      widget._suppressAmbient && widget.controller == null;

  ScrollController? get _effectiveController =>
      widget.controller ?? _owned;

  @override
  void initState() {
    super.initState();
    _syncOwnedController();
  }

  @override
  void didUpdateWidget(CcScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget._suppressAmbient != widget._suppressAmbient) {
      _syncOwnedController();
    }
  }

  void _syncOwnedController() {
    if (_ownsController) {
      _owned ??= ScrollController();
    } else if (_owned != null) {
      _owned!.dispose();
      _owned = null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    var content = widget.child;
    if (widget._suppressAmbient) {
      content = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: content,
      );
    }
    // Own a primary controller so a desktop [ScrollView] with no controller
    // of its own still attaches. [RawScrollbar] otherwise falls back to the
    // ambient [PrimaryScrollController], which desktop scrollables do not
    // inherit — hover then asserts "no ScrollPosition attached".
    if (_ownsController) {
      content = PrimaryScrollController(
        controller: _owned!,
        automaticallyInheritForPlatforms: _kInheritPrimaryOnAllPlatforms,
        child: content,
      );
    }
    // No `radius`/`shape`: RawScrollbar paints a square-cornered thumb by
    // default, which is exactly the design system's zero-radius geometry.
    return RawScrollbar(
      controller: _effectiveController,
      thumbVisibility: widget.thumbVisibility,
      thumbColor: widget.color ?? t.lineStrong,
      thickness: widget.thickness,
      interactive: widget.interactive,
      scrollbarOrientation: widget.scrollbarOrientation,
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
            // [Scrollable] supplies its effective controller. Without it the
            // thumb would fall back to [PrimaryScrollController], which
            // desktop scrollables do not attach to.
            final controller = details.controller;
            if (controller == null) {
              return child;
            }
            return CcScrollbar._injected(
              controller: controller,
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
