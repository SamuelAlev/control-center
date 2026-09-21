// Orchestrates port visibility + forwarding across a conversation's terminals
// and destinations.
//
// One instance per server, owned by `RigService`. EXEC: polls guest listeners,
// auto-opens host loopback bridges, keeps the panel stream current.
// HOST-SHELL: polls that session's PTY process tree only. BROWSER: plants
// guest-loopback listeners and Host-header routes for `myapp.test`. ANDROID:
// `adb reverse`. Mechanism lives in `rig_ports.dart`; this file is policy.
// Maps are per space (`workspaceId` + `conversationId`); a null conversation
// never broadcasts.

import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/host_shell_listeners.dart';
import 'package:cc_infra/src/rigs/reverse_mux.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart';
import 'package:meta/meta.dart';

/// Runs one shell command inside a guest and captures the result.
typedef RigGuestRun =
    Future<ProcessResult> Function(String machineName, String shellCommand);

/// Starts one interactive (stdio-wired) process inside a guest.
typedef RigGuestStart =
    Future<Process> Function(String machineName, List<String> guestArgv);

/// Lists TCP listeners whose pid sits in a host-shell PTY's process tree.
typedef RigHostTreeListen = Future<List<RigOpenPort>> Function(int rootPid);

/// Plants one `adb reverse tcp:devicePort tcp:hostPort`.
typedef RigAdbReverse =
    Future<void> Function({required int devicePort, required int hostPort});

/// Removes one `adb reverse` for a device port.
typedef RigAdbRemoveReverse = Future<void> Function(int devicePort);

/// The most guest ports auto-forwarded per rig. A dev stack is a handful of
/// listeners; dozens means something is scanning, and a bridge per scanned
/// port would turn the host into its amplifier.
const int kMaxAutoForwards = 16;

/// Guest ports never auto-forwarded and never shown: the port mux itself,
/// and the browser image's DevTools pair.
const Set<int> kNeverForwardPorts = {kRigPortMuxGuestPort, 9222, 9223};

/// Guest ports the DOMAIN lanes own inside a browser guest (HTTP and HTTPS).
/// A per-port tunnel on either would share the listener with the domain lane
/// (`reuseport` splits connections between them at random) and half of every
/// dev-domain request would be routed as if it were a plain port forward.
const Set<int> kBrowserDomainLanePorts = {80, 443};

class _ExecPorts {
  _ExecPorts({
    required this.rigId,
    required this.workspaceId,
    required this.conversationId,
    required this.machineName,
    required this.muxHostPort,
  });

  final String rigId;
  final String workspaceId;
  final String? conversationId;
  final String machineName;
  final int muxHostPort;

  bool autoForward = true;

  /// Ports the guest is currently listening on, from the last poll.
  Map<int, RigOpenPort> listening = {};

  /// Live bridges by guest port.
  final Map<int, HostPortBridge> bridges = {};

  /// Ports the user forwarded by hand (they persist while inactive).
  final Set<int> manual = {};

  /// Auto-forwards the user removed; suppressed until the guest port
  /// disappears (so "remove" does not respawn two polls later).
  final Set<int> dismissed = {};

  /// Dev domains by guest port.
  final Map<int, String> domains = {};

  /// Ports that belong to the plumbing, not the workload (the mux, the
  /// broker's reverse listener) — invisible to the panel.
  final Set<int> hiddenPorts = {...kNeverForwardPorts};

  GuestReverseTunnel? brokerTunnel;
  Timer? poll;
  bool polling = false;
  bool muxReady = false;
}

class _ShellPublished {
  _ShellPublished({
    required this.listenPort,
    required this.hostPort,
    required this.origin,
    this.process,
    this.active = true,
  });

  final int listenPort;
  int hostPort;
  RigPortOrigin origin;
  String? process;
  bool active;
  HostPortBridge? remap;
  HostLanRelay? lan;
  String? domain;
}

class _ShellPorts {
  _ShellPorts({
    required this.sessionId,
    required this.workspaceId,
    required this.conversationId,
    required this.rootPid,
  });

  final String sessionId;
  final String workspaceId;
  final String? conversationId;
  final int rootPid;

  bool autoForward = true;
  Map<int, RigOpenPort> listening = {};
  final Map<int, _ShellPublished> published = {};
  final Set<int> manual = {};
  final Set<int> dismissed = {};
  Timer? poll;
  bool polling = false;
}

class _BrowserPorts {
  _BrowserPorts({
    required this.rigId,
    required this.workspaceId,
    required this.conversationId,
    required this.machineName,
  });

  final String rigId;
  final String workspaceId;
  final String? conversationId;
  final String machineName;

  /// Reverse tunnels by guest port (the browser-side `localhost:<port>`).
  final Map<int, GuestReverseTunnel> tunnels = {};

  /// Dial identity per port (`mux:<rigId>:<guest>` or `host:<hostPort>`).
  /// Recreated when the kind changes so a space that gained an exec mux
  /// does not keep dialing the host-shell bind.
  final Map<int, String> dials = {};

  /// The guest :80 tunnel feeding the domain router's HTTP lane.
  GuestReverseTunnel? domainTunnel;

  /// The guest :443 tunnel feeding the domain router's HTTPS lane, when the
  /// host has TLS material.
  GuestReverseTunnel? domainTlsTunnel;
}

