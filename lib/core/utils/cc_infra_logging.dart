import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';

/// Bridges the `cc_infra` layer's logging seam into the app's [AppLog].
///
/// `cc_infra` is a Flutter-free package (it links into the `dart build cli`
/// server binary), so it cannot call [AppLog] — which depends on
/// `kDebugMode`/`debugPrint` — directly. It logs through [CcInfraLog] instead.
/// Call this once at startup (desktop `main`) so the dio network clients'
/// request/response and error diagnostics land in the same place as app logs,
/// under the `Infra` tag. [CcInfraLog.verbose] is seeded from [kDebugMode] so
/// verbose per-request logging is on in debug and off in release — matching the
/// `kDebugMode` gate the network logger used before the exodus.
void installCcInfraLogging() {
  CcInfraLog.verbose = kDebugMode;
  CcInfraLog.sink = (level, message, [error, stackTrace]) {
    switch (level) {
      case CcInfraLogLevel.info:
        AppLog.i('Infra', message);
      case CcInfraLogLevel.warning:
        AppLog.w('Infra', message);
      case CcInfraLogLevel.error:
        AppLog.e('Infra', message, error, stackTrace);
    }
  };
}
