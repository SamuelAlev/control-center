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
}
