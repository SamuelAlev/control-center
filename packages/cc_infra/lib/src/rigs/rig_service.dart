import 'dart:async';
import 'dart:convert';
import 'dart:io' show Process;

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart'
    show ComputerMouseMove, ComputerSetDisplay;
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/adb_client.dart';
import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/guest_credential_service.dart';
import 'package:cc_infra/src/rigs/qemu_enclosure_backend.dart';
import 'package:cc_infra/src/rigs/rig_dev_tls.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';
import 'package:cc_infra/src/rigs/rig_file_transfer.dart';
import 'package:cc_infra/src/rigs/rig_image_store.dart';
import 'package:cc_infra/src/rigs/rig_machine.dart';
import 'package:cc_infra/src/rigs/rig_port_service.dart';
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:cc_infra/src/rigs/worktree_sync.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

/// Releases a pin taken with [RigService.pin]. Idempotent.
typedef RigPinRelease = void Function();

/// Resolves a workspace's custom image reference for a smolvm surface, or
/// null for the pinned default. `exec` distinguishes the Terminal (VM) image
/// from the Browser (VM) one.
///
/// A callback rather than a repository dependency: the setting lives in the
/// workspace settings store, which belongs to the composition root — this
/// service must not grow a database.
typedef RigSmolvmImageResolver =
    Future<String?> Function(String workspaceId, {required bool exec});

/// Resolves the extra egress hosts a workspace configured for its browser
/// rigs (the `rigs.browser.egressHosts` workspace setting, already validated
/// by the resolver). Unioned into the spec's allowlist at open.
typedef RigBrowserEgressResolver =
    Future<List<String>> Function(String workspaceId);

/// One live rig: its record, its machine and its driver.
class _LiveRig {
  _LiveRig({required this.rig});

  Rig rig;
  RigMachine? machine;

  /// The surface driver. It also owns the watch-lane stream: disposing it is
  /// what ends a viewer's frames, so there is no separate viewer registry to
  /// keep in sync.
  RigDriver? driver;

  /// The resident memory this rig holds, whether running or parked. Parking
  /// stops the vCPUs; it does not hand the RAM back.
  int get residentMb => rig.spec.memoryMb;

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

/// The server-side [RigPort]: boots enclosures, drives them, reaps them.
///
/// One instance per server. It owns every live machine, so it is also what
/// makes `disposeAll` meaningful — an orphaned hypervisor process outlives the
/// server, holds gigabytes and answers to nobody.
///
/// Also the server-side [RigPortsPort]: the machines and their forwarded
/// ports share one lifecycle, so the plumbing attaches at boot and dies at
/// teardown without a second registry to keep in sync.
class RigService implements RigPort, RigPortsPort {
  /// Creates a [RigService].
  RigService({
    required RigRepository repository,
    required QemuEnclosureBackend qemu,
    required SmolvmEnclosureBackend smolvm,
    required RigImageStore images,
    GuestCredentialService? credentials,
    DomainEventBus? eventBus,
    String? dataDir,
    RigSmolvmImageResolver? smolvmImageOverride,
    RigBrowserEgressResolver? browserEgressHosts,
    int maxResidentMb = 12288,
    Duration reapInterval = const Duration(seconds: 30),
  }) : _repository = repository,
       _qemu = qemu,
       _smolvm = smolvm,
       _images = images,
       _credentials = credentials,
       _eventBus = eventBus,
       _dataDir = dataDir,
       _smolvmImageOverride = smolvmImageOverride,
       _browserEgressHosts = browserEgressHosts,
       _devTls = dataDir == null ? null : RigDevTlsMaterial(dataDir: dataDir),
       _maxResidentMb = maxResidentMb,
       _reapInterval = reapInterval;

  final RigRepository _repository;
  final QemuEnclosureBackend _qemu;
  final SmolvmEnclosureBackend _smolvm;
  final RigImageStore _images;
  final GuestCredentialService? _credentials;
  final DomainEventBus? _eventBus;

  /// The server's data directory, or null when the host did not name one.
  ///
  /// Only the mobile surface reads it, and only as an `install_apk`
  /// confinement root: every workspace's working directories live under it, so
  /// it is the one tree an agent's build output can honestly be expected in.
  /// Null leaves the rig with only its worktree, and a rig with neither
  /// installs nothing — fail-closed, because "unconfigured" must not read as
  /// "the whole filesystem".
  final String? _dataDir;

  /// The workspace's custom-image lookup, or null when the host wired none
  /// (every rig then boots the pinned defaults).
  final RigSmolvmImageResolver? _smolvmImageOverride;

  /// The workspace's extra egress hosts for browser rigs, or null when the
  /// host wired none (a browser rig then admits only its defaults). Read at
  /// OPEN, not at boot: smolvm pins `--allow-host` IPs when the machine is
  /// created, so editing the setting never retro-applies to a live machine —
  /// the next rig gets it.
  final RigBrowserEgressResolver? _browserEgressHosts;

  /// The dev-domain TLS material (a local CA + one wildcard leaf), or null on
  /// a host with no data dir to keep keys in. Minted lazily in [start]; its
  /// keys never enter a guest — only the leaf's public-key fingerprint does.
  final RigDevTlsMaterial? _devTls;
  final int _maxResidentMb;
  final Duration _reapInterval;

  final Map<String, _LiveRig> _live = {};

  /// Port discovery + forwarding for smolvm rigs (see `rig_port_service.dart`).
  ///
  /// Late so it can close over the resolved smolvm binary, which does not
  /// exist until the first probe. Every guest touch goes through `machine
  /// exec`, so a host with no smolvm simply never constructs a channel.
  late final RigPortsService _ports = RigPortsService(
    runInGuest: (machineName, command) async {
      final binary = _smolvm.resolvedBinary;
      if (binary == null) {
        throw StateError('smolvm is not resolved on this host.');
      }
      return Process.run(binary, [
        'machine',
        'exec',
        '--name',
        machineName,
        '--timeout',
        '20s',
        '--',
        'sh',
        '-c',
        command,
      ]);
    },
    startInGuest: (machineName, guestArgv) async {
      final binary = _smolvm.resolvedBinary;
      if (binary == null) {
        throw StateError('smolvm is not resolved on this host.');
      }
      return Process.start(binary, [
        'machine',
        'exec',
        '-i',
        '--name',
        machineName,
        '--',
        ...guestArgv,
      ]);
    },
    tlsContext: () => _devTls?.securityContext(),
  );

  /// Opens in flight, keyed by `(workspace, conversation, exec?)`.
  ///
  /// `open()` awaits several times before it registers in [_live], so two
  /// concurrent calls for one conversation both saw an empty map and both
  /// booted. Parallel tool calls in a single assistant turn make that
  /// reachable without any adversary. Callers now join the first attempt.
  final Map<String, Future<Rig>> _opening = {};

  /// Memory committed to opens that have not registered yet, so the budget
  /// check cannot be passed by six simultaneous callers each seeing the same
  /// pre-open total.
  int _reservedMb = 0;

  final Uuid _uuid = const Uuid();
  Timer? _reaper;
  bool _disposed = false;

  /// Starts the idle/TTL reaper and sweeps anything a previous process left.
  ///
  /// Called AFTER the server's ready banner, like code-graph indexing: a
  /// hypervisor probe and a directory sweep have no business on the path to
  /// the banner the desktop parses with a 20-second timeout.
  Future<void> start() async {
    await _qemu.sweepOrphanedRuntimes();
    await _smolvm.sweepOrphanedRuntimes();
    await _markStrandedSessionsFailed();
    // Dev-domain TLS: mint (or load) the local CA + leaf, then hand the
    // leaf's PUBLIC-key fingerprint to the browser workload builder so the
    // enclosed browser treats our certs as valid. Best-effort by design —
    // `ensure` never throws, and without it dev domains stay plain HTTP.
    final tls = _devTls;
    if (tls != null) {
      await tls.ensure();
      _smolvm.devTlsSpkiFingerprint = tls.spkiFingerprint;
    }
    _reaper ??= Timer.periodic(_reapInterval, (_) => unawaited(_reap()));
    CcInfraLog.info(
      'rig: service armed (reap every ${_reapInterval.inSeconds}s)',
    );
  }

  /// The last Android probe, cached like QEMU's.
  ///
  /// `probe()` is called by every rig surface on every open and by the
  /// settings page on every visit, and `_probeAndroid` shells out to `adb`
  /// and the emulator binary each time — which QEMU's probe explicitly does
  /// not, for the same reason. Invalidated by [refreshProbe], the same way an
  /// image download invalidates the QEMU one.
  RigBackendCapabilities? _androidProbe;

  @override
  Future<RigCapabilities> probe() async {
    final backends = <RigBackendCapabilities>[
      await _smolvm.probe(),
      await _qemu.probe(),
      _androidProbe ??= await _probeAndroid(),
    ];
    return RigCapabilities(backends: backends);
  }

  /// Drops every cached probe, so the next [probe] re-reads the host.
  ///
  /// Called after anything that can change what this host can boot: an image
  /// download or import, or an operator installing the Android SDK while the
  /// server runs.
  Future<void> refreshProbe() async {
    _androidProbe = null;
    await _qemu.probe(refresh: true);
  }

