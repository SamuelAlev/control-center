import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/guards.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/app_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('login blocks settings and palette until the app is entered', (
    tester,
  ) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: onboardingRoute,
      routes: [
        for (final path in [
          onboardingRoute,
          signedOutRoute,
          splashRoute,
          inboxRoute('ws-1'),
          settingsRoute('ws-1'),
        ])
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    final dispatcher = KeybindingDispatcher(
      platform: TargetPlatform.macOS,
      observeFocus: false,
      listenToHardwareKeyboard: false,
    );
    addTearDown(dispatcher.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          keybindingDispatcherProvider.overrideWithValue(dispatcher),
        ],
        child: AppShortcuts(
          readActiveWorkspaceId: () => 'ws-1',
          commandBuilder: (_, _) => [],
          child: WidgetsApp.router(
            color: const Color(0xFFFFFFFF),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final login in [onboardingRoute, signedOutRoute, splashRoute]) {
      router.go(login);
      await tester.pumpAndSettle();
      dispatcher.debugDispatchStroke(
        const KeyStroke(LogicalKeyboardKey.comma, cmd: true),
      );
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, login);

      dispatcher.debugDispatchStroke(
        const KeyStroke(LogicalKeyboardKey.keyK, cmd: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CcDialog), findsNothing);
    }

    router.go(inboxRoute('ws-1'));
    await tester.pumpAndSettle();
    dispatcher.debugDispatchStroke(
      const KeyStroke(LogicalKeyboardKey.comma, cmd: true),
    );
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      settingsRoute('ws-1'),
    );
  });

  testWidgets('direct settings links remain behind login admission', (
    tester,
  ) async {
    final gate = ValueNotifier(OnboardingGate.incomplete);
    addTearDown(gate.dispose);
    final router = GoRouter(
      initialLocation: settingsAppearanceRoute('ws-1'),
      refreshListenable: gate,
      redirect: (context, state) =>
          onboardingGuard(context, state, gate, () => 'ws-1'),
      routes: [
        for (final path in [
          onboardingRoute,
          signedOutRoute,
          settingsAppearanceRoute('ws-1'),
        ])
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      WidgetsApp.router(color: const Color(0xFFFFFFFF), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      onboardingRoute,
    );

    gate.value = OnboardingGate.signedOut;
    router.go(settingsAppearanceRoute('ws-1'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, signedOutRoute);
  });
}
