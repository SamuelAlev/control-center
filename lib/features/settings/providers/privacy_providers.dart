import 'package:control_center/di/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Whether crash/error diagnostics are sent to the error-reporting service.
///
/// Backed by `PrivacyPreferences`; shared by the onboarding diagnostics consent
/// and the Settings → Privacy toggle so both stay in sync.
final errorReportingEnabledProvider =
    NotifierProvider<ErrorReportingNotifier, bool>(ErrorReportingNotifier.new);

/// Notifier for [errorReportingEnabledProvider].
class ErrorReportingNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(privacyPreferencesProvider).errorReportingEnabled;

  /// Persists the preference and, when opting out at runtime in a release
  /// build, closes the live Sentry client so no further events are sent this
  /// session. Re-enabling takes full effect on the next launch, because Sentry
  /// is wired during startup (`runAppWithSentry`). The guard ensures debug and
  /// profile builds — where Sentry is never initialized — never touch the SDK.
  Future<void> setEnabled({required bool value}) async {
    await ref
        .read(privacyPreferencesProvider)
        .setErrorReportingEnabled(value: value);
    state = value;
    if (kReleaseMode && !value) {
      try {
        await Sentry.close();
      } on Object catch (_) {}
    }
  }
}
