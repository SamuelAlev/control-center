import 'package:cc_data/src/absent_op.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads live subscription-usage quotas (Claude Code, OpenAI Codex, Cursor,
/// z.ai GLM Coding Plan, Kimi Code) over the RPC client — the data behind the
/// title-bar usage pill.
///
/// The host fetches each provider's usage **server-side** (where the CLIs and
/// their credentials live) via the `subscriptions.usage` op. Cursor / z.ai /
/// Kimi credentials are resolved server-side too, from the harness provider
/// credential store (Settings → Adapters → Providers & models) — nothing
/// secret crosses here.
class RpcSubscriptionsRepository {
  /// Creates an [RpcSubscriptionsRepository] over [_client].
  RpcSubscriptionsRepository(this._client);

  final RemoteRpcClient _client;

  /// Fetches usage for every provider.
  ///
  /// [force] asks the host to skip its usage caches — a manual refresh. The
  /// host still refuses to refetch a reading only seconds old, so a button
  /// clicked repeatedly cannot get the provider endpoints to throttle it.
  Future<List<SubscriptionUsage>> fetchUsage({bool force = false}) async {
    final data = await _client.readOr('subscriptions.usage', {
      if (force) 'force': true,
    }, const {});
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
