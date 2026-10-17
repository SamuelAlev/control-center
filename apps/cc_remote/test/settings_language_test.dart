@TestOn('browser')
library;

import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/push/push_providers.dart';
import 'package:cc_remote/screens/settings_screen.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'language select persists RTL choice and can follow system again',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('en', 'US'),
      ];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith((ref) async* {
              yield null;
            }),
            remotePushStatusProvider.overrideWith(
              (ref) async => const RemotePushStatus(
                enabled: false,
                browserSubscribed: false,
                permission: 'unsupported',
                unsupportedReason: 'unsupported',
                quiet: false,
                categories: {},
                vapidPublicKey: '',
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(appLocaleProvider);
              return WidgetsApp(
                color: const Color(0xFFFFFFFF),
                locale: locale == null ? null : localeFromBcp47(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: kSupportedRemoteLocales,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF202020),
                  decoration: TextDecoration.none,
                ),
                pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
                  settings: settings,
                  pageBuilder: (context, _, _) => builder(context),
                ),
                builder: (_, child) =>
                    CcTheme(data: CcThemeData.light(), child: child!),
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final select = find.byType(CcSelect<String>);
      await tester.ensureVisible(select);
      expect(tester.getSize(select).height, greaterThanOrEqualTo(44));
      await tester.tap(select);
      await tester.pumpAndSettle();
      Finder option(String tag) => find.byWidgetPredicate(
        (widget) => widget is CcSelectRow<String> && widget.option.value == tag,
      );
      await tester.tap(option('ar-SA'));
      await tester.pumpAndSettle();
      expect(prefs.getString('app_locale'), 'ar-SA');
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl,
      );
      await tester.ensureVisible(select);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await tester.tap(option(''));
      await tester.pumpAndSettle();
      expect(prefs.containsKey('app_locale'), isFalse);
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.ltr,
      );
    },
  );
}
