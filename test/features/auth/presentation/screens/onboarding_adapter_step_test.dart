// Step 3 (adapter) of onboarding: the built-in runner serves its model list
// live from logged-in providers, so the step carries the provider login flow
// inline — a provider dropdown that opens the login dialog, after which the
// model dropdown populates. These tests pin that contract end to end.

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
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

  setUp(() {
    prefs = AppPreferences.inMemory();
    repository = _FakeHarnessProviderRepository();
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

  /// Pumps the full onboarding flow and drives it to step 3 (adapter): step 1
  /// Continue (authenticated), step 2 workspace create (fake), sandbox
  /// "Use sandbox" (native available).
  Future<void> pumpToAdapterStep(WidgetTester tester) async {
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
          githubCliStatusProvider.overrideWith(
            (ref) => Future.value(
              const GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                username: 'testuser',
              ),
            ),
          ),
          // The onboarding gate is "at least one forge connected"; overriding
          // the connections keeps the real derivation under test.
          forgeConnectionsProvider.overrideWith(
            (ref) async => const [
              ForgeConnection(
                forge: ForgeHost.github,
                authenticated: true,
                username: 'testuser',
                source: ForgeCredentialSource.cli,
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
          detectedAdaptersProvider.overrideWith(_FakeDetectedAdapters.new),
          harnessProviderRepositoryProvider.overrideWithValue(repository),
          rawModelCatalogProvider.overrideWith(
            (ref) => Future.value(ModelCatalog.empty),
          ),
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

      // The model field is now a real autocomplete; the connected provider's
      // model is selectable and unlocks Continue.
      expect(find.text('Connect a provider to see models.'), findsNothing);
      expect(find.byType(CcAutocomplete<String>), findsOneWidget);
      final modelField = find.descendant(
        of: find.byType(CcAutocomplete<String>),
        matching: find.byType(EditableText),
      );
      await tester.enterText(modelField, 'anthropic/claude-test');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Combo box semantics: typing stages the custom model id but does not
      // commit it, so Continue stays disabled until Enter.
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Continue'))
            .onPressed,
        isNull,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Continue'))
            .onPressed,
        isNotNull,
      );
    },
  );
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
    DetectedAdapter(
      adapter: predefinedAdapters.firstWhere((a) => a.id == 'cc-harness'),
      status: DetectionStatus.found,
    ),
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

  var _providers = const [_anthropicDisconnected];
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
    _providers = const [_anthropicConnected];
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
  }) async => 'custom-fake';

  @override
  Future<void> removeCustomProvider(String providerId) async {}

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