  /// Probes the mobile surface.
  ///
  /// Android does not boot one of our base images: it drives the host's own
  /// Android emulator over adb, so "is it ready" is a question about SDK
  /// tooling rather than about a download. The four ways it can be not-ready
  /// have four different fixes, so each is reported as itself — a single
  /// "unavailable" would send an operator who merely has no AVD off to
  /// reinstall an SDK they already have.
  ///
  /// It is always reported, including when nothing is installed. A backend
  /// that vanishes from the list when it is missing is indistinguishable from
  /// one we do not support, and the operator is left with no way to find out
  /// what the mobile tab needs.
  Future<RigBackendCapabilities> _probeAndroid() async {
    const backend = EnclosureBackend.androidEmulator;
    // Stated on every branch: the mobile surface is genuinely less contained
    // than the VM ones, and that is a property of the emulator, not of how
    // far setup got.
    const egressCaveat =
        'Note: the emulator manages its own networking, so this surface does '
        'NOT get the deny-by-default NIC the VM surfaces do. Full egress '
        'enforcement needs a Linux worker.';

    final adbPath = await AdbClient.locate();
    final emulatorPath = await AdbClient.locateEmulator();
    if (adbPath == null || emulatorPath == null) {
      final sdk = AdbClient.sdkRoot();
      return RigBackendCapabilities.unavailable(
        backend,
        requiresInstall: true,
        installHint:
            'Install Android Studio, then create a device in its Device '
            'Manager',
        note: sdk == null
            ? 'No Android SDK found. The mobile surface drives a real Android '
                  'emulator, so it needs the Android SDK with an emulator and '
                  'a virtual device.'
            : 'An Android SDK is present at $sdk but '
                  '${adbPath == null ? 'adb (platform-tools)' : 'the emulator'}'
                  ' is missing from it. Install the missing package from the '
                  'SDK Manager.',
      );
    }

    final devices = await AdbClient.devices(adbPath);
    if (devices.isNotEmpty) {
      return RigBackendCapabilities(
        backend: backend,
        available: true,
        surfaces: const {RigSurface.mobile},
        note: 'Android via adb (${devices.length} device(s)). $egressCaveat',
      );
    }

    final avds = await AdbClient.avds(emulatorPath);
    if (avds.isEmpty) {
      return RigBackendCapabilities.unavailable(
        backend,
        requiresInstall: true,
        installHint:
            'Create a virtual device in Android Studio\'s Device Manager',
        note:
            'The Android SDK is installed but has no virtual device to '
            'start.',
      );
    }
    return RigBackendCapabilities.unavailable(
      backend,
      // Nothing to install — the device just is not running yet, and saying
      // "install" here would be a lie that costs a 3 GB re-download.
      installHint: 'Start "${avds.first}" from the Device Manager',
      note:
          'No device is attached. Start "${avds.first}" and the mobile '
          'surface becomes available. $egressCaveat',
    );
  }

  @override
  Future<Rig> open({
    required String workspaceId,
    required RigSpec spec,
    required Principal openedBy,
  }) async {
    if (_disposed) {
      throw StateError('The rig service is shutting down.');
    }
    // The workspace's own egress hosts join the caller's allowlist HERE, at
    // the one chokepoint every open path (RPC op, `browser_use` tool, internal
    // callers) funnels through — a caller that forgets them cannot strip a
    // workspace's policy, and the envelope stays the server's to choose.
    // Browser rigs only: exec rigs carry their own forge/apt envelope.
    final egressResolver = _browserEgressHosts;
    if (spec.surface == RigSurface.browser && egressResolver != null) {
      final workspaceHosts = await egressResolver(workspaceId);
      if (workspaceHosts.isNotEmpty) {
        spec = spec.copyWith(
          egressAllowlist: {
            ...spec.egressAllowlist,
            ...workspaceHosts,
          }.toList(growable: false),
        );
      }
    }
    // One exec rig per conversation: a second `terminal.spawn` in the same
    // conversation joins the machine that is already there rather than booting
    // a second copy of the same worktree.
    final reusable = _reusableFor(workspaceId, spec);
    if (reusable != null) {
      await _touch(reusable);
      return reusable.rig;
    }

    // Join an open already in flight for the same conversation+kind rather
    // than starting a second one. Without this the reuse check above is a
    // check-then-act race across the awaits below.
    final key = spec.conversationId == null
        ? null
        : '$workspaceId/${spec.conversationId}/${spec.surface.wire}/'
              '${spec.isExec}';
    if (key == null) {
      return _open(workspaceId, spec, openedBy);
    }
    final inFlight = _opening[key];
    if (inFlight != null) {
      return inFlight;
    }
    final pending = _open(workspaceId, spec, openedBy);
    _opening[key] = pending;
    try {
      return await pending;
    } finally {
      // `Map.remove` returns the removed value — here the very future this
      // call already awaited — so the discard is deliberate rather than a
      // dropped future.
      // ignore: unawaited_futures
      _opening.remove(key);
    }
  }

  /// The backend a spec boots on.
  ///
  /// A property of the SURFACE, not of the host: a mobile rig drives the
  /// Android emulator; exec (terminal) and browser rigs are smolvm microVMs;
  /// the desktop surface keeps QEMU, the only backend here with a display
  /// device. Stamping anything else would have the row claim an accelerator
  /// we did not pick and the egress enforcement (`hasEnforcedEgress`) that
  /// backend may not have.
  ///
  /// A spec that NAMES a backend is validated here: naming one the surface
  /// does not run on is an error, never a silent downgrade.
  Future<EnclosureBackend> _backendFor(RigSpec spec) async {
    final routed = spec.surface == RigSurface.mobile
        ? EnclosureBackend.androidEmulator
        : (spec.isExec || spec.surface == RigSurface.browser)
        ? EnclosureBackend.smolvm
        : (await _qemu.probe()).backend;
    final requested = spec.backend;
    if (requested != null && requested != routed) {
      throw ArgumentError.value(
        requested.wire,
        'spec.backend',
        'This surface boots on ${routed.wire}; naming another backend is an '
            'error, not a downgrade. Open the surface without one, or ask for '
            'the surface that backend hosts.',
      );
    }
    return routed;
  }

  Future<Rig> _open(
    String workspaceId,
    RigSpec spec,
    Principal openedBy,
  ) async {
    // Check AND reserve under one lock, then hold the reservation across the
    // awaits below so a concurrent open cannot read a total that does not yet
    // include this machine. `_register` hands the accounting over to `_live`
    // before this returns.
    await _reserveResident(spec.memoryMb);
    try {
      return await _register(workspaceId, spec, openedBy);
    } finally {
      _reservedMb -= spec.memoryMb;
    }
  }

  Future<Rig> _register(
    String workspaceId,
    RigSpec spec,
    Principal openedBy,
  ) async {
    // Re-checked HERE, after the budget wait. `disposeAll` can land in the
    // gap between the check at the top of `open` and this point (the budget
    // gate awaits evictions), and a row saved after shutdown is a
    // `provisioning` entry nothing will ever advance: `_boot` aborts at its
    // first `_bootAborted`, and the row sits there until the next server
    // start reconciles it into `failed`.
    if (_disposed) {
      throw StateError(
        'The rig service is shutting down, so no new machine was opened.',
      );
    }
    final now = DateTime.now();
    final rig = Rig(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      surface: spec.surface,
      // The backend is a property of the SURFACE, not of what happens to be
      // installed — see _backendFor.
      backend: await _backendFor(spec),
      status: const RigProvisioning(step: 'Starting'),
      spec: spec,
      createdBy: openedBy,
      conversationId: spec.conversationId,
      agentId: spec.agentId,
      createdAt: now,
      lastActivityAt: now,
    );
    await _repository.save(workspaceId, rig);
    final live = _LiveRig(rig: rig);
    _live[rig.id] = live;

    // Boot in the background: the caller gets a session id immediately and
    // watches the status change, because a two-minute blocking call looks
    // identical to a hang from the other side of an RPC.
    unawaited(_boot(live));
    return rig;
  }

  @override
  Future<List<Rig>> list(String workspaceId) => _repository.list(workspaceId);

  @override
  Future<Rig?> get(String workspaceId, String rigId) =>
      _repository.getById(workspaceId, rigId);

  @override
  Stream<List<Rig>> watch(String workspaceId) => _repository.watch(workspaceId);

  @override
  Future<RigActionResult> act({
    required String workspaceId,
    required String rigId,
    required RigAction action,
    required Principal actor,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      // A foreign or unknown id must read the same: absent. Distinguishing
      // them would let a caller enumerate another workspace's rigs.
      return RigActionResult.error('Rig $rigId is not open in this workspace.');
    }

    // ── The take-over chokepoint ──────────────────────────────────────────
    // Mutual exclusion is enforced HERE, in the one place every action passes
    // through, rather than by asking a model to behave. Observation stays
    // allowed while a human drives: an agent that can still look can still
    // narrate what the human is doing, which is the point of watching.
    final controller = live.rig.controller;
    if (action.mutatesGuest &&
        controller != null &&
        controller.wire != actor.wire) {
      return RigActionResult.error(
        controller.isUser
            ? 'A person has taken control of this rig. You can still take '
                  'screenshots and read state, but input is theirs until they '
                  'hand it back.'
            : 'Another agent holds control of this rig.',
      );
    }

    final driver = live.driver;
    if (driver == null) {
      return RigActionResult.error(switch (live.rig.status) {
        RigFailed() => 'This rig failed to start: ${live.rig.status.detail}',
        RigReady() =>
          'This rig hosts an enclosed terminal, not a drivable surface — '
              'work in it through the terminal instead.',
        _ =>
          'This rig is still starting — '
              '${live.rig.status.detail ?? 'booting'}.',
      });
    }

    await _wakeMachine(live);

    final started = DateTime.now();
    final result = await driver.perform(action);
    final elapsed = DateTime.now().difference(started);

    // A streamed pointer position (fluid human mouse) is ~30 events/second;
    // bookkeeping each one through SQLite would put a write per wiggle on the
    // shared connection. Moves update the in-memory activity clock always,
    // but hit the database at most once a second — and the audit keeps one
    // sampled move per second rather than a row per pixel. Everything with a
    // consequence (clicks, keys, scroll, drags) is still logged one-to-one.
    final isPointerStream =
        action is ComputerMouseMove || action is BrowserMouseMove;
    final now = DateTime.now();
    if (isPointerStream) {
      if (_isCurrent(live)) {
        live.rig = live.rig.copyWith(lastActivityAt: now);
        if (now.difference(live.lastTouchWrite) > const Duration(seconds: 1)) {
          live.lastTouchWrite = now;
          await _repository.save(live.rig.workspaceId, live.rig);
        }
      }
      if (now.difference(live.lastMoveLog) < const Duration(seconds: 1)) {
        return result;
      }
      live.lastMoveLog = now;
    } else {
      // A mode change alters the coordinate space every later click maps
      // through, and the row is where the viewer reads the guest size from —
      // leaving it stale means take-over clicks land translated through the
      // OLD dimensions. The browser's viewport is the same fact with a
      // different verb.
      if ((action is ComputerSetDisplay || action is BrowserSetViewport) &&
          !result.isError &&
          _isCurrent(live) &&
          live.driver != null) {
        live.rig = live.rig.copyWith(display: live.driver!.display);
      }
      await _touch(live);
    }
    await _logAction(
      live: live,
      action: action,
      actor: actor,
      result: result,
      durationMs: elapsed.inMilliseconds,
    );
    return result;
  }

