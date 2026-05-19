/// Severity of a [CcPersistenceLog] record.
enum CcPersistenceLogLevel {
  /// Informational diagnostic.
  info,

  /// Recoverable problem (a query that fell back, a degraded aggregation).
  warning,

  /// Failure — carries the originating error + stack.
  error,
}

/// Sink for a [CcPersistenceLog] record. The embedding app/server installs one
/// to route persistence logs into its own logger; when null, records are
/// dropped.
typedef CcPersistenceLogSink =
    void Function(
      CcPersistenceLogLevel level,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// The persistence layer's logging seam.
///
/// `cc_persistence` must not depend on the app's `AppLog` (that would drag
/// Flutter into a package that links into the Flutter-free `dart build cli`
/// server binary), so its Drift-backed repositories log through this static
/// façade. The desktop wires [sink] into `AppLog`; `cc_server` routes it to
/// stdout/stderr. Mirrors `CcHostLog` / `CcInfraLog` and the "inject the
/// platform detail at the composition root" rule the codebase follows for ports.
class CcPersistenceLog {
  CcPersistenceLog._();

  /// The installed sink, or null to drop records.
  static CcPersistenceLogSink? sink;

  /// Logs an informational diagnostic.
  static void info(String message) =>
      sink?.call(CcPersistenceLogLevel.info, message);

  /// Logs a recoverable problem.
  static void warning(String message) =>
      sink?.call(CcPersistenceLogLevel.warning, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      sink?.call(CcPersistenceLogLevel.error, message, error, stackTrace);
}
