import 'package:cc_domain/features/focus_mode/domain/focus_mode_state.dart';
import 'package:control_center/app/focus_primary_window.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _durationKey = 'focus_mode_duration_minutes';
const _blockNotificationsKey = 'focus_mode_block_notifications';

/// Persists the user's focus-mode *preferences* — never the live session.
///
/// A focus session is ephemeral to a single app run, so nothing about it
/// (whether it is active, when it started, its goal) is stored. Only the
/// preferred duration and the notification setting carry over between runs; the
/// pill's window position is persisted by the windowing layer (see
/// `persistWindowGeometry`).
class _FocusModeStorage {
  const _FocusModeStorage(this._prefs);
  final AppPreferences _prefs;

  int get durationMinutes => _prefs.getInt(_durationKey) ?? 50;

  bool get blockNotifications => _prefs.getBool(_blockNotificationsKey) ?? true;

  Future<void> savePreferences({
    required int durationMinutes,
    required bool blockNotifications,
  }) async {
    await _prefs.setInt(_durationKey, durationMinutes);
    await _prefs.setBool(_blockNotificationsKey, blockNotifications);
  }
}

/// Notifier managing focus mode lifecycle.
///
/// The floating pill is a sibling window in the same isolate (see
/// `FocusPillWindow` / `AppWindows`); [FocusModeState.compactMode] alone drives
/// whether it is on screen — flipping the flag adds or removes the window. There
/// is no sub-window engine, IPC channel, or launch token anymore.
class FocusModeNotifier extends Notifier<FocusModeState> {
  late _FocusModeStorage _storage;

  @override
  FocusModeState build() {
    _storage = _FocusModeStorage(ref.watch(appPreferencesProvider));

    // A focus session lives for exactly one app run: every launch and restart
    // starts inactive, with no pill and a reset timer. Only the user's duration
    // and notification preferences carry over.
    return FocusModeState(
      active: false,
      sessionDurationMinutes: _storage.durationMinutes,
      blockNotifications: _storage.blockNotifications,
    );
  }

  /// Activates focus mode and shows the floating pill.
  Future<void> activateAndFloat({
    int durationMinutes = 50,
    String? goal,
    bool blockNotifications = true,
  }) async {
    await activate(
      durationMinutes: durationMinutes,
      goal: goal,
      blockNotifications: blockNotifications,
    );
    state = state.copyWith(compactMode: true);
  }

  /// Activates focus mode without showing the pill.
  Future<void> activate({
    int durationMinutes = 50,
    String? goal,
    bool blockNotifications = true,
  }) async {
    state = state.copyWith(
      active: true,
      sessionStartedAt: DateTime.now(),
      sessionDurationMinutes: durationMinutes,
      goal: goal,
      clearGoal: goal == null,
      blockNotifications: blockNotifications,
    );
    await _storage.savePreferences(
      durationMinutes: durationMinutes,
      blockNotifications: blockNotifications,
    );
  }

  /// Deactivates focus mode and removes the pill.
  Future<void> deactivate() async {
    state = state.copyWith(
      active: false,
      clearStartedAt: true,
      clearGoal: true,
      clearPausedAt: true,
      compactMode: false,
    );
  }

  /// Toggles focus mode.
  Future<void> toggle() async {
    if (state.active) {
      await deactivate();
    } else {
      await activateAndFloat(durationMinutes: state.sessionDurationMinutes);
    }
  }

  /// Updates the preferred session duration without toggling.
  Future<void> setDuration(int minutes) async {
    state = state.copyWith(sessionDurationMinutes: minutes);
    await _storage.savePreferences(
      durationMinutes: minutes,
      blockNotifications: state.blockNotifications,
    );
  }

  /// Sets the goal shown in the floating bar.
  void setGoal(String? goal) {
    state = state.copyWith(goal: goal, clearGoal: goal == null);
  }

  /// Shows the pill (compact mode). No-op unless a session is active.
  Future<void> enterCompactMode() async {
    if (!state.active || state.compactMode) {
      return;
    }
    state = state.copyWith(compactMode: true);
  }

  /// Hides the pill and brings the main window back to the front.
  Future<void> exitCompactMode() async {
    if (!state.compactMode) {
      return;
    }
    state = state.copyWith(compactMode: false);
    focusPrimaryWindow();
  }
}

/// Provides the current [FocusModeState] and the [FocusModeNotifier].
final focusModeProvider = NotifierProvider<FocusModeNotifier, FocusModeState>(
  FocusModeNotifier.new,
);
