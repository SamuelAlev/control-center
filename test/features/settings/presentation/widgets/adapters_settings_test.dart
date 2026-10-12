import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_account.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_detail_pane.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/claude_accounts_section.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
  String? initialAdapterId,
  Future<List<ClaudeAccountView>> Function(Ref)? loadAccounts,
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
          loadAccounts ?? (ref) async => const <ClaudeAccountView>[],
        ),
        accountPoolProvider(
          const AccountPoolScope(lane: AccountPoolLanes.claudeCode),
        ).overrideWith(
          (ref) async => (pool: const AccountPool(), inherited: null),
        ),
      ],
      child: _wrap(AdaptersSettings(initialAdapterId: initialAdapterId)),
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

CcStatusDot _railDot(WidgetTester tester, String runner) =>
    tester.widget<CcStatusDot>(
      find.descendant(
        of: find.widgetWithText(SettingsRailItem, runner),
        matching: find.byType(CcStatusDot),
      ),
    );

CcStatusTag _runnerStatus(WidgetTester tester) => tester.widget<CcStatusTag>(
  find.descendant(
    of: find.byType(AdapterDetailPane),
    matching: find.byType(CcStatusTag),
  ),
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
        id: 'missing',
        name: 'Missing CLI',
        description: 'A runner that is not installed',
        cliName: 'missing',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        ),
      ]);

      expect(find.text('Missing CLI'), findsNWidgets(2));
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('renders checking adapter', (tester) async {
      const adapter = Adapter(
        id: 'checking',
        name: 'Checking CLI',
        description: 'A runner still being probed',
        cliName: 'checking',
      );

      await _pump(tester, [
        const DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.checking,
        ),
      ]);

      expect(find.text('Checking CLI'), findsNWidgets(2));
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

    testWidgets('expired non-default login warns until credentials refresh', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      var accounts = [
        const ClaudeAccountView(
          account: ClaudeAccount(
            id: 'default',
            label: 'Default account',
            isDefault: true,
            loggedIn: true,
            usesLongLivedToken: true,
          ),
        ),
        ClaudeAccountView(
          account: ClaudeAccount(
            id: 'expired',
            label: 'Expired account',
            loggedIn: true,
            credentialExpiresAt: DateTime.utc(2000),
          ),
        ),
      ];
      late VoidCallback refreshAccounts;
      await _pump(
        tester,
        const [_aider, _claudeCode],
        loadAccounts: (ref) async {
          refreshAccounts = ref.invalidateSelf;
          return accounts;
        },
      );

      expect(_railDot(tester, 'Claude Code').tone, CcStatusTone.caution);
      expect(_railDot(tester, 'Aider').tone, CcStatusTone.positive);
      expect(_runnerStatus(tester).label, l10n.available);

      await tester.tap(find.text('Claude Code').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_runnerStatus(tester).tone, CcStatusTone.caution);
      expect(_runnerStatus(tester).label, l10n.claudeAccountExpired);
      expect(
        find.widgetWithText(CcBadge, l10n.claudeAccountExpired),
        findsOneWidget,
      );

      accounts = [
        accounts.first,
        ClaudeAccountView(
          account: accounts.last.account.copyWith(
            credentialExpiresAt: DateTime.utc(2100),
          ),
        ),
      ];
      refreshAccounts();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_railDot(tester, 'Claude Code').tone, CcStatusTone.positive);
      expect(_runnerStatus(tester).tone, CcStatusTone.positive);
      expect(_runnerStatus(tester).label, l10n.available);
      expect(
        find.widgetWithText(CcBadge, l10n.claudeAccountExpired),
        findsNothing,
      );
    });

    testWidgets('missing CLI keeps detection status ahead of account expiry', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await _pump(
        tester,
        [
          DetectedAdapter(
            adapter: _claudeCode.adapter,
            status: DetectionStatus.notFound,
          ),
        ],
        loadAccounts: (ref) async => [
          ClaudeAccountView(
            account: ClaudeAccount(
              id: 'expired',
              label: 'Expired account',
              loggedIn: true,
              credentialExpiresAt: DateTime.utc(2000),
            ),
          ),
        ],
      );

      expect(_railDot(tester, 'Claude Code').tone, CcStatusTone.neutral);
      expect(_runnerStatus(tester).tone, CcStatusTone.neutral);
      expect(_runnerStatus(tester).label, l10n.unavailable);
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

    testWidgets('initialAdapterId opens that runner', (tester) async {
      await _pump(tester, const [
        _aider,
        _claudeCode,
      ], initialAdapterId: 'claude-code');

      expect(find.byType(ClaudeAccountsSection), findsOneWidget);
      expect(find.text('/usr/bin/claude'), findsOneWidget);
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
    testWidgets('keeps the outer scroll extent stable across tall sections', (
      tester,
    ) async {
      final models = List<HarnessModelInfo>.generate(
        120,
        (i) => HarnessModelInfo(
          id: 'local/model-$i',
          providerId: 'local',
          displayName: 'Model $i',
          contextWindow: 200000,
        ),
      );
      await _pump(
        tester,
        const [_aider],
        size: const Size(1200, 620),
        extraOverrides: [
          harnessProvidersProvider.overrideWith(
            (ref) async => const [
              HarnessProviderInfo(
                id: 'local',
                displayName: 'Local provider',
                authMethods: [],
                enabled: HarnessProviderEnabled.local,
                hasCredential: true,
                baseUrl: 'http://localhost:8080/v1',
              ),
            ],
          ),
          harnessModelsProvider.overrideWith((ref) async => models),
        ],
      );
      await tester.pumpAndSettle();

      final position = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .map((state) => state.position)
          .where((candidate) => candidate.axis == Axis.vertical)
          .reduce((a, b) => a.maxScrollExtent >= b.maxScrollExtent ? a : b);
      final before = position.maxScrollExtent;
      expect(before, greaterThan(3000));

      // A desktop scrollbar derives its thumb length from maxScrollExtent. The
      // page has a few short cards and one very tall model section; if those
      // are separate lazy sliver children, Flutter repeatedly re-estimates the
      // total from whichever child is visible and the thumb changes size.
      for (var step = 1; step <= 8; step++) {
        position.jumpTo(before * step / 8);
        await tester.pump();
        expect(position.maxScrollExtent, closeTo(before, 0.01));
      }
    });
  });
}
