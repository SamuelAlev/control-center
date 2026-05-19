import 'package:cc_host/cc_host.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Bridges the `cc_host` kernel's logging seam into the app's [AppLog].
///
/// `cc_host` is a pure-Dart package that knows nothing of [AppLog]; it logs
/// through [CcHostLog]. Call this once at startup (desktop `main` and the
/// `cc-server` entrypoint) so host logs land in the same place as app logs,
/// under the `RemoteControl` tag.
void installCcHostLogging() {
  CcHostLog.sink = (level, message, [error, stackTrace]) {
    switch (level) {
      case CcHostLogLevel.info:
        AppLog.i('RemoteControl', message);
      case CcHostLogLevel.warning:
        AppLog.w('RemoteControl', message);
      case CcHostLogLevel.error:
        AppLog.e('RemoteControl', message, error, stackTrace);
    }
  };
}
