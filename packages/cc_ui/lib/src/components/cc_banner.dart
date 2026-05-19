import 'package:cc_ui/src/components/cc_button.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The semantic intent of a [CcBanner], driving its tint and default glyph.
enum CcBannerVariant {
  /// Neutral / time-critical prompt — brand tint.
  info,

  /// Positive outcome.
  success,

  /// Caution — something needs attention.
  warning,

  /// Error / failure — something is broken.
  danger,
}

/// A single actionable control on a [CcBanner] (a label + a callback).
///
/// The banner renders these as buttons; [primary] picks the loud accent
/// treatment for the one recommended action (the rest read as secondary).
@immutable
class CcBannerAction {
  /// Creates a [CcBannerAction].
  const CcBannerAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  /// The button label (the caller localizes it).
  final String label;

  /// Invoked when the action is triggered.
  final VoidCallback onPressed;

  /// Whether this is the recommended action (rendered in the accent variant).
  final bool primary;
}

/// A floating, ambient banner for a time-critical, actionable event.
///
/// Louder than an in-flow [CcAlert]: it lifts off the canvas with the golden
/// float shadow and is meant to be stacked into an ambient rail overlay. Intent
/// reads from the leading status glyph, tint, and copy together — **never color
/// alone** (DESIGN.md accessibility bar), so the glyph is always present and the
/// banner is announced to assistive tech as a live region.
///
/// Motion: slides down and fades in on mount, and collapses to a static
/// appearance when the ambient [CcTheme] (or the platform) requests reduced
/// motion.
class CcBanner extends StatefulWidget {
  /// Creates a [CcBanner].
  const CcBanner({
    super.key,
    required this.title,
    this.body,
    this.variant = CcBannerVariant.info,
    this.icon,
    this.actions = const [],
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
  });

  /// The banner's headline text.
  final String title;

  /// Optional supporting body below the title.
  final String? body;

  /// The semantic variant driving the tint and default glyph role.
  final CcBannerVariant variant;

  /// Leading status glyph. When null, a glyph matching [variant] is used so the
  /// status marker is always present (color is never the only signal).
  final IconData? icon;

  /// Optional actionable controls rendered as buttons below the body.
  final List<CcBannerAction> actions;

  /// Optional dismiss handler. When set, a close (×) control renders at the
  /// top-right.
  final VoidCallback? onDismiss;

  /// Accessibility label for the dismiss control (localized by the caller).
  final String dismissLabel;

  @override
  State<CcBanner> createState() => _CcBannerState();
}

class _CcBannerState extends State<CcBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CcMotion.normal,
      value: 1, // Start settled; play the entrance in didChangeDependencies.
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: no slide/fade — render settled and static.
    if (CcMotion.reduced(context)) {
      _controller.value = 1;
    } else if (_controller.value == 1 && !_controller.isAnimating) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final colors = _resolve(t);
    final statusIcon = widget.icon ?? _defaultIcon(widget.variant);

    Widget banner = DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: colors.border),
        boxShadow: CcElevation.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusGlyph(icon: statusIcon, bg: colors.bg, fg: colors.fg),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: CcTypography.body.copyWith(
                            color: t.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      if (widget.onDismiss != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _BannerCloseButton(
                          onDismiss: widget.onDismiss!,
                          color: t.textTertiary,
                          semanticLabel: widget.dismissLabel,
                        ),
                      ],
                    ],
                  ),
                  if (widget.body != null && widget.body!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.body!,
                      style: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                  if (widget.actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final action in widget.actions)
                          CcButton(
                            size: CcButtonSize.sm,
                            variant: action.primary
                                ? CcButtonVariant.accent
                                : CcButtonVariant.secondary,
                            onPressed: action.onPressed,
                            child: Text(action.label),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    banner = Semantics(
      container: true,
      liveRegion: true,
      label: widget.title,
      child: banner,
    );

    // Entrance: slide down + fade. Under reduced motion the controller is
    // pinned to 1, so both transitions are no-ops (static).
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: CcMotion.emphasized),
            ),
        child: banner,
      ),
    );
  }

  IconData _defaultIcon(CcBannerVariant v) {
    switch (v) {
      case CcBannerVariant.info:
        return CcIcons.info;
      case CcBannerVariant.success:
        return CcIcons.circleCheck;
      case CcBannerVariant.warning:
        return CcIcons.triangleAlert;
      case CcBannerVariant.danger:
        return CcIcons.circleX;
    }
  }

  _BannerColors _resolve(DesignSystemTokens t) {
    switch (widget.variant) {
      case CcBannerVariant.info:
        return _BannerColors(
          bg: t.accentSoft,
          border: t.borderBrand,
          fg: t.accent,
        );
      case CcBannerVariant.success:
        return _BannerColors(
          bg: t.successSoft,
          border: t.success,
          fg: t.success,
        );
      case CcBannerVariant.warning:
        return _BannerColors(bg: t.warnSoft, border: t.warn, fg: t.warn);
      case CcBannerVariant.danger:
        return _BannerColors(
          bg: t.dangerSoft,
          border: t.borderError,
          fg: t.danger,
        );
    }
  }
}

/// The leading status marker: a soft-tinted square holding the variant glyph.
class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.icon, required this.bg, required this.fg});

  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(child: Icon(icon, size: 16, color: fg)),
      ),
    );
  }
}

class _BannerColors {
  const _BannerColors({
    required this.bg,
    required this.border,
    required this.fg,
  });

  final Color bg;
  final Color border;
  final Color fg;
}

/// The small dismiss control for a [CcBanner].
class _BannerCloseButton extends StatelessWidget {
  const _BannerCloseButton({
    required this.onDismiss,
    required this.color,
    required this.semanticLabel,
  });

  final VoidCallback onDismiss;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onDismiss,
      semanticLabel: semanticLabel,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            CcIcons.x,
            size: 14,
            color: hovered ? color : color.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }
}
