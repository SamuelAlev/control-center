import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/language_picker.dart';
import 'package:control_center/shared/widgets/server_connect/connect_landing.dart';
import 'package:control_center/shared/widgets/server_connect/pre_app_settings.dart';
import 'package:control_center/shared/widgets/server_connect/server_connect_dialog.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:control_center/shared/widgets/theme_choice_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoServerDiscovery extends ServerDiscovery {
  const _NoServerDiscovery();

  @override
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) => const Stream.empty();
}

Widget _app(ServerConnectionStore store, {Object? error}) => ProviderScope(
  child: ServerSetupApp(
    store: store,
    initialError: error,
    previousSessionClosed: null,
    onResolved: (_) => fail('No connection attempted'),
    discovery: const _NoServerDiscovery(),
  ),
);

ServerConnectionStore _store() =>
    ServerConnectionStore(AppPreferences.inMemory(), SecureStore.inMemory());

/// Mounts setup under reduced motion: the cloudscape otherwise animates for as
/// long as the screen is up, and nothing would ever settle.
Future<void> _mount(
  WidgetTester tester,
  ServerConnectionStore store, {
  Object? error,
}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(_app(store, error: error));
}

void main() {
  setUp(() => serverStartupStatus.value = null);
  tearDown(() => serverStartupStatus.value = null);

  for (final mode in ServerConnectionMode.values) {
    testWidgets('opening a dialog from $mode clears its connection error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = _store();
      await store.setMode(mode);
      await _mount(
        tester,
        store,
        error: const UserFacingMessage('Earlier attempt failed'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Earlier attempt failed'), findsOneWidget);

      await tester.tap(find.text('Paste a pairing link'));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectionErrorAlert), findsNothing);
      expect(store.readMode(), mode, reason: 'Looking is not connecting');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('the main action follows how this client last ran', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<List<String>> order(ServerConnectionMode mode) async {
      final store = _store();
      await store.setMode(mode);
      await _mount(tester, store);
      await tester.pumpAndSettle();
      final buttons = tester.widgetList<CcButton>(find.byType(CcButton));
      final labels = [
        for (final button in buttons)
          if (button.child case final Text text) text.data!,
      ];
      await tester.pumpWidget(const SizedBox.shrink());
      return labels;
    }

    expect(await order(ServerConnectionMode.local), [
      'Run in this app',
      'Connect to a server',
      'Paste a pairing link',
    ]);
    expect(await order(ServerConnectionMode.remote), [
      'Connect to a server',
      'Run in this app',
      'Paste a pairing link',
    ]);
  });

  testWidgets('connect opens the shared dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _mount(tester, _store());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect to a server'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerConnectDialog), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings re-theme the surface and keep the choice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _store();
    await _mount(tester, store);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(store.preferences.getString(themeModeKey), 'dark');
    expect(
      CcTheme.of(tester.element(find.byType(PreAppSettingsPage))).brightness,
      CcBrightness.dark,
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(PreAppSettingsPage), findsNothing);
    expect(
      CcTheme.of(tester.element(find.byType(ConnectLanding))).brightness,
      CcBrightness.light,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings offer only what signing in needs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _mount(tester, _store());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();
    expect(find.byType(LanguagePicker), findsOneWidget);
    expect(find.byType(ThemeChoicePicker), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('escape leaves settings', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _mount(tester, _store());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CcIconButton));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PreAppSettingsPage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a saved language applies before any server is chosen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _store();
    await store.preferences.setString(localeKey, 'fr-FR');
    await _mount(tester, store);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue dans Control Center'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion freezes the cloudscape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _mount(tester, _store());
    await tester.pumpAndSettle();
    expect(
      tester.widget<ShaderBackground>(find.byType(ShaderBackground)).animate,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the landing mirrors in a right-to-left language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _store();
    await store.preferences.setString(localeKey, 'ar-SA');
    await _mount(tester, store);
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(ConnectLanding))),
      TextDirection.rtl,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('setup keeps connection failures in the callout, not activity', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _store();
    await store.setMode(ServerConnectionMode.remote);
    const failure = UserFacingMessage('Remote server unavailable');
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.failed,
      error: failure,
    );
    await _mount(tester, store, error: failure);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionErrorAlert), findsOneWidget);
    expect(find.text('Remote server unavailable'), findsOneWidget);
    expect(find.text('Server activity'), findsNothing);

    await tester.tap(find.text('Connect to a server'));
    await tester.pump();
    expect(serverStartupStatus.value, isNull);
    expect(find.byType(ConnectionErrorAlert), findsNothing);
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.starting,
    );
    await tester.pump();
    expect(find.text('Starting local server…'), findsOneWidget);
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.ready,
    );
    await tester.pump();
    expect(find.text('Server activity'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
