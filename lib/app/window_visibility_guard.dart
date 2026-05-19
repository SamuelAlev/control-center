import 'dart:async';

import 'package:control_center/app/window_chrome.dart' show isMainWindowTitle;
import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart' show WindowManager;

/// Repairs the launch-time lifecycle state that leaves the first window black.
///
/// The macOS runner is headless: every window is created from Dart (see
/// `AppWindows`), and the desktop only gets there after it has spawned or
/// connected its `cc_server` — seconds on a first boot, longer on a fresh data
/// directory. The engine derives `AppLifecycleState` from AppKit
/// notifications, and the one that fires during launch,
/// `NSApplicationWillBecomeActiveNotification`, resolves the state by scanning
/// `NSApp.windows` for a visible one (`FlutterEngine.mm`
/// `handleWillBecomeActive`). At that moment this app has NO windows, so the
/// engine reports [AppLifecycleState.hidden].
///
/// `hidden` sets `SchedulerBinding.framesEnabled = false`, which makes every
/// later `scheduleFrame()` a no-op. The window is then created and shown and
/// the widget tree builds into it — and nothing is ever rasterized: a black
/// window, with no error anywhere. Only the two paths that bypass
/// `framesEnabled` bring it back, which is exactly what the two accidental
/// workarounds are: Cmd-Tab out and back (the engine re-runs
/// `handleWillBecomeActive`, this time finding a visible window, and sends
/// `resumed`, which re-enables frames) and nudging the window's size by a
/// pixel (`handleMetricsChanged` → `scheduleForcedFrame`, which ignores
/// `framesEnabled`).
///
/// Usually the occlusion-state notification that follows the window's
/// appearance repairs the state on its own. `NSApplication.occlusionState`
/// latches stale — the engine says so itself in the comment above
/// `handleWillBecomeActive` (flutter/flutter#155977) — so on a slow boot it
/// does not, and the app is left painting nothing into a window that is right
/// there on screen.
///
/// The same hole opens mid-session, without any launch involved, every time
/// one main window replaces another: the pre-app setup window is destroyed
/// before the primary window is created, so the app briefly owns nothing
/// visible and the engine disables frames again. That is why the repair passes
/// are scheduled per SHOW rather than once (see [onMainWindowShown]).
///
/// The correction has two strengths. Rewriting the state from Dart (pushing
/// `resumed` through the lifecycle channel) is applied ONLY where it can be
/// proven wrong: one of this app's own main windows holds keyboard focus, so
/// the app is frontmost and `hidden` cannot be true. Everything else is left
/// alone — a genuine `hidden` (Cmd-H, minimized, fully occluded) is what stops
/// the primary window burning GPU memory on frames nobody can see (see
/// `ForegroundTickerGate`), so this guard must never out-argue the platform
/// about it.
///
/// Repairing through a REAL platform event (see [_nativeNudgeMainWindow]) is
/// held to the weaker proof of a main window merely being VISIBLE, because it
/// does not argue with the platform at all — it gives the window server an
/// event to recompute occlusion from and lets the engine draw its own
/// conclusion. This is the path that reaches the login flows (invite code,
/// SSO), where the app is not frontmost at the moment the stale `hidden`
/// latches and the focus proof is therefore unavailable precisely where the
/// repair is needed most: the window the operator is staring at stays black
/// until they Cmd-Tab or resize it by hand.
class WindowVisibilityGuard with WidgetsBindingObserver {
  /// Creates a guard.
  ///
  /// [mainWindowFocused] answers "does one of this app's main windows hold
  /// keyboard focus right now"; it defaults to asking the platform and is
  /// injectable for tests. [nudgeMainWindow] performs the real-window resize
  /// nudge described on [_nativeNudgeMainWindow] and reports whether it found
  /// a window to nudge; also injectable for tests.
  WindowVisibilityGuard({
    bool Function()? mainWindowFocused,
    bool Function()? nudgeMainWindow,
  }) : _mainWindowFocused = mainWindowFocused ?? _nativeMainWindowFocused,
       _nudgeMainWindow = nudgeMainWindow ?? _nativeNudgeMainWindow;

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
    AppLog.i('window', 'main window shown — visibility guard armed');
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
    _repair('window shown');
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
      _rechecks.add(Timer(delay, () => _repair('window shown')));
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
    AppLog.i('window', 'lifecycle → ${state.name}');
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
        scheduleMicrotask(() => _repair('lifecycle → ${state.name}'));
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _repair(String reason) {
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
    final nudged = _nudgeMainWindow();
    AppLog.w(
      'window',
      'repair pass: state=${state.name} '
          'framesEnabled=${binding.framesEnabled} focused=$focused '
          'nudged=$nudged ($reason)',
    );

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

/// How long a nudge holds its +1px size before restoring it.
///
/// An out-and-back issued within a single Dart turn can be a complete no-op:
/// the engine may coalesce the two metric updates into "nothing changed", and
/// the window server may never flush the intermediate size — which is exactly
/// a repair that runs and does nothing. Holding the new size for a beat makes
/// the resize REAL (metrics delivered, occlusion recomputed) before the
/// restore, at a duration the eye cannot see. It also cannot be persisted by
/// the geometry watcher, which only writes a frame two of its one-second
/// polls agree on — a 120ms blip never spans two polls.
const Duration _nudgeHoldDuration = Duration(milliseconds: 120);

/// Re-asserts a visible main window with a real 1px resize, held briefly.
///
/// This is the repair that works when focus cannot be proven — the invite-code
/// and SSO logins land exactly there, with the app not frontmost at the moment
/// the stale `hidden` latches. It is deliberately a REAL AppKit event rather
/// than (only) the synthetic `resumed` the guard pushes through the lifecycle
/// channel, because the two halves of the failure live on different sides:
///
///  - The ENGINE's `_visible` latch (FlutterEngine.mm, from AppKit occlusion)
///    is what pushed `hidden`, and a channel message written by Dart cannot
///    touch it — the next occlusion notification re-pushes `hidden` and frames
///    die again. A window resize makes the window server recompute occlusion,
///    so the engine itself sends the correction (the Cmd-Tab fix).
///  - The FRAMEWORK's `framesEnabled` gate is what swallows every later
///    `scheduleFrame()`. A resize delivers a metrics change, and
///    `handleMetricsChanged` forces a frame that ignores the gate (the
///    1px-resize fix).
///
/// The operator has been doing this by hand; this is the same nudge, issued
/// by the guard while a main window is demonstrably on screen. The restore is
/// scheduled (see [_nudgeHoldDuration]) and re-resolves the window, so a
/// window closed in between is left alone. Full-screen windows are skipped
/// (`setContentSize:` on one is ignored at best), as are minimized ones
/// (nudging a window in the Dock proves nothing about visibility).
///
/// Returns whether a window was found and nudged.
bool _nativeNudgeMainWindow() {
  // One at a time: `dressKnownWindows` reports every main window on every
  // show, so a single hook can reach here twice within one turn — and two
  // stacked nudges capture different baselines for their restores, leaving
  // the window permanently 1px wider.
  final now = DateTime.now();
  if (_lastNudgeAt != null &&
      now.difference(_lastNudgeAt!) < _nudgeHoldDuration) {
    return true;
  }
  for (final window in WindowManager.instance.getAll()) {
    if (!isMainWindowTitle(window.title)) {
      continue;
    }
    if (!window.isVisible || window.isMinimized || window.isFullScreen) {
      continue;
    }
    final size = window.contentSize;
    window.contentSize = Size(size.width + 1, size.height);
    final windowId = window.id;
    Timer(_nudgeHoldDuration, () {
      final stillOpen = WindowManager.instance.get(windowId);
      if (stillOpen != null) {
        stillOpen.contentSize = size;
      }
    });
    _lastNudgeAt = now;
    return true;
  }
  return false;
}

DateTime? _lastNudgeAt;
