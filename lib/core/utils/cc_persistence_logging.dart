import 'package:cc_persistence/cc_persistence.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Bridges the `cc_persistence` layer's logging seam into the app's [AppLog].
///
/// `cc_persistence` is Flutter-free (it links into the `dart build cli` server
/// binary), so its Drift-backed repositories cannot call [AppLog] directly;
/// they log through [CcPersistenceLog]. Call this once at startup (desktop
/// `main`) so persistence diagnostics land in the same place as app logs, under
/// the `Persistence` tag. The headless `cc_server` wires its own stdout sink.
void installCcPersistenceLogging() {
  CcPersistenceLog.sink = (level, message, [error, stackTrace]) {
    switch (level) {
      case CcPersistenceLogLevel.info:
        AppLog.i('Persistence', message);
      case CcPersistenceLogLevel.warning:
        AppLog.w('Persistence', message);
      case CcPersistenceLogLevel.error:
        AppLog.e('Persistence', message, error, stackTrace);
    }
  };
}
