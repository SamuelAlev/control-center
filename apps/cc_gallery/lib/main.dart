import 'package:accessibility_tools/accessibility_tools.dart'
    show AccessibilityTools;
import 'package:cc_gallery/gallery_chrome.dart';
import 'package:cc_gallery/main.directories.g.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Entry point for the cc_ui gallery — a Storybook-equivalent catalogue of the
/// Control Center design system, built with Widgetbook.
///
/// Run it with `flutter run -d macos` (or `-d chrome`) from `apps/cc_gallery`.
///
/// The navigation tree is generated from `@widgetbook.UseCase`-annotated builder
/// functions (under `lib/use_cases/`) into [directories] by widgetbook_generator
/// — regenerate after adding or editing use-cases with:
///
/// ```sh
/// flutter pub run build_runner build --delete-conflicting-outputs
/// ```
///
/// Each use-case resolves its tokens from the [ThemeAddon] below, which wraps
/// every preview in a [CcTheme]; toggle Light/Dark from the addon panel.
void main() {
  runApp(const CcGalleryApp());
}

/// The preview Workbench's app builder — a Material-free [WidgetsApp].
///
/// Replaces widgetbook's default `widgetsAppBuilder`, which builds a
/// `WidgetsApp` with only `home:` set. The current Flutter SDK asserts that a
/// `WidgetsApp` provides one of `builder` / `onGenerateRoute` /
/// `pageRouteBuilder` (`packages/flutter/lib/src/widgets/app.dart`), so the
/// stock builder throws for every use-case. We supply a `pageRouteBuilder` and
/// keep the preview Material-free — cc_ui itself uses no Material.
///
/// We do, however, register the default Material/Cupertino localizations
/// delegates. cc_ui draws no Material widgets, but Widgetbook addons that wrap
/// the preview *do*: the [InspectorAddon]'s info panel uses an `ExpansionTile`
/// and `AccessibilityTools` uses Material chrome, both of which assert on a
/// `MaterialLocalizations` ancestor. Those addons render inside this builder
/// (see `Workbench`), so without these delegates every inspected use-case
/// throws `No MaterialLocalizations found`. `WidgetsApp` already appends
/// `DefaultWidgetsLocalizations.delegate` itself.
Widget ccAppBuilder(BuildContext context, Widget child) {
  return WidgetsApp(
    debugShowCheckedModeBanner: false,
    color: const Color(0xFF000000),
    localizationsDelegates: const <LocalizationsDelegate<Object?>>[
      DefaultMaterialLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
    ],
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      );
    },
    home: child,
  );
}

/// Node names floated to the front of their sibling list (case-insensitive),
/// in this order. Everything else keeps its original (alphabetical) order
/// behind them:
///  - `docs`       → the Docs category leads, before Components / Foundations
///  - `welcome`    → the intro page leads the Docs section
///  - `playground` → each component opens on its interactive playground
const _navPriority = ['docs', 'welcome', 'playground'];

/// Reorders a generated navigation tree to honour [_navPriority] at every
/// level. Widgetbook otherwise orders categories and use-cases alphabetically.
///
/// Rebuilds nodes via the same `copyWith(children:)` contract Widgetbook uses
/// internally for search, so node identity and parenting are preserved.
List<WidgetbookNode> orderedNav(List<WidgetbookNode> nodes) {
  int rank(WidgetbookNode n) {
    final i = _navPriority.indexOf(n.name.toLowerCase());
    return i < 0 ? _navPriority.length : i;
  }

  // Recurse into children first, then float prioritised names to the front of
  // this level (in priority order); the rest keep their original order.
  final mapped = [
    for (final node in nodes)
      node.children == null || node.children!.isEmpty
          ? node
          : node.copyWith(children: orderedNav(node.children!)),
  ];
  final pinned = mapped.where((n) => rank(n) < _navPriority.length).toList()
    ..sort((a, b) => rank(a).compareTo(rank(b)));
  final rest = mapped.where((n) => rank(n) == _navPriority.length);
  return [...pinned, ...rest];
}

