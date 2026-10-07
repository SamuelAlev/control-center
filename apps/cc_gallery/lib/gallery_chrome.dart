// The gallery's one deliberate import of the deprecated framework Material
// library. Widgetbook 4 builds its own chrome (navigation tree, search, addon
// and args panels) on `package:flutter/material.dart`, and
// `Config.lightTheme`/`darkTheme` take that library's `ThemeData`, which is a
// different class from material_ui's. Drop this once widgetbook moves to
// material_ui. Everything the gallery renders itself stays Material-free.
import 'package:cc_ui/cc_ui.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widgetbook chrome styling via legacy Material `ThemeData` mapped from cc_ui
/// tokens.
///
/// Widgetbook only exposes `lightTheme`/`darkTheme`; its tree tiles are
/// `@internal` Material and cannot become `Cc*` widgets. Selected tile uses
/// `accentSoft` (not `bgBrandSolid`): the tile keeps resting label/icon color,
/// so a solid brand fill would be illegible. Pill radius, accent border,
/// group eyebrows, search focus ring, and resize separators are unreachable
/// through `ThemeData`.
legacy.ThemeData galleryChromeTheme(Brightness brightness) {
  final t = brightness == Brightness.dark
      ? DesignSystemTokens.dark()
      : DesignSystemTokens.light();

  final scheme =
      legacy.ColorScheme.fromSeed(
        seedColor: t.accent,
        brightness: brightness,
      ).copyWith(
        // Outer workspace background (the ColoredBox behind the resizable panels).
        surface: t.canvas,
        onSurface: t.fg,
        onSurfaceVariant: t.muted,
        // The single orange signal — search focus, accents, ripple.
        primary: t.accent,
        onPrimary: t.accentOn,
        secondary: t.accent,
        onSecondary: t.accentOn,
        // Selected nav-tile fill. The tile paints only this fill on selection — it
        // does not switch its label/icon color — so `onSecondaryContainer` is the
        // on-color for other Material surfaces (menus, chips), not the nav row.
        secondaryContainer: t.accentSoft,
        onSecondaryContainer: t.fg,
        outline: t.lineStrong,
        outlineVariant: t.borderSoft,
        error: t.danger,
        onError: t.accentOn,
      );

  final base = legacy.ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.canvas,
    dividerColor: t.lineStrong,
    // cc_ui has no ripple — a `CcTappable` washes hover→pressed and never inks.
    // Drop the Material ripple chrome-wide so nav rows (and chrome buttons) read
    // like `Cc*` widgets: a subtle `hover` wash, a slightly stronger `hoverStrong`
    // pressed wash, both cc_ui's warm fg overlays rather than the Material tint.
    splashFactory: legacy.NoSplash.splashFactory,
    hoverColor: t.hover,
    highlightColor: t.hoverStrong,
    focusColor: t.accentSoft,
    // The cc_ui UI font (Manrope), bundled as a host asset. CcFonts.ui()
    // resolves the bundled family, which we apply across the chrome's text
    // styles.
    textTheme: base.textTheme.apply(
      fontFamily: CcFonts.ui().fontFamily,
      bodyColor: t.fg,
      displayColor: t.fg,
    ),
    // Nav-tree glyphs (folder / component / story + the expander chevron) are
    // bare `Icon`s that read `IconTheme`. A resting `CcSidebarItem` paints its
    // icon `textSecondary`, so match it. (The tile does not re-color the icon on
    // selection — see the doc note above.)
    iconTheme: IconThemeData(color: t.textSecondary),
    // The navigation and addons panels are Material `Card`s — make them the
    // warm sidebar surface, flat, with no surface tint or margin.
    cardTheme: legacy.CardThemeData(
      color: t.sidebar,
      surfaceTintColor: const Color(0x00000000),
      shadowColor: const Color(0x00000000),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
    ),
    // The sidebar search field.
    inputDecorationTheme: legacy.InputDecorationThemeData(
      filled: true,
      fillColor: t.panel,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(color: t.textPlaceholder),
      enabledBorder: legacy.OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.borderSoft),
      ),
      focusedBorder: legacy.OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.accent, width: 1.5),
      ),
    ),
  );
}

/// Branded header pinned to the top of Widgetbook's navigation sidebar (passed
/// to `Config.header`). Renders inside the chrome's legacy `MaterialApp`, which
/// follows the platform brightness (`ThemeMode.system`), so it reads the
/// matching cc_ui tokens directly instead of the legacy Material `Theme`.
class GalleryNavHeader extends StatelessWidget {
  /// Creates the gallery navigation header.
  const GalleryNavHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final t = MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? DesignSystemTokens.dark()
        : DesignSystemTokens.light();
    return Row(
      children: [
        // The brand mark: the figure SVG (tinted white) on the brand orange
        // gradient — mirrors web/favicon.svg. The figure is composited on a
        // Flutter-drawn gradient rather than rendering the full favicon SVG,
        // whose nested <svg> + feDropShadow filters flutter_svg renders poorly.
        Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB83E),
                Color(0xFFFF8105),
                Color(0xFFFA500F),
                Color(0xFFC03E0F),
              ],
              stops: [0, 0.34, 0.7, 1],
            ),
          ),
          child: SvgPicture.asset(
            'assets/brand/logo.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Control Center',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcFonts.ui(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.fg,
                  ),
                ),
              ),
              Text(
                'Design system',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcFonts.ui(
                  textStyle: TextStyle(fontSize: 12, color: t.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
