import 'package:cc_domain/features/telemetry/domain/entities/telemetry_config.dart';

/// Read/write access to the install's [TelemetryConfig].
///
/// Reads are open to every authenticated session: each client must know
/// whether it may collect. Writes are operator-only; the transport enforces
/// that with `ServerAuthority.serverOwner`.
abstract interface class TelemetryConfigRepository {
  /// The current configuration.
  Future<TelemetryConfig> get();

  /// The configuration, then every change to it.
  Stream<TelemetryConfig> watch();

  /// Turns install-wide usage analytics on or off.
  Future<void> setUsageAnalyticsEnabled({required bool enabled});
}
