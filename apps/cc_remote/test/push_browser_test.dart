@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/push/push_browser.dart';
import 'package:cc_remote/push/push_providers.dart';
import 'package:cc_remote/push/push_settings_section.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late JSAny? originalNotification;
  late JSAny? originalPushManager;
  late bool hadPushManager;
  late JSObject notification;
  late Completer<JSString> response;
  late int requests;

  setUp(() {
    originalNotification = globalContext['Notification'];
    originalPushManager = globalContext['PushManager'];
    hadPushManager = globalContext.hasProperty('PushManager'.toJS).toDart;
    // Permission cases control push capability independently of the runner.
    globalContext['PushManager'] = JSObject();
    notification = JSObject();
    response = Completer<JSString>();
    requests = 0;
    notification['requestPermission'] = (() {
      requests++;
      return response.future.toJS;
    }).toJS;
    globalContext['Notification'] = notification;
  });

  tearDown(() {
    globalContext['Notification'] = originalNotification;
    if (hadPushManager) {
      globalContext['PushManager'] = originalPushManager;
    } else {
      globalContext
          .getProperty<JSObject>('Reflect'.toJS)
          .callMethod<JSBoolean>(
            'deleteProperty'.toJS,
            globalContext,
            'PushManager'.toJS,
          );
    }
  });

  test(
    'default requests permission immediately, before the first await',
    () async {
      notification['permission'] = 'default'.toJS;
      const browser = BrowserPush();
      expect(browser.permission, 'default');
      final pending = browser.subscribe('invalid-key');
      expect(requests, 1); // A tap must not await an RPC before this call.
      response.complete('granted'.toJS);
      // The invalid key stops before installing or touching any worker.
      await expectLater(pending, throwsA(isA<FormatException>()));
      expect(requests, 1);
    },
  );

  test('granted never re-prompts and proceeds to subscription setup', () async {
    notification['permission'] = 'granted'.toJS;
    const browser = BrowserPush();
    expect(browser.permission, 'granted');
    await expectLater(
      browser.subscribe('invalid-key'),
      throwsA(isA<FormatException>()),
    );
    expect(requests, 0);
  });

  test('denied does not request permission or register', () async {
    notification['permission'] = 'denied'.toJS;
    const browser = BrowserPush();
    expect(browser.permission, 'denied');
    await expectLater(
      browser.subscribe('invalid-key'),
      throwsA(isA<StateError>()),
    );
    expect(requests, 0);
  });

  test('a dismissed prompt cannot create a registration', () async {
    notification['permission'] = 'default'.toJS;
    final pending = const BrowserPush().subscribe('invalid-key');
    expect(requests, 1);
    response.complete('default'.toJS);
    await expectLater(pending, throwsA(isA<StateError>()));
  });

  testWidgets('Settings never prompts; blocked permission can be refreshed', (
    tester,
  ) async {
    var permission = 'default';
    var reads = 0;
    notification['permission'] = 'default'.toJS;
    final container = ProviderContainer(
      overrides: [
        remotePushStatusProvider.overrideWith((ref) async {
          reads++;
          return RemotePushStatus(
            enabled: false,
            browserSubscribed: false,
            permission: permission,
            unsupportedReason: null,
            quiet: false,
            categories: const {},
            vapidPublicKey: 'invalid-key',
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: WidgetsApp(
          color: const Color(0xFF000000),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: const DefaultTextStyle(
            style: TextStyle(color: Color(0xFF000000)),
            child: Center(
              child: SizedBox(width: 360, child: PushSettingsSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    CcButton button(String label) => tester.widget<CcButton>(
      find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
    );
    expect(requests, 0);
    expect(button('Enable notifications').onPressed, isNotNull);
    permission = 'denied';
    container.invalidate(remotePushStatusProvider);
    await tester.pumpAndSettle();
    expect(button('Enable notifications').onPressed, isNull);
    expect(button('Refresh').onPressed, isNotNull);
    expect(requests, 0);
    permission = 'granted';
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(reads, greaterThanOrEqualTo(3));
    expect(button('Enable notifications').onPressed, isNotNull);
    expect(requests, 0);
  });
}