class _AndroidPorts {
  _AndroidPorts({
    required this.rigId,
    required this.workspaceId,
    required this.conversationId,
    required this.reverse,
    required this.removeReverse,
  });

  final String rigId;
  final String workspaceId;
  final String? conversationId;
  final RigAdbReverse reverse;
  final RigAdbRemoveReverse removeReverse;

  /// Device port → host port currently planted on this emulator.
  final Map<int, int> planted = {};
}

class _PortDial {
  const _PortDial.mux(this.sourceId, this.guestPort)
    : kind = 'mux',
      hostPort = null;

  const _PortDial.host(this.hostPort)
    : kind = 'host',
      sourceId = null,
      guestPort = null;

  final String kind;
  final String? sourceId;
  final int? guestPort;
  final int? hostPort;

  String get key =>
      kind == 'mux' ? 'mux:$sourceId:$guestPort' : 'host:$hostPort';
}

/// Discovers, forwards and publishes the open ports of enclosed rigs and
/// host-shell terminals.
class RigPortsService {
  /// Creates a [RigPortsService].
  ///
  /// [_tlsContext] supplies the dev-domain TLS material, resolved lazily when
  /// the first browser rig attaches. Null (or a provider returning null)
  /// leaves the HTTPS lane un-armed and dev domains route over plain HTTP.
  RigPortsService({
    required this._runInGuest,
    required this._startInGuest,
    this._tlsContext,
    this._pollInterval = const Duration(seconds: 4),
    RigHostTreeListen? listHostTreeListeners,
  }) : _listHostTreeListeners =
           listHostTreeListeners ?? discoverHostShellListeners {
    _router = RigDomainRouter(
      muxPortOf: (id) => _execs[id]?.muxHostPort,
      hostPortOf: (id, guest) => _shells[id]?.published[guest]?.hostPort,
    );
  }

  final RigGuestRun _runInGuest;
  final RigGuestStart _startInGuest;
  final SecurityContext? Function()? _tlsContext;
  final Duration _pollInterval;
  final RigHostTreeListen _listHostTreeListeners;

  final Map<String, _ExecPorts> _execs = {};
  final Map<String, _ShellPorts> _shells = {};
  final Map<String, _BrowserPorts> _browsers = {};
  final Map<String, _AndroidPorts> _androids = {};
  late final RigDomainRouter _router;
  final StreamController<RigPortsSnapshot> _changes =
      StreamController<RigPortsSnapshot>.broadcast();
  bool _disposed = false;

  /// The mux forward for [rigId], for callers (the domain router, tests) that
  /// need to dial a rig's guest directly.
  int? muxPortOf(String rigId) => _execs[rigId]?.muxHostPort;

  /// Dial identity per guest port on [browserRigId] (`mux:…` or `host:…`).
  @visibleForTesting
  Map<int, String> debugBrowserDials(String browserRigId) =>
      Map.of(_browsers[browserRigId]?.dials ?? const {});

  /// Device-port → host-port reverses currently planted for [androidRigId].
  @visibleForTesting
  Map<int, int> debugAndroidReverses(String androidRigId) =>
      Map.of(_androids[androidRigId]?.planted ?? const {});


  /// Attaches an exec (terminal) rig: bootstraps the in-guest mux, arms the
  /// credential broker's reverse tunnel and starts port discovery.
  ///
  /// [brokerPort] is the credential broker's HOST port; the guest's
  /// credential helper dials `127.0.0.1:<brokerPort>` (its `CC_BROKER_PORT`
  /// env), which under a filtered NIC only works because a reverse tunnel
  /// puts a real listener there. Null means no broker is running and the
  /// guest simply has nothing to mint against — the correct floor.
  void attachExec({
    required String rigId,
    required String workspaceId,
    required String machineName,
    required int muxHostPort,
    String? conversationId,
    int? brokerPort,
  }) {
    if (_disposed || _execs.containsKey(rigId)) {
      return;
    }
    final state = _ExecPorts(
      rigId: rigId,
      workspaceId: workspaceId,
      conversationId: _nonEmpty(conversationId),
      machineName: machineName,
      muxHostPort: muxHostPort,
    );
    _execs[rigId] = state;
    if (brokerPort != null) {
      state.hiddenPorts.add(brokerPort);
      state.brokerTunnel = GuestReverseTunnel(
        guestPort: brokerPort,
        slots: 1,
        startChannel: (argv) => _startInGuest(machineName, argv),
        dialTarget: () async {
          try {
            return await Socket.connect(
              InternetAddress.loopbackIPv4,
              brokerPort,
              timeout: const Duration(seconds: 5),
            );
          } on Object {
            return null;
          }
        },
      )..start();
    }
    state.poll = Timer.periodic(_pollInterval, (_) => unawaited(_poll(state)));
    unawaited(_poll(state));
  }

  /// Attaches a host-shell terminal: polls that session's PTY process tree
  /// for listeners. No mux. [conversationId] is required to publish into a
  /// Browser (VM) or Android; empty means discover for the panel only.
  void attachHostShell({
    required String sessionId,
    required String workspaceId,
    required int rootPid,
    String? conversationId,
  }) {
    if (_disposed || _shells.containsKey(sessionId) || rootPid <= 0) {
      return;
    }
    final state = _ShellPorts(
      sessionId: sessionId,
      workspaceId: workspaceId,
      conversationId: _nonEmpty(conversationId),
      rootPid: rootPid,
    );
    _shells[sessionId] = state;
    state.poll = Timer.periodic(
      _pollInterval,
      (_) => unawaited(_pollShell(state)),
    );
    unawaited(_pollShell(state));
  }

