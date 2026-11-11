/// @docImport 'package:control_center/shared/widgets/foreground_ticker_gate.dart';
library;

import 'dart:async';

import 'package:control_center/app/main_window_nudger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show WindowManager;

/// Repairs stale [AppLifecycleState.hidden] that leaves a visible window black.
///
/// Headless macOS: boot/setup and primary windows are created from Dart.
/// At launch (and when one main window replaces another), AppKit's
/// `handleWillBecomeActive` finds no visible window and reports `hidden`, which
/// sets `SchedulerBinding.framesEnabled = false` — later `scheduleFrame()` is a
/// no-op and nothing rasterizes (flutter/flutter#155977 can leave occlusion
/// stale). Schedule repairs per show ([onMainWindowShown]), not once.
///
/// Push synthetic `resumed` only when a main window holds keyboard focus —
/// never invent frontmost over a genuine `hidden` ([ForegroundTickerGate]).
/// When focus cannot be proven (invite/SSO), [MainWindowNudger] issues a
/// real 1px resize so AppKit recomputes occlusion and
/// `handleMetricsChanged` forces a frame past `framesEnabled`.
class WindowVisibilityGuard with WidgetsBindingObserver {
  /// Creates a guard.
  ///
  /// [mainWindowFocused] answers "does one of this app's main windows hold
  /// keyboard focus right now"; it defaults to asking the platform and is
  /// injectable for tests. [nudgeMainWindow] performs the real-window resize
  /// nudge described on [MainWindowNudger] and reports whether it found
  /// a window to nudge; also injectable for tests.
  WindowVisibilityGuard({
    bool Function()? mainWindowFocused,
    bool Function()? nudgeMainWindow,
  }) : _mainWindowFocused = mainWindowFocused ?? _nativeMainWindowFocused,
       _nudgeMainWindow = nudgeMainWindow ?? mainWindowNudger.nudge;

  /// The process-wide guard the desktop bootstrap installs.
  static final WindowVisibilityGuard instance = WindowVisibilityGuard();

  final bool Function() _mainWindowFocused;
  final bool Function() _nudgeMainWindow;

  bool _installed = false;
  bool _armed = false;
  final List<Timer> _rechecks = [];

