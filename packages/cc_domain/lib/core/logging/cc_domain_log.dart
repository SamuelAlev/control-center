/// Severity of a [CcDomainLog] record.
enum CcDomainLogLevel {
  /// Informational diagnostic.
  info,

  /// Recoverable problem (a degraded path, a skipped item).
  warning,

  /// Failure — carries the originating error + stack.
  error,
}

/// Sink for a [CcDomainLog] record. The embedding app/server installs one to
/// route domain logs into its own logger; when null, records are dropped.
typedef CcDomainLogSink =
    void Function(
      CcDomainLogLevel level,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// The shared-kernel domain layer's logging seam.
///
/// `cc_domain` is the pure-Dart contract layer imported by every other package
/// (and by Flutter web), so it cannot call the app's `AppLog` (which pulls in
/// Flutter). Domain *services* that need a diagnostic log — event listeners,
/// reconcilers, the pipeline engine — emit through this static façade instead.
/// The desktop wires [sink] into `AppLog`; `cc_server` routes it to
/// stdout/stderr. This completes the one-seam-per-Flutter-free-package pattern
/// (`CcHostLog` / `CcInfraLog` / `CcPersistenceLog` / `CcDomainLog`), each
/// installed at the composition root — so no package depends on another, or on
/// Flutter, merely to log.
///
/// Note: pure domain *entities and value objects* must stay silent (a null
/// return / thrown error is their contract). And where a service already takes
/// explicit `onWarn`/`onError` callbacks (e.g. `TicketWorkflowService`), keep
/// those — this seam is for services that would otherwise reach for `AppLog`.
class CcDomainLog {
  CcDomainLog._();

  /// The installed sink, or null to drop records.
  static CcDomainLogSink? sink;

  /// Logs an informational diagnostic.
  static void info(String message) =>
      sink?.call(CcDomainLogLevel.info, message);

  /// Logs a recoverable problem.
  static void warning(String message) =>
      sink?.call(CcDomainLogLevel.warning, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      sink?.call(CcDomainLogLevel.error, message, error, stackTrace);
}
