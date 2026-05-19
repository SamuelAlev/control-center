/// Severity of a [CcInfraLog] record.
enum CcInfraLogLevel {
  /// Detailed trace (a dio request/response line, a no-op index sweep).
  debug,

  /// Informational diagnostic (a resolved binary, a lifecycle event).
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
/// façade. The embedding app wires [sink] (and [level]) once at startup to
/// forward into its logger; `cc_server` sets both from `--log-level` /
/// `CC_SERVER_LOG_LEVEL`, tests can leave them alone (no-op).
/// Mirrors `CcHostLog` in `cc_host` and the "inject the platform detail at the
/// composition root" rule the rest of the codebase follows for ports.
class CcInfraLog {
  CcInfraLog._();

  /// The installed sink, or null to drop records.
  static CcInfraLogSink? sink;

  /// The minimum level emitted. Records below it are suppressed — the
  /// debug-tier call sites (the dio network client's per-request/response
  /// logging) check [isEnabled] before doing any formatting work. Defaults to
  /// [CcInfraLogLevel.info] so a release/server build is quiet about traces.
  static CcInfraLogLevel level = CcInfraLogLevel.info;

  /// Returns `true` when [messageLevel] is loud enough to be emitted.
  static bool isEnabled(CcInfraLogLevel messageLevel) =>
      messageLevel.index >= level.index;

  /// Logs a detailed trace. Gated on [level] — check [isEnabled] first when
  /// building the message is non-trivial.
  static void debug(String message) {
    if (isEnabled(CcInfraLogLevel.debug)) {
      sink?.call(CcInfraLogLevel.debug, message);
    }
  }

  /// Logs an informational diagnostic.
  static void info(String message) => sink?.call(CcInfraLogLevel.info, message);

  /// Logs a recoverable problem.
  static void warning(String message) =>
      sink?.call(CcInfraLogLevel.warning, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      sink?.call(CcInfraLogLevel.error, message, error, stackTrace);
}
