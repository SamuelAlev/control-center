import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';

/// App theme.
class AppTheme {
  AppTheme._();

  /// Light.
  static ThemeData light({String appFontFamily = AppFonts.uiFamily}) =>
      _withExtensions(
        _withFontFamily(
          _baseTheme(
            Brightness.light,
            DesignSystemTokens.light(),
            fontFamily: appFontFamily,
          ),
          appFontFamily,
        ),
        DesignSystemTokens.light(),
      );

  /// Dark.
  static ThemeData dark({String appFontFamily = AppFonts.uiFamily}) =>
      _withExtensions(
        _withFontFamily(
          _baseTheme(
            Brightness.dark,
            DesignSystemTokens.dark(),
            fontFamily: appFontFamily,
          ),
          appFontFamily,
        ),
        DesignSystemTokens.dark(),
      );

  /// Minimal token-built Material base — the one Material concession.
  ///
  /// A fallback [ThemeData] so the transitive Material widgets we still mount
  /// under `MaterialApp` (chewie, kalender, flutter_markdown_plus) render with
  /// the design system's surface, text, and selection colors instead of
  /// Material's stock blue. Our own widgets read tokens via
  /// `context.designSystem` (cc_ui's `CcTheme`), never `Theme.of`. Richer
  /// component theming is layered on by [_withExtensions]; [_withFontFamily]
  /// applies the user font; [_proseTextTheme] restores line-heights. Replaces
  /// the prior approximate token-to-Material-theme conversion, and the
  /// active-nav identity that used to be themed here now lives natively in
  /// cc_ui's `CcSidebarItem`.
  static ThemeData _baseTheme(
    Brightness brightness,
    DesignSystemTokens tokens, {
    required String fontFamily,
  }) {
    final brand = brightness == Brightness.dark
        ? DesignSystemPalette.brand500
        : DesignSystemPalette.brand600;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    ).copyWith(
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      error: tokens.fgErrorPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      // Resolved fallback family — the bundled font (Manrope by default).
      // Set here, not in [copyWith], because `ThemeData.copyWith` has no
      // `fontFamily` parameter. Without this the field is null and web resolves
      // it to the engine default (Roboto), fetched over the network even though
      // the text themes carry the bundled family.
      fontFamily: fontFamily,
      // Flat design — no ink ripple on the transitive Material widgets.
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.textPrimary,
        selectionColor: tokens.bgBrandPrimary,
        selectionHandleColor: tokens.bgBrandSolid,
      ),
    );
  }

  // Tokens are no longer attached as a Material `ThemeExtension` — they travel
  // through `CcTheme` (an InheritedWidget in cc_ui) instead, read via
  // `context.designSystem`. This method now only maps tokens onto the Material
  // component themes that remain while MaterialApp is still mounted.
  static ThemeData _withExtensions(ThemeData base, DesignSystemTokens tokens) {
    return base.copyWith(
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
  /// Also restores accessible line-heights. The prior approximate
  /// token-to-Material-theme conversion flattened every entry to `height: 1`,
  /// which strips leading from `Theme.of(context).textTheme.*` and hurts
  /// legibility for any multi-line Material `Text`. WCAG 2.1 SC 1.4.12
  /// recommends ≥1.5x
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

  static ThemeData _withFontFamily(ThemeData base, String family) =>
      // [AppFonts.textThemeFor] resolves the family for the text themes:
      // bundled host families (Manrope / Fira Code) and pre-loaded system
      // fonts apply by name; other Google families route through google_fonts.
      // The top-level [ThemeData.fontFamily] (the resolved fallback family) is
      // set in [_baseTheme] so it is the bundled font on every platform.
      base.copyWith(
        textTheme: AppFonts.textThemeFor(family, base.textTheme),
        primaryTextTheme: AppFonts.textThemeFor(family, base.primaryTextTheme),
      );

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
