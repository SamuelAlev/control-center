import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_accounts_section.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

class _TestNotifier extends AdapterDetectionNotifier {
  _TestNotifier(this._adapters);
  final List<DetectedAdapter> _adapters;
  @override
  List<DetectedAdapter> build() => _adapters;
}

Future<void> _pump(
  WidgetTester tester,
  List<DetectedAdapter> adapters, {
  AppPreferences? prefs,
  Size size = const Size(1200, 900),
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...extraOverrides,
        appPreferencesProvider.overrideWithValue(
          prefs ?? AppPreferences.inMemory(),
        ),
        detectedAdaptersProvider.overrideWith(() => _TestNotifier(adapters)),
        claudeAccountsProvider.overrideWith(
          (ref) async => const <ClaudeAccountView>[],
        ),
      ],
      child: _wrap(const AdaptersSettings()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

const _claudeCode = DetectedAdapter(
  adapter: Adapter(
    id: 'claude-code',
    name: 'Claude Code',
    description: 'Claude CLI',
    cliName: 'claude',
    transport: AdapterTransport.claudeCli,
  ),
  status: DetectionStatus.found,
  version: '1.0.0',
  path: '/usr/bin/claude',
);

const _aider = DetectedAdapter(
  adapter: Adapter(
    id: 'aider',
    name: 'Aider',
    description: 'Aider CLI',
    cliName: 'aider',
  ),
  status: DetectionStatus.found,
  version: '0.9.0',
  path: '/usr/bin/aider',
);

void main() {
  group('AdaptersSettings', () {
    testWidgets('renders header and refresh button', (tester) async {
      await _pump(tester, const []);

      expect(find.text('Adapters'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await _pump(tester, const []);

      expect(
        find.textContaining('Auto-detected agent runners'),
        findsOneWidget,
      );
    });

    testWidgets('renders detected adapter in rail and detail', (tester) async {
      const adapter = Adapter(
        id: 'claude',
        name: 'Claude Code',
        description: 'Claude CLI',
        cliName: 'claude',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.found,
          version: '1.0.0',
          path: '/usr/bin/claude',
        ),
      ]);

      // Name appears in the rail AND the detail pane title.
      expect(find.text('Claude Code'), findsNWidgets(2));
      // Status tag appears in the detail pane only (rail shows a dot).
      expect(find.text('Available'), findsOneWidget);
    });

    testWidgets('renders unavailable adapter', (tester) async {
      const adapter = Adapter(
        id: 'pi',
        name: 'Pi',
        description: 'Pi AI',
        cliName: 'pi',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        ),
      ]);

      expect(find.text('Pi'), findsNWidgets(2));
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('renders checking adapter', (tester) async {
      const adapter = Adapter(
        id: 'oc',
        name: 'OpenCode',
        description: 'OpenCode CLI',
        cliName: 'opencode',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.checking,
        ),
      ]);

      expect(find.text('OpenCode'), findsNWidgets(2));
      expect(find.text('Checking'), findsOneWidget);
    });

    testWidgets('renders multiple adapters with different statuses', (
      tester,
    ) async {
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

      await _pump(tester, [found, notFound, checking]);

      // All three names appear in the rail; the found one is auto-selected so
      // its name also appears in the detail pane title.
      expect(find.text('FoundAdapter'), findsNWidgets(2));
      expect(find.text('MissingAdapter'), findsOneWidget);
      expect(find.text('CheckingAdapter'), findsOneWidget);
      // Found adapter's status tag in the detail pane.
      expect(find.text('Available'), findsOneWidget);
      // The other two statuses: not visible as text (rail uses dots only).
      expect(find.text('Unavailable'), findsNothing);
      expect(find.text('Checking'), findsNothing);
    });

    testWidgets('renders adapter path in detail pane', (tester) async {
      const adapter = Adapter(
        id: 'claude',
        name: 'Claude Code',
        description: 'Claude CLI',
        cliName: 'claude',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.found,
          version: '1.0.0',
          path: '/usr/local/bin/claude',
        ),
      ]);

      expect(find.text('/usr/local/bin/claude'), findsOneWidget);
    });

    testWidgets('renders installed version in detail pane', (tester) async {
      const adapter = Adapter(
        id: 'kilo',
        name: 'Kilo Code',
        description: 'Kilo AI',
        cliName: 'kilo',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.found,
          version: '2.5.0',
          path: '/opt/bin/kilo',
        ),
      ]);

      expect(find.text('Kilo Code'), findsNWidgets(2));
      expect(find.textContaining('Installed'), findsOneWidget);
    });

    testWidgets('not found adapter shows Not found text', (tester) async {
      const adapter = Adapter(
        id: 'missing',
        name: 'MissingCLI',
        description: 'A missing CLI',
        cliName: 'missingcli',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        ),
      ]);

      expect(find.text('Not found'), findsOneWidget);
    });

    testWidgets('selecting a rail item updates the detail pane', (
      tester,
    ) async {
      const claude = DetectedAdapter(
        adapter: Adapter(
          id: 'claude',
          name: 'Claude Code',
          description: 'Claude CLI',
          cliName: 'claude',
        ),
        status: DetectionStatus.found,
        version: '1.0.0',
        path: '/usr/bin/claude',
      );
      const aider = DetectedAdapter(
        adapter: Adapter(
          id: 'aider',
          name: 'Aider',
          description: 'Aider CLI',
          cliName: 'aider',
        ),
        status: DetectionStatus.found,
        version: '0.9.0',
        path: '/usr/bin/aider',
      );

      await _pump(tester, [claude, aider]);

      // Claude is auto-selected (found, first in catalog order).
      expect(find.text('/usr/bin/claude'), findsOneWidget);

      // Tap Aider in the rail.
      final aiderTexts = find.text('Aider');
      expect(aiderTexts, findsWidgets);
      await tester.tap(aiderTexts.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Detail pane now shows Aider's path.
      expect(find.text('/usr/bin/aider'), findsOneWidget);
    });

    testWidgets('Claude Code detail pane owns the accounts group', (
      tester,
    ) async {
      await _pump(tester, const [_claudeCode]);

      expect(find.byType(ClaudeAccountsSection), findsOneWidget);
      expect(find.text('Add account'), findsOneWidget);
      // The old page-level card is gone: the group heading is "Accounts",
      // not a second "Claude Code accounts" eyebrow under the runner list.
      expect(find.text('Claude Code accounts'), findsNothing);
    });

    testWidgets('other runners do not show Claude Code accounts', (
      tester,
    ) async {
      await _pump(tester, const [_aider]);

      expect(find.byType(ClaudeAccountsSection), findsNothing);
      expect(find.text('Add account'), findsNothing);
    });

    testWidgets('selecting away from Claude Code hides accounts', (
      tester,
    ) async {
      await _pump(tester, const [_claudeCode, _aider]);

      expect(find.byType(ClaudeAccountsSection), findsOneWidget);

      await tester.tap(find.text('Aider').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ClaudeAccountsSection), findsNothing);
      expect(find.text('/usr/bin/aider'), findsOneWidget);
    });
  });
}