  /// Attaches a browser rig, wiring its guest loopback to the conversation's
  /// forwarded ports and to the dev-domain router.
  void attachBrowser({
    required String rigId,
    required String workspaceId,
    required String machineName,
    String? conversationId,
  }) {
    if (_disposed || _browsers.containsKey(rigId)) {
      return;
    }
    final state = _BrowserPorts(
      rigId: rigId,
      workspaceId: workspaceId,
      conversationId: _nonEmpty(conversationId),
      machineName: machineName,
    );
    _browsers[rigId] = state;
    unawaited(_armBrowserDomainTunnel(state));
    _syncBrowser(state);
  }

  /// Attaches an Android rig, planting `adb reverse` for this conversation's
  /// published ports only. Failures log; they do not fail the boot.
  void attachAndroid({
    required String rigId,
    required String workspaceId,
    required RigAdbReverse reverse,
    required RigAdbRemoveReverse removeReverse,
    String? conversationId,
    Future<void> Function()? removeAllReverses,
  }) {
    if (_disposed || _androids.containsKey(rigId)) {
      return;
    }
    final state = _AndroidPorts(
      rigId: rigId,
      workspaceId: workspaceId,
      conversationId: _nonEmpty(conversationId),
      reverse: reverse,
      removeReverse: removeReverse,
    );
    _androids[rigId] = state;
    unawaited(() async {
      try {
        await removeAllReverses?.call();
      } on Object catch (e) {
        CcInfraLog.debug('rig/ports: android reverse clear failed: $e');
      }
      await _syncAndroid(state);
    }());
  }

  /// Detaches [id] (exec, host-shell, browser or android), closing everything
  /// it held.
  Future<void> detach(String id) async {
    final exec = _execs.remove(id);
    if (exec != null) {
      exec.poll?.cancel();
      exec.brokerTunnel?.stop();
      for (final bridge in exec.bridges.values) {
        await bridge.close();
      }
      exec.bridges.clear();
      _router.removeRig(id);
      _syncConversation(exec.workspaceId, exec.conversationId);
    }
    final shell = _shells.remove(id);
    if (shell != null) {
      shell.poll?.cancel();
      for (final published in shell.published.values) {
        await published.remap?.close();
        await published.lan?.close();
      }
      shell.published.clear();
      _router.removeRig(id);
      _syncConversation(shell.workspaceId, shell.conversationId);
    }
    final browser = _browsers.remove(id);
    if (browser != null) {
      browser.domainTunnel?.stop();
      browser.domainTlsTunnel?.stop();
      for (final tunnel in browser.tunnels.values) {
        tunnel.stop();
      }
      browser.tunnels.clear();
      browser.dials.clear();
    }
    final android = _androids.remove(id);
    if (android != null) {
      for (final devicePort in android.planted.keys.toList()) {
        try {
          await android.removeReverse(devicePort);
        } on Object catch (e) {
          CcInfraLog.debug(
            'rig/ports: android reverse remove :$devicePort failed: $e',
          );
        }
      }
      android.planted.clear();
    }
  }

  /// Tears everything down (server shutdown).
  Future<void> dispose() async {
    _disposed = true;
    for (final id in [
      ..._execs.keys,
      ..._shells.keys,
      ..._browsers.keys,
      ..._androids.keys,
    ]) {
      await detach(id);
    }
    await _router.dispose();
    await _changes.close();
  }


