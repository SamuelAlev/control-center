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

/// Satisfies the harness credential gate without holding a secret.
///
/// `DispatchSession` aborts a run with exit 127 unless
/// `hasSecret || method == HarnessAuthMethod.none`. Returning a
/// [HarnessAuthMethod.none] credential takes the second branch, so a demo run
/// reaches the loop with no key on the box and nothing to leak.
///
/// Writes are accepted and dropped rather than thrown: the `credentials.*` and
/// `providers.*` ops are absent from the demo's op registry, so nothing should
/// reach these — but a background refresher that did must not take the server
/// down over a credential the demo does not have.
class DemoCredentialStore implements ProviderCredentialStore {
  /// Creates the store.
  const DemoCredentialStore();

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(providerId: providerId, method: HarnessAuthMethod.none);

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

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
  }) => DemoInertProvider(model: model ?? kDemoModelId);
}

/// A provider that answers metadata and throws on any attempt to complete.
///
/// Throwing is the point. The demo's guarantee is that a public server makes no
/// outbound model call; if a wiring regression ever routed a real run here, a
/// thrown error surfaces as a failed run in the transcript instead of a silent
/// egress from a box on the internet.
class DemoInertProvider implements LlmProviderPort {
  /// Creates the inert provider.
  const DemoInertProvider({this.model = kDemoModelId});

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

  /// Always empty is the WRONG answer for `providers.listModels`: the demo
  /// profile admits that op by name (a read answered from static data), and
  /// the client's model picker renders it. Returning nothing made Settings →
  /// Model providers read as broken on a demo whose whole job is to look
  /// alive. These are catalogue-accurate entries for the one provider a demo
  /// reports (`anthropic`, [kDemoProviderId]) — display metadata only, since
  /// nothing ever completes against them.
  @override
  Future<List<ProviderModel>> listModels() async => const [
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
  ];
}
