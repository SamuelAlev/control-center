import 'dart:async';

import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat, ink-dark tooltip that appears after a short hover dwell.
///
/// Wraps [child] in a [MouseRegion]; on hover-enter a ~[showDelay] timer starts
/// and, once it fires, a small dark panel carrying [message] is shown anchored
/// beneath the child via a [CcOverlayAnchor]. Leaving the child cancels the
/// timer and hides the panel. The panel is non-dismissible by tapping outside —
/// it is purely hover-driven. Motion is suppressed under reduced-motion.
class CcTooltip extends StatefulWidget {
  /// Creates a [CcTooltip].
  const CcTooltip({
    super.key,
    required this.child,
    this.message,
    this.tip,
    this.alignment,
    this.showDelay = const Duration(milliseconds: 500),
    this.targetAnchor = Alignment.bottomCenter,
    this.followerAnchor = Alignment.topCenter,
    this.offset = const Offset(0, AppSpacing.xs),
    this.maxWidth = 280,
  }) : assert(
          message != null || tip != null,
          'CcTooltip needs a message or a tip',
        );

  /// The widget the tooltip describes.
  final Widget child;

  /// The tooltip text (used when [tip] is null).
  final String? message;

  /// Optional rich tooltip content, rendered inside the dark panel chrome
  /// instead of [message]. Provide exactly one of [message] or [tip].
  final Widget? tip;

  /// Alignment of the message text within the panel.
  final AlignmentGeometry? alignment;

  /// Hover dwell before the tooltip appears.
  final Duration showDelay;

  /// Point on the target the panel aligns to.
  final Alignment targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the panel.
  final Offset offset;

  /// Maximum width of the tooltip panel before the text wraps.
  final double maxWidth;

  @override
  State<CcTooltip> createState() => _CcTooltipState();
}

class _CcTooltipState extends State<CcTooltip> {
  final CcOverlayController _controller = CcOverlayController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    _timer?.cancel();
    _timer = Timer(widget.showDelay, _show);
  }

  void _onExit() {
    _timer?.cancel();
    _timer = null;
    _controller.hide();
  }

  void _show() {
    if (!mounted) {
      return;
    }
    _controller.show();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: CcOverlayAnchor(
        controller: _controller,
        targetAnchor: widget.targetAnchor,
        followerAnchor: widget.followerAnchor,
        offset: widget.offset,
        barrierDismissible: false,
        target: widget.child,
        overlayBuilder: _buildPanel,
      ),
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    return _CcTooltipPanel(
      message: widget.message,
      tip: widget.tip,
      alignment: widget.alignment,
      maxWidth: widget.maxWidth,
    );
  }
}

/// The dark tooltip panel — fades itself in on mount so it animates each time
/// the overlay reopens (the [CcOverlayAnchor] rebuilds it fresh on show).
class _CcTooltipPanel extends StatefulWidget {
  const _CcTooltipPanel({
    required this.message,
    required this.tip,
    required this.alignment,
    required this.maxWidth,
  });

  final String? message;
  final Widget? tip;
  final AlignmentGeometry? alignment;
  final double maxWidth;

  @override
  State<_CcTooltipPanel> createState() => _CcTooltipPanelState();
}

class _CcTooltipPanelState extends State<_CcTooltipPanel> {
  bool _opaque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opaque = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final duration = CcMotion.resolve(context, CcMotion.normal);

    final panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.fg,
          borderRadius: AppRadii.brSm,
          boxShadow: CcElevation.raised,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: widget.tip != null
              ? DefaultTextStyle(
                  style: CcTypography.caption.copyWith(color: t.textWhite),
                  child: widget.tip!,
                )
              : Text(
                  widget.message!,
                  textAlign: TextAlign.start,
                  style: CcTypography.caption.copyWith(color: t.textWhite),
                ),
        ),
      ),
    );

    final aligned = widget.alignment == null
        ? panel
        : Align(alignment: widget.alignment!, child: panel);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _opaque ? 1 : 0,
        duration: duration,
        curve: CcMotion.standard,
        child: aligned,
      ),
    );
  }
}
