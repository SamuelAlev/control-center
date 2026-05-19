import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/providers_models_section.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/model_catalog_providers.dart';
import 'package:control_center/features/settings/providers/provider_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

CcCheckbox _checkbox(WidgetTester tester, String label) {
  return tester.widget<CcCheckbox>(
    find
        .byWidgetPredicate((w) => w is CcCheckbox && w.semanticLabel == label)
        .first,
  );
}

void main() {
  late _FakeHarnessProviderRepository repository;

  /// A models.dev fixture enriching `anthropic/claude-live` — the live report
  /// carries no price/context for it, so the row must show the catalog's.
  final catalog = ModelCatalog.fromModelsDev({
    'anthropic': {
      'id': 'anthropic',
      'name': 'Anthropic',
      'env': ['ANTHROPIC_API_KEY'],
      'models': {
        'claude-live': {
          'id': 'claude-live',
          'name': 'Claude Live',
          'modalities': {
            'input': ['text', 'image'],
            'output': ['text'],
          },
          'limit': {'context': 200000, 'output': 8192},
          'cost': {'input': 3, 'output': 15},
        },
      },
    },
    // Published under a different id than our harness provider (`kimi-code`).
    'kimi-for-coding': {
      'id': 'kimi-for-coding',
      'name': 'Kimi For Coding',
      'env': <String>[],
      'models': {
        'k3': {
          'id': 'k3',
          'name': 'Kimi K3',
          'modalities': {
            'input': ['text', 'image', 'video'],
            'output': ['text'],
          },
          'limit': {'context': 1048576, 'output': 131072},
        },
      },
    },
  });

  setUp(() {
    repository = _FakeHarnessProviderRepository();
  });

  Future<void> pumpSection(WidgetTester tester) async {
    // The section is a tall master-detail surface; the default 800×600 test
    // viewport pushes the pane's lower half off-screen.
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          harnessProviderRepositoryProvider.overrideWithValue(repository),
          rawModelCatalogProvider.overrideWith((ref) async => catalog),
          workspaceProviderPoliciesProvider.overrideWith(
            (ref) => Stream.value(const <WorkspaceProviderPolicy>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(child: ProvidersModelsSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ProvidersModelsSection', () {
    testWidgets('rail lists providers and the connected one is preselected', (
      tester,
    ) async {
      await pumpSection(tester);

      // Both groups render in the rail.
      expect(find.text('Anthropic'), findsOneWidget);
      // The rail row AND the detail pane header both carry the name.
      expect(find.text('My Local LLM'), findsNWidgets(2));
      // The connected custom provider is preselected: its detail pane shows
      // the base URL subtitle and its model list.
      expect(find.text('http://localhost:8080/v1'), findsWidgets);
      expect(find.text('llama-live'), findsOneWidget);
      expect(find.text('llama-manual'), findsOneWidget);
    });

    testWidgets('selecting another provider swaps the detail pane', (
      tester,
    ) async {
      await pumpSection(tester);
      await tester.tap(find.text('Anthropic'));
      await tester.pump();

      // The disconnected provider's pane: its state and its live models.
      expect(find.text('Not connected'), findsOneWidget);
      expect(find.text('claude-live'), findsOneWidget);
      // Catalog enrichment: the live row carries no context/price, the
      // models.dev fixture supplies both.
      expect(find.text('200K'), findsOneWidget);
      expect(find.text('\$3.00 / \$15.00 per 1M'), findsOneWidget);
    });

    testWidgets('editing a model saves an override for it', (tester) async {
      await pumpSection(tester);
      await tester.tap(find.text('Anthropic'));
      await tester.pump();

      await tester.tap(find.widgetWithIcon(CcIconButton, AppIcons.pencil));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dialog = find.byType(CcDialog);
      expect(dialog, findsOneWidget);
      // The dialog prefills from the catalog: context 200000, output 8192.
      final contextField = find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (w) => w is CcTextField && w.hintText == 'e.g. 200000',
        ),
      );
      expect(
        tester.widget<CcTextField>(contextField).controller!.text,
        '200000',
      );
      // Matching models.dev provider ids still enrich modalities.
      expect(_checkbox(tester, 'Image').value, isTrue);
      expect(_checkbox(tester, 'Video').value, isFalse);

      await tester.enterText(contextField, '1000000');
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(CcButton, 'Save'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final saved = repository.savedOverrides['anthropic/claude-live'];
      expect(saved, isNotNull);
      expect(saved!.contextWindow, 1000000);
      expect(saved.manual, isFalse);
      // Untouched fields stay inherited — an override stores only what changed.
      expect(saved.maxOutputTokens, isNull);
      expect(saved.inputModalities, isEmpty);
    });

    testWidgets('a hand-registered model can be removed', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.widgetWithIcon(CcIconButton, AppIcons.trash2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.descendant(
          of: find.byType(CcDialog),
          matching: find.widgetWithText(CcButton, 'Remove'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.removedOverrides, ['custom-local/llama-manual']);
    });

    testWidgets('kimi-code/k3 prefills image and video from kimi-for-coding', (
      tester,
    ) async {
      await pumpSection(tester);
      await tester.tap(find.text('Kimi Code'));
      await tester.pump();

      await tester.tap(find.widgetWithIcon(CcIconButton, AppIcons.pencil));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CcDialog), findsOneWidget);
      expect(_checkbox(tester, 'Image').value, isTrue);
      expect(_checkbox(tester, 'Video').value, isTrue);
      expect(_checkbox(tester, 'Audio').value, isFalse);
      expect(_checkbox(tester, 'PDF').value, isFalse);
    });

    testWidgets('adding a provider with a hand-registered model', (
      tester,
    ) async {
      await pumpSection(tester);

      await tester.tap(find.text('Add provider'));
      await tester.pump();
      expect(find.text('Add model provider'), findsOneWidget);

      // The submit stays disabled until name + a valid URL are entered.
      final addButton = find.widgetWithText(CcButton, 'Add provider');
      expect(tester.widget<CcButton>(addButton).onPressed, isNull);

      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CcTextField && w.hintText == 'e.g. DeepSeek',
        ),
        'Acme Inference',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is CcTextField && w.hintText == 'https://api.example.com/v1',
        ),
        'https://api.acme.example/v1',
      );
      await tester.pump();
      expect(tester.widget<CcButton>(addButton).onPressed, isNotNull);

      // Register one model by hand through the dialog.
      await tester.tap(find.widgetWithText(CcButton, 'Add model'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final dialog = find.byType(CcDialog);
      await tester.enterText(
        find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (w) => w is CcTextField && w.hintText == 'e.g. glm-5-turbo',
          ),
        ),
        'acme-pro',
      );
      await tester.enterText(
        find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (w) => w is CcTextField && w.hintText == 'e.g. 200000',
          ),
        ),
        '131072',
      );
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(CcButton, 'Save'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('acme-pro'), findsOneWidget);

      await tester.tap(addButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final added = repository.addedCustom;
      expect(added, isNotNull);
      expect(added!.displayName, 'Acme Inference');
      expect(added.dialect, CustomProviderDialect.openai);
      final model = added.models!['acme-pro'];
      expect(model, isNotNull);
      expect(model!.contextWindow, 131072);
      expect(model.manual, isTrue);
      expect(model.inputModalities, ['text']);
    });
  });
}