  // ── The clipboard and file lanes ────────────────────────────────────────
  //
  // Same chokepoint as [act] — take-over exclusivity, the activity clock, the
  // action log — reached through [_admit] so the three rules cannot be
  // implemented three slightly different ways. What is deliberately NOT the
  // same is what gets written down: these carry bytes, and the log records
  // only how many.

  @override
  Future<RigClipboardData> readClipboard({
    required String workspaceId,
    required String rigId,
    required Principal actor,
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  }) async {
    final live = _admit(workspaceId, rigId, mutating: false, actor: actor);
    if (live == null) {
      return RigClipboardData.empty;
    }
    final driver = live.driver;
    if (driver == null) {
      // An exec rig. Its "clipboard" is the host's, mediated by the terminal
      // widget the person is typing into — there is no X server and no
      // browser inside to hold one. Empty is the honest answer, and the
      // terminal never asks.
      return RigClipboardData.empty;
    }
    await _wakeMachine(live);
    final started = DateTime.now();
    try {
      final data = await driver.readClipboard(selection);
      await _touch(live);
      await _logRaw(
        live: live,
        verb: 'clipboard_read',
        args: {'selection': selection.wire},
        summary: 'Read ${data.summary} off the ${selection.wire} selection',
        actor: actor,
        // The SHAPE, never the content: this is a clipboard, which is exactly
        // where credentials are for a few seconds at a time.
        resultText: data.summary,
        isError: false,
        durationMs: DateTime.now().difference(started).inMilliseconds,
      );
      return data;
    } on Object catch (e) {
      CcInfraLog.warning('rig/$rigId: clipboard read failed: $e');
      return RigClipboardData.empty;
    }
  }

  @override
  Future<RigActionResult> writeClipboard({
    required String workspaceId,
    required String rigId,
    required RigClipboardData data,
    required Principal actor,
  }) async {
    if (data.isEmpty) {
      return RigActionResult.error(
        'There is nothing on the clipboard to send.',
      );
    }
    final live = _admit(workspaceId, rigId, mutating: true, actor: actor);
    if (live == null) {
      return _absentOrHeld(workspaceId, rigId, actor);
    }
    final driver = live.driver;
    if (driver == null) {
      return RigActionResult.error(
        'This rig hosts an enclosed terminal, which has no clipboard of its '
        'own — paste into the terminal instead.',
      );
    }
    await _wakeMachine(live);
    final started = DateTime.now();
    final result = await _guarded(() async {
      await driver.writeClipboard(data);
      return RigActionResult.ok('Put ${data.summary} on the clipboard.');
    }, verb: 'clipboard_write');
    await _touch(live);
    await _logRaw(
      live: live,
      verb: 'clipboard_write',
      args: {
        'shape': data.summary,
        if (data.text != null) 'textLength': data.text!.length,
        if (data.hasImage) 'hasImage': true,
      },
      summary: 'Put ${data.summary} on the clipboard',
      actor: actor,
      resultText: result.text,
      isError: result.isError,
      durationMs: DateTime.now().difference(started).inMilliseconds,
    );
    return result;
  }

  @override
  Future<RigDropResult> dropFiles({
    required String workspaceId,
    required String rigId,
    required RigDropRequest request,
    required Principal actor,
  }) async {
    // Validated as a WHOLE before anything is written: half a drop looks
    // exactly like a whole one in the guest's folder.
    final rejection = request.rejection;
    if (rejection != null) {
      return RigDropResult.error(rejection);
    }
    final live = _admit(workspaceId, rigId, mutating: true, actor: actor);
    if (live == null) {
      final refusal = _absentOrHeld(workspaceId, rigId, actor);
      return RigDropResult.error(refusal.text);
    }
    final transfer = _fileTransferFor(live);
    if (transfer == null) {
      return RigDropResult.error(
        'This machine has no channel to copy files through yet — it may still '
        'be starting.',
      );
    }
    await _wakeMachine(live);
    final started = DateTime.now();
    RigDropResult result;
    try {
      final landed = await transfer.put(request.files);
      // The bytes are in. Offering them to the guest is a separate, weaker
      // promise, so a failure there must not report the copy as failed —
      // the files really are in the machine either way.
      final driver = live.driver;
      result = driver == null
          ? RigDropResult(
              files: landed,
              summary: landed.length == 1
                  ? 'Copied "${landed.single.name}" into '
                        '${transfer.dropDirectory} in the machine.'
                  : 'Copied ${landed.length} files into '
                        '${transfer.dropDirectory} in the machine.',
            )
          : await driver.offerDroppedFiles(landed, request);
    } on RigFileTransferException catch (e) {
      result = RigDropResult.error(e.message);
    } on Object catch (e) {
      CcInfraLog.error('rig/$rigId: drop failed: $e', e);
      result = RigDropResult.error('The files could not be copied in: $e');
    }
    await _touch(live);
    await _logRaw(
      live: live,
      verb: 'drop_files',
      args: {
        'fileCount': request.files.length,
        'totalBytes': request.totalBytes,
        if (request.hasPoint) 'coordinate': [request.x, request.y],
      },
      summary: result.summary,
      actor: actor,
      resultText: result.summary,
      isError: result.isError,
      durationMs: DateTime.now().difference(started).inMilliseconds,
    );
    return result;
  }

  @override
  Future<RigFileBytes?> readFile({
    required String workspaceId,
    required String rigId,
    required String guestPath,
    required Principal actor,
  }) async {
    // Reading a file OUT is observation, like a screenshot: it is allowed
    // while a person holds control, because the agent narrating what they are
    // doing is the point of watching.
    final live = _admit(workspaceId, rigId, mutating: false, actor: actor);
    if (live == null) {
      return null;
    }
    final transfer = _fileTransferFor(live);
    if (transfer == null) {
      return null;
    }
    await _wakeMachine(live);
    final started = DateTime.now();
    RigFileBytes? bytes;
    String? failure;
    try {
      bytes = await transfer.get(guestPath);
    } on RigFileTransferException catch (e) {
      failure = e.message;
    }
    await _touch(live);
    await _logRaw(
      live: live,
      verb: 'read_file',
      // The PATH is recorded and the contents are not. A path is the
      // reviewable half ("what left this machine?"); the bytes are the half
      // an audit table has no business holding.
      args: {'guestPath': guestPath},
      summary: bytes == null
          ? 'Could not read $guestPath out of the machine'
          : 'Read ${bytes.name} (${bytes.bytes.length} bytes) out of the '
                'machine',
      actor: actor,
      resultText: failure ?? (bytes == null ? 'not readable' : bytes.name),
      isError: bytes == null,
      durationMs: DateTime.now().difference(started).inMilliseconds,
    );
    if (failure != null) {
      throw RigFileTransferException(failure);
    }
    return bytes;
  }

  /// Resolves a live rig in [workspaceId] and applies the take-over rule.
  ///
  /// Null means "you may not do this here", collapsing three cases that must
  /// all look the same from outside: no such rig, a rig in another workspace
  /// (distinguishing it would let ids be enumerated) and a rig somebody else
  /// is driving. Callers that need to SAY which use [_absentOrHeld].
  _LiveRig? _admit(
    String workspaceId,
    String rigId, {
    required bool mutating,
    required Principal actor,
  }) {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return null;
    }
    final controller = live.rig.controller;
    if (mutating && controller != null && controller.wire != actor.wire) {
      return null;
    }
    return live;
  }