  /// The current snapshot for [id], or null when it is not an attached
  /// exec rig or host-shell session in [workspaceId]. A [spaceId] that does
  /// not match the source's conversation reads as absent.
  RigPortsSnapshot? snapshotFor(
    String workspaceId,
    String id, {
    String? spaceId,
  }) {
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    if (exec != null) {
      return _snapshotExec(exec);
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    if (shell != null) {
      return _snapshotShell(shell);
    }
    return null;
  }

  /// Live snapshots for [id], current value first.
  Stream<RigPortsSnapshot> watch(
    String workspaceId,
    String id, {
    String? spaceId,
  }) async* {
    final current = snapshotFor(workspaceId, id, spaceId: spaceId);
    if (current != null) {
      yield current;
    }
    yield* _changes.stream.where(
      (s) =>
          s.rigId == id &&
          snapshotFor(workspaceId, id, spaceId: spaceId) != null,
    );
  }

  RigPortsSnapshot _snapshotExec(_ExecPorts state) {
    final ports = <RigPortForward>[];
    final guestPorts = {...state.bridges.keys, ...state.manual}.toList()
      ..sort();
    for (final guestPort in guestPorts) {
      final bridge = state.bridges[guestPort];
      if (bridge == null) {
        continue;
      }
      ports.add(
        RigPortForward(
          guestPort: guestPort,
          hostPort: bridge.hostPort,
          lanPort: bridge.lanPort,
          origin: state.manual.contains(guestPort)
              ? RigPortOrigin.manual
              : RigPortOrigin.auto,
          domain: state.domains[guestPort],
          process: state.listening[guestPort]?.process,
          active: state.listening.containsKey(guestPort),
        ),
      );
    }
    final dest = _destinations(state.workspaceId, state.conversationId);
    return RigPortsSnapshot(
      rigId: state.rigId,
      autoForward: state.autoForward,
      tlsEnabled: _router.tlsPort != null,
      browserReachable: dest.browser,
      androidReachable: dest.android,
      ports: ports,
    );
  }

  RigPortsSnapshot _snapshotShell(_ShellPorts state) {
    final ports = <RigPortForward>[];
    final listenPorts = state.published.keys.toList()..sort();
    for (final listenPort in listenPorts) {
      final published = state.published[listenPort]!;
      ports.add(
        RigPortForward(
          guestPort: listenPort,
          hostPort: published.hostPort,
          lanPort: published.lan?.lanPort ?? published.remap?.lanPort,
          origin: published.origin,
          domain: published.domain,
          process: published.process,
          active: published.active,
        ),
      );
    }
    final dest = _destinations(state.workspaceId, state.conversationId);
    return RigPortsSnapshot(
      rigId: state.sessionId,
      autoForward: state.autoForward,
      tlsEnabled: _router.tlsPort != null,
      browserReachable: dest.browser,
      androidReachable: dest.android,
      ports: ports,
    );
  }

  ({bool browser, bool android}) _destinations(
    String workspaceId,
    String? conversationId,
  ) {
    if (conversationId == null) {
      return (browser: false, android: false);
    }
    var browser = false;
    var android = false;
    for (final b in _browsers.values) {
      if (_sameSpace(
        b.workspaceId,
        b.conversationId,
        workspaceId,
        conversationId,
      )) {
        browser = true;
        break;
      }
    }
    for (final a in _androids.values) {
      if (_sameSpace(
        a.workspaceId,
        a.conversationId,
        workspaceId,
        conversationId,
      )) {
        android = true;
        break;
      }
    }
    return (browser: browser, android: android);
  }

  void _emitExec(_ExecPorts state) {
    if (!_changes.isClosed) {
      _changes.add(_snapshotExec(state));
    }
    _syncConversation(state.workspaceId, state.conversationId);
  }

  void _emitShell(_ShellPorts state) {
    if (!_changes.isClosed) {
      _changes.add(_snapshotShell(state));
    }
    _syncConversation(state.workspaceId, state.conversationId);
  }

  void _syncConversation(String workspaceId, String? conversationId) {
    if (conversationId == null) {
      return;
    }
    for (final browser in _browsers.values) {
      if (_sameSpace(
        browser.workspaceId,
        browser.conversationId,
        workspaceId,
        conversationId,
      )) {
        _syncBrowser(browser);
      }
    }
    for (final android in _androids.values) {
      if (_sameSpace(
        android.workspaceId,
        android.conversationId,
        workspaceId,
        conversationId,
      )) {
        unawaited(_syncAndroid(android));
      }
    }
  }


  /// Turns auto-forwarding on or off for [id].
  Future<bool> setAutoForward(
    String workspaceId,
    String id, {
    required bool enabled,
    String? spaceId,
  }) async {
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    if (exec != null) {
      exec.autoForward = enabled;
      if (enabled) {
        exec.dismissed.clear();
        await _reconcile(exec);
      } else {
        _emitExec(exec);
      }
      return true;
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    if (shell != null) {
      shell.autoForward = enabled;
      if (enabled) {
        shell.dismissed.clear();
        await _reconcileShell(shell);
      } else {
        _emitShell(shell);
      }
      return true;
    }
    return false;
  }

  /// Forwards [guestPort] by hand. Idempotent.
  ///
  /// [hostPort] remaps a host-shell listener onto a different loopback port.
  /// Ignored for exec rigs (the bridge still prefers the guest number).
  Future<bool> addForward(
    String workspaceId,
    String id,
    int guestPort, {
    String? spaceId,
    int? hostPort,
  }) async {
    if (guestPort <= 0 || guestPort > 65535) {
      return false;
    }
    if (hostPort != null && (hostPort <= 0 || hostPort > 65535)) {
      return false;
    }
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    if (exec != null) {
      if (exec.hiddenPorts.contains(guestPort)) {
        return false;
      }
      exec.manual.add(guestPort);
      exec.dismissed.remove(guestPort);
      await _ensureBridge(exec, guestPort);
      _emitExec(exec);
      return true;
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    if (shell != null) {
      if (_hiddenHostPort(guestPort)) {
        return false;
      }
      shell.manual.add(guestPort);
      shell.dismissed.remove(guestPort);
      await _ensurePublished(shell, guestPort, preferredHostPort: hostPort);
      _emitShell(shell);
      return true;
    }
    return false;
  }

  /// Removes [guestPort]'s forward. An auto forward is suppressed until the
  /// guest port disappears, so it does not respawn on the next poll.
  Future<bool> removeForward(
    String workspaceId,
    String id,
    int guestPort, {
    String? spaceId,
  }) async {
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    if (exec != null) {
      exec.manual.remove(guestPort);
      if (exec.listening.containsKey(guestPort)) {
        exec.dismissed.add(guestPort);
      }
      final domain = exec.domains.remove(guestPort);
      if (domain != null) {
        _router.removeRoute(domain);
      }
      final bridge = exec.bridges.remove(guestPort);
      await bridge?.close();
      _emitExec(exec);
      return true;
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    if (shell != null) {
      shell.manual.remove(guestPort);
      if (shell.listening.containsKey(guestPort)) {
        shell.dismissed.add(guestPort);
      }
      final published = shell.published.remove(guestPort);
      if (published?.domain != null) {
        _router.removeRoute(published!.domain!);
      }
      await published?.remap?.close();
      await published?.lan?.close();
      _emitShell(shell);
      return true;
    }
    return false;
  }

  /// Exposes (or unexposes) [guestPort] on the LAN.
  Future<bool> setLanExposed(
    String workspaceId,
    String id,
    int guestPort, {
    required bool exposed,
    String? spaceId,
  }) async {
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    final bridge = exec?.bridges[guestPort];
    if (exec != null && bridge != null) {
      await bridge.setLanExposed(exposed);
      _emitExec(exec);
      return true;
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    final published = shell?.published[guestPort];
    if (shell == null || published == null) {
      return false;
    }
    if (published.remap != null) {
      await published.remap!.setLanExposed(exposed);
    } else if (exposed) {
      if (published.lan == null) {
        try {
          published.lan = await HostLanRelay.start(
            targetHostPort: published.hostPort,
          );
        } on Object catch (e) {
          CcInfraLog.warning('rig/ports: LAN relay for :$guestPort failed: $e');
          return false;
        }
      }
    } else {
      await published.lan?.close();
      published.lan = null;
    }
    _emitShell(shell);
    return true;
  }

  /// Assigns (or clears, with null) a dev domain for [guestPort].
  ///
  /// Throws [ArgumentError] on a malformed domain or one already routed to a
  /// different port — silently stealing a name someone else's panel shows
  /// would leave two rows claiming the same URL.
  Future<bool> setDomain(
    String workspaceId,
    String id,
    int guestPort,
    String? domain, {
    String? spaceId,
  }) async {
    final exec = _execOf(workspaceId, id, spaceId: spaceId);
    if (exec != null) {
      if (!exec.bridges.containsKey(guestPort)) {
        return false;
      }
      return _assignDomain(
        sourceId: id,
        guestPort: guestPort,
        domain: domain,
        current: exec.domains,
        emit: () => _emitExec(exec),
      );
    }
    final shell = _shellOf(workspaceId, id, spaceId: spaceId);
    if (shell != null) {
      final published = shell.published[guestPort];
      if (published == null) {
        return false;
      }
      final previous = published.domain;
      if (previous != null) {
        _router.removeRoute(previous);
        published.domain = null;
      }
      if (domain == null || domain.isEmpty) {
        _emitShell(shell);
        return true;
      }
      final normalized = _normalizeDomain(domain);
      await _router.start();
      published.domain = normalized;
      _router.setRoute(normalized, rigId: id, guestPort: guestPort);
      _emitShell(shell);
      return true;
    }
    return false;
  }

  Future<bool> _assignDomain({
    required String sourceId,
    required int guestPort,
    required String? domain,
    required Map<int, String> current,
    required void Function() emit,
  }) async {
    final previous = current.remove(guestPort);
    if (previous != null) {
      _router.removeRoute(previous);
    }
    if (domain == null || domain.isEmpty) {
      emit();
      return true;
    }
    final normalized = _normalizeDomain(domain);
    await _router.start();
    current[guestPort] = normalized;
    _router.setRoute(normalized, rigId: sourceId, guestPort: guestPort);
    emit();
    return true;
  }

  String _normalizeDomain(String domain) {
    final normalized = domain.toLowerCase();
    if (!kRigPortDomainPattern.hasMatch(normalized)) {
      throw ArgumentError.value(
        domain,
        'domain',
        'Use a lower-case dev domain ending in .test or .localhost '
            '(e.g. myapp.test)',
      );
    }
    if (_router.hasRoute(normalized)) {
      throw ArgumentError.value(
        domain,
        'domain',
        'That domain is already routed to another port',
      );
    }
    return normalized;
  }

  _ExecPorts? _execOf(String workspaceId, String id, {String? spaceId}) {
    final state = _execs[id];
    if (state == null || state.workspaceId != workspaceId) {
      return null;
    }
    if (spaceId != null && state.conversationId != spaceId) {
      return null;
    }
    return state;
  }

  _ShellPorts? _shellOf(String workspaceId, String id, {String? spaceId}) {
    final state = _shells[id];
    if (state == null || state.workspaceId != workspaceId) {
      return null;
    }
    if (spaceId != null && state.conversationId != spaceId) {
      return null;
    }
    return state;
  }


  Future<void> _poll(_ExecPorts state) async {
    if (state.polling || _disposed || !_execs.containsKey(state.rigId)) {
      return;
    }
    state.polling = true;
    try {
      if (!state.muxReady) {
        // The mux bootstrap is idempotent and cheap on a warm guest; running
        // it from the poll loop (rather than once at attach) also self-heals
        // a mux that died with a guest restart.
        final result = await _runInGuest(
          state.machineName,
          buildPortMuxBootstrapCommand(),
        );
        state.muxReady = result.exitCode == 0;
        if (!state.muxReady) {
          return;
        }
      }
      final result = await _runInGuest(
        state.machineName,
        kRigPortDiscoveryScript,
      );
      if (result.exitCode != 0) {
        return;
      }
      final found = parsePortDiscoveryOutput('${result.stdout}');
      final listening = <int, RigOpenPort>{
        for (final p in found)
          if (!state.hiddenPorts.contains(p.port)) p.port: p,
      };
      final changed = !_samePorts(listening, state.listening);
      state.listening = listening;
      // A dismissed port that went away may come back honestly next time.
      state.dismissed.removeWhere((port) => !listening.containsKey(port));
      if (changed) {
        await _reconcile(state);
      }
    } on Object catch (e) {
      // A poll against a machine that is parking/closing fails routinely;
      // the detach is what stops the loop, not the error.
      CcInfraLog.debug('rig/ports: poll failed for ${state.rigId}: $e');
    } finally {
      state.polling = false;
    }
  }

  Future<void> _pollShell(_ShellPorts state) async {
    if (state.polling || _disposed || !_shells.containsKey(state.sessionId)) {
      return;
    }
    state.polling = true;
    try {
      final found = await _listHostTreeListeners(state.rootPid);
      final listening = <int, RigOpenPort>{
        for (final p in found)
          if (!_hiddenHostPort(p.port)) p.port: p,
      };
      final changed = !_samePorts(listening, state.listening);
      state.listening = listening;
      state.dismissed.removeWhere((port) => !listening.containsKey(port));
      if (changed) {
        await _reconcileShell(state);
      }
    } on Object catch (e) {
      CcInfraLog.debug(
        'rig/ports: host-shell poll failed for ${state.sessionId}: $e',
      );
    } finally {
      state.polling = false;
    }
  }

  static bool _samePorts(Map<int, RigOpenPort> a, Map<int, RigOpenPort> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static bool _hiddenHostPort(int port) => kNeverForwardPorts.contains(port);

  Future<void> _reconcile(_ExecPorts state) async {
    // Open bridges for newly listening ports (auto) and manual ones.
    if (state.autoForward) {
      for (final port in state.listening.keys) {
        if (state.bridges.length >= kMaxAutoForwards &&
            !state.bridges.containsKey(port)) {
          CcInfraLog.warning(
            'rig/ports: ${state.rigId} has more than $kMaxAutoForwards '
            'listening ports; not auto-forwarding :$port',
          );
          continue;
        }
        if (!state.dismissed.contains(port)) {
          await _ensureBridge(state, port);
        }
      }
    }
    for (final port in state.manual) {
      await _ensureBridge(state, port);
    }
    // Close auto bridges whose guest port went away. Manual ones persist —
    // the user asked for them, and a dev server mid-restart should not lose
    // its URL.
    final stale = [
      for (final port in state.bridges.keys)
        if (!state.listening.containsKey(port) && !state.manual.contains(port))
          port,
    ];
    for (final port in stale) {
      final domain = state.domains.remove(port);
      if (domain != null) {
        _router.removeRoute(domain);
      }
      final bridge = state.bridges.remove(port);
      await bridge?.close();
    }
    _emitExec(state);
  }

  Future<void> _reconcileShell(_ShellPorts state) async {
    if (state.autoForward) {
      for (final port in state.listening.keys) {
        if (state.published.length >= kMaxAutoForwards &&
            !state.published.containsKey(port)) {
          CcInfraLog.warning(
            'rig/ports: ${state.sessionId} has more than $kMaxAutoForwards '
            'listening ports; not auto-forwarding :$port',
          );
          continue;
        }
        if (!state.dismissed.contains(port)) {
          await _ensurePublished(state, port);
        }
      }
    }
    for (final port in state.manual) {
      await _ensurePublished(state, port);
    }
    final stale = [
      for (final port in state.published.keys)
        if (!state.listening.containsKey(port) && !state.manual.contains(port))
          port,
    ];
    for (final port in stale) {
      final published = state.published.remove(port);
      if (published?.domain != null) {
        _router.removeRoute(published!.domain!);
      }
      await published?.remap?.close();
      await published?.lan?.close();
    }
    // Refresh process names / active flags on what remains.
    for (final entry in state.published.entries) {
      final listen = state.listening[entry.key];
      entry.value
        ..active = listen != null
        ..process = listen?.process ?? entry.value.process;
    }
    _emitShell(state);
  }

  Future<void> _ensureBridge(_ExecPorts state, int guestPort) async {
    if (state.bridges.containsKey(guestPort)) {
      return;
    }
    try {
      final bridge = await HostPortBridge.start(
        guestPort: guestPort,
        muxHostPort: state.muxHostPort,
      );
      // Re-checked AFTER the await. `detach` (or `dispose`) can land while
      // this listener is being opened — the poll fires every 4 s — and the
      // old code then registered a live host listener into a state object
      // nobody holds any more. Nothing ever closed it: a rig that came and
      // went during a poll leaked a listening socket per port.
      if (_disposed ||
          !identical(_execs[state.rigId], state) ||
          state.bridges.containsKey(guestPort)) {
        await bridge.close();
        return;
      }
      state.bridges[guestPort] = bridge;
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/ports: could not bridge :$guestPort for ${state.rigId}: $e',
      );
    }
  }

  Future<void> _ensurePublished(
    _ShellPorts state,
    int listenPort, {
    int? preferredHostPort,
  }) async {
    final existing = state.published[listenPort];
    if (existing != null) {
      if (preferredHostPort != null &&
          preferredHostPort != existing.hostPort &&
          preferredHostPort != listenPort) {
        await _remapShell(existing, preferredHostPort, listenPort);
      }
      existing
        ..active = state.listening.containsKey(listenPort)
        ..process = state.listening[listenPort]?.process ?? existing.process
        ..origin = state.manual.contains(listenPort)
            ? RigPortOrigin.manual
            : existing.origin;
      return;
    }
    final origin = state.manual.contains(listenPort)
        ? RigPortOrigin.manual
        : RigPortOrigin.auto;
    final published = _ShellPublished(
      listenPort: listenPort,
      hostPort: listenPort,
      origin: origin,
      process: state.listening[listenPort]?.process,
      active: state.listening.containsKey(listenPort),
    );
    if (preferredHostPort != null && preferredHostPort != listenPort) {
      await _remapShell(published, preferredHostPort, listenPort);
    }
    if (_disposed ||
        !identical(_shells[state.sessionId], state) ||
        state.published.containsKey(listenPort)) {
      await published.remap?.close();
      await published.lan?.close();
      return;
    }
    state.published[listenPort] = published;
  }

  Future<void> _remapShell(
    _ShellPublished published,
    int preferredHostPort,
    int listenPort,
  ) async {
    try {
      final remap = await HostPortBridge.startDirect(
        preferredHostPort: preferredHostPort,
        targetHostPort: listenPort,
      );
      await published.remap?.close();
      published
        ..remap = remap
        ..hostPort = remap.hostPort;
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/ports: could not remap :$listenPort → :$preferredHostPort: $e',
      );
    }
  }


  /// Same workspace AND a non-null conversation on both sides. A missing
  /// space never matches — that would broadcast into every conversation.
  bool _sameSpace(
    String workspaceId,
    String? conversationId,
    String otherWorkspaceId,
    String? otherConversationId,
  ) =>
      workspaceId == otherWorkspaceId &&
      conversationId != null &&
      conversationId == otherConversationId;

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;

  _ExecPorts? _execForSpace(String workspaceId, String? conversationId) {
    if (conversationId == null) {
      return null;
    }
    for (final exec in _execs.values) {
      if (_sameSpace(
        exec.workspaceId,
        exec.conversationId,
        workspaceId,
        conversationId,
      )) {
        return exec;
      }
    }
    return null;
  }

  Iterable<_ShellPorts> _shellsForSpace(
    String workspaceId,
    String? conversationId,
  ) {
    if (conversationId == null) {
      return const [];
    }
    return _shells.values.where(
      (s) => _sameSpace(
        s.workspaceId,
        s.conversationId,
        workspaceId,
        conversationId,
      ),
    );
  }

  Map<int, _PortDial> _wantedDials(String workspaceId, String? conversationId) {
    final wanted = <int, _PortDial>{};
    final exec = _execForSpace(workspaceId, conversationId);
    if (exec != null) {
      for (final port in exec.bridges.keys) {
        if (kNeverForwardPorts.contains(port) ||
            kBrowserDomainLanePorts.contains(port)) {
          continue;
        }
        wanted[port] = _PortDial.mux(exec.rigId, port);
      }
    }
    for (final shell in _shellsForSpace(workspaceId, conversationId)) {
      for (final published in shell.published.values) {
        _offerHostDial(
          wanted,
          guestPort: published.listenPort,
          hostPort: published.hostPort,
        );
      }
    }
    return wanted;
  }

  /// Publishes a host-shell port into [wanted]: the listen number always,
  /// and the remapped desktop number too so typing the panel's copy-URL in
  /// the Browser (VM) hits the same server.
  void _offerHostDial(
    Map<int, _PortDial> wanted, {
    required int guestPort,
    required int hostPort,
  }) {
    void offer(int port, int dial) {
      if (wanted.containsKey(port) ||
          kNeverForwardPorts.contains(port) ||
          kBrowserDomainLanePorts.contains(port)) {
        return;
      }
      wanted[port] = _PortDial.host(dial);
    }

    offer(guestPort, hostPort);
    if (hostPort != guestPort) {
      offer(hostPort, hostPort);
    }
  }

  /// Reconciles the in-browser-guest listeners with THIS browser's space
  /// only: exec mux wins over host-shell on the same number. Other spaces
  /// never enter the wanted set.
  void _syncBrowser(_BrowserPorts browser) {
    if (_disposed || !_browsers.containsKey(browser.rigId)) {
      return;
    }
    final wanted = _wantedDials(browser.workspaceId, browser.conversationId);
    for (final port in browser.tunnels.keys.toList()) {
      final next = wanted[port];
      if (next == null || browser.dials[port] != next.key) {
        browser.tunnels.remove(port)?.stop();
        browser.dials.remove(port);
      }
    }
    for (final entry in wanted.entries) {
      final port = entry.key;
      if (browser.tunnels.containsKey(port)) {
        continue;
      }
      final dial = entry.value;
      browser.dials[port] = dial.key;
      browser.tunnels[port] = GuestReverseTunnel(
        guestPort: port,
        slots: kBrowserReverseTunnelSlots,
        ensureMux: () => _installReverseMux(browser.machineName),
        startChannel: (argv) => _startInGuest(browser.machineName, argv),
        dialTarget: () => _dial(dial),
      )..start();
    }
  }

  Future<void> _installReverseMux(String machineName) async {
    final result = await _runInGuest(
      machineName,
      buildReverseMuxBootstrapCommand(),
    );
    if (result.exitCode != 0) {
      throw StateError(
        'cc-revtun install failed (exit ${result.exitCode}): '
        '${result.stderr}',
      );
    }
  }

  Future<Socket?> _dial(_PortDial dial) async {
    if (dial.kind == 'mux') {
      final exec = _execs[dial.sourceId!];
      if (exec == null) {
        return null;
      }
      return _dialMux(exec, dial.guestPort!);
    }
    try {
      return await Socket.connect(
        InternetAddress.loopbackIPv4,
        dial.hostPort!,
        timeout: const Duration(seconds: 2),
      );
    } on Object {
      // A process that binds `localhost` (Node 17+ often does) answers as
      // `::1` only. IPv4 refused is not "nothing is listening".
      try {
        return await Socket.connect(
          InternetAddress.loopbackIPv6,
          dial.hostPort!,
          timeout: const Duration(seconds: 2),
        );
      } on Object {
        return null;
      }
    }
  }

  Future<void> _armBrowserDomainTunnel(_BrowserPorts browser) async {
    GuestReverseTunnel arm(int guestPort, int routerPort) => GuestReverseTunnel(
      guestPort: guestPort,
      slots: kBrowserReverseTunnelSlots,
      ensureMux: () => _installReverseMux(browser.machineName),
      startChannel: (argv) => _startInGuest(browser.machineName, argv),
      dialTarget: () async {
        try {
          return await Socket.connect(
            InternetAddress.loopbackIPv4,
            routerPort,
            timeout: const Duration(seconds: 5),
          );
        } on Object {
          return null;
        }
      },
    )..start();

    try {
      final routerPort = await _router.start();
      browser.domainTunnel = arm(80, routerPort);
    } on Object catch (e) {
      CcInfraLog.warning(
        'rig/ports: dev-domain routing unavailable for ${browser.rigId}: $e',
      );
      return;
    }
    // The HTTPS lane. Optional and independently degradable: a host with no
    // TLS material still routes the domains over plain HTTP, and the panel's
    // `tls_enabled` says which of the two schemes is being promised.
    final context = _tlsContext?.call();
    if (context == null) {
      return;
    }
    final tlsPort = await _router.startTls(context);
    if (tlsPort != null) {
      browser.domainTlsTunnel = arm(443, tlsPort);
    }
  }

  Future<Socket?> _dialMux(_ExecPorts exec, int guestPort) async {
    // Straight to the exec rig's mux — not through the host bridge — so the
    // browser lane works even when the host-side port was taken by something
    // else, and a connect can never land back on a host listener of ours.
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        exec.muxHostPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add('$guestPort\n'.codeUnits);
      return socket;
    } on Object {
      return null;
    }
  }


  Future<void> _syncAndroid(_AndroidPorts android) async {
    if (_disposed || !_androids.containsKey(android.rigId)) {
      return;
    }
    final wanted = <int, int>{};
    final exec = _execForSpace(android.workspaceId, android.conversationId);
    if (exec != null) {
      for (final entry in exec.bridges.entries) {
        if (kNeverForwardPorts.contains(entry.key) ||
            kBrowserDomainLanePorts.contains(entry.key)) {
          continue;
        }
        wanted[entry.key] = entry.value.hostPort;
      }
    }
    for (final shell in _shellsForSpace(
      android.workspaceId,
      android.conversationId,
    )) {
      for (final published in shell.published.values) {
        void offer(int devicePort, int hostPort) {
          if (wanted.containsKey(devicePort) ||
              kNeverForwardPorts.contains(devicePort) ||
              kBrowserDomainLanePorts.contains(devicePort)) {
            return;
          }
          wanted[devicePort] = hostPort;
        }

        offer(published.listenPort, published.hostPort);
        if (published.hostPort != published.listenPort) {
          offer(published.hostPort, published.hostPort);
        }
      }
    }
    for (final devicePort in android.planted.keys.toList()) {
      final host = wanted[devicePort];
      if (host == null) {
        try {
          await android.removeReverse(devicePort);
        } on Object catch (e) {
          CcInfraLog.debug(
            'rig/ports: android reverse remove :$devicePort failed: $e',
          );
        }
        android.planted.remove(devicePort);
      } else if (android.planted[devicePort] != host) {
        try {
          await android.reverse(devicePort: devicePort, hostPort: host);
          android.planted[devicePort] = host;
        } on Object catch (e) {
          CcInfraLog.debug(
            'rig/ports: android reverse retarget :$devicePort failed: $e',
          );
        }
      }
    }
    for (final entry in wanted.entries) {
      if (android.planted.containsKey(entry.key)) {
        continue;
      }
      try {
        await android.reverse(devicePort: entry.key, hostPort: entry.value);
        android.planted[entry.key] = entry.value;
      } on Object catch (e) {
        CcInfraLog.debug('rig/ports: android reverse :${entry.key} failed: $e');
      }
    }
  }
}
