import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client access to the server-owned built-in-harness provider brain (PRD 13),
/// over RPC on both desktop and web — the host owns credentials, OAuth flows,
/// and the live model list.
final harnessProviderRepositoryProvider = Provider<HarnessProviderRepository>(
  (ref) => RpcHarnessProviderRepository(ref.watch(rpcClientProvider)),
);

/// Every harness-supported provider with its live connection state.
final harnessProvidersProvider = FutureProvider<List<HarnessProviderInfo>>(
  (ref) => ref.watch(harnessProviderRepositoryProvider).listProviders(),
);

/// The providers holding more than one credential, and so the only ones a
/// rotation pool has anything to choose between.
final rotatableHarnessProvidersProvider = Provider<List<HarnessProviderInfo>>((
  ref,
) {
  final providers = ref.watch(harnessProvidersProvider).asData?.value;
  return [
    for (final p in providers ?? const <HarnessProviderInfo>[])
      if (p.credentials.length > 1) p,
  ];
});

/// Selectable models served live by the logged-in providers (qualified
/// `provider/model` ids). Empty until at least one provider is connected.
final harnessModelsProvider = FutureProvider<List<HarnessModelInfo>>(
  (ref) => ref.watch(harnessProviderRepositoryProvider).listModels(),
);

/// Saves an API key (or a local base-URL) for a provider, then refreshes the
/// provider + model lists.
Future<void> saveHarnessApiKey(
  WidgetRef ref, {
  required String providerId,
  required String apiKey,
  String? baseUrl,
  String? accountLabel,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .saveApiKey(
        providerId: providerId,
        apiKey: apiKey,
        baseUrl: baseUrl,
        accountLabel: accountLabel,
      );
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
}

/// Removes a provider's stored credential, then refreshes the lists. For a
/// custom provider this drops only the key; the provider itself survives.
/// [credentialId] removes one credential of a multi-key/account rotation;
/// without it (and without [accountLabel]) every credential is removed.
Future<void> removeHarnessCredential(
  WidgetRef ref, {
  required String providerId,
  String? accountLabel,
  String? credentialId,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .removeCredential(
        providerId: providerId,
        accountLabel: accountLabel,
        credentialId: credentialId,
      );
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
}

/// Saves a provider's sampling recipe and output ceiling, then refreshes the
/// lists. A null field clears it back to the endpoint's own default.
Future<void> saveHarnessGenerationDefaults(
  WidgetRef ref, {
  required String providerId,
  int? maxTokens,
  double? temperature,
  double? topP,
  int? topK,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .saveGenerationDefaults(
        providerId: providerId,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
  ref.invalidate(harnessProvidersProvider);
}

/// Registers a custom provider (an OpenAI- or Anthropic-compatible endpoint,
/// optionally authenticated), then refreshes the lists. Returns its id.
/// [models] pre-registers models for endpoints that cannot enumerate their own.
Future<String> addCustomHarnessProvider(
  WidgetRef ref, {
  required String displayName,
  required CustomProviderDialect dialect,
  required String baseUrl,
  String? apiKey,
  Map<String, ProviderModelOverride>? models,
}) async {
  final id = await ref
      .read(harnessProviderRepositoryProvider)
      .addCustomProvider(
        displayName: displayName,
        dialect: dialect,
        baseUrl: baseUrl,
        apiKey: apiKey,
        models: models,
      );
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
  return id;
}

/// Saves a per-model metadata override (context window, output ceiling,
/// modalities) — or registers a hand-added model when the override is
/// [ProviderModelOverride.manual] — then refreshes the model lists.
Future<void> saveHarnessModelOverride(
  WidgetRef ref, {
  required String providerId,
  required String modelId,
  required ProviderModelOverride override,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .saveModelOverride(
        providerId: providerId,
        modelId: modelId,
        override: override,
      );
  ref.invalidate(harnessModelsProvider);
}

/// Clears a model's stored override, then refreshes the model lists. For a
/// hand-registered (manual) model this removes it from the list.
Future<void> removeHarnessModelOverride(
  WidgetRef ref, {
  required String providerId,
  required String modelId,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .removeModelOverride(providerId: providerId, modelId: modelId);
  ref.invalidate(harnessModelsProvider);
}

/// Deletes a custom provider (definition + any stored key), then refreshes.
Future<void> removeCustomHarnessProvider(
  WidgetRef ref,
  String providerId,
) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .removeCustomProvider(providerId);
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
}

/// Starts a browser OAuth login for a provider (the caller opens the returned
/// URL and polls [pollHarnessOAuth]).
Future<HarnessOAuthStart> startHarnessOAuth(WidgetRef ref, String providerId) =>
    ref.read(harnessProviderRepositoryProvider).startOAuth(providerId);

/// Polls the state of an in-progress OAuth login.
Future<HarnessOAuthStatus> pollHarnessOAuth(WidgetRef ref, String flowId) =>
    ref.read(harnessProviderRepositoryProvider).oauthStatus(flowId);

/// Completes an OAuth login with a manually-pasted code (web / remote path).
Future<void> completeHarnessOAuth(
  WidgetRef ref, {
  required String flowId,
  required String code,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .completeOAuth(flowId: flowId, code: code);
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
}

/// Cancels an in-progress OAuth login.
Future<void> cancelHarnessOAuth(WidgetRef ref, String flowId) =>
    ref.read(harnessProviderRepositoryProvider).cancelOAuth(flowId);
