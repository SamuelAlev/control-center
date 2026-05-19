import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_dark_theme.dart';
import 'package:control_center/core/theme/design_system_light_theme.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme.
class AppTheme {
  AppTheme._();

  /// Light ForUI theme data, rendered in the user-selected [appFontFamily].
  static FThemeData lightFTheme({String appFontFamily = 'Manrope'}) =>
      _withBrandedSidebar(
        designSystemLight(fontFamily: appFontFamily),
        activeBackground: DesignSystemPalette.brand600.withValues(alpha: 0.12),
        activeForeground: DesignSystemPalette.brand600,
      );

  /// Dark ForUI theme data, rendered in the user-selected [appFontFamily].
  static FThemeData darkFTheme({String appFontFamily = 'Manrope'}) =>
      _withBrandedSidebar(
        designSystemDark(fontFamily: appFontFamily),
        activeBackground: DesignSystemPalette.brand500.withValues(alpha: 0.16),
        activeForeground: DesignSystemPalette.brand500,
      );

  /// Gives the selected sidebar item a brand identity.
  ///
  /// ForUI's default `FSidebarItemStyle.inherit` collapses `selected`,
  /// `hovered`, and `pressed` onto the same grey `secondary` fill with
  /// `foreground` text — so the active destination is indistinguishable from a
  /// hovered one, and the nav loses its "you are here" signal entirely. Per
  /// DESIGN.md the active item carries an accent-tinted fill plus accent text +
  /// icon at weight 400 (hierarchy comes from color, not weight — the orange
  /// "you are here" is one of the rationed accent uses). Selected is a
  /// higher-tier variant constraint than hovered/pressed, so a selected item
  /// keeps its brand treatment even while hovered. Applied at the theme level
  /// so every sidebar (primary nav, the settings sub-sidebar, the footer item)
  /// inherits it from one place.
  static FThemeData _withBrandedSidebar(
    FThemeData base, {
    required Color activeBackground,
    required Color activeForeground,
  }) {
    final colors = base.colors;
    final item = base.sidebarStyle.groupStyle.itemStyle;
    final branded = FSidebarItemStyle(
      backgroundColor: FVariants(
        colors.background,
        variants: {
          [FTappableVariantConstraint.selected]: activeBackground,
          [
            FTappableVariantConstraint.hovered,
            FTappableVariantConstraint.pressed,
          ]: colors.secondary,
          [FTappableVariantConstraint.disabled]: colors.background,
        },
      ),
      textStyle: FVariants(
        item.textStyle.base,
        variants: {
          [FTappableVariantConstraint.selected]: item.textStyle.base.copyWith(
            color: activeForeground,
            fontWeight: FontWeight.w400,
          ),
          [FTappableVariantConstraint.disabled]: item.textStyle.base.copyWith(
            color: colors.mutedForeground,
          ),
        },
      ),
      iconStyle: FVariants(
        item.iconStyle.base,
        variants: {
          [FTappableVariantConstraint.selected]: item.iconStyle.base.copyWith(
            color: activeForeground,
          ),
          [FTappableVariantConstraint.disabled]: item.iconStyle.base.copyWith(
            color: colors.mutedForeground,
          ),
        },
      ),
      collapsibleIconStyle: item.collapsibleIconStyle,
      collapsibleIcon: item.collapsibleIcon,
      padding: item.padding,
      borderRadius: item.borderRadius,
      tappableStyle: item.tappableStyle,
      focusedOutlineStyle: item.focusedOutlineStyle,
      iconSpacing: item.iconSpacing,
      collapsibleIconSpacing: item.collapsibleIconSpacing,
      childrenSpacing: item.childrenSpacing,
      childrenPadding: item.childrenPadding,
      motion: item.motion,
    );
    return base.copyWith(
      sidebarStyle: FSidebarStyleDelta.delta(
        groupStyle: FSidebarGroupStyleDelta.delta(itemStyle: branded),
      ),
    );
  }

  /// Light.
  static ThemeData light({String appFontFamily = 'Manrope'}) =>
      _withExtensions(
        _withFontFamily(
          lightFTheme(appFontFamily: appFontFamily).toApproximateMaterialTheme(),
          appFontFamily,
        ),
        DesignSystemTokens.light(),
      );

  /// Dark.
  static ThemeData dark({String appFontFamily = 'Manrope'}) =>
      _withExtensions(
        _withFontFamily(
          darkFTheme(appFontFamily: appFontFamily).toApproximateMaterialTheme(),
          appFontFamily,
        ),
        DesignSystemTokens.dark(),
      );

  static ThemeData _withExtensions(ThemeData base, DesignSystemTokens tokens) {
    return base.copyWith(
      extensions: [tokens],
      chipTheme: _chipTheme(tokens, base.brightness),
      dividerTheme: DividerThemeData(color: tokens.borderSecondary, space: 1),
      textTheme: _proseTextTheme(base.textTheme, tokens),
      primaryTextTheme: _proseTextTheme(base.primaryTextTheme, tokens),
      elevatedButtonTheme: _elevatedButtonTheme(tokens),
      outlinedButtonTheme: _outlinedButtonTheme(tokens),
      textButtonTheme: _textButtonTheme(tokens),
      iconButtonTheme: _iconButtonTheme(tokens),
      inputDecorationTheme: _inputDecorationTheme(tokens),
    );
  }

