import 'package:cc_remote/app_router.dart';
import 'package:cc_remote/pairing/pairing_store.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// Entry point for the Control Center phone client (a Flutter web PWA).
///
/// Run with `flutter run -d chrome` (debug) from `apps/cc_remote`, or build
/// `flutter build web --release` and deploy to
/// Cloudflare Pages (see `wrangler.jsonc`).
Future<void> main() async {
  // Grab the pairing payload from the URL fragment FIRST. The router navigates
  // during the first build (not-paired → /connect), which drops the fragment
  // from the URL — so capturing it here, before runApp, is what survives it.
  PairingStore.captureBootFragment(web.window.location.hash);
  // Path-based routing: routes live in the path so the fragment (`/#<payload>`)
  // is reserved for the pairing deep link instead of being parsed as a route.
  usePathUrlStrategy();
  // SharedPreferences is the backing store for non-sensitive UI prefs (theme,
  // language, last workspace). Resolve the singleton once before runApp so the
  // appearance notifiers can read/write it synchronously.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const CcRemoteApp(),
    ),
  );
}

/// The root app: a Material-free [WidgetsApp.router] driven by go_router,
/// wrapped in a [CcTheme] that follows the chosen (or system) appearance.
///
/// No `MaterialApp`, `Scaffold`, or `Material` widget — cc_ui is purist (built
/// on `package:flutter/widgets.dart`), so the whole UI renders on the widgets
/// layer. The session is started once on first build.
class CcRemoteApp extends ConsumerStatefulWidget {
  /// Creates a [CcRemoteApp].
  const CcRemoteApp({super.key});

  @override
  ConsumerState<CcRemoteApp> createState() => _CcRemoteAppState();
}

class _CcRemoteAppState extends ConsumerState<CcRemoteApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Kick off pairing consumption + the auto-reconnect loop exactly once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remoteSessionProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return WidgetsApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'Control Center',
      color: const Color(0xFFFCFBF9),
      builder: (context, child) => _Themed(child: child),
    );
  }
}

/// Resolves the active [CcThemeData] from the theme preference (system follows
/// the platform brightness; light/dark pin it) and paints the canvas behind the
/// routed screens.
class _Themed extends ConsumerWidget {
  const _Themed({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(themePreferenceProvider);
    final systemDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = switch (pref) {
      ThemePreference.dark => true,
      ThemePreference.light => false,
      ThemePreference.system => systemDark,
    };
    final theme = isDark ? CcThemeData.dark() : CcThemeData.light();
    final tokens = theme.tokens;

    return CcTheme(
      data: theme,
      child: DefaultTextStyle(
        // Inherit the bundled UI font (Manrope, owned by cc_ui) so every Text
        // descendant renders in the brand family rather than the engine default.
        style: CcFonts.ui(
          textStyle: TextStyle(color: tokens.textPrimary, fontSize: 14),
        ),
        child: ColoredBox(
          color: tokens.canvas,
          child: child ?? const SizedBox(),
        ),
      ),
    );
  }
}
