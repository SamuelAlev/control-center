import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeHarnessProviderRepository repository;

  setUp(() {
    repository = _FakeHarnessProviderRepository();
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    HarnessProviderInfo info, {
    VoidCallback? onConnected,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          harnessProviderRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              // Scrollable, because that is the only context the panel ever
              // renders in: a CcDialog's content or a settings tile inside the
              // scrolling settings page. Pinned bare in an 800x600 body it
              // overflows as soon as a provider has more than one stored
              // credential — a failure of the harness, not of the panel.
              body: SingleChildScrollView(
                child: HarnessProviderLoginPanel(
                  info: info,
                  onConnected: onConnected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('HarnessProviderLoginPanel', () {
    testWidgets('shows an API-key row for key providers', (tester) async {
      await pumpPanel(tester, _FakeHarnessProviderRepository.anthropicKey);
      expect(find.byType(CcTextField), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Save'), findsOneWidget);
      // No OAuth method → no browser-login button.
      expect(find.text('Log in with browser'), findsNothing);
    });

    testWidgets('shows the browser-login button for OAuth providers', (
      tester,
    ) async {
      await pumpPanel(tester, _FakeHarnessProviderRepository.openaiOAuth);
      expect(find.text('Log in with browser'), findsOneWidget);
      // OAuth-only providers issue no key — no key box.
      expect(find.byType(CcTextField), findsNothing);
    });

    testWidgets('saving a key stores the credential and fires onConnected', (
      tester,
    ) async {
      var connected = false;
      await pumpPanel(
        tester,
        _FakeHarnessProviderRepository.anthropicKey,
        onConnected: () => connected = true,
      );

      await tester.enterText(find.byType(CcTextField), 'sk-test-key');
      await tester.pump();
      await tester.tap(find.widgetWithText(CcButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        repository.savedKeys['anthropic'],
        'sk-test-key',
        reason: 'the trimmed key must reach the repository',
      );
      expect(connected, isTrue);
    });

    testWidgets('an empty key never reaches the repository', (tester) async {
      var connected = false;
      await pumpPanel(
        tester,
        _FakeHarnessProviderRepository.anthropicKey,
        onConnected: () => connected = true,
      );

      await tester.tap(find.widgetWithText(CcButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.savedKeys, isEmpty);
      expect(connected, isFalse);
    });

    testWidgets('lists stored credentials with the active one marked', (
      tester,
    ) async {
      await pumpPanel(tester, _FakeHarnessProviderRepository.anthropicMultiKey);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('…wxyz'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // The add row stays available so a third key can join the rotation.
      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('removing a credential confirms, then passes its id', (
      tester,
    ) async {
      await pumpPanel(tester, _FakeHarnessProviderRepository.anthropicMultiKey);

      await tester.tap(find.byIcon(AppIcons.trash2).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(CcButton, 'Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.removedCredentialIds, ['key:aaa111']);
    });

    testWidgets(
      'an OAuth-connected provider still offers to add another account',
      (tester) async {
        await pumpPanel(
          tester,
          _FakeHarnessProviderRepository.kimiCodeSignedIn,
        );
        expect(find.text('Add another account'), findsOneWidget);
      },
    );
  });

  group('showHarnessProviderLoginDialog', () {
    Future<void> pumpOpener(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            harnessProviderRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: CcTheme(
              data: CcThemeData.light(),
              child: Scaffold(
                body: Builder(
                  builder: (context) => CcButton(
                    onPressed: () => showHarnessProviderLoginDialog(
                      context,
                      _FakeHarnessProviderRepository.anthropicKey,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('titles the dialog with the provider name', (tester) async {
      await pumpOpener(tester);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in to Anthropic'), findsOneWidget);
      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('resolves true once the provider connects', (tester) async {
      await pumpOpener(tester);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(CcTextField), 'sk-dialog-key');
      await tester.pump();
      await tester.tap(find.widgetWithText(CcButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The dialog popped: its title and key field are gone.
      expect(find.text('Log in to Anthropic'), findsNothing);
      expect(repository.savedKeys['anthropic'], 'sk-dialog-key');
    });
  });
}

class _FakeHarnessProviderRepository implements HarnessProviderRepository {
  static const anthropicKey = HarnessProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.disabled,
    hasCredential: false,
  );

  static const openaiOAuth = HarnessProviderInfo(
    id: 'openai',
    displayName: 'OpenAI',
    authMethods: [HarnessAuthMethod.oauth],
    enabled: HarnessProviderEnabled.disabled,
    hasCredential: false,
  );

  /// A provider mid-rotation: two stored keys, the first one active.
  static const anthropicMultiKey = HarnessProviderInfo(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
    enabled: HarnessProviderEnabled.account,
    hasCredential: true,
    credentials: [
      HarnessCredentialSummary(
        credentialId: 'key:aaa111',
        method: HarnessAuthMethod.apiKey,
        isActive: true,
        removable: true,
        label: 'Personal',
      ),
      HarnessCredentialSummary(
        credentialId: 'key:bbb222',
        method: HarnessAuthMethod.apiKey,
        isActive: false,
        removable: true,
        hint: '…wxyz',
      ),
    ],
  );

  /// An OAuth plan provider with one account connected.
  static const kimiCodeSignedIn = HarnessProviderInfo(
    id: 'kimi-code',
    displayName: 'Kimi Code',
    authMethods: [HarnessAuthMethod.oauth],
    enabled: HarnessProviderEnabled.oauth,
    hasCredential: true,
    credentials: [
      HarnessCredentialSummary(
        credentialId: 'oauth:dev@example.com',
        method: HarnessAuthMethod.oauth,
        isActive: true,
        removable: true,
        label: 'dev@example.com',
      ),
    ],
  );

  final savedKeys = <String, String>{};
  final removedCredentialIds = <String>[];

  @override
  Future<List<HarnessProviderInfo>> listProviders() async => const [];

  @override
  Future<List<HarnessModelInfo>> listModels({String? providerId}) async =>
      const [];

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
  }) async {
    if (credentialId != null) {
      removedCredentialIds.add(credentialId);
    }
  }

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
