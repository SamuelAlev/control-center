import 'package:control_center/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed store for privacy-related preferences.
class PrivacyPreferences {
  /// Creates a [PrivacyPreferences].
  const PrivacyPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _diffSharingKey = 'privacy_llm_diff_sharing_enabled';

  /// Whether diff content may be sent to the configured LLM adapter.
  ///
  /// When `false`, agents operating in review mode must not include raw diff
  /// content in prompts — they may only use structured metadata (file paths,
  /// line numbers, PR description).
  bool get llmDiffSharingEnabled => _prefs.getBool(_diffSharingKey) ?? true;

  /// Updates the LLM diff-sharing preference.
  Future<void> setLlmDiffSharingEnabled({required bool value}) =>
      _prefs.setBool(_diffSharingKey, value);

  /// Whether crash/error diagnostics are sent to the error-reporting service.
  ///
  /// Defaults to `true`. The key is shared with `runAppWithSentry`
  /// (core/observability/sentry_bootstrap), which reads it at startup to decide
  /// whether to initialize Sentry. Diagnostics are only ever sent in release
  /// builds; this preference lets the user opt out of even that.
  bool get errorReportingEnabled =>
      _prefs.getBool(errorReportingEnabledKey) ?? true;

  /// Updates the error-reporting preference.
  ///
  /// Takes full effect on the next launch (Sentry is wired during startup);
  /// disabling at runtime is additionally enforced by the caller closing the
  /// live Sentry client.
  Future<void> setErrorReportingEnabled({required bool value}) =>
      _prefs.setBool(errorReportingEnabledKey, value);
}