/// The Widgetbook gallery application.
///
/// The `@widgetbook.App()` annotation tells widgetbook_generator to emit the
/// [directories] tree into `main.directories.g.dart` (next to this file).
@widgetbook.App()
class CcGalleryApp extends StatelessWidget {
  /// Creates the gallery app.
  const CcGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      initialRoute: '?path=docs/welcome/welcome',
      // widgetbook's default `widgetsAppBuilder` builds `WidgetsApp(home: …)`
      // with no `pageRouteBuilder`/`builder`/`onGenerateRoute`, which the
      // current Flutter SDK rejects (asserts at WidgetsApp's build) — so every
      // use-case preview throws. Supply our own Material-free app builder with a
      // `pageRouteBuilder` instead.
      appBuilder: ccAppBuilder,
      // Restyle Widgetbook's own chrome (navigation sidebar, search, addons
      // panel) from cc_ui tokens so it stops reading as default-Material blue.
      // These are Material `ThemeData`s — the chrome's tree tiles/cards are
      // `@internal` package widgets, so this maps tokens onto the Material
      // slots they read rather than swapping in `Cc*` widgets. See
      // `gallery_chrome.dart`.
      lightTheme: galleryChromeTheme(Brightness.light),
      darkTheme: galleryChromeTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Brand header pinned to the top of the navigation sidebar.
      header: const GalleryNavHeader(),
      addons: [
        ThemeAddon<CcThemeData>(
          themes: [
            WidgetbookTheme(name: 'Light', data: CcThemeData.light()),
            WidgetbookTheme(name: 'Dark', data: CcThemeData.dark()),
          ],
          themeBuilder: (context, theme, child) =>
              GalleryFrame(theme: theme, child: child),
        ),
        // Desktop widths — the app is desktop-first; the narrow steps exercise
        // the CcSidebar rail collapse and dense layouts.
        ViewportAddon(const [
          ViewportData(
            name: 'Desktop — 1440',
            width: 1440,
            height: 900,
            pixelRatio: 1,
            platform: TargetPlatform.macOS,
          ),
          ViewportData(
            name: 'Compact — 1024',
            width: 1024,
            height: 800,
            pixelRatio: 1,
            platform: TargetPlatform.macOS,
          ),
          ViewportData(
            name: 'Narrow — 900',
            width: 900,
            height: 720,
            pixelRatio: 1,
            platform: TargetPlatform.macOS,
          ),
          MacosViewports.macbookPro,
        ]),
        AlignmentAddon(),
        TextScaleAddon(),
        InspectorAddon(),
        // Debug-only a11y overlay (deprecated AccessibilityAddon's replacement).
        // Flags missing semantic labels, sub-minimum tap targets and overflows
        // on the live preview. Material-based chrome — relies on the Material
        // localizations registered in [ccAppBuilder].
        BuilderAddon(
          name: 'Accessibility',
          builder: (context, child) => AccessibilityTools(child: child),
        ),
      ],
      // Reorder the generated tree: Docs category first, Welcome page first
      // within it, and each component's interactive Playground above its static
      // variants (Widgetbook otherwise orders everything alphabetically).
      directories: orderedNav(directories),
    );
  }
}

/// Wraps each use-case in a [CcTheme] plus the canvas background and a default
/// text style, so previews render exactly as they would in the app.
///
/// Use-case builders therefore return their component directly (no per-case
/// theme/canvas wrapping) — the addon supplies the environment.
class GalleryFrame extends StatelessWidget {
  /// Wraps [child] in the resolved gallery [theme].
  const GalleryFrame({required this.theme, required this.child, super.key});

  /// The theme selected in the Widgetbook theme addon.
  final CcThemeData theme;

  /// The use-case preview to wrap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = theme.tokens;
    return CcTheme(
      data: theme,
      child: DefaultTextStyle(
        style: TextStyle(color: tokens.textPrimary, fontSize: 14),
        child: ColoredBox(color: tokens.canvas, child: child),
      ),
    );
  }
}
