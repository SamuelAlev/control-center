import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/focus_mode/domain/focus_mode_state.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

const _durationKey = 'focus_mode_duration_minutes';
const _blockNotificationsKey = 'focus_mode_block_notifications';
const _pillXKey = 'focus_mode_pill_x';
const _pillYKey = 'focus_mode_pill_y';

/// Key under which the main engine records the one-shot token of the pill it is
/// currently creating, consumed by [consumeFreshPillLaunch].
const _pendingPillTokenKey = 'focus_mode_pending_pill_token';

const _uuid = Uuid();

/// Channel the pill window uses to send actions back to the main window.
const _pillToMainChannel = WindowMethodChannel(
  'focus_pill_to_main',
  mode: ChannelMode.unidirectional,
);

/// Closes the floating focus-pill sub-window if one is open.
///
/// Enumerates the real windows and asks each pill to close itself, so it works
/// even when the Dart-side [WindowController] handle has been lost (e.g. across
/// a restart) while the native always-on-top window lives on. This is the
/// cooperative teardown for user-initiated close (ending a session, expanding
/// back to the app, quitting): in those cases the pill is running normally and
/// its close handler is registered. Hot-restart orphans are handled by the pill
/// itself on launch (see `_bootstrapFocusPill` in `main.dart`), not here. Safe
/// to call when no pill exists.
Future<void> closeAllFocusPillWindows() async {
  try {
    final windows = await WindowController.getAll();
    for (final window in windows) {
      if (!window.arguments.contains('focusPill')) {
        continue;
      }
      try {
        await window.invokeMethod<void>('window_close');
      } on Object catch (_) {}
    }
  } on Object catch (_) {}
}

/// Whether this pill sub-window is a *fresh* launch — the one the main window
/// just created and is awaiting — rather than a hot-restart re-run.
///
/// Identifying the pill is not enough on its own: a hot restart re-runs the
/// pill's entrypoint on the *same* engine — for the live pill, and also for a
/// completed pill whose window was hidden but never released (the platform
/// closes pill windows with `isReleasedWhenClosed = false`, so the engine stays
/// alive as a "zombie") — and every such re-run carries the same args token. So
/// the token is a *one-shot* launch ticket: `_openPillWindow` mints it, stores
/// it (before the window exists) and stamps it into the pill's args; this
/// returns true exactly once per token by matching the pill's [pillToken]
/// against the stored pending token and, on a match, **consuming** it. A later
/// re-run finds the token already consumed (or replaced by a newer pill's) and
/// returns false, so the pill dismisses itself. Race-free: written before the
/// pill engine starts, consumed by the pill itself — no other engine competes.
Future<bool> consumeFreshPillLaunch(String? pillToken) async {
  if (pillToken == null) {
    return false;
  }
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_pendingPillTokenKey) != pillToken) {
    return false;
  }
  await prefs.remove(_pendingPillTokenKey);
  return true;
}

/// Persists the user's focus-mode *preferences* — never the live session.
///
/// A focus session is ephemeral to a single app run, so nothing about it
/// (whether it is active, when it started, its goal) is stored. Only the
/// preferred duration, the notification setting, and the pill's last position
/// carry over between runs.
class _FocusModeStorage {
  const _FocusModeStorage(this._prefs);
  final SharedPreferences _prefs;

  int get durationMinutes => _prefs.getInt(_durationKey) ?? 50;

  bool get blockNotifications => _prefs.getBool(_blockNotificationsKey) ?? true;

  Future<void> savePreferences({
    required int durationMinutes,
    required bool blockNotifications,
  }) async {
    await _prefs.setInt(_durationKey, durationMinutes);
    await _prefs.setBool(_blockNotificationsKey, blockNotifications);
  }

  Future<void> savePillPosition(double x, double y) async {
    await _prefs.setDouble(_pillXKey, x);
    await _prefs.setDouble(_pillYKey, y);
  }

  /// Records the one-shot token of the pill the main engine is about to create,
  /// for [consumeFreshPillLaunch] to match against on the pill's first launch.
  Future<void> setPendingPillToken(String token) async {
    await _prefs.setString(_pendingPillTokenKey, token);
  }

