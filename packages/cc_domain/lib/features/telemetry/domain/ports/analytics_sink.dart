import 'package:cc_domain/features/telemetry/domain/entities/analytics_envelope.dart';

/// Where sanitized analytics records go: the provider seam.
///
/// One adapter per provider (`UmamiAnalyticsSink` in `cc_analytics`); the
/// rest of the app talks to `Analytics` and never to a sink, so switching
/// providers means writing one adapter and changing the factory that builds
/// it. An implementation owns delivery: queueing, batching, retry and
/// backoff. It must never throw from [record], never block the caller on the
/// network, and drop rather than buffer without bound.
abstract interface class AnalyticsSink {
  /// Queues [envelope] for delivery.
  void record(AnalyticsEnvelope envelope);

  /// Attempts delivery of everything queued. Completes when the attempt
  /// finishes, successfully or not.
  Future<void> flush();

  /// Releases resources; records after [close] are dropped. With [flush]
  /// (the default) queued records get one last delivery attempt first; the
  /// consent switch turning off passes `flush: false`, which discards them.
  Future<void> close({bool flush = true});
}

/// A sink that drops everything.
class NoopAnalyticsSink implements AnalyticsSink {
  /// Creates a [NoopAnalyticsSink].
  const NoopAnalyticsSink();

  @override
  void record(AnalyticsEnvelope envelope) {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> close({bool flush = true}) async {}
}

/// A sink that hands each record to [log] and sends nothing.
///
/// Debug and profile builds use it in place of the provider sink, so a
/// developer can watch the tracking plan fire without polluting production
/// data.
class LoggingAnalyticsSink implements AnalyticsSink {
  /// Creates a [LoggingAnalyticsSink] writing to [log].
  const LoggingAnalyticsSink(this.log);

  /// Receives one line per record.
  final void Function(String line) log;

  @override
  void record(AnalyticsEnvelope envelope) {
    final props = envelope.properties.entries
        .map((e) => '${e.key}=${e.value}')
        .join(' ');
    log(
      '[analytics] ${envelope.kind.name} ${envelope.name}'
      '${envelope.path == null ? '' : ' ${envelope.path}'} $props',
    );
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close({bool flush = true}) async {}
}
