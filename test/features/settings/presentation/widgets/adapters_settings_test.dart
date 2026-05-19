import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters_settings.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
  );
}

class _TestNotifier extends AdapterDetectionNotifier {
  _TestNotifier(this._adapters);
  final List<DetectedAdapter> _adapters;
  @override
  List<DetectedAdapter> build() => _adapters;
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });


  group('AdaptersSettings', () {
    testWidgets('renders header and refresh button', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier(const []),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Adapters'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('renders detected adapters list', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'claude',
        name: 'Claude Code',
        description: 'Claude CLI',
        cliName: 'claude',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.found,
                  version: '1.0.0',
                  path: '/usr/bin/claude',
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Claude Code'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('renders unavailable adapter', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'pi',
        name: 'Pi',
        description: 'Pi AI',
        cliName: 'pi',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.notFound,
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pi'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('renders checking adapter', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'oc',
        name: 'OpenCode',
        description: 'OpenCode CLI',
        cliName: 'opencode',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.checking,
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OpenCode'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);
    });

    testWidgets('renders multiple adapters with different statuses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const found = DetectedAdapter(
        adapter: Adapter(
          id: 'found',
          name: 'FoundAdapter',
          description: 'd',
          cliName: 'f',
        ),
        status: DetectionStatus.found,
        version: '2.0.0',
      );
      const notFound = DetectedAdapter(
        adapter: Adapter(
          id: 'missing',
          name: 'MissingAdapter',
          description: 'd',
          cliName: 'm',
        ),
        status: DetectionStatus.notFound,
      );
      const checking = DetectedAdapter(
        adapter: Adapter(
          id: 'checking',
          name: 'CheckingAdapter',
          description: 'd',
          cliName: 'c',
        ),
        status: DetectionStatus.checking,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([found, notFound, checking]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('FoundAdapter'), findsOneWidget);
      expect(find.text('MissingAdapter'), findsOneWidget);
      expect(find.text('CheckingAdapter'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);
    });

    testWidgets('renders adapter with path', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'claude',
        name: 'Claude Code',
        description: 'Claude CLI',
        cliName: 'claude',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.found,
                  version: '1.0.0',
                  path: '/usr/local/bin/claude',
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('/usr/local/bin/claude'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier(const []),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Auto-detected agent runners'),
        findsOneWidget,
      );
    });

    testWidgets('adapter with installed version', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'kilo',
        name: 'Kilo Code',
        description: 'Kilo AI',
        cliName: 'kilo',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.found,
                  version: '2.5.0',
                  path: '/opt/bin/kilo',
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Kilo Code'), findsOneWidget);
      expect(find.textContaining('Installed'), findsOneWidget);
    });

    testWidgets('not found adapter shows Not found version text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const adapter = Adapter(
        id: 'missing',
        name: 'MissingCLI',
        description: 'A missing CLI',
        cliName: 'missingcli',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            detectedAdaptersProvider.overrideWith(
              () => _TestNotifier([
                const DetectedAdapter(
                  adapter: adapter,
                  status: DetectionStatus.notFound,
                ),
              ]),
            ),
          ],
          child: _wrap(const AdaptersSettings()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Not found'), findsOneWidget);
    });
  });
}
