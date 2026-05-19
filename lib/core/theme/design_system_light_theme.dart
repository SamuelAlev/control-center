import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

// ignore_for_file: avoid_redundant_argument_values

/// ForUI theme for the design system's light (default) variant.
///
/// Near-white canvas, ink-black structure, a single rationed orange accent.
/// Field-by-field mapping:
/// * `background`           ← canvas              (near-white #fcfbf9)
/// * `foreground`           ← ink black       (gray-900 #1f1f1f)
/// * `primary`              ← ink black       (gray-900 — dark primary, warms to accent on hover)
/// * `primaryForeground`    ← white
/// * `secondary`            ← warm surface        (gray-100 #f2f0e9)
/// * `secondaryForeground`  ← secondary text      (gray-700)
/// * `muted`                ← warm surface        (gray-100)
/// * `mutedForeground`      ← muted text          (gray-600 #3d3d3d)
/// * `destructive`/`error`  ← danger              (red-600 #dc2626)
/// * `card`                 ← panel               (pure white #ffffff)
/// * `border`               ← warm hairline       (gray-200 #e8e5dc)
///
/// The orange signal lives on the `accent`/`fgBrandPrimary` tokens — see
/// [DesignSystemTokens] for the full semantic token surface.
///
/// [fontFamily] is the user-selected UI font; it is threaded into the forui
/// [FTypography] so every forui surface (field hints, select placeholders/items,
/// sidebar labels) renders in the chosen font, matching the Material text theme.
FThemeData designSystemLight({
  String fontFamily = FTypography.defaultFontFamily,
}) {
  const touch = false;

  final colors = FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: const Color(0x5C1F1F1F), // ink black @ 36% — warm scrim
    // The page canvas is near-white (#fcfbf9), NOT pure white; pure white is
    // reserved for data surfaces (card), so cards read as lifted above the page.
    background: DesignSystemPalette.gray50,
    foreground: DesignSystemPalette.gray900,
    // Primary affordance is ink black, not orange — the page rests calm and
    // warms toward the accent on hover. Orange is the rationed signal, exposed
    // via the `accent` token, not the default fill.
    primary: DesignSystemPalette.gray900,
    primaryForeground: DesignSystemPalette.white,
    secondary: DesignSystemPalette.gray100,
    secondaryForeground: DesignSystemPalette.gray700,
    muted: DesignSystemPalette.gray100,
    mutedForeground: DesignSystemPalette.gray600,
    destructive: DesignSystemPalette.red600,
    destructiveForeground: DesignSystemPalette.white,
    error: DesignSystemPalette.red600,
    errorForeground: DesignSystemPalette.white,
    card: DesignSystemPalette.white,
    // Default border = warm hairline (gray-200 = #e8e5dc) so all
    // FCard / FDivider / FAlert frames render with the secondary border.
    border: DesignSystemPalette.gray200,
  );

  final typography = _typography(
    colors: colors,
    touch: touch,
    fontFamily: fontFamily,
  );
  final style = _style(colors: colors, typography: typography, touch: touch);

  // FSwitch: the toggled-on track uses the orange accent so "on" reads as a
  // real, unmistakable state and matches the dark theme. (forui's default
  // selected track is `colors.primary`, the ink fill.)
  final switchBase = FSwitchStyle.inherit(colors: colors, style: style);
  final switchStyle = FSwitchStyle(
    focusColor: switchBase.focusColor,
    trackColor: FVariants(
      colors.secondary,
      variants: {
        [FSwitchVariant.disabled]: colors.disable(colors.secondary),
        [FSwitchVariant.selected]: DesignSystemPalette.brand600,
        [FSwitchVariant.selected.and(FSwitchVariant.disabled)]:
            colors.disable(DesignSystemPalette.brand600),
      },
    ),
    thumbColor: switchBase.thumbColor,
    leadingLabelStyle: switchBase.leadingLabelStyle,
    trailingLabelStyle: switchBase.trailingLabelStyle,
  );

  return FThemeData(
    colors: colors,
    typography: typography,
    style: style,
    touch: touch,
    switchStyle: switchStyle,
    // FAvatar fallback chip — gray-100 surface with gray-600 initials
    // (design system "avatar/neutral"), not the brand color.
    avatarStyle: FAvatarStyle(
      backgroundColor: colors.muted,
      foregroundColor: colors.mutedForeground,
      textStyle: typography.sm.copyWith(color: colors.mutedForeground),
      fallbackIcon: FIcons.lucide().userRound,
    ),
    // Strip the default vertical/horizontal padding from FDivider.
    dividerStyles: FVariants.all(
      FDividerStyle(
        color: colors.secondary,
        padding: EdgeInsets.zero,
        width: style.borderWidth,
      ),
    ),
  );
}

