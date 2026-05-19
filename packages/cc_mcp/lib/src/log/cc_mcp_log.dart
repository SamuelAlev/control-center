/// Severity of a [CcMcpLog] record.
enum CcMcpLogLevel {
  /// Verbose diagnostic (tool entry/exit, resolved arguments).
  debug,

  /// Informational (a tool invocation line).
  info,

  /// Recoverable problem (a tool blocked by a guard or denied).
  warning,

  /// Failure — carries the originating error + stack.
  error,
}

/// Sink for a [CcMcpLog] record. The embedding app installs one to route MCP
/// tool logs into its own logger; when null, records are dropped.
typedef CcMcpLogSink =
    void Function(
      CcMcpLogLevel level,
      String tag,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// The MCP tool surface's logging seam.
///
/// `cc_mcp` is a Flutter-free package (it links into the `dart build cli`
/// server binary alongside `cc_server_core`), so it must not depend on the
/// app's `AppLog` (which drags `kDebugMode`/`debugPrint` from Flutter). The
/// tools + dispatcher log through this static façade instead. It deliberately
/// mirrors `AppLog`'s `(tag, message)` API so relocating the tools was a pure
/// rename, and the embedding app bridges [sink] into `AppLog` at startup (see
/// `installCcMcpLogging`). `cc_server` / tests can leave [sink] null (no-op).
/// Mirrors `CcInfraLog` / `CcHostLog`.
class CcMcpLog {
  CcMcpLog._();

  /// The installed sink, or null to drop records.
  static CcMcpLogSink? sink;

  /// Logs a verbose diagnostic.
  static void d(String tag, String message) =>
      sink?.call(CcMcpLogLevel.debug, tag, message);

  /// Logs an informational record.
  static void i(String tag, String message) =>
      sink?.call(CcMcpLogLevel.info, tag, message);

  /// Logs a recoverable problem.
  static void w(String tag, String message) =>
      sink?.call(CcMcpLogLevel.warning, tag, message);

  /// Logs a failure with its originating [error] and [stackTrace].
  static void e(String tag, String message, [Object? error, StackTrace? st]) =>
      sink?.call(CcMcpLogLevel.error, tag, message, error, st);
}
