import 'package:control_center/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry DSN for the Control Center project.
const String _sentryDsn =
    'https://099ea742dcbae8ef6c31cad7a89b3a53@o4510620405530624.ingest.de.sentry.io/4511531427561552';

/// Whether crash reporting is active this run (release build + user opted in).
///
/// The native multi-window root is a `ViewCollection`, which has no single
/// [View] ancestor for [SentryWidget] to instrument — so the widget wrapping
/// moved down into `PrimaryWindow`, which reads this flag to decide whether to
/// wrap its content. `SentryFlutter.init` (zone + error handlers) still runs
/// app-wide regardless.
bool sentryReportingActive = false;

/// Initializes Sentry crash/performance reporting and runs the multi-window
/// [root] via `runWidget`.
///
/// Sentry is only wired up for production (release) builds *and* only when the
/// user has not opted out. Debug and profile builds skip initialization
/// entirely (so local development and profiling never report), and so does a
/// release build where the user disabled diagnostics in onboarding or
/// Settings → Privacy ([errorReportingEnabledKey]). In any skipped case the app
/// is run directly, with no Sentry instrumentation.
Future<void> runAppWithSentry(Widget Function() root) async {
  sentryReportingActive = kReleaseMode && _errorReportingEnabled();
  if (!sentryReportingActive) {
    runWidget(root());
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runWidget(root()),
  );
}

/// Reads the user's error-reporting opt-out from app preferences.
///
/// Defaults to `true` (enabled) when the preference is unset or unreadable, so
/// a transient storage failure never silently disables crash reporting. Only an
/// explicit `false` (the bool encoding the storage facade writes) disables it.
bool _errorReportingEnabled() {
  final prefs = Preferences();
  try {
    return prefs.get(errorReportingEnabledKey, 'true') != 'false';
  } on Object catch (_) {
    return true;
  } finally {
    prefs.dispose();
  }
}
