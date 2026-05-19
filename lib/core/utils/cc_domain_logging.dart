import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:control_center/core/utils/app_log.dart';

/// Bridges the `cc_domain` layer's logging seam into the app's [AppLog].
///
/// `cc_domain` is the pure-Dart shared kernel (imported by Flutter web too), so
/// its domain services cannot call [AppLog] directly; they log through
/// [CcDomainLog]. Call this once at startup (desktop `main`) so domain
/// diagnostics land in the same place as app logs, under the `Domain` tag. The
/// headless `cc_server` wires its own stdout sink.
void installCcDomainLogging() {
  CcDomainLog.sink = (level, message, [error, stackTrace]) {
    switch (level) {
      case CcDomainLogLevel.info:
        AppLog.i('Domain', message);
      case CcDomainLogLevel.warning:
        AppLog.w('Domain', message);
      case CcDomainLogLevel.error:
        AppLog.e('Domain', message, error, stackTrace);
    }
  };
}
