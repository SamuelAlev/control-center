import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Owns which connected session a composition root renders, for desktop and
/// web alike: adopting a new one, serializing server switches and retiring the
/// outgoing session only once nothing mounted still reads it.
///
/// [S] is the root's session handle (the desktop's `DesktopBackendSession`,
/// the web's `RemoteServerConnection`); [retire] tears one down.
class ServerConnectController<S extends Object> {
  /// Creates a controller that tears sessions down with [retire].
  ServerConnectController({required this.retire, this._binding});

  /// Tears a session down (container, client, a bundled server child).
  final Future<void> Function(S session) retire;

  /// The scheduler retirement waits on; the app binding when null.
  final SchedulerBinding? _binding;
  S? _current;
  final ValueNotifier<int> _generation = ValueNotifier(0);
  Future<void>? _switching;
  String? _switchTarget;

  /// The live session, or null before the first adoption or while the root
  /// shows its sign-in surface.
  S? get current => _current;

  /// Bumped on every adoption; the root remounts the session UI.
  ValueListenable<int> get generation => _generation;

  /// Whether a [switchTo] is still connecting.
  bool get isSwitching => _switching != null;

  /// Makes [next] the live session and retires the previous one after the
  /// frame that remounts the UI around [next].
  void adopt(S next) {
    final old = _current;
    _current = next;
    _generation.value++;
    if (old != null && !identical(old, next)) {
      retireAfterFrame(() => retire(old), binding: _binding);
    }
  }

  /// Stops rendering the live session (the root is going back to its sign-in
  /// surface) and hands it to the caller to retire.
  S? detach() {
    final old = _current;
    _current = null;
    return old;
  }

  /// Connects [serverId] with [connect] and adopts the result, one switch at a
  /// time.
  ///
  /// A second request for the same server while one is connecting joins it; a
  /// request for another server throws [StateError] instead of racing it —
  /// two overlapping switches to the bundled local server would start two
  /// servers on one data directory. On failure the current session stays live
  /// and the error reaches the caller.
  Future<void> switchTo(String serverId, Future<S> Function() connect) {
    final inFlight = _switching;
    if (inFlight != null) {
      if (_switchTarget == serverId) {
        return inFlight;
      }
      return Future.error(
        StateError('Another server switch is still in progress.'),
      );
    }
    _switchTarget = serverId;
    final run = () async {
      adopt(await connect());
    }();
    return _switching = run.whenComplete(() {
      _switching = null;
      _switchTarget = null;
    });
  }
}

/// Runs [dispose] after the next frame, forcing one if frames are off.
///
/// A session's widget tree is rebuilt around its replacement in the next frame
/// (`setState`), so disposing its container or client right away would leave
/// the still-mounted tree reading a disposed `ProviderContainer`: every
/// `ref.watch` throws, the remount frame dies half-built and the window is
/// painted but dead. Post-frame callbacks run after `finalizeTree`, i.e. once
/// the old tree is unmounted for real.
///
/// A post-frame callback needs a frame. `ensureVisualUpdate` schedules one
/// normally, but not while frames are disabled (a hidden or minimised window —
/// e.g. a switch adopted from an SSO bounce while the browser is in front): the
/// old session, and a bundled `cc_server` the user just left, would then
/// outlive the switch until the window next painted. A forced frame is the one
/// scheduling path that ignores `framesEnabled`.
void retireAfterFrame(
  Future<void> Function() dispose, {
  SchedulerBinding? binding,
}) {
  final scheduler = binding ?? SchedulerBinding.instance;
  scheduler.addPostFrameCallback((_) => unawaited(dispose()));
  if (scheduler.framesEnabled) {
    scheduler.ensureVisualUpdate();
  } else {
    scheduler.scheduleForcedFrame();
  }
}
