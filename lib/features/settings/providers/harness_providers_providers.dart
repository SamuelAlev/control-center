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
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .saveApiKey(providerId: providerId, apiKey: apiKey, baseUrl: baseUrl);
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
}

/// Removes a provider's stored credential, then refreshes the lists. For a
/// custom provider this drops only the key; the provider itself survives.
Future<void> removeHarnessCredential(
  WidgetRef ref, {
  required String providerId,
  String? accountLabel,
}) async {
  await ref
      .read(harnessProviderRepositoryProvider)
      .removeCredential(providerId: providerId, accountLabel: accountLabel);
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
Future<String> addCustomHarnessProvider(
  WidgetRef ref, {
  required String displayName,
  required CustomProviderDialect dialect,
  required String baseUrl,
  String? apiKey,
}) async {
  final id = await ref
      .read(harnessProviderRepositoryProvider)
      .addCustomProvider(
        displayName: displayName,
        dialect: dialect,
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
  ref
    ..invalidate(harnessProvidersProvider)
    ..invalidate(harnessModelsProvider);
  return id;
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
