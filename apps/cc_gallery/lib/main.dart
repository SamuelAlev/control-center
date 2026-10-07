import 'package:accessibility_tools/accessibility_tools.dart'
    show AccessibilityTools;
import 'package:cc_gallery/components.g.dart';
import 'package:cc_gallery/gallery_chrome.dart';
import 'package:cc_gallery/text_direction_addon.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show BrowserContextMenu;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:widgetbook/widgetbook.dart';

/// Entry point for the cc_ui gallery — a Storybook-equivalent catalogue of the
/// Control Center design system, built with Widgetbook.
///
/// Run it with `flutter run -d macos` (or `-d chrome`) from `apps/cc_gallery`.
///
/// The navigation tree is the generated [components] list: one component per
/// `lib/stories/*.stories.dart` file, whose `$`-prefixed stories widgetbook's
/// generator turns into `*.stories.g.dart` parts and `components.g.dart`.
/// Regenerate after adding or editing stories with:
///
/// ```sh
/// dart run build_runner build
/// ```
///
/// Each story resolves its tokens from the [ThemeAddon] below, which wraps
/// every preview in a [CcTheme]; toggle Light/Dark from the addon panel.
void main() {
  if (kIsWeb) {
    // The catalogue previews right-click surfaces (showCcMenuAt), which the
    // browser's own context menu would cover when the gallery is served on web.
    WidgetsFlutterBinding.ensureInitialized();
    BrowserContextMenu.disableContextMenu();
  }
  runWidgetbook(galleryConfig);
}

/// The gallery's Widgetbook configuration.
final galleryConfig = Config(
  // Open on the Welcome docs page.
  initialRoute: Uri(
    path: '/',
    queryParameters: {'path': '[Docs]/Welcome/Welcome'},
  ).toString(),
  // Docs category first, Welcome first within it; everything else
  // alphabetical (widgetbook keeps the list order).
  components: orderedComponents(components),
  // widgetbook's default `materialAppBuilder` wraps every preview in a
  // Material `MaterialApp`; the gallery and cc_ui are Material-free, so supply
  // our own `WidgetsApp` instead.
  appBuilder: ccAppBuilder,
  // Restyle Widgetbook's own chrome (navigation sidebar, search, addons
  // panel) from cc_ui tokens so it stops reading as default-Material blue.
  // These are legacy Material `ThemeData`s — the chrome's tree tiles/cards are
  // `@internal` package widgets, so this maps tokens onto the Material slots
  // they read rather than swapping in `Cc*` widgets. See `gallery_chrome.dart`.
  lightTheme: galleryChromeTheme(Brightness.light),
  darkTheme: galleryChromeTheme(Brightness.dark),
  // Brand header pinned to the top of the navigation sidebar.
  header: const GalleryNavHeader(),
  // Each component's docs page: its name and every story rendered in turn.
  // The default also has a `DartCommentDocBlock`, which would show the
  // `Showcase` doc comment on every component, since all stories target it.
  docsBuilder: () => const [ComponentNameDocBlock(), StoriesDocBlock()],
  addons: [
    ThemeAddon<CcThemeData>({
      'Light': CcThemeData.light(),
      'Dark': CcThemeData.dark(),
    }, (context, theme, child) => GalleryFrame(theme: theme, child: child)),
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
    // Preview every component under RTL / LTR.
    TextDirectionAddon(),
    TextScaleAddon(),
    // Debug-only a11y overlay. Flags missing semantic labels, sub-minimum tap
    // targets and overflows on the live preview. Built on material_ui, whose
    // localizations [ccAppBuilder] registers.
    BuilderAddon(
      name: 'Accessibility',
      builder: (context, child) => AccessibilityTools(child: child),
    ),
  ],
);

/// Preview app builder — a Material-free [WidgetsApp].
///
/// A bare `WidgetsApp(home: …)` trips the SDK assert requiring `builder` /
/// `onGenerateRoute` / `pageRouteBuilder`, so this supplies a
/// `pageRouteBuilder`. Two Material libraries still reach into the preview:
/// AccessibilityTools is built on material_ui, whose localizations are
/// registered here, and widgetbook's own viewport frame is built on the legacy
/// framework Material, which the compatibility bridge re-provides a theme and
/// localizations for.
Widget ccAppBuilder(BuildContext context, Widget child) {
  return WidgetsApp(
    debugShowCheckedModeBanner: false,
    color: const Color(0xFF000000),
    localizationsDelegates: material.GlobalMaterialLocalizations.delegates,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
      return PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      );
    },
    // widgetbook 4 still builds its viewport frame on the legacy framework
    // Material; drop the bridge once it moves to material_ui.
    // ignore: deprecated_member_use
    home: material.MaterialUiCompatibilityBridge(
      // Previews scroll with the design-system scrollbar, same as the app.
      child: ScrollConfiguration(
        behavior: const CcScrollBehavior(),
        child: child,
      ),
    ),
  );
}

/// Node names floated to the front of their siblings (case-insensitive), in
/// this order; everything else sorts alphabetically behind them:
///  - `[docs]`  → the Docs category leads, before Components / Foundations
///  - `welcome` → the intro page leads the Docs section
///
/// Within a component, stories keep their declaration order, and each stories
/// file declares its interactive Playground first.
const _navPriority = ['[docs]', 'welcome'];

final _separator = RegExp(r'[/\\]');

/// Sorts the generated [components] so the navigation tree reads like the
/// Widgetbook 3 one: alphabetical at every level, with [_navPriority] names
/// first. Widgetbook 4 builds the tree in list order, and `components.g.dart`
/// lists files in generation order.
List<Component> orderedComponents(List<Component> components) {
  int rank(String segment) {
    final i = _navPriority.indexOf(segment.toLowerCase());
    return i < 0 ? _navPriority.length : i;
  }

  int compare(Component a, Component b) {
    // `fullPath` is a `package:path` join: `\` separators on Windows.
    final pa = a.fullPath.split(_separator);
    final pb = b.fullPath.split(_separator);
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final byRank = rank(pa[i]).compareTo(rank(pb[i]));
      if (byRank != 0) {
        return byRank;
      }
      final byName = pa[i].toLowerCase().compareTo(pb[i].toLowerCase());
      if (byName != 0) {
        return byName;
      }
    }
    return pa.length.compareTo(pb.length);
  }

  return [...components]..sort(compare);
}

/// Wraps each story in a [CcTheme] plus the canvas background and a default
/// text style, so previews render exactly as they would in the app.
///
/// Story builders therefore return their component directly (no per-story
/// theme/canvas wrapping) — the addon supplies the environment.
class GalleryFrame extends StatelessWidget {
  /// Wraps [child] in the resolved gallery [theme].
  const GalleryFrame({required this.theme, required this.child, super.key});

  /// The theme selected in the Widgetbook theme addon.
  final CcThemeData theme;

  /// The story preview to wrap.
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