FTypography _typography({
  required FColors colors,
  required bool touch,
  String fontFamily = FTypography.defaultFontFamily,
}) {
  assert(
    fontFamily.isNotEmpty,
    'fontFamily ($fontFamily) should not be empty.',
  );
  final color = colors.foreground;
  final base = touch
      ? const Scale(
          xs3: 10,
          xs2: 12,
          xs: 14,
          sm: 16,
          md: 18,
          lg: 20,
          xl: 24,
          xl2: 30,
          xl3: 36,
          xl4: 48,
          xl5: 60,
          xl6: 72,
          xl7: 96,
          xl8: 108,
        )
      : const Scale(
          xs3: 10,
          xs2: 12,
          xs: 12,
          sm: 14,
          md: 16,
          lg: 18,
          xl: 20,
          xl2: 24,
          xl3: 30,
          xl4: 36,
          xl5: 48,
          xl6: 60,
          xl7: 72,
          xl8: 96,
        );

  // Route through AppFonts so Google Fonts are actually loaded and the
  // returned style carries the registered variant family (e.g.
  // 'Manrope_regular') rather than the bare 'Manrope', which would not
  // resolve. System fonts (FontLoader-registered under the bare family) pass
  // through unchanged.
  TextStyle make(double size, double height) => AppFonts.uiDynamic(
        fontFamily,
        textStyle: TextStyle(
          color: color,
          fontSize: size,
          height: height,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      );

  // FTypography.fontFamily must hold the *resolved* family so any forui style
  // built from it (not from the size scales below) resolves to the same font.
  final resolvedFamily = make(base.md, 1.5).fontFamily ?? fontFamily;

  return FTypography(
    fontFamily: resolvedFamily,
    xs3: make(base.xs3, 1.4),
    xs2: make(base.xs2, 1.4),
    xs: make(base.xs, 1.5),
    sm: make(base.sm, 1.5),
    md: make(base.md, 1.5),
    lg: make(base.lg, 1.55),
    xl: make(base.xl, 1.5),
    xl2: make(base.xl2, 1.45),
    xl3: make(base.xl3, 1.35),
    xl4: make(base.xl4, 1.25),
    xl5: make(base.xl5, 1.2),
    xl6: make(base.xl6, 1.15),
    xl7: make(base.xl7, 1.1),
    xl8: make(base.xl8, 1.05),
  );
}

FStyle _style({
  required FColors colors,
  required FTypography typography,
  required bool touch,
}) {
  return FStyle(
    formFieldStyle: FFormFieldStyle.inherit(
      colors: colors,
      typography: typography,
      touch: touch,
    ),
    // Focus ring is the signal-orange accent (keyboard operability is a P0).
    focusedOutlineStyle: const FFocusedOutlineStyle(
      color: DesignSystemPalette.brand600,
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
    sizes: FSizes.inherit(touch: touch),
    iconStyle: IconThemeData(
      color: colors.foreground,
      size: typography.lg.fontSize,
    ),
    tappableStyle: FTappableStyle(),
    // Sharp architectural geometry: 2px standard, 4px large containers.
    borderRadius: _sharpRadius,
    borderWidth: 1,
    pagePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    // Golden-hour shadow-soft: warm amber tint, offset lower-left, as if lit by
    // late-afternoon sun from the right. Floating surfaces only.
    shadow: const [
      BoxShadow(
        color: Color(0x0D7F6315),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color(0x0D7F6315),
        offset: Offset(-2, 6),
        blurRadius: 18,
      ),
    ],
  );
}

/// Sharp 2px/4px corner system shared by both themes. Standard elements are
/// 2px (xs2..md); large containers cap at 4px (lg..xl3); pills stay round.
const FBorderRadius _sharpRadius = FBorderRadius(
  xs2: BorderRadius.all(Radius.circular(2)),
  xs: BorderRadius.all(Radius.circular(2)),
  sm: BorderRadius.all(Radius.circular(2)),
  md: BorderRadius.all(Radius.circular(2)),
  lg: BorderRadius.all(Radius.circular(4)),
  xl: BorderRadius.all(Radius.circular(4)),
  xl2: BorderRadius.all(Radius.circular(4)),
  xl3: BorderRadius.all(Radius.circular(4)),
  pill: BorderRadius.all(Radius.circular(100)),
);

