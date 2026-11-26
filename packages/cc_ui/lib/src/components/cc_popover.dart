import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_focus_trap.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_trigger_wash.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:flutter/widgets.dart';

/// A flat floating panel anchored to a [target], shown on tap (or driven by an
/// external [CcOverlayController]).
///
/// Wraps [overlayBuilder]'s content in a [CcCard]-like floating surface
/// (`t.panel` fill, hairline border, large radius, golden float shadow). When no
/// [controller] is supplied an internal one is created and tapping the target
/// toggles it; supply a [controller] to drive open/close yourself (the target
/// is then rendered inert to taps unless [toggleOnTargetTap] is left on).
class CcPopover extends StatefulWidget {
  /// Creates a [CcPopover].
  const CcPopover({
    super.key,
    required this.target,
    required this.overlayBuilder,
    this.controller,
    this.targetAnchor = AlignmentDirectional.bottomStart,
    this.followerAnchor = AlignmentDirectional.topStart,
    this.offset = const Offset(0, 6),
    this.matchTargetWidth = false,
    this.barrierDismissible = true,
    this.toggleOnTargetTap = true,
    this.interceptPointer = true,
    this.semanticLabel,
  });

  /// The trigger widget the popover anchors to.
  final Widget target;

  /// Builds the popover's inner content (it is wrapped in a floating panel).
  final CcOverlayContentBuilder overlayBuilder;

  /// Optional external open/close controller; an internal one is created when
  /// null.
  final CcOverlayController? controller;

  /// Point on the target the panel aligns to (directional — mirrors in RTL).
  final AlignmentGeometry targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final AlignmentGeometry followerAnchor;

  /// Extra offset applied to the panel. With directional anchors the `dx` is
  /// logical (toward the reading direction's end) and mirrors under RTL.
  final Offset offset;

  /// Constrain the panel to the target's width.
  final bool matchTargetWidth;

  /// Whether tapping outside closes the popover.
  final bool barrierDismissible;

  /// Whether tapping the target toggles the popover.
  ///
  /// On, the target is wrapped in a trigger that paints the ghost hover and
  /// press wash. Turn this off when [target] is itself a button and drive a
  /// [controller] from that button's `onPressed`: the wrapper is a second
  /// tappable, so the two recognizers fight over the tap, and an opaque
  /// target covers the wrapper's wash. The button is what carries the hover
  /// then.
  final bool toggleOnTargetTap;

  /// Whether to shield the panel + barrier with a [PointerInterceptor] so taps
  /// land when the popover floats over a web platform view (an `<iframe>` /
  /// embedded webview). Defaults on; no-op off-web.
  final bool interceptPointer;

  /// Accessibility label for the trigger. With [toggleOnTargetTap] off the
  /// caller's button is the trigger, so it names itself and reports its own
  /// expanded state.
  final String? semanticLabel;

  @override
  State<CcPopover> createState() => _CcPopoverState();
}

class _CcPopoverState extends State<CcPopover> {
  CcOverlayController? _internal;

  // Focus scope for the open panel: the trap moves focus into it on open (so
  // Escape and Tab operate within it), `closedLoop` keeps Tab inside the
  // popover, and closing hands focus back to the trigger.
  final FocusScopeNode _panelScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  CcOverlayController get _controller =>
      widget.controller ?? (_internal ??= CcOverlayController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOpenChanged);
  }

  @override
  void didUpdateWidget(CcPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internal)?.removeListener(_onOpenChanged);
      _controller.addListener(_onOpenChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onOpenChanged);
    _internal?.dispose();
    _panelScope.dispose();
    super.dispose();
  }

  /// The trigger reports open/closed to assistive technology.
  void _onOpenChanged() {
    if (mounted && widget.toggleOnTargetTap) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.toggleOnTargetTap
        ? CcTappable(
            onPressed: _controller.toggle,
            borderRadius: AppRadii.brSm,
            semanticLabel: widget.semanticLabel,
            semanticExpanded: _controller.isOpen,
            builder: (context, states) =>
                CcTriggerWash(states: states, child: widget.target),
          )
        : widget.target;

    return CcOverlayAnchor(
      controller: _controller,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      matchTargetWidth: widget.matchTargetWidth,
      barrierDismissible: widget.barrierDismissible,
      interceptPointer: widget.interceptPointer,
      target: trigger,
      overlayBuilder: _buildPanel,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final theme = context.ccTheme;
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    // OverlayPortal paints on the overlay; the nearest DefaultTextStyle there
    // is often WidgetsApp's error fallback (48px, double yellow underline).
    // CopyWith on body styles leaves decoration unset, so the underline
    // bleeds through every Text in the panel. Same discipline as showCcDialog.
    final baseStyle = CcFonts.ui(
      family: theme?.fontFamily,
      textStyle: CcTypography.body.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: card.border),
        boxShadow: CcElevation.floating,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: DefaultTextStyle(
          style: baseStyle,
          child: CcFocusTrap(
            node: _panelScope,
            child: widget.overlayBuilder(context, targetSize),
          ),
        ),
      ),
    );
  }
}
