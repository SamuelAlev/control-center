import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/mcp/data/services/mcp_http_server.dart';
import 'package:control_center/features/mcp/data/services/mcp_tool_dispatcher.dart';
import 'package:control_center/features/mcp/domain/mcp_config.dart';
import 'package:control_center/features/mcp/providers/mcp_config_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_server_provider.dart';
import 'package:control_center/features/mcp/providers/mcp_tools_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/mcp_settings.dart';
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

class _TestMcpConfigNotifier extends McpConfigNotifier {
  _TestMcpConfigNotifier(this._config);
  final McpConfig _config;
  @override
  McpConfig build() => _config;
  @override
  Future<void> setPort(int port) async {}
  @override
  Future<void> setToken(String? token) async {}
  @override
  Future<void> setEnabled({required bool enabled}) async {}
}

McpHttpServer _fakeServer(bool isRunning) {
  final container = ProviderContainer();
  final registry = container.read(mcpToolRegistryProvider);
  addTearDown(container.dispose);
  return McpHttpServer(
    config: const McpConfig(port: 9020, enabled: true),
    dispatcher: McpToolDispatcher(registry: registry),
  );
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });


  group('McpSettingsPanel stopped', () {
    testWidgets('renders stopped status', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('shows default port in subtitle when stopped', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 8080, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Default: 9020'), findsOneWidget);
    });
  });

  group('McpSettingsPanel auth', () {
    testWidgets('shows no token message', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true, token: null)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('No token'), findsOneWidget);
    });

    testWidgets('shows token configured message', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true, token: 'secret')),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Configured — clients must present this token.'), findsOneWidget);
    });
  });

  group('McpSettingsPanel enabled toggle', () {
    testWidgets('shows disabled state', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: false)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('Enable MCP Server section renders', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enable MCP server'), findsOneWidget);
    });

    testWidgets('enabled state shows Enabled text', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enabled'), findsOneWidget);
    });
  });

  group('McpSettingsPanel stopped state', () {
    testWidgets('shows server stopped message', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Server is stopped'), findsOneWidget);
    });

    testWidgets('shows not running message', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('enable MCP connections'), findsOneWidget);
    });
  });

  group('McpSettingsPanel Status card', () {
    testWidgets('Status section always renders', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('Port section always renders', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Port'), findsAtLeast(1));
    });

    testWidgets('Authentication section always renders', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final server = _fakeServer(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mcpConfigProvider.overrideWith(
              () => _TestMcpConfigNotifier(const McpConfig(port: 9020, enabled: true)),
            ),
            mcpServerProvider.overrideWith((ref) => server),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: _wrap(const McpSettingsPanel()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Authentication'), findsOneWidget);
    });
  });
}
