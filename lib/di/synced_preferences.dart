import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/settings/synced_preference.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/providers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
import 'package:control_center/features/settings/providers/editor_preferences_provider.dart';
import 'package:control_center/features/vscode_theme/providers/vscode_theme_providers.dart';

/// Preferences that follow the signed-in user across devices.
///
/// Composition root only (names `core/` + feature providers). Do not sync:
/// hardware/paths (`audio_input_device_id`, `selected_ide_id`, font paths —
/// family/source only); pre-RPC reads (`privacy_error_reporting_enabled`,
/// `app_log_level`); per-machine UI (`window_*`, `ui.sidebarCollapsed`,
/// `active_workspace_id`, server dial keys); workspace-shared policy
/// (`workspace_settings`); account facts that must be true
/// (`users.onboarding_finished_at`, not a preference — promotion would seed lies).
List<SyncedPreference> buildSyncedPreferences() => [
  // Appearance.
  SyncedPreference(
    themeModeKey,
    onPulled: (ref) => ref.invalidate(themeModeProvider),
  ),
  SyncedPreference(
    localeKey,
    onPulled: (ref) => ref.invalidate(localeProvider),
  ),
  for (final key in const [
    appFontFamilyKey,
    appFontSourceKey,
    codeFontFamilyKey,
    codeFontSourceKey,
    codeFontLigaturesKey,
  ])
    SyncedPreference(
      key,
      onPulled: (ref) => ref.invalidate(fontSettingsProvider),
    ),

  // Editor.
  SyncedPreference(
    editorAutoSaveKey,
    onPulled: (ref) => ref.invalidate(editorAutoSaveModeProvider),
  ),

  // Voice input. The microphone CHOICE itself is hardware and stays local (see
  // the exclusion list above); these two are plain behavioral booleans — the
  // composer's push-to-talk mode and whether meetings are auto-detected — so
  // they follow the user to every machine with a mic.
  SyncedPreference(
    dictationHoldToTalkKey,
    onPulled: (ref) => ref.invalidate(dictationHoldToTalkProvider),
  ),
  SyncedPreference(
    meetingAutoDetectKey,
    onPulled: (ref) => ref.invalidate(meetingAutoDetectEnabledProvider),
  ),

  // Clipboard boundary decisions are personal security preferences. The
  // temporary ten-minute grants remain process-local and never enter sync.
  SyncedPreference(
    rigClipboardHostToRigAlwaysKey,
    onPulled: (ref) => ref.invalidate(rigClipboardPreferencesProvider),
  ),
  SyncedPreference(
    rigClipboardRigToHostAlwaysKey,
    onPulled: (ref) => ref.invalidate(rigClipboardPreferencesProvider),
  ),
  // An imported VS Code colour theme is the largest legitimate payload here
  // (50-200 KB), so it carries a raised ceiling rather than the default.
  SyncedPreference(
    vscodeEditorThemeKey,
    onPulled: (ref) => ref.invalidate(vscodeEditorThemeProvider),
    maxBytes: 384 * 1024,
  ),

  // Notifications. `SharedPreferencesNotificationPreferences` reads through to
  // the store on every call, so only the service's cached view needs
  // refreshing.
  for (final key in SharedPreferencesNotificationPreferences.syncedKeys)
    SyncedPreference(
      key,
      onPulled: (ref) => ref.invalidate(notificationPreferencesProvider),
    ),
];
