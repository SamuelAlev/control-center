import 'package:cc_infra/cc_infra_log.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';

/// Bridges the `cc_infra` layer's logging seam into the app's [AppLog].
///
/// `cc_infra` is a Flutter-free package (it links into the `dart build cli`
/// server binary), so it cannot call [AppLog] — which depends on
/// `kDebugMode`/`debugPrint` — directly. It logs through [CcInfraLog] instead.
/// Call once at desktop startup to route infrastructure diagnostics into the
/// `Infra` app log. [CcInfraLog.level] follows [kDebugMode]; [AppLog] also applies
/// the user's configured log-level filter.
void installCcInfraLogging() {
  CcInfraLog.level = kDebugMode ? CcInfraLogLevel.debug : CcInfraLogLevel.info;
  CcInfraLog.sink = (level, message, [error, stackTrace]) {
    switch (level) {
      case CcInfraLogLevel.debug:
        AppLog.d('Infra', message);
      case CcInfraLogLevel.info:
        AppLog.i('Infra', message);
      case CcInfraLogLevel.warning:
        AppLog.w('Infra', message);
      case CcInfraLogLevel.error:
        AppLog.e('Infra', message, error, stackTrace);
    }
  };
}
