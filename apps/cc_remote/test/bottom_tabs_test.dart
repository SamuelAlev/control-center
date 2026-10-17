@TestOn('browser')
library;

import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/widgets/app_shell_bottom_tabs.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar', 'SA')]) {
    testWidgets('all six tabs remain tappable at 320 px in $locale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 760);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final router = GoRouter(
        initialLocation: '/tab/0',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => Column(
              children: [
                Expanded(child: shell),
                BottomTabs(shell: shell),
              ],
            ),
            branches: [
              for (var i = 0; i < 6; i++)
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/tab/$i',
                      builder: (_, _) => Center(
                        key: ValueKey('branch-$i'),
                        child: Text('Destination $i'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [inboxAttentionCountProvider.overrideWithValue(0)],
          child: WidgetsApp.router(
            color: const Color(0xFFFFFFFF),
            locale: locale,
            supportedLocales: kSupportedRemoteLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              PhoneWidgetsLocalizationsDelegate(),
            ],
            routerConfig: router,
            builder: (_, child) =>
                CcTheme(data: CcThemeData.light(), child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final specs = tabs(
        AppLocalizations.of(tester.element(find.byType(BottomTabs))),
      );
      final buttons = [
        for (final spec in specs)
          find.ancestor(
            of: find.byIcon(spec.icon),
            matching: find.byType(CcTappable),
          ),
      ];
      for (final button in buttons) {
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
        expect(rect.width, greaterThanOrEqualTo(kMinTouchTarget));
        expect(rect.height, greaterThanOrEqualTo(kMinTouchTarget));
      }
      for (var i = 0; i < buttons.length; i++) {
        await tester.tap(buttons[i]);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('branch-$i')), findsOneWidget);
      }
    });
  }
}
