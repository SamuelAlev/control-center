// Step 3 (adapter) of onboarding: the built-in runner serves its model list
// live from logged-in providers, so the step carries the provider login flow
// inline — a provider dropdown that opens the login dialog, after which the
// model dropdown populates. These tests pin that contract end to end.

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/model_picker_field.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppPreferences prefs;
  late _FakeHarnessProviderRepository repository;
  late _FakeAgentRepository agents;

  setUp(() {
    prefs = AppPreferences.inMemory();
    repository = _FakeHarnessProviderRepository();
    agents = _FakeAgentRepository(_seededRoster());
  });

  const macNativeDetection = SandboxDetectionResult(
    platform: 'macos',
    recommendation: SandboxBackend.native,
    capabilities: {
      SandboxBackend.native: SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
      ),
    },
  );

  /// Pumps the full onboarding flow and drives it to the adapter step: step 1
  /// Continue (authenticated), step 2 workspace create (fake), sandbox
  /// "Use sandbox" (native available).
  Future<void> pumpToAdapterStep(
    WidgetTester tester, {
    AdapterDetectionNotifier Function() detection = _FakeDetectedAdapters.new,
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          // The onboarding gate is "at least one forge connected"; overriding
          // the connections keeps the real derivation under test.
          forgeConnectionsProvider.overrideWith(
            (ref) async => const [
              ForgeConnection(
                forge: ForgeHost.github,
                authenticated: true,
                username: 'testuser',
                source: ForgeCredentialSource.oauth,
              ),
            ],
          ),
          createWorkspaceProvider.overrideWith(
            _FakeCreateWorkspaceNotifier.new,
          ),
          workspacesProvider.overrideWith(
            (ref) => Stream.value(const <Workspace>[]),
          ),
          sandboxDetectionProvider.overrideWith(
            (ref) => Future.value(macNativeDetection),
          ),
          detectedAdaptersProvider.overrideWith(detection),
          harnessProviderRepositoryProvider.overrideWithValue(repository),
          rawModelCatalogProvider.overrideWith(
            (ref) => Future.value(ModelCatalog.empty),
          ),
          agentRepositoryProvider.overrideWithValue(agents),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(body: OnboardingScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Step 1 → step 2.
    final stepOneContinue = find.widgetWithText(CcButton, 'Continue');
    await tester.ensureVisible(stepOneContinue);
    await tester.pump();
    await tester.tap(stepOneContinue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Give your work a home.'), findsOneWidget);

    // Step 2 → step 3 (sandbox): create the workspace, then use the sandbox.
    await tester.enterText(find.byType(CcTextField), 'Acme');
    await tester.pump();
    final stepTwoContinue = find.widgetWithText(CcButton, 'Continue');
    await tester.ensureVisible(stepTwoContinue);
    await tester.pump();
    await tester.tap(stepTwoContinue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Isolate agent execution.'), findsOneWidget);

    final useSandbox = find.widgetWithText(CcButton, 'Use sandbox');
    await tester.ensureVisible(useSandbox);
    await tester.pump();
    await tester.tap(useSandbox);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Choose your agent runner.'), findsOneWidget);
  }

  testWidgets(
    'the built-in runner shows the provider dropdown and the login dialog, '
    'then the models appear',
    (tester) async {
      await pumpToAdapterStep(tester);

      // The provider dropdown is there and the model field explains why it
      // is empty; Continue stays disabled until a model is chosen.
      expect(find.text('Select a provider to log in'), findsOneWidget);
      expect(find.text('Connect a provider to see models.'), findsOneWidget);
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Continue'))
            .onPressed,
        isNull,
      );

      // Open the provider dropdown: the unconnected provider opens the login
      // dialog.
      await tester.tap(find.text('Select a provider to log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Anthropic').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in to Anthropic'), findsOneWidget);

      // Log in with an API key: the dialog closes and the model dropdown
      // repopulates from the now-connected provider.
      await tester.enterText(find.byType(CcTextField).last, 'sk-onboarding');
      await tester.pump();
      await tester.tap(find.widgetWithText(CcButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in to Anthropic'), findsNothing);
      expect(repository.savedKeys['anthropic'], 'sk-onboarding');

      // The model field is now the browser picker; the connected provider's
      // model is one tap away and unlocks Continue.
      expect(find.text('Connect a provider to see models.'), findsNothing);
      expect(find.byType(ModelPickerField), findsOneWidget);

      // Opening the browser stages nothing: Continue stays disabled until a
      // row is actually picked.
      await tester.ensureVisible(find.byType(ModelPickerField));
      await tester.pump();
      await tester.tap(find.byType(ModelPickerField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Continue'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('claude-test').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Continue'))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'continuing stamps the pick on EVERY seeded agent, not just the CEO',
    (tester) async {
      await pumpToAdapterStep(tester);

      // Connect a provider so the model list populates, then commit a model.
      await tester.tap(find.text('Select a provider to log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Anthropic').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(CcTextField).last, 'sk-onboarding');
      await tester.pump();
      await tester.tap(find.widgetWithText(CcButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.byType(ModelPickerField));
      await tester.pump();
      await tester.tap(find.byType(ModelPickerField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('claude-test').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(CcButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Workspace creation seeds a CEO *and* four specialists with no runner;
      // the adapter step is the only place the pick exists, so patching the
      // CEO alone left four of the five agents unable to run.
      expect(agents.saved.map((a) => a.name).toSet(), {
        'ceo',
        'architect',
        'engineer',
        'qa',
        'librarian',
      });
      for (final agent in agents.saved) {
        expect(agent.adapterId, 'cc-harness', reason: agent.name);
        expect(agent.modelId, 'anthropic/claude-test', reason: agent.name);
      }
    },
  );

  testWidgets(
    'does not wait for Claude Code detection before showing the built-in runner',
    (tester) async {
      await pumpToAdapterStep(
        tester,
        detection: _HarnessReadyWhileClaudeChecks.new,
      );

      expect(find.text('Control Center (built-in)'), findsOneWidget);
      expect(find.text('Select a provider to log in'), findsOneWidget);
      expect(find.text('Detecting adapters…'), findsNothing);
    },
  );

  testWidgets(
    'prefers the built-in runner when Claude Code is also installed',
    (tester) async {
      await pumpToAdapterStep(tester, detection: _BothRunnersFound.new);

      expect(find.text('Select a provider to log in'), findsOneWidget);

      await tester.tap(find.text('Control Center (built-in)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Claude Code'), findsOneWidget);
    },
  );

  testWidgets(
    'the built-in runner lists Cursor as a provider next to Anthropic',
    (tester) async {
      await pumpToAdapterStep(tester);

      await tester.tap(find.text('Select a provider to log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Anthropic'), findsWidgets);
      expect(find.text('Cursor'), findsOneWidget);

      await tester.tap(find.text('Cursor').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in to Cursor'), findsOneWidget);
      expect(find.text('Log in with browser'), findsOneWidget);
    },
  );

  testWidgets(
    'a leftover deleted-runner preference still lands on the built-in',
    (tester) async {
      prefs = AppPreferences.inMemory({'default_chat_adapter_id': 'pi'});
      await pumpToAdapterStep(tester);

      expect(find.text('Control Center (built-in)'), findsOneWidget);
      expect(find.text('Select a provider to log in'), findsOneWidget);
    },
  );

  testWidgets('empty detection no longer tells the operator to install Pi', (
    tester,
  ) async {
    await pumpToAdapterStep(tester, detection: _NoAdaptersFound.new);

    expect(
      find.text('No runners detected yet. Refresh to scan again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Install Pi'), findsNothing);
    expect(find.textContaining('@anthropic/pi'), findsNothing);
    expect(find.text('Select a provider to log in'), findsNothing);
  });
}

/// The roster a freshly created workspace is seeded with: a CEO and four
/// specialists, none of them carrying a runner yet (the seeder runs at
/// workspace creation, before the adapter is picked).
List<Agent> _seededRoster() => [
  for (final name in ['ceo', 'architect', 'engineer', 'qa', 'librarian'])
    Agent(
      id: 'agent-$name',
      name: name,
      title: name,
      agentMdPath: '/tmp/$name/AGENTS.md',
      workspaceId: 'ws-new',
      skills: AgentSkills(const []),
      createdAt: DateTime(2026),
    ),
];

class _FakeAgentRepository implements AgentRepository {
  _FakeAgentRepository(this._agents);

  final List<Agent> _agents;

  /// Every agent handed to [upsert], in call order.
  final saved = <Agent>[];

  @override
  Stream<List<Agent>> watchAll() => Stream.value(_agents);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String workspaceId, String id) async => _agents
      .where((a) => a.workspaceId == workspaceId && a.id == id)
      .firstOrNull;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async => _agents
      .where((a) => a.workspaceId == workspaceId && a.name == name)
      .firstOrNull;

  @override
  Future<void> upsert(Agent agent) async => saved.add(agent);

  @override
  Future<void> delete(String workspaceId, String id) async =>
      _agents.removeWhere((a) => a.workspaceId == workspaceId && a.id == id);
}

class _FakeCreateWorkspaceNotifier extends CreateWorkspaceNotifier {
  @override
  Future<String?> create({required String name, String? logoPath}) async {
    state = const AsyncData<String?>('ws-new');
    return 'ws-new';
  }
}

/// Detection fixture: only the built-in harness adapter is "installed", so
/// the step pre-selects it.
class _FakeDetectedAdapters extends AdapterDetectionNotifier {
  @override
  List<DetectedAdapter> build() => [
    DetectedAdapter(adapter: builtInAdapter, status: DetectionStatus.found),
  ];
}

/// Production starts every catalogued runner as `checking`. The built-in loop
/// is always found (no binary); Claude Code's `--version` can lag. The step
/// must not hide the provider login behind that probe.
class _HarnessReadyWhileClaudeChecks extends AdapterDetectionNotifier {
  @override
  List<DetectedAdapter> build() => [
    DetectedAdapter(adapter: builtInAdapter, status: DetectionStatus.found),
    DetectedAdapter(
      adapter: predefinedAdapters.firstWhere((a) => a.id == 'claude-code'),
      status: DetectionStatus.checking,
    ),
  ];
}

class _BothRunnersFound extends AdapterDetectionNotifier {
  @override
  List<DetectedAdapter> build() => [
    for (final adapter in predefinedAdapters)
      DetectedAdapter(adapter: adapter, status: DetectionStatus.found),
  ];
}

class _NoAdaptersFound extends AdapterDetectionNotifier {
  @override
  List<DetectedAdapter> build() => [
    for (final adapter in predefinedAdapters)
      DetectedAdapter(adapter: adapter, status: DetectionStatus.notFound),
  ];
}

class _FakeHarnessProviderRepository implements HarnessProviderRepository {
  static const _anthropicDisconnected = HarnessProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.disabled,
    hasCredential: false,
  );

  static const _anthropicConnected = HarnessProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.account,
    hasCredential: true,
  );

  static const _cursorDisconnected = HarnessProviderInfo(
    id: 'cursor',
    displayName: 'Cursor',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.disabled,
    hasCredential: false,
  );

  var _providers = const [_anthropicDisconnected, _cursorDisconnected];
  final savedKeys = <String, String>{};

  @override
  Future<List<HarnessProviderInfo>> listProviders() async => _providers;

  @override
  Future<List<HarnessModelInfo>> listModels({String? providerId}) async {
    const models = [
      HarnessModelInfo(id: 'anthropic/claude-test', providerId: 'anthropic'),
    ];
    final connected = _providers.any((p) => p.connected);
    if (!connected) {
      return const [];
    }
    return providerId == null
        ? models
        : models.where((m) => m.providerId == providerId).toList();
  }

  @override
  Future<void> saveApiKey({
    required String providerId,
    required String apiKey,
    String? baseUrl,
    String? accountLabel,
  }) async {
    savedKeys[providerId] = apiKey;
    _providers = const [_anthropicConnected, _cursorDisconnected];
  }

  @override
  Future<void> removeCredential({
    required String providerId,
    String? accountLabel,
    String? credentialId,
  }) async {}

  @override
  Future<String> addCustomProvider({
    required String displayName,
    required CustomProviderDialect dialect,
    required String baseUrl,
    String? apiKey,
    Map<String, ProviderModelOverride>? models,
  }) async => 'custom-fake';

  @override
  Future<void> removeCustomProvider(String providerId) async {}

  @override
  Future<void> saveModelOverride({
    required String providerId,
    required String modelId,
    required ProviderModelOverride override,
  }) async {}

  @override
  Future<void> removeModelOverride({
    required String providerId,
    required String modelId,
  }) async {}

  @override
  Future<void> saveGenerationDefaults({
    required String providerId,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) async {}

  @override
  Future<HarnessOAuthStart> startOAuth(String providerId) =>
      throw UnimplementedError();

  @override
  Future<HarnessOAuthStatus> oauthStatus(String flowId) =>
      throw UnimplementedError();

  @override
  Future<void> completeOAuth({
    required String flowId,
    required String code,
  }) async {}

  @override
  Future<void> cancelOAuth(String flowId) async {}
}
