import 'dart:ui' as ui;

import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A flat, floating modal dialog surface for the design system.
///
/// Renders a centered panel (`t.panel` background, [AppRadii.brLg] corners, the
/// signature warm [CcElevation.floating] shadow, hairline border) with an
/// optional [title], a required [content], and an optional right-aligned
/// [actions] row. Pair with [showCcDialog] to present it over a scrim.
class CcDialog extends StatelessWidget {
  /// Creates a [CcDialog].
  const CcDialog({
    super.key,
    required this.content,
    this.title,
    this.actions,
    this.maxWidth = 480,
  });

  /// Optional heading shown above the [content].
  final String? title;

  /// The dialog body.
  final Widget content;

  /// Optional action buttons, laid out in a right-aligned row.
  final List<Widget>? actions;

  /// Maximum width of the dialog panel.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final actions = this.actions;
    final title = this.title;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderPrimary),
          boxShadow: CcElevation.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  style: CcTypography.title.copyWith(color: t.textPrimary),
                ),
                AppSpacing.vGapMd,
              ],
              DefaultTextStyle.merge(
                style: CcTypography.body.copyWith(color: t.textSecondary),
                child: content,
              ),
              if (actions != null && actions.isNotEmpty) ...[
                AppSpacing.vGapLg,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) AppSpacing.hGapSm,
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Presents a modal dialog built by [builder], centered over a warm scrim.
///
/// Implemented with [showGeneralDialog] (part of `package:flutter/widgets.dart`)
/// so cc_ui stays off the Material layer. The scrim is a translucent
/// `bgOverlay` wash over a [BackdropFilter] blur, so the surface beneath stays
/// legible-but-defocused (frosted glass) instead of being fully obscured. The
/// entrance is a quick fade + scale on the panel that collapses to an instant
/// cut when motion is reduced (via [CcMotion.resolve]). Returns the value the
/// dialog is popped with, or null if dismissed.
Future<T?> showCcDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = context.ccTheme;
  final t = theme?.tokens ?? DesignSystemTokens.light();
  final duration = CcMotion.resolve(context, CcMotion.normal);

  // `showGeneralDialog` presents into the root overlay, outside any route's
  // `Material`/text theme. The only ambient `DefaultTextStyle` there is
  // `WidgetsApp`'s error fallback — 48px red text with a double yellow
  // underline — which every dialog `Text` would otherwise inherit (and
  // bleed the underline through, since copyWith leaves `decoration` unset).
  // Supply a complete design-system base style here so dialog text renders
  // correctly without dragging cc_ui onto the Material layer.
  final dialogTextStyle = CcFonts.ui(
    family: theme?.fontFamily,
    textStyle: CcTypography.body.copyWith(
      color: t.textPrimary,
      decoration: TextDecoration.none,
    ),
  );

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    // The scrim lives in the page content (so it can blur); keep the route's
    // own barrier transparent but still dismissible.
    barrierColor: const Color(0x00000000),
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => DefaultTextStyle(
      style: dialogTextStyle,
      child: builder(context),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: CcMotion.emphasized,
      );
      return Stack(
        children: [
          // Frosted scrim over the content beneath. `IgnorePointer` lets taps
          // fall through to the route barrier (dismiss) and to the panel on
          // top. The [BackdropFilter] must never sit inside an
          // `Opacity`/`FadeTransition`: the save-layer boundary blanks its
          // backdrop, so only the tint alpha and blur radius are animated here.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, _) {
                  final v = curved.value;
                  return BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 6 * v,
                      sigmaY: 6 * v,
                    ),
                    child: ColoredBox(
                      color: t.bgOverlay.withValues(alpha: 0.5 * v),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}
