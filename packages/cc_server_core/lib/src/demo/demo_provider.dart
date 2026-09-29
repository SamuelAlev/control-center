import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';

/// The model id a demo run reports.
///
/// It is deliberately a REAL catalogue id: `DispatchSession` prices every turn
/// through the same `HarnessCostCalculator` a live run uses, so a model the
/// models.dev catalogue does not know would silently price every demo run at
/// zero and make the cost, budget and observability surfaces read as broken.
const String kDemoModelId = 'claude-sonnet-4-5';

/// The provider id a demo run reports.
const String kDemoProviderId = 'anthropic';

/// Fictional provider accounts for the demo's settings and agent model picker.
///
/// Claude (Anthropic API keys), GLM (the z.ai coding plan) and Kimi Code each
/// have two logins, so the account rows and the rotation control have something
/// to show. The secrets are obvious placeholders: `providers.list` ships only
/// a masked tail, and [DemoInertProvider] throws if anything tries to spend
/// one. A provider id outside this set and outside the harness catalog still
/// answers [HarnessAuthMethod.none] with no secret, which is what lets a
/// scripted run clear `DispatchSession`'s auth gate (`hasSecret || method ==
/// none`) without a key on the box.
///
/// Writes are accepted and dropped rather than thrown: the credential-touching
/// `providers.*` ops are absent from the demo's op registry, so nothing should
/// reach these — but a background refresher that did must not take the server
/// down over a credential the demo does not have.
class DemoCredentialStore implements ProviderCredentialStore {
  /// Creates the store.
  const DemoCredentialStore();

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async {
    final accounts = kDemoProviderAccounts[providerId];
    if (accounts != null && accounts.isNotEmpty) {
      for (final account in accounts) {
        if (account.isActive) {
          return account;
        }
      }
      return accounts.first;
    }
    if (harnessProviderMetas.containsKey(providerId)) {
      return null;
    }
    return ProviderCredential(
      providerId: providerId,
      method: HarnessAuthMethod.none,
    );
  }

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async {
    final accounts = kDemoProviderAccounts[providerId];
    if (accounts != null) {
      return accounts;
    }
    if (harnessProviderMetas.containsKey(providerId)) {
      return const [];
    }
    return [
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
      ),
    ];
  }

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// Two fictional logins per provider the demo pretends is connected.
///
/// Keys and tokens all contain `not-a-real` so a hint that leaked further than
/// the masked tail would still be obviously inert.
const Map<String, List<ProviderCredential>> kDemoProviderAccounts = {
  'anthropic': [
    ProviderCredential(
      providerId: 'anthropic',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'demo-not-a-real-key-maya',
      accountLabel: 'Maya Okonkwo',
    ),
    ProviderCredential(
      providerId: 'anthropic',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'demo-not-a-real-key-dieg',
      accountLabel: 'Diego Ferrer',
      isActive: false,
    ),
  ],
  'zai-coding': [
    ProviderCredential(
      providerId: 'zai-coding',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'demo-not-a-real-key-glm1',
      accountLabel: 'Maya Okonkwo',
    ),
    ProviderCredential(
      providerId: 'zai-coding',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'demo-not-a-real-key-glm2',
      accountLabel: 'Priya Raman',
      isActive: false,
    ),
  ],
  'kimi-code': [
    ProviderCredential(
      providerId: 'kimi-code',
      method: HarnessAuthMethod.oauth,
      accessToken: 'demo-not-a-real-token-kim1',
      email: 'diego.ferrer@helix.example',
      accountLabel: 'Diego Ferrer',
      accountId: 'demo-kimi-diego',
    ),
    ProviderCredential(
      providerId: 'kimi-code',
      method: HarnessAuthMethod.oauth,
      accessToken: 'demo-not-a-real-token-kim2',
      email: 'priya.raman@helix.example',
      accountLabel: 'Priya Raman',
      accountId: 'demo-kimi-priya',
      isActive: false,
    ),
  ],
};