  /// Delays at which a repair is re-attempted after a main window appears.
  ///
  /// The will-show hook runs BEFORE the window is on screen, and macOS makes
  /// it the key window a moment later still, so a single immediate check would
  /// always be too early to prove anything. The ladder also has to be LONG
  /// enough to outlast the content settling into the window: the first frame
  /// after the setup→primary handoff is the splash, and the real screen
  /// (onboarding, the invite-code flow) only replaces it once `identity.me`,
  /// the forge connections and the workspace list resolve over RPC — on a
  /// cold first-run local server or a remote login that routinely outlasts
  /// any 3-second schedule, which is how a "repaired" window stayed black
  /// until a manual resize. These are cheap (a lifecycle-state read, then one
  /// platform query) and stop as soon as the state is healthy.
  static const List<Duration> _recheckDelays = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 1000),
    Duration(seconds: 3),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  /// Starts observing lifecycle changes. Idempotent; call once from the
  /// desktop bootstrap.
  void install() {
    if (_installed) {
      return;
    }
    _installed = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Records that one of this app's main windows is being shown, and schedules
  /// the repair passes. Called from the window manager's will-show hook.
  void onMainWindowShown() {
    _armed = true;
    // One nudge on every show, BEFORE any lifecycle reasoning: a freshly
    // created window's content view carries a black layer until its first
    // present, and if that first frame is lost (a warm-up frame that ran
    // before the view attached, or frames disabled by a stale `hidden`),
    // nothing else schedules one. The resize is the exact event the operator
    // performs by hand to recover, and it is invisible (1px, 120ms). When the
    // state is healthy this is at worst one redundant frame.
    _nudgeMainWindow();
    // Immediately, then again once the window has had time to be mapped and
    // made key: this first pass can rarely prove the state wrong (the window
    // is not on screen yet inside the hook), but it does force the one frame
    // that costs nothing and may be all that is missing.
    _repair();
    // EVERY show gets the staged batch, not just the first. The app puts two
    // main windows on screen in succession whenever it has no server yet: the
    // pre-app setup window (choose local, or paste a pairing key), then — once
    // that resolves — the primary window the app itself renders into. The
    // handoff destroys the first before creating the second, so the app owns no
    // visible window for a moment and the engine pushes `hidden`, disabling
    // frames exactly as it does at launch. Arming on the setup window and
    // leaving the primary one with only the immediate pass above gave the
    // window that matters the one check that cannot prove anything: onboarding
    // built into a black window until a resize or Cmd-Tab forced a frame.
    //
    // Replacing the batch rather than appending is what keeps a repeated
    // activation from piling timers up.
    _cancelRechecks();
    for (final delay in _recheckDelays) {
      _rechecks.add(Timer(delay, _repair));
    }
  }

  /// Records that a focusable non-main window (the tray panel) is being shown.
  ///
  /// The panel opens while the main window may be hidden in the tray, which
  /// is exactly when the engine reports `hidden` and disables frames: the
  /// panel would paint its first frame and then freeze. The panel takes key
  /// focus, which [_repair] accepts as proof the app is frontmost. Unlike
  /// [onMainWindowShown] it adds no unconditional nudge: that resizes a main
  /// window, and opening the panel over a healthy app must not touch it.
  void onAuxiliaryWindowShown() {
    _armed = true;
    _repair();
    _cancelRechecks();
    for (final delay in _recheckDelays.take(3)) {
      _rechecks.add(Timer(delay, _repair));
    }
  }

  void _cancelRechecks() {
    for (final timer in _rechecks) {
      timer.cancel();
    }
    _rechecks.clear();
  }

  /// Cancels the pending repair passes (tests; the app never tears this down).
  @visibleForTesting
  void dispose() {
    _cancelRechecks();
    if (_installed) {
      WidgetsBinding.instance.removeObserver(this);
      _installed = false;
    }
    _armed = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Frames have just been disabled. If this app is demonstrably on
        // screen, that is the launch-time state machine talking, not the user.
        //
        // Deferred, never immediate: this runs inside the binding's observer
        // loop, and the repair is itself a lifecycle message that
        // `ChannelBuffers.push` delivers SYNCHRONOUSLY. Repairing on the spot
        // therefore re-enters the dispatch — observers after this one are
        // handed the repaired `resumed` before the `hidden` that is still
        // being delivered, and `AppLifecycleListener` asserts on the
        // resumed → hidden jump that leaves behind. A microtask lets the
        // in-flight notification finish first.
        scheduleMicrotask(_repair);
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _repair() {
    if (!_armed) {
      return;
    }
    final binding = WidgetsBinding.instance;
    final state = binding.lifecycleState;
    if (state == null ||
        (state != AppLifecycleState.hidden &&
            state != AppLifecycleState.paused)) {
      // Healthy (or unknown): nothing to repair.
      return;
    }

    // Paint once regardless: a forced frame is the one scheduling path that
    // ignores `framesEnabled` (it is what nudging the window size does). It
    // cannot make anything worse, so it runs even when the state below cannot
    // be proven wrong — a stale-but-correct first frame beats a black window.
    binding.scheduleForcedFrame();

    final focused = _mainWindowFocused();
    // The nudge runs for BOTH strengths of proof: with focus it complements
    // the synthetic `resumed` below (which fixes the framework but cannot
    // touch the engine's own occlusion latch), and without it, it is the only
    // repair there is.
    _nudgeMainWindow();

    if (!focused) {
      // No focused main window: push nothing through the lifecycle channel.
      // Visibility alone authorizes the nudge above (it repairs via the
      // platform's own event), but rewriting the state from Dart requires the
      // stronger proof below.
      return;
    }

    // Go through the platform's own channel rather than the binding's
    // protected hook, so the correction takes exactly the path a real
    // notification would: state transitions are generated, `framesEnabled`
    // flips back on and every observer (ticker gate, shader background) sees
    // one consistent story.
    ServicesBinding.instance.channelBuffers.push(
      SystemChannels.lifecycle.name,
      const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
      (ByteData? _) {},
    );
  }
}

/// Whether one of this app's windows is visible AND holds keyboard focus.
///
/// Keyboard focus is the proof that matters: a key window means this app is
/// frontmost, which is incompatible with the platform reporting the app as
/// hidden. Focus also selects the right windows on its own — the HUDs (focus
/// pill, meeting toolbar, mini player) are created with `isFocusable = false`
/// precisely so they can never become key, because they are meant to stay up
/// while the operator works in ANOTHER app. One of them being on screen says
/// nothing about whether this app is; one of them being focused cannot happen.
bool _nativeMainWindowFocused() {
  for (final window in WindowManager.instance.getAll()) {
    if (window.isVisible && !window.isMinimized && window.isFocused) {
      return true;
    }
  }
  return false;
}
