import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads the aggregated usage/cost summary over the RPC client (PRD 05,
/// feature #12) — the data behind the usage dashboard. The host computes the
/// summary from its run-cost history via `UsageTracker`; this maps the
/// [CostSummaryDto] wire shape back to a [CostSummary].
class RpcUsageRepository {
  /// Creates an [RpcUsageRepository] over [_client].
  RpcUsageRepository(this._client);

  final RemoteRpcClient _client;

  /// Spend over the last [windowDays] days for the bound workspace.
  Future<CostSummary> costSummary({int windowDays = 7}) async {
    final data = await _client.call('usage.costSummary', {
      'window_days': windowDays,
    });
    final dto = CostSummaryDto.fromJson(data);
    return CostSummary(
      totalUsd: dto.totalUsd,
      requestCount: dto.requestCount,
      windowStart: dto.windowStart == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.parse(dto.windowStart!),
      byProvider: dto.byProvider,
      byModel: dto.byModel,
      nextResetAt: dto.nextResetAt == null
          ? null
          : DateTime.parse(dto.nextResetAt!),
    );
  }
}
