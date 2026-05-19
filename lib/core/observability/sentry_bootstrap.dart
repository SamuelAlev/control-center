import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry DSN for the Control Center project.
const String _sentryDsn =
    'https://099ea742dcbae8ef6c31cad7a89b3a53@o4510620405530624.ingest.de.sentry.io/4511531427561552';

/// Initializes Sentry crash/performance reporting and runs the app returned by
/// [appBuilder] inside a [SentryWidget].
///
/// Both the main window and the focus-pill sub-window route their bootstrap
/// through here so the Sentry configuration lives in exactly one place.
Future<void> runAppWithSentry(Widget Function() appBuilder) {
  return SentryFlutter.init(
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
    appRunner: () => runApp(SentryWidget(child: appBuilder())),
  );
}