  /// The refusal sentence for a rig that could not be admitted.
  RigActionResult _absentOrHeld(
    String workspaceId,
    String rigId,
    Principal actor,
  ) {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return RigActionResult.error('Rig $rigId is not open in this workspace.');
    }
    final controller = live.rig.controller;
    if (controller != null && controller.wire != actor.wire) {
      return RigActionResult.error(
        controller.isUser
            ? 'A person has taken control of this rig. You can still read '
                  'state, but input is theirs until they hand it back.'
            : 'Another agent holds control of this rig.',
      );
    }
    return RigActionResult.error('Rig $rigId cannot be driven right now.');
  }

  /// Runs [body], turning a surface's refusal into a result rather than an
  /// exception. A caller of the clipboard lane has to say something to a
  /// person either way; a thrown object gives it nothing to say.
  Future<RigActionResult> _guarded(
    Future<RigActionResult> Function() body, {
    required String verb,
  }) async {
    try {
      return await body();
    } on RigSurfaceUnsupported catch (e) {
      return RigActionResult.error(e.message);
    } on GuestAgentTooOld {
      return RigActionResult.error(
        'This machine\'s base image predates clipboard support. Rebuild it '
        'with scripts/rigs/build_image.sh and re-import it in '
        'Settings → Server → Enclosures.',
      );
    } on Object catch (e) {
      return rigDriverFailure(verb, e);
    }
  }

  /// The file carrier for [live]'s machine, or null when one cannot be built.
  RigFileTransfer? _fileTransferFor(_LiveRig live) {
    final machine = live.machine;
    if (machine == null) {
      return null;
    }
    final transport = _transportFor(machine);
    if (transport == null) {
      return null;
    }
    return RigFileTransfer(
      transport: transport,
      dropDirectory: rigDropDirectory(
        surface: live.rig.surface,
        exec: live.rig.spec.isExec,
      ),
    );
  }

  /// The guest carrier for [machine], or null when it cannot be built yet.
  ///
  /// The same split [_worktreeSyncFor] makes, exposed one level lower: the
  /// file lane needs the transport itself, not a worktree sync built on it.
  WorktreeTransport? _transportFor(RigMachine machine) {
    if (machine is QemuMachine) {
      return SshWorktreeTransport(
        sshPort: machine.sshPort,
        privateKeyPath: machine.privateKeyPath,
      );
    }
    if (machine is SmolvmMachine) {
      final binary = _smolvm.resolvedBinary;
      if (binary != null) {
        return SmolvmWorktreeTransport(
          smolvmPath: binary,
          machineName: machine.name,
        );
      }
    }
    return null;
  }

  @override
  Future<RigStream?> watchStream({
    required String workspaceId,
    required String rigId,
    required RigWatchRequest request,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return null;
    }
    final driver = live.driver;
    if (driver == null) {
      return null;
    }
    await _wakeMachine(live);
    await _touch(live);
    final clamped = request.clamped();
    final bytes = await driver.openWatchStream(clamped);
    if (bytes == null) {
      return null;
    }
    return RigStream(
      bytes: _trackedLane(live, bytes),
      // The codec comes from the DRIVER, not from the request. A client never
      // sends `codec`, so every request defaults to MJPEG and echoing it back
      // had the relay label a raw H.264 lane as JPEG frames — the mobile
      // viewer then scanned it for markers that were never coming.
      negotiated: clamped.withCodec(driver.watchCodec),
      displaySize: driver.display,
    );
  }

  /// Wraps a watch lane so the rig knows somebody is on the other end of it.
  ///
  /// The count is what the reaper and the memory budget read: the single
  /// `_touch` at open is one timestamp, and an hour of passive watching is
  /// indistinguishable from an hour of nothing to a clock. Every exit is
  /// counted — cancel, done AND error — because a lane that ends by failing
  /// leaves a rig immortal if only the happy path decrements.
  Stream<List<int>> _trackedLane(_LiveRig live, Stream<List<int>> source) {
    late StreamController<List<int>> controller;
    // Cancelled in onCancel below; the closure indirection is past the lint's
    // reach.
    // ignore: cancel_subscriptions
    StreamSubscription<List<int>>? sub;
    var counted = false;
    void release() {
      if (!counted) {
        return;
      }
      counted = false;
      if (live.watchers > 0) {
        live.watchers--;
      }
      // The watch held the idle reaper off, but it did not advance the
      // activity clock — an hour-long watch leaves `lastActivityAt` an hour
      // stale, so without this the rig is already past 2x its idle timeout
      // the moment the viewer disconnects and is destroyed with no grace.
      if (_isCurrent(live)) {
        live.rig = live.rig.copyWith(lastActivityAt: DateTime.now());
      }
    }

    controller = StreamController<List<int>>(
      onListen: () {
        counted = true;
        live.watchers++;
        sub = source.listen(
          controller.add,
          onError: (Object e, StackTrace st) {
            controller.addError(e, st);
            release();
            unawaited(controller.close());
          },
          onDone: () {
            release();
            unawaited(controller.close());
          },
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () async {
        release();
        final open = sub;
        sub = null;
        await open?.cancel();
      },
    );
    return controller.stream;
  }

  /// The guest's audio lane for [rigId] (encoded bytes), or null when the rig
  /// is not live or its surface has no audio.
  ///
  /// Same posture as [watchStream]: opening it is activity, a parked machine
  /// wakes, and the server relays without decoding.
  Future<Stream<List<int>>?> watchAudio({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return null;
    }
    final driver = live.driver;
    if (driver == null) {
      return null;
    }
    await _wakeMachine(live);
    await _touch(live);
    try {
      final audio = await driver.openAudioStream();
      return audio == null ? null : _trackedLane(live, audio);
    } on Object catch (e) {
      CcInfraLog.warning('rig/$rigId: audio lane failed to open: $e');
      return null;
    }
  }

  @override
  Future<Rig> takeControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final held = live.rig.controller;
    if (held != null && held.wire != actor.wire) {
      // A person takes over from an agent unconditionally — the machine is
      // ultimately theirs, and "the agent is holding the lock" must never be
      // a reason a human cannot intervene. Everything else (agent from
      // human, agent from agent, human from another human) stays a refusal.
      final humanOverridesAgent = actor.isUser && !held.isUser;
      if (!humanOverridesAgent) {
        throw StateError(
          'Control of this rig is already held by ${held.wire}.',
        );
      }
    }
    live.rig = live.rig.copyWith(
      controller: actor,
      controlHeldSince: DateTime.now(),
    );
    await _repository.save(workspaceId, live.rig);
    _eventBus?.publish(
      RigControlChanged(
        workspaceId: workspaceId,
        rigId: rigId,
        controller: actor,
        occurredAt: DateTime.now(),
      ),
    );
    return live.rig;
  }

  @override
  Future<Rig> releaseControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  }) async {
    final live = _requireLive(workspaceId, rigId);
    final held = live.rig.controller;
    if (held == null) {
      return live.rig;
    }
    if (held.wire != actor.wire) {
      // Releasing someone else's hold would make the lock advisory, which is
      // the same as not having one.
      throw StateError(
        'Control is held by ${held.wire}; only they can release it.',
      );
    }
    live.rig = live.rig.releaseControl();
    await _repository.save(workspaceId, live.rig);
    _eventBus?.publish(
      RigControlChanged(
        workspaceId: workspaceId,
        rigId: rigId,
        controller: null,
        occurredAt: DateTime.now(),
      ),
    );
    return live.rig;
  }

  @override
  Future<void> close({
    required String workspaceId,
    required String rigId,
    RigCloseReason? reason,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      // No live machine — but the ROW may still claim one: a session from a
      // previous server process, or another server sharing the database.
      // Closing a dead row must still close it, or the panel shows a machine
      // with a stop button that silently does nothing, forever.
      final stale = await _repository.getById(workspaceId, rigId);
      if (stale != null && !stale.status.phase.isTerminal) {
        await _repository.save(
          workspaceId,
          stale.copyWith(
            status: RigClosed(reason ?? RigCloseReason.requested),
            closedAt: DateTime.now(),
          ),
        );
      }
      return;
    }
    // An explicit reason from the caller beats the default. "The conversation
    // ended" and "you pressed close" are different answers to "where did my
    // machine go", and the row is the only place that answer survives.
    await _teardown(live, reason ?? RigCloseReason.requested);
  }

  @override
  Future<void> disposeAll() async {
    _disposed = true;
    _reaper?.cancel();
    _reaper = null;
    final all = _live.values.toList();
    for (final live in all) {
      try {
        await _teardown(live, RigCloseReason.serverShutdown);
      } on Object catch (e) {
        CcInfraLog.warning('rig: teardown of ${live.rig.id} failed: $e');
      }
    }
    await _ports.dispose();
    await _credentials?.stop();
  }

  /// Carries commits made inside [rigId] back to the host worktree.
  ///
  /// Not part of [RigPort] because it is specific to a rig that has a
  /// worktree: the port describes driving a machine, this describes what a
  /// developer does with one afterwards.
  Future<WorktreeSyncResult> writeBackWorktree({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return const WorktreeSyncResult(
        ok: false,
        message: 'That rig is not open in this workspace.',
      );
    }
    final hostPath = live.rig.spec.worktreePath;
    final machine = live.machine;
    final sync = machine == null ? null : _worktreeSyncFor(machine);
    if (hostPath == null || sync == null) {
      return const WorktreeSyncResult(
        ok: false,
        message: 'This rig has no worktree, so there is nothing to carry back.',
      );
    }
    return sync.writeBack(hostPath: hostPath, rigId: rigId);
  }

  /// The rig's uncommitted diff, for the UI to show before anything is applied.
  Future<String> worktreeDiff({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _live[rigId];
    final machine = live?.machine;
    if (live == null ||
        machine == null ||
        live.rig.workspaceId != workspaceId) {
      return '';
    }
    final sync = _worktreeSyncFor(machine);
    if (live.rig.spec.worktreePath == null || sync == null) {
      return '';
    }
    return sync.diffOut();
  }

  /// The carrier for [machine]'s guest, or null when it cannot be built
  /// (a smolvm rig whose binary resolution has not run yet).
  WorktreeSync? _worktreeSyncFor(RigMachine machine) {
    if (machine is QemuMachine) {
      return WorktreeSync(
        sshPort: machine.sshPort,
        privateKeyPath: machine.privateKeyPath,
      );
    }
    if (machine is SmolvmMachine) {
      final binary = _smolvm.resolvedBinary;
      if (binary != null) {
        return WorktreeSync.smolvm(
          smolvmPath: binary,
          machineName: machine.name,
        );
      }
    }
    return null;
  }

  /// Marks a consumer as attached to [rigId] and returns its release.
  ///
  /// While at least one is attached the rig is neither parked nor idle-reaped.
  /// Its hard TTL still applies: a pin says "somebody is using this", not
  /// "this may live forever".
  RigPinRelease pin(String workspaceId, String rigId) {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return () {};
    }
    live.pins++;
    var released = false;
    return () {
      if (released) {
        return;
      }
      released = true;
      if (live.pins > 0) {
        live.pins--;
      }
      // Same as a watch lane's release: the pin held the reaper off without
      // advancing the activity clock, so restart the idle grace from the
      // moment the consumer let go rather than from the last keystroke that
      // happened to reach this service.
      if (_isCurrent(live)) {
        live.rig = live.rig.copyWith(lastActivityAt: DateTime.now());
      }
    };
  }

  /// The argv for an interactive shell into [rigId], or null when the rig is
  /// not live. Used by the terminal path.
  List<String>? shellArgvFor(String workspaceId, String rigId) {
    final live = _live[rigId];
    final machine = live?.machine;
    if (live == null ||
        machine == null ||
        live.rig.workspaceId != workspaceId) {
      return null;
    }
    // Terminals are served by smolvm exec rigs; a desktop machine answering
    // here would be handed a shell path it no longer has.
    if (machine is! SmolvmMachine) {
      return null;
    }
    final binary = _smolvm.resolvedBinary;
    if (binary == null) {
      return null;
    }
    // Opening a shell IS activity, and it is the last signal this service
    // gets until the user runs something that reaches it.
    unawaited(_touch(live));
    return WorktreeSync.smolvm(
      smolvmPath: binary,
      machineName: machine.name,
    ).interactiveShellArgv(
      workingDirectory: live.rig.spec.worktreePath == null
          ? null
          : kSmolvmGuestWorkdir,
    );
  }

  /// The live EXEC rig serving [conversationId], if there is one.
  ///
  /// Exec specifically: a conversation can have a desktop rig open at the same
  /// time, and a terminal must not be dropped into it.
  Rig? execRigFor(String workspaceId, String conversationId) {
    for (final live in _live.values) {
      if (live.rig.workspaceId == workspaceId &&
          live.rig.conversationId == conversationId &&
          live.rig.spec.isExec &&
          live.rig.status.phase.holdsMachine) {
        return live.rig;
      }
    }
    return null;
  }

  // ── Ports (RigPortsPort; mechanism in rig_port_service.dart) ─────────────

  @override
  Map<String, dynamic>? portsFor(String workspaceId, String rigId) =>
      _ports.snapshotFor(workspaceId, rigId)?.toWire();

  @override
  Stream<Map<String, dynamic>> watchPorts(String workspaceId, String rigId) =>
      _ports.watch(workspaceId, rigId).map((s) => s.toWire());

  @override
  Future<bool> setPortsAutoForward(
    String workspaceId,
    String rigId, {
    required bool enabled,
  }) => _ports.setAutoForward(workspaceId, rigId, enabled: enabled);

  @override
  Future<bool> addPortForward(
    String workspaceId,
    String rigId,
    int guestPort,
  ) async {
    final ok = await _ports.addForward(workspaceId, rigId, guestPort);
    if (ok) {
      await _touchById(rigId, workspaceId);
    }
    return ok;
  }

  @override
  Future<bool> removePortForward(
    String workspaceId,
    String rigId,
    int guestPort,
  ) => _ports.removeForward(workspaceId, rigId, guestPort);

  @override
  Future<bool> setPortLanExposed(
    String workspaceId,
    String rigId,
    int guestPort, {
    required bool exposed,
  }) => _ports.setLanExposed(workspaceId, rigId, guestPort, exposed: exposed);

  @override
  Future<bool> setPortDomain(
    String workspaceId,
    String rigId,
    int guestPort,
    String? domain,
  ) => _ports.setDomain(workspaceId, rigId, guestPort, domain);

  Future<void> _touchById(String rigId, String workspaceId) async {
    final live = _live[rigId];
    if (live != null && live.rig.workspaceId == workspaceId) {
      await _touch(live);
    }
  }

  // ── Internals ───────────────────────────────────────────────────────────

  Future<void> _boot(_LiveRig live) async {
    final rig = live.rig;
    try {
      switch (rig.backend) {
        case EnclosureBackend.androidEmulator:
          await _bootMobile(live);
        case EnclosureBackend.smolvm:
          await _bootSmolvm(live);
        case EnclosureBackend.qemuHvf:
        case EnclosureBackend.qemuKvm:
        case EnclosureBackend.qemuTcg:
          await _bootQemu(live);
      }
    } on Object catch (e, st) {
      CcInfraLog.error('rig/${rig.id}: boot failed: $e', e, st);
      await _updateStatus(live, RigFailed('$e'));
      // A failed boot must release everything it took, or a host that cannot
      // start rigs slowly fills with half-built ones.
      await _teardown(live, RigCloseReason.backendFailure, alreadyFailed: true);
    }
  }

  /// Whether the rig this boot is building has already been torn down.
  ///
  /// Three ways it can be: an explicit close, `disposeAll`, or the entry being
  /// replaced in `_live`. All three mean the same thing — nothing holds this
  /// object any more, so anything the boot produces from here on is the boot's
  /// own to release.
  bool _bootAborted(_LiveRig live) =>
      live.closing || _disposed || !_isCurrent(live);

  Future<void> _bootQemu(_LiveRig live) async {
    final rig = live.rig;
    // Published BEFORE the first await so a teardown arriving at any point
    // during the launch has something to wait on.
    final launched = Completer<void>();
    live.launched = launched.future;
    final QemuMachine machine;
    try {
      machine = await _qemu.launch(
        rigId: rig.id,
        spec: rig.spec,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      );
      if (_bootAborted(live)) {
        // The close landed while QEMU was starting. Assigning the machine now
        // would hand it to an object nobody holds: the hypervisor and its
        // egress proxies would run, unreferenced, until the next server start
        // swept them. Destroy it here — teardown is waiting on `launched`
        // precisely so this happens before it returns.
        await _discardMachine(rig.id, machine);
        return;
      }
      live.machine = machine;
    } finally {
      // Completed on every exit, including the throw: teardown awaits this,
      // and a failed launch that never completes it would hang a close.
      if (!launched.isCompleted) {
        launched.complete();
      }
    }

    // Watch the machine's death sentinel (the hypervisor itself on QEMU).
    _watchMachineDeath(live, machine);

    _credentials?.registerRig(
      rigId: rig.id,
      workspaceId: rig.workspaceId,
      conversationId: rig.conversationId ?? rig.id,
      secret: machine.guestSecret,
      // The rig's OWN capabilities, not a default: with
      // `AgentCapabilities.safeDefault` the broker mints nothing and every
      // request is refused, which is the right floor for an agent-opened rig.
      // A terminal rig carries the operator's capabilities, which is what
      // makes `git push` work there and nowhere else.
      capabilities: rig.spec.capabilities,
      repoOwner: rig.spec.repoOwner,
      repoName: rig.spec.repoName,
      // The credential allowlist and the egress allowlist are one policy: a
      // host the guest cannot reach must never be one we hand it a token for.
      // Note the direction of the implication — being reachable does NOT by
      // itself grant a credential; `capabilities` above is what does.
      allowedHosts: rig.spec.egressAllowlist
          .where((h) => !h.startsWith('*'))
          .toSet(),
    );

    if (rig.spec.worktreePath != null) {
      final sync = WorktreeSync(
        sshPort: machine.sshPort,
        privateKeyPath: machine.privateKeyPath,
      );
      // The shell is usable before the worktree lands; the status line says
      // which stage it is in rather than making the user wait on a blank panel
      // while a multi-gigabyte repo copies.
      final result = await sync.syncIn(
        hostPath: rig.spec.worktreePath!,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      );
      if (!result.ok) {
        CcInfraLog.warning('rig/${rig.id}: ${result.message}');
      }
    }

    // QEMU boots exactly one surface now: the desktop. Browser rigs are
    // smolvm's — a headless Chromium behind a forwarded CDP port needs no
    // display device, and the microVM boots it in a fraction of the time.
    final driver = ComputerRigDriver(machine);
    if (_bootAborted(live)) {
      // Teardown already read `driver` (it was null then) and destroyed the
      // machine, so this one — and the DevTools socket a browser driver holds
      // — is ours to close. The check and the assignment below share a turn,
      // so exactly one side owns it.
      await driver.dispose();
      return;
    }
    live.driver = driver;

    live.rig = live.rig.copyWith(
      status: const RigReady(),
      display: machine.display,
      readyAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
    await _repository.save(rig.workspaceId, live.rig);
    _eventBus?.publish(
      RigOpened(
        workspaceId: rig.workspaceId,
        rigId: rig.id,
        surface: rig.surface,
        openedBy: rig.createdBy,
        conversationId: rig.conversationId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  Future<CdpClient> _attachBrowser(SmolvmMachine machine) async {
    final port = machine.devtoolsPort;
    if (port == null) {
      throw StateError('The browser rig has no forwarded DevTools port.');
    }
    final cdp = await CdpClient.attachToFirstPage(
      host: '127.0.0.1',
      port: port,
      // Longer than the default: the backend's readiness wait already covered
      // the cold-start image pull, but a slow launch still has to come up
      // before the endpoint answers.
      timeout: const Duration(seconds: 75),
    );
    await cdp.enableDomains();
    return cdp;
  }

  /// Watches the machine's death sentinel and fails the rig when it drops.
  ///
  /// On QEMU the sentinel IS the hypervisor process; on smolvm it is the held
  /// `machine exec` connection (the CLI spawns the VMM detached). Either way
  /// a machine that dies on its own otherwise leaves a `ready` row whose
  /// stream and actions all fail while the panel keeps promising a machine.
  /// A normal destroy also resolves this future, but by then teardown has
  /// removed the rig from `_live` and `_isCurrent` is false.
  void _watchMachineDeath(_LiveRig live, RigMachine machine) {
    unawaited(
      machine.process.exitCode.then((code) async {
        if (!_isCurrent(live)) {
          return;
        }
        CcInfraLog.warning(
          'rig/${live.rig.id}: machine exited unexpectedly (code $code)',
        );
        await _updateStatus(
          live,
          RigFailed('The virtual machine exited unexpectedly (code $code).'),
        );
        await _teardown(
          live,
          RigCloseReason.backendFailure,
          alreadyFailed: true,
        );
      }),
    );
  }

  Future<void> _bootSmolvm(_LiveRig live) async {
    final rig = live.rig;
    // Published BEFORE the first await, mirroring _bootQemu, so a teardown
    // arriving mid-launch has something to wait on.
    final launched = Completer<void>();
    live.launched = launched.future;
    // The workspace's own image, when configured. Failure to READ the
    // setting degrades to the default image: a settings store hiccup must
    // not stop terminals from opening.
    String? imageOverride;
    try {
      imageOverride = await _smolvmImageOverride?.call(
        rig.workspaceId,
        exec: rig.spec.isExec,
      );
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/${rig.id}: could not read the workspace image override: $e',
      );
    }
    final SmolvmMachine machine;
    try {
      machine = await _smolvm.launch(
        rigId: rig.id,
        spec: rig.spec,
        imageOverride: imageOverride,
        onProgress: (step) =>
            unawaited(_updateStatus(live, RigProvisioning(step: step))),
      );
      if (_bootAborted(live)) {
        await _discardMachine(rig.id, machine);
        return;
      }
      live.machine = machine;
    } finally {
      if (!launched.isCompleted) {
        launched.complete();
      }
    }

    _watchMachineDeath(live, machine);

    _credentials?.registerRig(
      rigId: rig.id,
      workspaceId: rig.workspaceId,
      conversationId: rig.conversationId ?? rig.id,
      secret: machine.guestSecret,
      // Same floor as the QEMU path: the rig's OWN capabilities, so an
      // agent-opened rig mints nothing by default.
      capabilities: rig.spec.capabilities,
      repoOwner: rig.spec.repoOwner,
      repoName: rig.spec.repoName,
      // The credential allowlist and the egress allowlist are one policy: a
      // host the guest cannot reach must never be one we hand it a token for.
      allowedHosts: rig.spec.egressAllowlist
          .where((h) => !h.startsWith('*'))
          .toSet(),
    );

    if (rig.spec.worktreePath != null) {
      final binary = _smolvm.resolvedBinary;
      if (binary != null) {
        final sync = WorktreeSync.smolvm(
          smolvmPath: binary,
          machineName: machine.name,
        );
        final result = await sync.syncIn(
          hostPath: rig.spec.worktreePath!,
          onProgress: (step) =>
              unawaited(_updateStatus(live, RigProvisioning(step: step))),
        );
        if (!result.ok) {
          CcInfraLog.warning('rig/${rig.id}: ${result.message}');
        }
      }
    }

    if (rig.surface == RigSurface.browser) {
      final driver = BrowserRigDriver(
        cdp: await _attachBrowser(machine),
        viewport: rig.spec.display,
        onUrlChanged: (url) => unawaited(_browserNavigated(live, url)),
      );
      if (_bootAborted(live)) {
        await driver.dispose();
        return;
      }
      live.driver = driver;
      // The home page loaded BEFORE the driver attached, so no navigation
      // event will ever name it — seed the tracker with where the page is.
      unawaited(driver.seedCurrentUrl());
    }
    // An exec rig deliberately gets NO driver: there is no surface to drive,
    // and `act` says so rather than pretending a terminal can take a click.

    // Re-checked after every await above (the worktree sync alone can take
    // minutes): a close that landed mid-boot already wrote the closed row and
    // destroyed the machine, and saving `ready` over it here would resurrect
    // a rig the panel can never act on.
    if (_bootAborted(live)) {
      return;
    }

    // Ports: discovery + forwarding for the terminal machine, and the
    // guest-loopback listeners that let a browser rig in the same
    // conversation reach its forwarded ports as `localhost:<port>`.
    final muxPort = machine.portMuxHostPort;
    if (muxPort != null) {
      _ports.attachExec(
        rigId: rig.id,
        workspaceId: rig.workspaceId,
        machineName: machine.name,
        muxHostPort: muxPort,
        conversationId: rig.conversationId,
        brokerPort: _smolvm.credentialPort,
      );
    } else if (rig.surface == RigSurface.browser) {
      _ports.attachBrowser(
        rigId: rig.id,
        workspaceId: rig.workspaceId,
        machineName: machine.name,
        conversationId: rig.conversationId,
      );
    }

    live.rig = live.rig.copyWith(
      status: const RigReady(),
      display: machine.display,
      readyAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
    await _repository.save(rig.workspaceId, live.rig);
    _eventBus?.publish(
      RigOpened(
        workspaceId: rig.workspaceId,
        rigId: rig.id,
        surface: rig.surface,
        openedBy: rig.createdBy,
        conversationId: rig.conversationId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  Future<void> _bootMobile(_LiveRig live) async {
    final rig = live.rig;
    await _updateStatus(live, const RigProvisioning(step: 'Finding a device'));
    final adbPath = await AdbClient.locate();
    if (adbPath == null) {
      throw StateError(
        'adb is not installed, so the mobile surface is unavailable. Install '
        'the Android platform tools and start an emulator.',
      );
    }
    final devices = await AdbClient.devices(adbPath);
    if (devices.isEmpty) {
      throw StateError(
        'No Android device is attached. Start an emulator, then open the rig '
        'again.',
      );
    }
    // The serial is chosen ONCE and pinned for the rig's whole life. Every
    // later command carries `-s <serial>` and `ensureReady` re-checks it, so a
    // device that disconnects is reported rather than silently swapped for
    // whichever one ADB would have picked next.
    final adb = AdbClient(
      serial: devices.first,
      adbPath: adbPath,
      apkRoots: [
        if (rig.spec.worktreePath != null) rig.spec.worktreePath!,
        if (_dataDir != null) _dataDir,
      ],
    );
    final booted = await adb.awaitBoot(
      onProgress: (step) =>
          unawaited(_updateStatus(live, RigProvisioning(step: step))),
    );
    if (!booted) {
      throw StateError('The device never finished booting.');
    }
    final size = await adb.screenSize();
    final display = size == null
        ? RigDisplaySize.defaultMobile
        : RigDisplaySize(size.$1, size.$2);
    if (_bootAborted(live)) {
      // No machine of ours to leak here — the emulator was already running and
      // outlives the rig — but publishing `RigOpened` and a `ready` row for a
      // session that was closed while `awaitBoot` ran would leave the panel
      // showing a device it can never act on.
      return;
    }
    live.driver = MobileRigDriver(adb: adb, size: display);
    live.rig = live.rig.copyWith(
      status: const RigReady(),
      display: display,
      readyAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );
    await _repository.save(rig.workspaceId, live.rig);
    _eventBus?.publish(
      RigOpened(
        workspaceId: rig.workspaceId,
        rigId: rig.id,
        surface: rig.surface,
        openedBy: rig.createdBy,
        conversationId: rig.conversationId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  _LiveRig _requireLive(String workspaceId, String rigId) {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      // NotFound, not Forbidden, and the two cases are deliberately
      // indistinguishable: telling a caller that a rig exists but belongs to
      // someone else is enough to enumerate another workspace's machines. The
      // RPC layer maps this to `notFound`, which clients treat as terminal.
      throw NotFoundException('Rig $rigId is not open in this workspace.');
    }
    return live;
  }

  _LiveRig? _reusableFor(String workspaceId, RigSpec spec) {
    final conversationId = spec.conversationId;
    if (conversationId == null) {
      return null;
    }
    for (final live in _live.values) {
      if (live.rig.workspaceId == workspaceId &&
          live.rig.conversationId == conversationId &&
          live.rig.surface == spec.surface &&
          // An exec rig and a `computer_use` rig share the `computer` surface
          // and can share a conversation, but the exec image is a shell with
          // no display server. Reusing one for the other would hand the agent
          // a machine it cannot see, and the failure would look like a broken
          // screenshot rather than the wrong machine.
          live.rig.spec.isExec == spec.isExec &&
          // `holdsMachine`, not `isLive`: a rig that is still booting already
          // owns a VM, and matching only live ones makes every "still
          // starting, try again" retry boot another one.
          live.rig.status.phase.holdsMachine) {
        return live;
      }
    }
    return null;
  }

  /// Whether [live] is still the registered session for its id.
  ///
  /// Teardown removes from `_live` FIRST and then awaits several teardown
  /// steps, so an in-flight `act()` or boot step can still be holding this
  /// object. Writing its status after that point would save `ready` over the
  /// `closed` row teardown just wrote, leaving a rig the UI shows as running
  /// forever with no machine, no `_live` entry and no way to act on it —
  /// until the next server start reconciles it.
  bool _isCurrent(_LiveRig live) => identical(_live[live.rig.id], live);

  Future<void> _updateStatus(_LiveRig live, RigStatus status) async {
    if (!_isCurrent(live)) {
      return;
    }
    live.rig = live.rig.copyWith(status: status);
    await _repository.save(live.rig.workspaceId, live.rig);
  }

  Future<void> _touch(_LiveRig live) async {
    if (!_isCurrent(live)) {
      return;
    }
    live.rig = live.rig.copyWith(lastActivityAt: DateTime.now());
    await _repository.save(live.rig.workspaceId, live.rig);
  }

  Future<void> _logAction({
    required _LiveRig live,
    required RigAction action,
    required Principal actor,
    required RigActionResult result,
    required int durationMs,
  }) async {
    // The image bytes are NOT stored — a hash is, so a retained agent-lane
    // still can be joined back to the action that produced it without the
    // audit table carrying megabytes of base64 per row.
    final imageHash = result.imageBase64 == null
        ? null
        : sha256.convert(utf8.encode(result.imageBase64!)).toString();
    final audit = _auditPayload(action);
    await _logRaw(
      live: live,
      verb: action.verb,
      args: audit.args,
      summary: audit.summary,
      actor: actor,
      resultText: result.text,
      isError: result.isError,
      imageHash: imageHash,
      durationMs: durationMs,
    );
  }

  /// Appends one audit row.
  ///
  /// Takes the already-redacted pieces rather than a [RigAction], because the
  /// clipboard and file lanes have no action to derive them from — an exec
  /// rig has no verb vocabulary at all, and the bytes those lanes carry must
  /// never reach [_auditPayload]'s argument map in the first place. Their
  /// callers pass a SHAPE ("2 files", "48 characters"); this writes it down.
  Future<void> _logRaw({
    required _LiveRig live,
    required String verb,
    required Map<String, dynamic> args,
    required String summary,
    required Principal actor,
    required String resultText,
    required bool isError,
    required int durationMs,
    String? imageHash,
  }) async {
    try {
      await _repository.appendAction(
        live.rig.workspaceId,
        RigActionLogEntry(
          id: _uuid.v4(),
          workspaceId: live.rig.workspaceId,
          rigId: live.rig.id,
          seq: 0, // Allocated inside the repository's transaction.
          verb: verb,
          args: _capArgs(args, verb),
          summary: summary,
          actor: actor,
          isTakeOver: actor.isUser && live.rig.controller?.wire == actor.wire,
          isError: isError,
          resultText: resultText.length > 500
              ? '${resultText.substring(0, 500)}…'
              : resultText,
          imageHash: imageHash,
          durationMs: durationMs,
          createdAt: DateTime.now(),
        ),
      );
    } on Object catch (e) {
      // An audit write that fails must not fail the action the user already
      // performed, but it must be loud: an unlogged action is exactly what the
      // log exists to prevent.
      CcInfraLog.error('rig/${live.rig.id}: action log write failed: $e', e);
    }
  }

  /// Verbs whose `text` is a key COMBINATION rather than content.
  ///
  /// `ctrl+s` is precisely what the audit exists to record, and it is a name,
  /// not something anybody types a secret into.
  static const Set<String> _keyComboVerbs = {'key', 'hold_key'};

  /// How much serialized argument JSON one row may carry.
  static const int _maxArgsChars = 4096;

  /// What [action] looks like once it is safe to persist.
  ///
  /// `type` and `fill` carry whatever was typed, and the take-over path sends
  /// a human's keystrokes as `type`: without this a person taking control to
  /// enter a password writes it in plaintext into the workspace database,
  /// where it outlives the rig by the retention window. Agents get the same
  /// treatment — an agent pasting a token is the same leak with a different
  /// author.
  ///
  /// It happens HERE because this is the single chokepoint every action passes
  /// through on its way to storage, so a verb added later is covered by
  /// construction rather than by remembering. The length and the hash keep the
  /// questions an audit actually asks answerable ("was something typed here?",
  /// "was it the same string twice?") without keeping the string. The hash is
  /// NOT a defence for a short text: one `type` per character means many
  /// one-character hashes, and those are brute-forced instantly.
  ///
  /// The summary is redacted with it. It sits in the next column and quotes
  /// the same text, so leaving it would make the argument redaction
  /// decorative.
  ({Map<String, dynamic> args, String summary}) _auditPayload(
    RigAction action,
  ) {
    final args = Map<String, dynamic>.of(action.toJson());
    var summary = action.summary;
    final text = args['text'];
    if (!_keyComboVerbs.contains(action.verb) &&
        text is String &&
        text.isNotEmpty) {
      args['text'] = {
        'textLength': text.length,
        'textSha256': sha256.convert(utf8.encode(text)).toString(),
      };
      summary = _redactQuoted(summary, text.length);
    }
    return (args: _capArgs(args, action.verb), summary: summary);
  }

  /// Replaces the quoted preview in [summary] with a length note.
  ///
  /// Every summary that quotes anything quotes exactly the text just redacted
  /// (`Typed "hunter2"`, `Filled #pw with "hunter2"`), so dropping what lies
  /// between the first and the last quote keeps the part that carries the
  /// audit — the verb, the selector — and loses the part that carries the
  /// secret.
  static String _redactQuoted(String summary, int length) {
    final first = summary.indexOf('"');
    final last = summary.lastIndexOf('"');
    if (first < 0 || last <= first) {
      return summary;
    }
    return '${summary.substring(0, first)}$length '
        '${length == 1 ? 'character' : 'characters'} (hidden)'
        '${summary.substring(last + 1)}';
  }

  /// Caps one row's arguments. A `navigate` URL is caller-supplied and
  /// unbounded, and a log row that costs a megabyte is a payload store rather
  /// than an audit trail.
  static Map<String, dynamic> _capArgs(Map<String, dynamic> args, String verb) {
    final encoded = jsonEncode(args);
    if (encoded.length <= _maxArgsChars) {
      return args;
    }
    return {'action': verb, 'argsTruncated': true, 'argsChars': encoded.length};
  }

  /// Destroys a machine that finished booting into a rig nobody holds.
  Future<void> _discardMachine(String rigId, RigMachine machine) async {
    CcInfraLog.warning(
      'rig/$rigId: closed while booting — destroying the machine that arrived '
      'after it',
    );
    try {
      await _destroyMachine(machine);
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/$rigId: destroy of an orphaned machine failed: $e',
      );
    }
  }

  /// Destroys [machine], whichever hypervisor owns it.
  Future<void> _destroyMachine(RigMachine machine) async {
    switch (machine) {
      case QemuMachine():
        await _qemu.destroy(machine);
      case SmolvmMachine():
        await _smolvm.destroy(machine);
    }
  }

  /// Parks [machine], whichever hypervisor owns it.
  Future<void> _parkMachine(RigMachine machine) async {
    switch (machine) {
      case QemuMachine():
        await _qemu.park(machine);
      case SmolvmMachine():
        await _smolvm.park(machine);
    }
  }

  /// Wakes a parked machine, whichever hypervisor owns it, and marks the rig
  /// ready again. A no-op when nothing is parked.
  Future<void> _wakeMachine(_LiveRig live) async {
    final machine = live.machine;
    if (machine == null || !machine.parked) {
      return;
    }
    switch (machine) {
      case QemuMachine():
        await _qemu.wake(machine);
      case SmolvmMachine():
        await _smolvm.wake(machine);
    }
    await _updateStatus(live, const RigReady());
  }

  /// Persists a browser rig's current URL as the page itself reports it.
  ///
  /// The push matters more than the row: `rig.watchSessions` re-emits on the
  /// save, which is how the address bar learns about a link the PERSON
  /// clicked in the canvas — no act() call carries that navigation.
  /// How often a browser rig's URL may be written to its row.
  ///
  /// The same 1 s discipline pointer moves already use, and for the same
  /// reason: a redirect chain (or a page that rewrites its own hash on scroll)
  /// fires several navigations in a few hundred milliseconds, and every one of
  /// them was a write on the server's ONE shared database connection with
  /// every RPC read queued behind it.
  static const Duration _urlWriteInterval = Duration(seconds: 1);

  Future<void> _browserNavigated(_LiveRig live, String url) async {
    if (!_isCurrent(live) || live.rig.currentUrl == url) {
      return;
    }
    // The in-memory row updates immediately — `browserState` and the panel
    // read it, and being a second stale there would be worse than the write
    // cost. Only the PERSIST is throttled.
    live.rig = live.rig.copyWith(currentUrl: url);
    live.pendingUrlWrite = true;
    final now = DateTime.now();
    if (now.difference(live.lastUrlWrite) < _urlWriteInterval) {
      // Land the final URL of a burst even if nothing navigates again.
      live.urlWriteTimer ??= Timer(_urlWriteInterval, () {
        live.urlWriteTimer = null;
        unawaited(_flushUrl(live));
      });
      return;
    }
    await _flushUrl(live);
  }

  Future<void> _flushUrl(_LiveRig live) async {
    if (!_isCurrent(live) || !live.pendingUrlWrite) {
      return;
    }
    live.pendingUrlWrite = false;
    live.lastUrlWrite = DateTime.now();
    try {
      await _repository.save(live.rig.workspaceId, live.rig);
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/${live.rig.id}: could not record the page URL: $e',
      );
    }
  }

  @override
  Future<RigBrowserState?> browserState({
    required String workspaceId,
    required String rigId,
  }) async {
    final live = _live[rigId];
    if (live == null || live.rig.workspaceId != workspaceId) {
      return null;
    }
    final driver = live.driver;
    if (driver is! BrowserRigDriver) {
      return null;
    }
    // A parked machine's vCPUs are stopped: a CDP read against it would hang
    // the caller until the socket's timeout. The parked page is not moving,
    // so the last known URL IS the state — back/forward stay unavailable
    // until an action wakes the machine.
    if (live.machine?.parked ?? false) {
      return RigBrowserState(
        url: live.rig.currentUrl ?? '',
        canGoBack: false,
        canGoForward: false,
      );
    }
    return driver.navState();
  }

  Future<void> _teardown(
    _LiveRig live,
    RigCloseReason reason, {
    bool alreadyFailed = false,
  }) async {
    if (live.closing) {
      // Exactly once. `close()` racing the hypervisor-exit watcher, or a
      // second reaper pass over an entry the first one is still tearing down,
      // must not destroy a machine twice or publish a second close event.
      return;
    }
    // Set before the first await: it is what tells an in-flight boot that the
    // machine it is about to produce belongs to nobody.
    live.closing = true;
    // A pending URL write must not outlive the rig: its timer would fire
    // against a row this teardown is about to close.
    live.urlWriteTimer?.cancel();
    live.urlWriteTimer = null;
    live.pendingUrlWrite = false;
    _live.remove(live.rig.id);
    // A close that lands mid-boot has nothing to destroy YET. Wait for the
    // launch to hand its machine over — bounded, because a launch can take
    // minutes and an RPC caller cannot. On expiry the machine is still not
    // orphaned: the boot path re-reads `closing` and destroys it itself. Only
    // this call's knowledge of it is lost.
    final launched = live.launched;
    if (launched != null) {
      try {
        await launched.timeout(const Duration(seconds: 30));
      } on Object catch (e) {
        CcInfraLog.warning(
          'rig/${live.rig.id}: boot did not settle before teardown ($e); the '
          'boot path will destroy the machine when it lands',
        );
      }
    }
    try {
      await live.driver?.dispose();
    } on Object catch (e) {
      // A driver that throws on dispose must not keep the hypervisor below it
      // alive: the machine is the expensive half.
      CcInfraLog.warning('rig/${live.rig.id}: driver dispose failed: $e');
    }
    try {
      // Bridges, reverse tunnels and domain routes die with the rig. A host
      // listener whose guest is gone is a port that answers with nothing.
      await _ports.detach(live.rig.id);
    } on Object catch (e) {
      CcInfraLog.warning('rig/${live.rig.id}: ports detach failed: $e');
    }
    await _credentials?.unregisterRig(live.rig.id);
    final machine = live.machine;
    if (machine != null) {
      try {
        await _destroyMachine(machine);
      } on Object catch (e) {
        CcInfraLog.warning('rig/${live.rig.id}: destroy failed: $e');
      }
    }
    if (!alreadyFailed) {
      live.rig = live.rig.copyWith(
        status: RigClosed(reason),
        closedAt: DateTime.now(),
      );
      await _repository.save(live.rig.workspaceId, live.rig);
    }
    _eventBus?.publish(
      RigClosedEvent(
        workspaceId: live.rig.workspaceId,
        rigId: live.rig.id,
        reason: reason,
        occurredAt: DateTime.now(),
      ),
    );
    CcInfraLog.info('rig/${live.rig.id}: closed (${reason.wire})');
  }

  /// Parks idle rigs, closes long-idle and expired ones.
  Future<void> _reap() async {
    if (_disposed) {
      return;
    }
    final now = DateTime.now();
    for (final live in _live.values.toList()) {
      final rig = live.rig;
      try {
        if (rig.isExpired(now)) {
          await _teardown(live, RigCloseReason.ttlExpired);
          _publishReaped(rig, RigCloseReason.ttlExpired);
          continue;
        }
        if (live.isInUse) {
          // Somebody has a terminal open or is watching the guest. The hard
          // TTL above still applies — a pin cannot make a rig immortal — but
          // idling it out from under a live consumer is what this exists to
          // prevent.
          continue;
        }
        final idleFor = now.difference(rig.lastActivityAt);
        if (idleFor > rig.spec.idleTimeout * 2) {
          await _teardown(live, RigCloseReason.idleTimeout);
          _publishReaped(rig, RigCloseReason.idleTimeout);
          continue;
        }
        if (idleFor > rig.spec.idleTimeout &&
            live.machine != null &&
            !live.machine!.parked) {
          // Park first, close later. Parking costs the user nothing (the next
          // action wakes it) and buys back the CPU; closing costs them their
          // machine, so it waits for twice the idle window.
          await _parkMachine(live.machine!);
          await _updateStatus(live, const RigParked());
          CcInfraLog.info(
            'rig/${rig.id}: parked after ${idleFor.inMinutes}m idle',
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('rig/${rig.id}: reap step failed: $e');
      }
    }
  }

  void _publishReaped(Rig rig, RigCloseReason reason) {
    _eventBus?.publish(
      RigReaped(
        workspaceId: rig.workspaceId,
        rigId: rig.id,
        reason: reason,
        agentId: rig.agentId,
        occurredAt: DateTime.now(),
      ),
    );
  }

  /// Frees memory until `wantedMb` fits under the budget.
  ///
  /// Callers go through [_reserveResident], which holds a lock across this and
  /// the reservation that follows it.
  ///
  /// The budget counts RESIDENT megabytes, not sessions. A parked VM has
  /// stopped vCPUs and still holds every byte of its RAM, so counting sessions
  /// would let eight parked 2 GB desktops sit on 16 GB of a laptop and call it
  /// idle.
  /// Serialises budget check + reservation. See [_reserveResident].
  Future<void> _budgetGate = Future<void>.value();

  /// Committed megabytes right now: every live machine plus every reservation
  /// an in-flight open is holding.
  int get _committedMb =>
      _live.values.fold<int>(0, (sum, l) => sum + l.residentMb) + _reservedMb;

  /// Makes room for [wantedMb] and RESERVES it, atomically.
  ///
  /// The check and the reservation have to happen under one lock because the
  /// check itself awaits evictions. Split, two concurrent opens for different
  /// conversations both read a total that excluded the other, both passed, and
  /// the host committed twice its budget — the `_opening` join only dedupes
  /// the same conversation and kind, so it never saw them.
  ///
  /// Throws (and reserves nothing) when even after evicting everything
  /// evictable there is not enough room.
  Future<void> _reserveResident(int wantedMb) {
    final previous = _budgetGate;
    final done = Completer<void>();
    _budgetGate = done.future;
    return previous.then((_) async {
      try {
        await _enforceResidentBudget(wantedMb);
        _reservedMb += wantedMb;
      } finally {
        // Released whatever happened: a failed reservation must not wedge
        // every later open behind a gate that never opens.
        done.complete();
      }
    });
  }

  Future<void> _enforceResidentBudget(int wantedMb) async {
    if (_committedMb + wantedMb <= _maxResidentMb) {
      return;
    }
    // Evict least-recently-used first, and never evict one a human is driving.
    final candidates = _live.values.toList()
      ..sort((a, b) => a.rig.lastActivityAt.compareTo(b.rig.lastActivityAt));
    for (final live in candidates) {
      if (_committedMb + wantedMb <= _maxResidentMb) {
        return;
      }
      // Never evict one somebody is driving, has a terminal in, or is
      // watching: reclaiming memory from under an open viewer trades a
      // measurable resource for an unexplainable disappearance.
      if (live.rig.isHumanControlled || live.isInUse) {
        continue;
      }
      CcInfraLog.info(
        'rig/${live.rig.id}: evicting to make room '
        '(${_committedMb}MB committed, ${_maxResidentMb}MB budget)',
      );
      // Recomputed from `_live` AFTER the teardown rather than deducted
      // before it: `_teardown` is what removes the entry, so a running tally
      // decremented up front counted memory as reclaimed while the eviction
      // was still in flight.
      await _teardown(live, RigCloseReason.idleTimeout);
      _publishReaped(live.rig, RigCloseReason.idleTimeout);
    }
    if (_committedMb + wantedMb > _maxResidentMb) {
      throw StateError(
        'Not enough memory budget for a ${wantedMb}MB rig: ${_committedMb}MB '
        'of ${_maxResidentMb}MB is already committed to rigs a person is '
        'using. Close one first.',
      );
    }
  }

  /// Marks sessions the previous process left behind as failed.
  ///
  /// Their machines died with that process, so a row still saying `ready` is a
  /// promise nothing can keep — and the panel would spin forever waiting for a
  /// VM that does not exist.
  Future<void> _markStrandedSessionsFailed() async {
    try {
      final stranded = await _repository.listAllLive();
      for (final rig in stranded) {
        await _repository.save(
          rig.workspaceId,
          rig.copyWith(
            status: const RigFailed(
              'The server restarted while this rig was running, so the machine '
              'is gone. Open a new one.',
            ),
            closedAt: DateTime.now(),
          ),
        );
      }
      if (stranded.isNotEmpty) {
        CcInfraLog.info(
          'rig: marked ${stranded.length} stranded session(s) failed after '
          'restart',
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('rig: could not reconcile stranded sessions: $e');
    }
  }

  /// The image store, exposed for the settings surface.
  RigImageStore get images => _images;

  @override
  List<Map<String, dynamic>> imageStatuses() => _images.statusesToJson();

  /// Downloads in flight, keyed by image id, so a second request joins the
  /// first instead of racing it onto the same `.part` file.
  final Map<String, Future<void>> _downloads = {};

  @override
  Future<void> downloadImage(String imageId) async {
    final spec = _images.byId(imageId);
    if (spec == null) {
      throw RigImageException('No base image "$imageId" is catalogued.');
    }
    // Kicked off and NOT awaited. A base image is ~590 MB, so this runs for
    // minutes; awaiting it here held the caller's RPC call open for the whole
    // download, which is what the drain below was written to avoid and did
    // not. Progress is observable through `rig.images` (the partial size on
    // disk), which is how the settings UI already renders it.
    _downloads[imageId] ??= _runDownload(imageId, spec).whenComplete(() {
      _downloads.remove(imageId);
    });
  }

  Future<void> _runDownload(String imageId, RigImageSpec spec) async {
    try {
      await for (final progress in _images.download(spec)) {
        if (progress.stage == 'verifying') {
          CcInfraLog.info('rig/images: verifying $imageId');
        }
      }
      // A new image can change which surfaces are offered, so the cached probe
      // is now stale.
      await refreshProbe();
      CcInfraLog.info('rig/images: $imageId is installed');
    } on Object catch (e) {
      // Nobody is awaiting this any more, so an unreported failure would be a
      // download that simply never appears. The store discards a failed
      // download's `.part`, so `rig.images` goes back to "not downloaded" and
      // the log says why.
      CcInfraLog.warning('rig/images: download of $imageId failed: $e');
    }
  }

  /// Waits for an in-flight [downloadImage] to finish. Tests only — production
  /// callers observe progress through `rig.images`.
  @visibleForTesting
  Future<void> debugAwaitDownload(String imageId) async {
    await _downloads[imageId];
  }

  @override
  Future<void> importImage({
    required String imageId,
    required String sourcePath,
  }) async {
    final spec = _images.byId(imageId);
    if (spec == null) {
      throw RigImageException('No base image "$imageId" is catalogued.');
    }
    await _images.importFrom(spec, sourcePath).drain<void>();
    await refreshProbe();
  }

  /// Registers [rig] as live WITHOUT booting a machine.
  ///
  /// The bookkeeping this class does — reuse matching, take-over exclusion,
  /// pins, the reaper — is where its bugs live, and none of it needs a
  /// hypervisor. Without this seam those paths can only be exercised by
  /// booting a real VM, which is why they had no tests and why several of
  /// them were wrong.
  ///
  /// [driver] is what makes the paths BEHIND the driver check reachable: the
  /// action log and the watch lane both return early without one, so the
  /// redaction and the lane counting are otherwise untestable.
  @visibleForTesting
  void debugRegister(Rig rig, {RigDriver? driver}) {
    _live[rig.id] = _LiveRig(rig: rig)..driver = driver;
  }

  /// Runs one reaper pass immediately.
  @visibleForTesting
  Future<void> debugReap() => _reap();
}
