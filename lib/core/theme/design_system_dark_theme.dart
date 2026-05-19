import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

// ignore_for_file: avoid_redundant_argument_values

/// ForUI theme for the design system's warm-dark variant.
///
/// The spec is light-first; this is a coherent warm-dark derivation of the same
/// identity (warm near-blacks, off-white text, the orange accent).
/// * `background`           ← warm near-black      (gray-950 #171614)
/// * `foreground`           ← warm off-white       (gray-50)
/// * `primary`              ← warm off-white       (inverted: light fill, dark text)
/// * `primaryForeground`    ← warm near-black       (gray-950)
/// * `secondary`            ← warm dark surface     (gray-900)
/// * `mutedForeground`      ← muted                 (gray-400)
/// * `destructive`          ← danger                (red-600)
/// * `error`                ← danger text           (red-400)
/// * `card`                 ← page surface          (gray-950)
/// * `border`               ← warm dark hairline    (gray-800)
///
/// The richer semantic tokens live on [DesignSystemTokens] and are registered as
/// a [ThemeExtension] alongside this [FThemeData] in `AppTheme`.
///
/// [fontFamily] is the user-selected UI font; it is threaded into the forui
/// [FTypography] so every forui surface (field hints, select placeholders/items,
/// sidebar labels) renders in the chosen font, matching the Material text theme.
FThemeData designSystemDark({
  String fontFamily = FTypography.defaultFontFamily,
}) {
  const touch = false;

  final colors = FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: const Color(0xB3171614), // warm near-black @ 70%
    background: DesignSystemPalette.gray950,
    foreground: DesignSystemPalette.gray50,
    // Inverted primary: in dark mode the calm structural fill is the warm
    // off-white foreground (the mirror of light mode's dark primary), with
    // dark text on it. The orange accent stays the rationed signal.
    primary: DesignSystemPalette.gray50,
    primaryForeground: DesignSystemPalette.gray950,
    secondary: DesignSystemPalette.gray900,
    secondaryForeground: DesignSystemPalette.gray300,
    muted: DesignSystemPalette.gray800,
    mutedForeground: DesignSystemPalette.gray400,
    destructive: DesignSystemPalette.red600,
    destructiveForeground: DesignSystemPalette.white,
    error: DesignSystemPalette.red400,
    errorForeground: DesignSystemPalette.white,
    // Cards read as part of the page surface rather than a raised panel.
    card: DesignSystemPalette.gray950,
    // Default border = warm dark hairline (gray-800).
    border: DesignSystemPalette.gray800,
  );

  final typography = _typography(
    colors: colors,
    touch: touch,
    fontFamily: fontFamily,
  );
  final style = _style(colors: colors, typography: typography, touch: touch);

  // FSwitch: the toggled-on track uses the rationed orange accent so "on" is
  // unmistakable. forui's default selected track is `colors.primary`, which in
  // this dark theme is the inverted off-white fill — same value as the thumb
  // (`colors.foreground`), so an on switch rendered white-on-white.
  final switchBase = FSwitchStyle.inherit(colors: colors, style: style);
  final switchStyle = FSwitchStyle(
    focusColor: switchBase.focusColor,
    trackColor: FVariants(
      colors.secondary,
      variants: {
        [FSwitchVariant.disabled]: colors.disable(colors.secondary),
        [FSwitchVariant.selected]: DesignSystemPalette.brand500,
        [FSwitchVariant.selected.and(FSwitchVariant.disabled)]:
            colors.disable(DesignSystemPalette.brand500),
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
    // FAvatar fallback chip — gray-800 surface with gray-400 initials
    // (design system "avatar/neutral" in dark mode), not the brand color.
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
  // design system's display/text scale (touch = mobile, desktop otherwise).
  // xs=12 / sm=14 / md=16 (body) / lg=18 (subheading) / xl=20 / 2xl=24 / 3xl=30 …
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
    // Focus ring is the (brighter) orange accent for dark contrast.
    focusedOutlineStyle: const FFocusedOutlineStyle(
      color: DesignSystemPalette.brand500,
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
    // Warm shadow: deeper, amber-black, offset lower-left. Floating only.
    shadow: const [
      BoxShadow(
        color: Color(0x66120D04),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color(0x33120D04),
        offset: Offset(-2, 6),
        blurRadius: 18,
      ),
    ],
  );
}

/// Sharp 2px/4px corner system (mirrors the light theme). Standard elements
/// are 2px; large containers cap at 4px; pills stay round.
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

