import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads live subscription-usage quotas (Claude Code, OpenAI Codex, z.ai GLM
/// Coding Plan) over the RPC client — the data behind the title-bar usage pill.
///
/// The host fetches each provider's usage **server-side** (where the CLIs and
/// their credentials live) via the `subscriptions.usage` op. The z.ai key is
/// resolved server-side too, from the harness provider credential store
/// (Settings → Adapters → Providers & models) — nothing secret crosses here.
class RpcSubscriptionsRepository {
  /// Creates an [RpcSubscriptionsRepository] over [_client].
  RpcSubscriptionsRepository(this._client);

  final RemoteRpcClient _client;

  /// Fetches usage for every provider.
  Future<List<SubscriptionUsage>> fetchUsage() async {
    final data = await _client.call('subscriptions.usage', const {});
    final providers = data['providers'];
    if (providers is! List) {
      return const [];
    }
    return [
      for (final p in providers)
        if (p is Map) SubscriptionUsage.fromJson(p.cast<String, dynamic>()),
    ];
  }
}
