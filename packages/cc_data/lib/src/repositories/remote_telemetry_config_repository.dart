import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [TelemetryConfigRepository] over the RPC client.
///
/// Every client reads the install's telemetry decision here and gates its
/// analytics on it; the server is the only place the decision lives. Writes
/// are refused by the server for anyone but its operator.
class RemoteTelemetryConfigRepository implements TelemetryConfigRepository {
  /// Creates a [RemoteTelemetryConfigRepository] over [_client].
  RemoteTelemetryConfigRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<TelemetryConfig> get() async =>
      TelemetryConfig.fromWire(await _client.call('telemetry.config', {}));

  @override
  Stream<TelemetryConfig> watch() => _client
      .subscribe('telemetry.watch', {})
      .map(TelemetryConfig.fromWire)
      .distinct();

  @override
  Future<void> setUsageAnalyticsEnabled({required bool enabled}) =>
      _client.call('telemetry.setUsageAnalytics', {'enabled': enabled});
}
