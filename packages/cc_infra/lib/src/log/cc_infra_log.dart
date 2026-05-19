/// Severity of a [CcInfraLog] record.
enum CcInfraLogLevel {
  /// Informational diagnostic (a request/response line, a resolved binary).
  info,

  /// Recoverable problem (a retried request, an auth/forbidden response).
  warning,

  /// Failure — carries the originating error + stack.
  error,
}

/// Sink for a [CcInfraLog] record. The embedding app installs one to route
/// infra logs into its own logger; when null, records are dropped.
typedef CcInfraLogSink =
    void Function(
      CcInfraLogLevel level,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// The infra layer's logging seam.
///
/// `cc_infra` must not depend on the app's `AppLog` (that would drag Flutter —
/// `kDebugMode` / `debugPrint` — into a package that links into the Flutter-free
/// `dart build cli` server binary), so its adapters log through this static
/// façade. The embedding app wires [sink] (and [verbose]) once at startup to
/// forward into its logger; `cc_server` / tests can leave it null (no-op).
/// Mirrors `CcHostLog` in `cc_host` and the "inject the platform detail at the
/// composition root" rule the rest of the codebase follows for ports.
class CcInfraLog {
  CcInfraLog._();

  /// The installed sink, or null to drop records.
  static CcInfraLogSink? sink;

  /// When true, infra adapters emit verbose diagnostics — specifically the dio
  /// network client's per-request/response logging (with truncated bodies).
  /// The embedding app sets this from `kDebugMode`; errors are logged in every
  /// build regardless. Defaults to false so a release/server build is quiet.
  static bool verbose = false;

  /// Logs an informational diagnostic.
  static void info(String message) => sink?.call(CcInfraLogLevel.info, message);

  /// Logs a recoverable problem.
  static void warning(String message) =>
      sink?.call(CcInfraLogLevel.warning, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      sink?.call(CcInfraLogLevel.error, message, error, stackTrace);
}
