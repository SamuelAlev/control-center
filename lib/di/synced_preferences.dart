import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/infrastructure/speech/dictation_controller.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/providers/locale_provider.dart';
import 'package:control_center/core/settings/synced_preference.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/meetings/providers/meeting_auto_detect_provider.dart';
import 'package:control_center/features/settings/providers/editor_preferences_provider.dart';
import 'package:control_center/features/vscode_theme/providers/vscode_theme_providers.dart';

/// Every preference that follows the signed-in user across devices.
///
/// Lives in the composition root because it names providers from `core/` AND
/// from features; assembling it inside `core/settings/` would invert the
/// Dependency Rule that `architecture_constraints_test.dart` enforces.
///
/// Adding a synced key is one entry. What does NOT belong here:
///
///  * **Anything naming hardware or a filesystem path** — `audio_input_device_id`
///    (this machine's mic), `selected_ide_id` (what is installed here) and
///    critically `app_font_path` / `code_font_path`, which are absolute paths
///    that would leak `/Users/<name>/…` to the server and mean nothing on
///    another machine. Syncing font *family* and *source* while leaving the
///    path local is safe by construction: `FontSettingsNotifier` already falls
///    back to the default when a stored path does not resolve.
///  * **Anything read before the RPC handshake** — `privacy_error_reporting_enabled`
///    (read by `runAppWithSentry` at startup) and `app_log_level` cannot be
///    server-sourced at the moment they are needed.
///  * **Window geometry, `ui.sidebarCollapsed`, `active_workspace_id`** — per
///    screen, per machine, per session. That covers `window_x/y/w/h` and the
///    `window_maximized` / `window_fullscreen` state flags: a frame that fits
///    a 27" display is off the edge of a laptop, and "I work full screen on
///    the desktop" is not a claim about the laptop.
///  * **Which server this client dials** (`server_connection_mode`,
///    `server_entries`, `server_active_id`) — definitionally per-device and
///    syncing it could point a device at a server it cannot reach.
///  * **Anything two members of a workspace must agree on** — the branch
///    template, the review level and the conversation-title model belong to the
///    `workspace_settings` lane, not here. A per-user copy of a shared decision
///    is a decision that quietly differs per sender.
///  * **Anything an ACCOUNT must be right about, not merely agree on** —
///    `onboarding_finished` is the cautionary tale and now lives on
///    `users.onboarding_finished_at`. This lane's promotion pass seeds the
///    server from whatever the first device holds locally, which is the correct
///    behaviour for a preference (adopt what the person already chose) and
///    exactly wrong for a claim about the account: a machine that had onboarded
///    once marked a brand-new user as already set up, and the onboarding gate
///    duly offered them the re-auth screen instead of the setup they had never
///    done. If a wrong value would be a lie rather than a stale taste, it
///    belongs on the entity.
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
