import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Styling for **Widgetbook's own chrome** — the navigation sidebar, search
/// field, settings/addons panel and workspace toolbar — derived from the cc_ui
/// design tokens.
///
/// Widgetbook renders its chrome inside an internal `MaterialApp` and exposes
/// only `lightTheme` / `darkTheme` (`ThemeData`) as styling hooks — the public
/// `Widgetbook` constructor has no navigation override, and its tree tiles,
/// cards and ripples are `@internal` Material widgets that cannot be swapped for
/// `Cc*` widgets. So rather than restyling the chrome with the design system
/// directly, we map cc_ui tokens onto the Material `ColorScheme` / `ThemeData`
/// slots the chrome actually reads (verified against widgetbook 3.24.0
/// `desktop_layout.dart` / `navigation_*.dart`):
///
///  - outer workspace background → `colorScheme.surface`
///  - nav + addons panels (Material `Card`) → `cardTheme.color`
///  - selected tree-tile fill → `colorScheme.secondaryContainer` (= `accentSoft`)
///  - nav-row hover / pressed wash → `hoverColor` / `highlightColor`
///  - all chrome ripples removed → `splashFactory` (cc_ui has none — CcTappable
///    washes hover→pressed and never inks)
///  - tile text → Manrope `textTheme` (`onSurface`); tree glyphs → `iconTheme`
///    (`textSecondary`, matching a resting `CcSidebarItem`)
///  - search-field fill + hint → `inputDecorationTheme.fillColor` / `hintStyle`
///
/// How close this gets to a real [CcSidebar]: the warm surface, the `accentSoft`
/// selected fill, the hover/pressed washes and the no-ripple feel all match. The
/// remaining `CcSidebarItem` signatures are baked into the `@internal`
/// `NavigationTreeTile` and cannot be reached by `ThemeData`:
///
///  - it is a 24px-tall pill (`BorderRadius.circular(24)`); `CcSidebarItem` is a
///    2px-radius (`AppRadii.brSm`) row with taller padding.
///  - the selected row paints **only** its fill — no 1px `accent` border, and the
///    label/icon keep their resting color rather than turning `accent`.
///  - folders/categories are plain tree rows; there is no mono uppercase group
///    eyebrow like [CcSidebarGroup].
///  - the search field hardcodes a transparent pill border, so its accent focus
///    ring and 2px corners are unreachable (only its fill/hint are themable).
///
/// True fidelity would require not using widgetbook's built-in navigation, which
/// it does not expose for override. The 2px resize separators are likewise
/// hardcoded (`Colors.white24`) and out of reach.
ThemeData galleryChromeTheme(Brightness brightness) {
  final t = brightness == Brightness.dark
      ? DesignSystemTokens.dark()
      : DesignSystemTokens.light();

  final scheme =
      ColorScheme.fromSeed(seedColor: t.accent, brightness: brightness).copyWith(
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

  final base = ThemeData(
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
    splashFactory: NoSplash.splashFactory,
    hoverColor: t.hover,
    highlightColor: t.hoverStrong,
    focusColor: t.accentSoft,
    // The cc_ui UI font (Manrope). Calling CcFonts.ui() registers the font
    // loader with google_fonts; we then apply its resolved family across the
    // chrome's text styles.
    textTheme: base.textTheme.apply(
      fontFamily: CcFonts.ui().fontFamily,
      bodyColor: t.fg,
      displayColor: t.fg,
    ),
    // Nav-tree glyphs (folder / component / use-case + the expander chevron) are
    // bare `Icon`s that read `IconTheme`. A resting `CcSidebarItem` paints its
    // icon `textSecondary`, so match it. (The tile does not re-color the icon on
    // selection — see the doc note above.)
    iconTheme: IconThemeData(color: t.textSecondary),
    // The navigation and addons panels are Material `Card`s — make them the
    // warm sidebar surface, flat, with no surface tint or margin.
    cardTheme: CardThemeData(
      color: t.sidebar,
      surfaceTintColor: const Color(0x00000000),
      shadowColor: const Color(0x00000000),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
    ),
    // The sidebar search field.
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.panel,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(color: t.textPlaceholder),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.accent, width: 1.5),
      ),
    ),
  );
}

/// Branded header pinned to the top of Widgetbook's navigation sidebar (passed
/// to `Widgetbook.header`). Renders inside the chrome `MaterialApp`, so it reads
/// colors from the themed [Theme.of] and adapts to light/dark automatically.
class GalleryNavHeader extends StatelessWidget {
  /// Creates the gallery navigation header.
  const GalleryNavHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                Color(0xFFFA520F),
                Color(0xFFC0400F),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                'Design system',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