/// The bare model id a scripted run reports when the caller did not name one.
String demoDefaultModel(String providerId) => switch (providerId) {
  'zai' || 'zai-coding' => 'glm-5.3',
  'kimi-code' => 'kimi-for-coding',
  'moonshotai' => 'kimi-k3',
  _ => kDemoModelId,
};

/// Builds the demo's inert provider for every provider id.
///
/// `ScriptedAgentLoop` never calls the provider, but `DispatchSession` still
/// CONSTRUCTS one on the dispatch path (`_buildHarnessProvider`) before the
/// loop runs, and reads `defaultModel` off it to price usage. So the demo needs
/// a provider object that answers those questions and refuses to do anything
/// else.
class DemoHarnessProviderFactory extends HarnessProviderFactory {
  /// Creates the factory.
  const DemoHarnessProviderFactory();

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => DemoInertProvider(
    providerId: providerId,
    model: model ?? demoDefaultModel(providerId),
  );
}

/// A provider that answers metadata and throws on any attempt to complete.
///
/// Throwing is the point. The demo's guarantee is that a public server makes no
/// outbound model call; if a wiring regression ever routed a real run here, a
/// thrown error surfaces as a failed run in the transcript instead of a silent
/// egress from a box on the internet.
class DemoInertProvider implements LlmProviderPort {
  /// Creates the inert provider.
  const DemoInertProvider({
    this.providerId = kDemoProviderId,
    this.model = kDemoModelId,
  });

  /// Which catalog [listModels] answers from.
  final String providerId;

  /// The model id reported to the cost calculator.
  final String model;

  @override
  String get displayName => 'Demo (scripted)';

  @override
  String get defaultModel => model;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) => throw StateError(
    'The demo server must never call a model. A scripted AgentLoop should have '
    'replaced the loop entirely — reaching the provider means the demo wiring '
    'regressed.',
  );

  /// Static catalogs for the providers [kDemoProviderAccounts] connects.
  ///
  /// Empty for everyone else: `providers.listModels` skips a provider with no
  /// credential, and a connected provider with no rows would make the picker
  /// look broken. Ids match what the live harness factory would ask those
  /// hosts for. Nothing here is ever completed against.
  @override
  Future<List<ProviderModel>> listModels() async =>
      kDemoProviderModels[providerId] ?? const [];
}

/// Display metadata for the demo's connected providers, keyed by provider id.
const Map<String, List<ProviderModel>> kDemoProviderModels = {
  'anthropic': [
    ProviderModel(
      id: kDemoModelId,
      displayName: 'Claude Sonnet 4.5',
      inputCostPerMTokens: 3.0,
      outputCostPerMTokens: 15.0,
      contextWindow: 200000,
    ),
    ProviderModel(
      id: 'claude-opus-4-6',
      displayName: 'Claude Opus 4.6',
      inputCostPerMTokens: 5.0,
      outputCostPerMTokens: 25.0,
      contextWindow: 200000,
    ),
    ProviderModel(
      id: 'claude-haiku-4-5',
      displayName: 'Claude Haiku 4.5',
      inputCostPerMTokens: 1.0,
      outputCostPerMTokens: 5.0,
      contextWindow: 200000,
    ),
  ],
  'zai-coding': [
    ProviderModel(id: 'glm-5.3', displayName: 'GLM 5.3', contextWindow: 200000),
    ProviderModel(
      id: 'glm-5.3-flash',
      displayName: 'GLM 5.3 Flash',
      contextWindow: 200000,
    ),
  ],
  'kimi-code': [
    ProviderModel(
      id: 'kimi-for-coding',
      displayName: 'Kimi for Coding',
      contextWindow: 262144,
    ),
    ProviderModel(id: 'k3', displayName: 'Kimi K3', contextWindow: 262144),
  ],
};
