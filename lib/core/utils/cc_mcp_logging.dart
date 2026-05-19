import 'package:cc_mcp/cc_mcp.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Bridges the `cc_mcp` tool surface's logging seam into the app's [AppLog].
///
/// `cc_mcp` is a Flutter-free package (it links into the `dart build cli`
/// server binary alongside `cc_server_core`), so it cannot call [AppLog] —
/// which depends on `kDebugMode`/`debugPrint` — directly. Its tools + dispatcher
/// log through [CcMcpLog] instead, which deliberately mirrors [AppLog]'s
/// `(tag, message)` API. Call this once at startup (desktop `main`) so MCP tool
/// invocations land in the same place as app logs. The headless `cc_server`
/// leaves the sink null (no-op). Mirrors `installCcInfraLogging`.
void installCcMcpLogging() {
  CcMcpLog.sink = (level, tag, message, [error, stackTrace]) {
    switch (level) {
      case CcMcpLogLevel.debug:
        AppLog.d(tag, message);
      case CcMcpLogLevel.info:
        AppLog.i(tag, message);
      case CcMcpLogLevel.warning:
        AppLog.w(tag, message);
      case CcMcpLogLevel.error:
        AppLog.e(tag, message, error, stackTrace);
    }
  };
}
