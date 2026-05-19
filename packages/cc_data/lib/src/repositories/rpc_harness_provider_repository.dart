import 'package:cc_domain/features/settings/domain/repositories/harness_provider_repository.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [HarnessProviderRepository] backed by the RPC client — the thin-client data
/// path for built-in-harness provider/credential management.
///
/// Mirrors the host's `providers.*` ops. The server owns all state (credentials,
/// OAuth flows, token refresh); this just forwards calls and maps the wire maps
/// to domain DTOs.
class RpcHarnessProviderRepository implements HarnessProviderRepository {
  /// Creates an [RpcHarnessProviderRepository] over [_client].
  RpcHarnessProviderRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<HarnessProviderInfo>> listProviders() async {
    final data = await _client.call('providers.list', const {});
    return ((data['providers'] as List?) ?? const [])
        .whereType<Map>()
        .map((p) => HarnessProviderInfo.fromJson(p.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<HarnessModelInfo>> listModels({String? providerId}) async {
    final data = await _client.call('providers.listModels', {
      'provider_id': ?providerId,
    });
    return ((data['models'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => HarnessModelInfo.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> saveApiKey({
    required String providerId,
    required String apiKey,
    String? baseUrl,
    String? accountLabel,
  }) => _client.call('providers.saveApiKey', {
    'provider_id': providerId,
    'api_key': apiKey,
    'base_url': ?baseUrl,
    'account_label': ?accountLabel,
  });

  @override
  Future<void> removeCredential({
    required String providerId,
    String? accountLabel,
    String? credentialId,
  }) => _client.call('providers.removeCredential', {
    'provider_id': providerId,
    'account_label': ?accountLabel,
    'credential_id': ?credentialId,
  });

  @override
  Future<String> addCustomProvider({
    required String displayName,
    required CustomProviderDialect dialect,
    required String baseUrl,
    String? apiKey,
  }) async {
    final data = await _client.call('providers.addCustom', {
      'display_name': displayName,
      'dialect': dialect.wire,
      'base_url': baseUrl,
      if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
    });
    return data['id'] as String? ?? '';
  }

  @override
  Future<void> removeCustomProvider(String providerId) =>
      _client.call('providers.removeCustom', {'provider_id': providerId});

  @override
  Future<void> saveGenerationDefaults({
    required String providerId,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
  }) =>
      // Omitted keys clear the corresponding field server-side, which is what
      // "let the endpoint decide" means on the wire.
      _client.call('providers.saveGenerationDefaults', {
        'provider_id': providerId,
        'max_tokens': ?maxTokens,
        'temperature': ?temperature,
        'top_p': ?topP,
        'top_k': ?topK,
      });

  @override
  Future<HarnessOAuthStart> startOAuth(String providerId) async {
    final data = await _client.call('providers.startOAuth', {
      'provider_id': providerId,
    });
    return HarnessOAuthStart.fromJson(data);
  }

  @override
  Future<HarnessOAuthStatus> oauthStatus(String flowId) async {
    final data = await _client.call('providers.oauthStatus', {
      'flow_id': flowId,
    });
    return HarnessOAuthStatus.fromJson(data);
  }

  @override
  Future<void> completeOAuth({required String flowId, required String code}) =>
      _client.call('providers.completeOAuth', {
        'flow_id': flowId,
        'code': code,
      });

  @override
  Future<void> cancelOAuth(String flowId) =>
      _client.call('providers.cancelOAuth', {'flow_id': flowId});
}