  Offset loadPillPosition() {
    final x = _prefs.getDouble(_pillXKey);
    final y = _prefs.getDouble(_pillYKey);
    if (x != null && y != null) {
      return Offset(x, y);
    }
    return const Offset(700, 30);
  }
}

/// Notifier managing focus mode lifecycle.
class FocusModeNotifier extends Notifier<FocusModeState> {
  late _FocusModeStorage _storage;

  @override
  FocusModeState build() {
    _storage = _FocusModeStorage(ref.watch(sharedPreferencesProvider));
    // Handle messages sent from the pill sub-window.
    _pillToMainChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'expandFocusPill':
          await exitCompactMode();
        case 'completeFocusSession':
          await deactivate();
        case 'savePillPosition':
          final args = call.arguments as Map;
          await _storage.savePillPosition(
            (args['x'] as num).toDouble(),
            (args['y'] as num).toDouble(),
          );
      }
      return null;
    });

    // A focus session lives for exactly one app run: every launch and restart
    // starts inactive, with no pill and a reset timer. Only the user's duration
    // and notification preferences carry over. Because nothing about the live
    // session is persisted, a pill sub-window can never be revived from stale
    // storage — on a hot restart it sees its own window already on-screen and
    // closes itself.
    return FocusModeState(
      active: false,
      sessionDurationMinutes: _storage.durationMinutes,
      blockNotifications: _storage.blockNotifications,
    );
  }

  /// Activates focus mode and opens the pill in a new separate window.
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
    await _openPillWindow();
  }

  /// Activates focus mode without opening the pill.
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

  /// Deactivates focus mode and closes the pill if open.
  Future<void> deactivate() async {
    // Close unconditionally via enumeration: after a restart `compactMode` is
    // false yet a pill window may still exist — a tracked-handle path would
    // miss it and leave the timer running.
    await closeAllFocusPillWindows();
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

  /// Opens the pill window (if not already open) and minimizes the main window.
  Future<void> enterCompactMode() async {
    if (!state.active || state.compactMode) {
      return;
    }
    await _openPillWindow();
  }

  /// Closes the pill window and restores the main window.
  Future<void> exitCompactMode() async {
    if (!state.compactMode) {
      return;
    }
    await _closePillWindow();
    // Bring the main window to the front so the user can see it again.
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _openPillWindow() async {
    // Never stack pills: close any orphan from a previous run before spawning a
    // fresh one.
    await closeAllFocusPillWindows();

    // Mint a one-shot launch token BEFORE creating the window — so it is already
    // stored when the pill engine starts — and stamp it into the pill's args.
    // The pill shows itself only if it can consume this exact token (see
    // consumeFreshPillLaunch); that is how a genuine first launch is told apart
    // from a hot-restart re-run of the live pill or a hidden zombie engine.
    final token = _uuid.v4();
    await _storage.setPendingPillToken(token);

    // Read `state` live rather than threading a snapshot across the awaits above,
    // so the pill is created from — and `compactMode` is flipped on — the
    // current session, never a stale copy that could resurrect a session the
    // user cancelled mid-creation.
    final pos = _storage.loadPillPosition();
    final args = jsonEncode({
      'type': 'focusPill',
      'pillToken': token,
      'goal': state.goal,
      'startedAtMs': state.sessionStartedAt?.millisecondsSinceEpoch,
      'durationMinutes': state.sessionDurationMinutes,
      'pillX': pos.dx,
      'pillY': pos.dy,
    });
    await WindowController.create(
      WindowConfiguration(hiddenAtLaunch: true, arguments: args),
    );
    state = state.copyWith(compactMode: true);
  }

  Future<void> _closePillWindow() async {
    await closeAllFocusPillWindows();
    state = state.copyWith(compactMode: false, clearPausedAt: true);
  }
}

/// Provides the current [FocusModeState] and the [FocusModeNotifier].
final focusModeProvider =
    NotifierProvider<FocusModeNotifier, FocusModeState>(FocusModeNotifier.new);
