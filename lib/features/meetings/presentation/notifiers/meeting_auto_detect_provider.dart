// Web-safe meeting auto-detect preference.
//
// Whether automatic meeting detection is enabled is a plain persisted boolean
// (shared_preferences) — web-safe — so it lives in its own file, away from the
// desktop-only `MeetingDetectionController` (which drives native audio capture).
// The settings screen reads only this toggle, so it no longer needs to import
// the recorder/detection controllers.
library;

import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether automatic meeting detection is enabled (persisted, default on).
class MeetingAutoDetectEnabledNotifier extends Notifier<bool> {
  late AppPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getBool(meetingAutoDetectKey) ?? true;
  }

  /// Enables or disables detection and persists the choice.
  // ignore: avoid_positional_boolean_parameters
  void setEnabled(bool value) {
    _prefs.setBool(meetingAutoDetectKey, value);
    state = value;
  }
}

/// Whether automatic meeting detection is enabled.
final meetingAutoDetectEnabledProvider =
    NotifierProvider<MeetingAutoDetectEnabledNotifier, bool>(
  MeetingAutoDetectEnabledNotifier.new,
);
