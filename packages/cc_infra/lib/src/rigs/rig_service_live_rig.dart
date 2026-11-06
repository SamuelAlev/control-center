part of 'rig_service.dart';

/// One live rig: its record, its machine and its driver.
class _LiveRig {
  _LiveRig({required this.rig});

  Rig rig;
  RigMachine? machine;
  IosSimulatorSession? iosSession;

  /// The surface driver. It also owns the watch-lane stream: disposing it is
  /// what ends a viewer's frames, so there is no separate viewer registry to
  /// keep in sync.
  RigDriver? driver;

  /// The resident memory this rig holds, whether running or parked. Parking
  /// stops the vCPUs; it does not hand the RAM back. A window rig holds none:
  /// the memory is the app's, and closing the rig frees nothing.
  int get residentMb =>
      rig.surface == RigSurface.window ? 0 : rig.spec.memoryMb;

  /// Attached consumers that make this rig "in use" even when no action has
  /// arrived: an open terminal, a viewer watching the stream.
  ///
  /// Idle is measured from the last ACTION, and a terminal's keystrokes never
  /// reach this service — they go down an SSH connection the host opened. So
  /// without a pin an exec rig freezes mid-keystroke at its idle timeout and
  /// is destroyed (with the user's uncommitted work) at twice that, which is
  /// precisely the case `RigSpec.exec`'s longer grace period was meant to
  /// protect.
  int pins = 0;

  bool get isPinned => pins > 0;

  /// Open watch lanes (video + audio) currently being consumed.
  ///
  /// A person watching a guest work sends no ACTIONS, so idle time is not
  /// evidence that nobody is there: without this the rig somebody was looking
  /// at parked at its idle timeout, was destroyed at twice that, and was
  /// LRU-evicted in between — under the viewer, mid-frame.
  int watchers = 0;

  /// Capture session currently allowed to feed the guest microphone.
  ///
  /// Set before forwarding `start=1`, so every later chunk/end is checked at
  /// the authoritative server even when the installed guest image predates
  /// guest-side session gating.
  String? microphoneSessionId;

  /// Completion tail for guest microphone writes.
  ///
  /// Each microphone-capable surface owns one playback process. Keeping start,
  /// chunks, and end on one ordered lane prevents an already-forwarded old end
  /// from overtaking the replacement start.
  Future<void> microphoneForwarding = Future<void>.value();

  Future<T> serializeMicrophone<T>(Future<T> Function() operation) {
    final result = microphoneForwarding.then((_) => operation());
    microphoneForwarding = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  /// Whether a consumer is attached: a pinned terminal or an open watch lane.
  /// The hard TTL ignores this — "somebody is using it", not "it may live
  /// forever".
  bool get isInUse => pins > 0 || watchers > 0;

  /// Set the moment teardown starts, BEFORE its first await.
  ///
  /// The window where a rig owns a hypervisor it cannot reach is the inside of
  /// `launch()`: [machine] is still null, so a teardown finds nothing to
  /// destroy and the machine that arrives a minute later is assigned to an
  /// object nobody holds. The boot path re-reads this after `launch` returns
  /// and destroys the machine itself instead.
  bool closing = false;

  /// Completes when the launch has either handed its machine to [machine] or
  /// failed. Teardown waits on it so `disposeAll` does not return while a
  /// hypervisor is still being born.
  Future<void>? launched;

  /// When the activity timestamp last reached the DATABASE. The in-memory
  /// timestamp updates on every action (the reaper reads that one); writing
  /// each of a hover stream's ~30 moves/second through SQLite would not.
  DateTime lastTouchWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// When a bare pointer move last landed in the action log.
  DateTime lastMoveLog = DateTime.fromMillisecondsSinceEpoch(0);

  /// When the browser rig's URL last reached the DATABASE. Same discipline as
  /// [lastTouchWrite]: the in-memory row is always current, the write is not.
  DateTime lastUrlWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the in-memory URL is ahead of the stored one.
  bool pendingUrlWrite = false;

  /// The trailing write scheduled for the end of a navigation burst, so a
  /// redirect chain's FINAL destination is persisted even though the ones
  /// before it were coalesced away.
  Timer? urlWriteTimer;
}