  static ButtonStyle _buttonFocusStyle(DesignSystemTokens tokens) => ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return Colors.transparent;
          }
          return null;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: tokens.focusRing, width: 2);
          }
          return null;
        }),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(DesignSystemTokens tokens) =>
      ElevatedButtonThemeData(style: _buttonFocusStyle(tokens));

  static OutlinedButtonThemeData _outlinedButtonTheme(DesignSystemTokens tokens) =>
      OutlinedButtonThemeData(style: _buttonFocusStyle(tokens));

  static TextButtonThemeData _textButtonTheme(DesignSystemTokens tokens) =>
      TextButtonThemeData(style: _buttonFocusStyle(tokens));

  static IconButtonThemeData _iconButtonTheme(DesignSystemTokens tokens) =>
      IconButtonThemeData(
        style: IconButton.styleFrom(
          focusColor: Colors.transparent,
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: tokens.focusRing, width: 2);
            }
            return null;
          }),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(DesignSystemTokens tokens) =>
      InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          // Sharp 2px corners; focus ring is the orange accent.
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: tokens.focusRing, width: 2),
        ),
      );

  /// Aligns the Material text theme with the design system prose rules:
  /// headings (display/headline/title) use `text-primary`, body and labels
  /// use `text-tertiary`. Mirrors the CSS `.prose` defaults.
  /// Also restores accessible line-heights. ForUI's
  /// `toApproximateMaterialTheme()` flattens every entry to `height: 1`, which
  /// strips leading from `Theme.of(context).textTheme.*` and hurts legibility
  /// for any multi-line Material `Text`. WCAG 2.1 SC 1.4.12 recommends ≥1.5x
  /// for body text; headings can stay tighter.
  static TextTheme _proseTextTheme(TextTheme base, DesignSystemTokens tokens) {
    // Headings carry weight 400 — the design system builds hierarchy from size
    // and color, never from bold (there is no 700 anywhere in the system).
    TextStyle? heading(TextStyle? s, double height) => s?.copyWith(
          color: tokens.textPrimary,
          height: height,
          fontWeight: FontWeight.w400,
        );
    TextStyle? body(TextStyle? s, double height) =>
        s?.copyWith(color: tokens.textTertiary, height: height);
    return base.copyWith(
      displayLarge: heading(base.displayLarge, 1.2),
      displayMedium: heading(base.displayMedium, 1.2),
      displaySmall: heading(base.displaySmall, 1.25),
      headlineLarge: heading(base.headlineLarge, 1.25),
      headlineMedium: heading(base.headlineMedium, 1.3),
      headlineSmall: heading(base.headlineSmall, 1.3),
      titleLarge: heading(base.titleLarge, 1.35),
      titleMedium: heading(base.titleMedium, 1.4),
      titleSmall: heading(base.titleSmall, 1.4),
      bodyLarge: body(base.bodyLarge, 1.5),
      bodyMedium: body(base.bodyMedium, 1.5),
      bodySmall: body(base.bodySmall, 1.5),
      labelLarge: body(base.labelLarge, 1.4),
      labelMedium: body(base.labelMedium, 1.4),
      labelSmall: body(base.labelSmall, 1.4),
    );
  }

  /// Material `InputChip` / `Chip` defaults use a near-black outline. Map
  /// them to the design system `border-secondary` so skill/agent chips fit
  /// the rest of the surface.
  static ChipThemeData _chipTheme(DesignSystemTokens tokens, Brightness brightness) {
    final selectedColor = brightness == Brightness.dark
        ? tokens.textWhite
        : tokens.textBrandPrimary;
    return ChipThemeData(
      backgroundColor: tokens.surface,
      selectedColor: tokens.bgBrandPrimary,
      secondarySelectedColor: tokens.bgBrandPrimary,
      disabledColor: tokens.bgDisabled,
      side: BorderSide(color: tokens.borderSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: tokens.borderSecondary),
      ),
      labelStyle: TextStyle(color: tokens.textTertiary, fontSize: 12),
      secondaryLabelStyle: TextStyle(color: selectedColor, fontSize: 12),
      deleteIconColor: tokens.fgTertiary,
      checkmarkColor: selectedColor,
    );
  }

  static ThemeData _withFontFamily(ThemeData base, String family) {
    if (GoogleFonts.asMap().containsKey(family)) {
      return base.copyWith(
        textTheme: AppFonts.textThemeFor(family, base.textTheme),
        primaryTextTheme: AppFonts.textThemeFor(family, base.primaryTextTheme),
      );
    }
    // System fonts that were pre-loaded via FontLoader at startup.
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: family),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family),
    );
  }

  /// Mode from string.
  static ThemeMode modeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
