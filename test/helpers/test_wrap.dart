import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// Provider overrides shared by both wrappers.
//
// Deliberately does NOT seed activeWorkspaceIdProvider. These wrappers create
// their own ProviderScope, so an override here would shadow one supplied by an
// enclosing scope — and many tests wrap `testWrap(...)` in a ProviderScope that
// pins a specific workspace id (or a null one, to exercise the pre-context
// surfaces). Tests needing a seeded workspace add `activeWorkspaceIdOverride()`
// from `active_workspace.dart` to their own outer scope instead.
//
// Overrides prReviewRepositoryProvider to EmptyPrReviewRepository and
// activeWorkspace / activeRepo to null so drift database streams (which leave pending timers on
// dispose) are never created. Meeting action items / decisions default to empty
// streams so meeting widgets never open the real drift database.
final _testOverrides = [
  activeWorkspaceProvider.overrideWith((ref) => null),
  activeRepoProvider.overrideWith((ref) => null),
  prReviewRepositoryProvider.overrideWith(
    (ref) => const EmptyPrReviewRepository(),
  ),
  workspacesProvider.overrideWith(
    (ref) => const Stream<List<Workspace>>.empty(),
  ),
  meetingActionItemsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingActionItemStatsProvider.overrideWith((ref, _) => const Stream.empty()),
  meetingDecisionCountsProvider.overrideWith((ref, _) => const Stream.empty()),
];

/// A router with [routes] inside the shell's [MouseNavigationHandler], for pages
/// whose navigation is under test. Pass the app's own route lists so the test
/// walks the production table; pump with [testRouterWrap].
GoRouter historyTestRouter({
  required String initialLocation,
  required List<RouteBase> routes,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    ShellRoute(
      builder: (context, state, child) => Consumer(
        builder: (context, ref, _) => MouseNavigationHandler(
          historyController: ref.read(navigationHistoryProvider.notifier),
          // Inside the navigator, for its overlay.
          child: CcToastScope(child: Scaffold(body: child)),
        ),
      ),
      routes: routes,
    ),
  ],
);

/// [testWrap] for a page that navigates: the same scope, l10n and theme around
/// [router].
Widget testRouterWrap(
  GoRouter router, {
  Locale locale = const Locale('en'),
  bool isDemo = false,
}) => ProviderScope(
  overrides: [
    isDemoServerProvider.overrideWith((ref) => isDemo),
    ..._testOverrides,
  ],
  child: MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: kSupportedAppLocales,
    locale: locale,
    builder: (context, child) => CcTheme(
      data: CcThemeData.light(),
      child: child ?? const SizedBox.shrink(),
    ),
  ),
);

/// Presses the mouse's back button, or its forward button with [forward].
Future<void> pressMouseHistoryButton(
  WidgetTester tester, {
  bool forward = false,
}) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: forward ? kForwardMouseButton : kBackMouseButton,
  );
  await mouse.down(const Offset(5, 5));
  await mouse.up();
  await mouse.removePointer();
  await tester.pumpAndSettle();
}

/// ProviderScope + MaterialApp (l10n) + CcTheme for widget tests.
///
/// [CcToastScope] inside `home` (rebuild-safe). Dialog toasts need
/// [testWrapWithToastOverlay]. [locale] / [textDirection] / [isDemo] optional.
Widget testWrap(
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
  bool isDemo = false,
}) {
  Widget home = CcTheme(
    data: CcThemeData.light(),
    child: CcToastScope(child: Scaffold(body: child)),
  );
  if (textDirection != null) {
    home = Directionality(textDirection: textDirection, child: home);
  }
  return ProviderScope(
    overrides: [
      isDemoServerProvider.overrideWith((ref) => isDemo),
      ..._testOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: kSupportedAppLocales,
      locale: locale,
      home: home,
    ),
  );
}

/// Like [testWrap], but mounts the [CcToastScope] *above* the navigator's
/// overlay (mirroring the production wiring in `lib/main.dart`) so a CcToast
/// raised from a dialog — shown via `showCcDialog` into the root navigator
/// overlay — resolves a host.
///
/// Use this only for dialog/flyout tests that surface a toast. It is NOT
/// rebuild-safe across `pumpWidget` re-pumps (the toast Overlay strands the
/// previous tree), so never use it for tests that re-pump to exercise
/// `didUpdateWidget`; use [testWrap] there.
///
/// [locale] / [textDirection] behave as on [testWrap]; the direction override
/// wraps the whole `builder` result so dialogs mounted into the root navigator
/// overlay inherit it too.
Widget testWrapWithToastOverlay(
  Widget child, {
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
  bool isDemo = false,
}) {
  return ProviderScope(
    overrides: [
      isDemoServerProvider.overrideWith((ref) => isDemo),
      ..._testOverrides,
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: kSupportedAppLocales,
      locale: locale,
      builder: (context, navigator) {
        Widget wrapped = CcTheme(
          data: CcThemeData.light(),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) =>
                    CcToastScope(child: navigator ?? const SizedBox.shrink()),
              ),
            ],
          ),
        );
        if (textDirection != null) {
          wrapped = Directionality(
            textDirection: textDirection,
            child: wrapped,
          );
        }
        return wrapped;
      },
      home: Scaffold(body: child),
    ),
  );
}
