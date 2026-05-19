/// Severity of a [CcHostLog] record.
enum CcHostLogLevel {
  /// Informational lifecycle event (channel open, workspace bound).
  info,

  /// Recoverable problem (dropped frame, denied call, rate limit).
  warning,

  /// Handler/transport failure — carries the originating error + stack.
  error,
}

/// Sink for a [CcHostLog] record. The embedding app installs one to route host
/// logs into its own logger; when null, host logs are dropped.
typedef CcHostLogSink =
    void Function(
      CcHostLogLevel level,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// The host kernel's logging seam.
///
/// `cc_host` must not depend on the app's `AppLog` (that would drag the Flutter
/// app into a pure-Dart server package), so it logs through this static façade.
/// The embedding app wires [sink] once at startup to forward into its logger;
/// `cc_server` / tests can leave it null (no-op) or print. Mirrors the
/// "inject the platform detail at the composition root" rule the rest of the
/// codebase follows for ports.
class CcHostLog {
  CcHostLog._();

  /// The installed sink, or null to drop records.
  static CcHostLogSink? sink;

  /// Logs an informational lifecycle event.
  static void info(String message) => sink?.call(CcHostLogLevel.info, message);

  /// Logs a recoverable problem.
  static void warning(String message) =>
      sink?.call(CcHostLogLevel.warning, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      sink?.call(CcHostLogLevel.error, message, error, stackTrace);
}
