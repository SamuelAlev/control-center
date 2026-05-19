import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
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
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 6),
    this.matchTargetWidth = false,
    this.barrierDismissible = true,
    this.toggleOnTargetTap = true,
    this.semanticLabel,
  });

  /// The trigger widget the popover anchors to.
  final Widget target;

  /// Builds the popover's inner content (it is wrapped in a floating panel).
  final CcOverlayContentBuilder overlayBuilder;

  /// Optional external open/close controller; an internal one is created when
  /// null.
  final CcOverlayController? controller;

  /// Point on the target the panel aligns to.
  final Alignment targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the panel.
  final Offset offset;

  /// Constrain the panel to the target's width.
  final bool matchTargetWidth;

  /// Whether tapping outside closes the popover.
  final bool barrierDismissible;

  /// Whether tapping the target toggles the popover.
  final bool toggleOnTargetTap;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcPopover> createState() => _CcPopoverState();
}

class _CcPopoverState extends State<CcPopover> {
  CcOverlayController? _internal;

  CcOverlayController get _controller =>
      widget.controller ?? (_internal ??= CcOverlayController());

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.toggleOnTargetTap
        ? CcTappable(
            onPressed: _controller.toggle,
            semanticLabel: widget.semanticLabel,
            builder: (context, states) => widget.target,
          )
        : widget.target;

    return CcOverlayAnchor(
      controller: _controller,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      matchTargetWidth: widget.matchTargetWidth,
      barrierDismissible: widget.barrierDismissible,
      target: trigger,
      overlayBuilder: _buildPanel,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: card.border),
        boxShadow: CcElevation.floating,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: widget.overlayBuilder(context, targetSize),
      ),
    );
  }
}