class _AddedCustom {
  _AddedCustom({
    required this.displayName,
    required this.dialect,
    required this.baseUrl,
    this.models,
  });

  final String displayName;
  final CustomProviderDialect dialect;
  final String baseUrl;
  final Map<String, ProviderModelOverride>? models;
}

class _FakeHarnessProviderRepository implements HarnessProviderRepository {
  static const _anthropic = HarnessProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.disabled,
    hasCredential: false,
  );

  static const _customLocal = HarnessProviderInfo(
    id: 'custom-local',
    displayName: 'My Local LLM',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.custom,
    hasCredential: false,
    baseUrl: 'http://localhost:8080/v1',
    isCustom: true,
    dialect: CustomProviderDialect.openai,
  );

  static const _kimiCode = HarnessProviderInfo(
    id: 'kimi-code',
    displayName: 'Kimi Code',
    authMethods: [HarnessAuthMethod.oauth],
    enabled: HarnessProviderEnabled.oauth,
    hasCredential: true,
  );

  final savedKeys = <String, String>{};
  final savedOverrides = <String, ProviderModelOverride>{};
  final removedOverrides = <String>[];
  _AddedCustom? addedCustom;

  @override
  Future<List<HarnessProviderInfo>> listProviders() async => const [
    _anthropic,
    _customLocal,
    _kimiCode,
  ];

  @override
  Future<List<HarnessModelInfo>> listModels({String? providerId}) async {
    const models = [
      HarnessModelInfo(id: 'anthropic/claude-live', providerId: 'anthropic'),
      HarnessModelInfo(
        id: 'custom-local/llama-live',
        providerId: 'custom-local',
        contextWindow: 32768,
      ),
      HarnessModelInfo(
        id: 'custom-local/llama-manual',
        providerId: 'custom-local',
        contextWindow: 131072,
        maxOutputTokens: 4096,
        inputModalities: ['text'],
        outputModalities: ['text'],
        hasOverride: true,
        manual: true,
      ),
      HarnessModelInfo(
        id: 'kimi-code/k3',
        providerId: 'kimi-code',
        displayName: 'k3',
        contextWindow: 1048576,
      ),
    ];
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
  }) async {
    addedCustom = _AddedCustom(
      displayName: displayName,
      dialect: dialect,
      baseUrl: baseUrl,
      models: models,
    );
    return 'custom-acme';
  }

  @override
  Future<void> removeCustomProvider(String providerId) async {}

  @override
  Future<void> saveModelOverride({
    required String providerId,
    required String modelId,
    required ProviderModelOverride override,
  }) async {
    savedOverrides['$providerId/$modelId'] = override;
  }

  @override
  Future<void> removeModelOverride({
    required String providerId,
    required String modelId,
  }) async {
    removedOverrides.add('$providerId/$modelId');
  }

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
