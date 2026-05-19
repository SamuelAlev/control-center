// Orchestrates port visibility + forwarding across a conversation's rigs.
//
// One instance per server, owned by `RigService`. For every EXEC (terminal)
// rig it polls the guest for listening TCP ports, auto-opens a host loopback
// bridge per port (VS Code's auto-forward behaviour), and keeps the panel's
// snapshot stream current. For every BROWSER rig sharing the conversation it
// plants guest-loopback listeners on the same ports, so `localhost:3000`
// typed into the enclosed browser lands on the terminal VM's server — and a
// `myapp.test` domain routes through the Host-header router.
//
// Everything here rides the two validated primitives in `rig_ports.dart`;
// this file is bookkeeping and policy: what gets forwarded, what stays
// loopback-only, and who is told when it changes.

import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart';

/// Runs one shell command inside a guest and captures the result.
typedef RigGuestRun =
    Future<ProcessResult> Function(String machineName, String shellCommand);

/// Starts one interactive (stdio-wired) process inside a guest.
typedef RigGuestStart =
    Future<Process> Function(String machineName, List<String> guestArgv);

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

  /// The guest :80 tunnel feeding the domain router's HTTP lane.
  GuestReverseTunnel? domainTunnel;

  /// The guest :443 tunnel feeding the domain router's HTTPS lane, when the
  /// host has TLS material.
  GuestReverseTunnel? domainTlsTunnel;
}

/// Discovers, forwards and publishes the open ports of enclosed rigs.
class RigPortsService {
  /// Creates a [RigPortsService].
  ///
  /// [tlsContext] supplies the dev-domain TLS material, resolved lazily when
  /// the first browser rig attaches. Null (or a provider returning null)
  /// leaves the HTTPS lane un-armed and dev domains route over plain HTTP.
  RigPortsService({
    required RigGuestRun runInGuest,
    required RigGuestStart startInGuest,
    SecurityContext? Function()? tlsContext,
    Duration pollInterval = const Duration(seconds: 4),
  }) : _runInGuest = runInGuest,
       _startInGuest = startInGuest,
       _tlsContext = tlsContext,
       _pollInterval = pollInterval {
    _router = RigDomainRouter(muxPortOf: (rigId) => _execs[rigId]?.muxHostPort);
  }

  final RigGuestRun _runInGuest;
  final RigGuestStart _startInGuest;
  final SecurityContext? Function()? _tlsContext;
  final Duration _pollInterval;

  final Map<String, _ExecPorts> _execs = {};
  final Map<String, _BrowserPorts> _browsers = {};
  late final RigDomainRouter _router;
  final StreamController<RigPortsSnapshot> _changes =
      StreamController<RigPortsSnapshot>.broadcast();
  bool _disposed = false;

  /// The mux forward for [rigId], for callers (the domain router, tests) that
  /// need to dial a rig's guest directly.
  int? muxPortOf(String rigId) => _execs[rigId]?.muxHostPort;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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
      conversationId: conversationId,
      machineName: machineName,
      muxHostPort: muxHostPort,
    );
    _execs[rigId] = state;
    if (brokerPort != null) {
      state.hiddenPorts.add(brokerPort);
      state.brokerTunnel = GuestReverseTunnel(
        guestPort: brokerPort,
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
      conversationId: conversationId,
      machineName: machineName,
    );
    _browsers[rigId] = state;
    unawaited(_armBrowserDomainTunnel(state));
    _syncBrowser(state);
  }

  /// Detaches [rigId] (either kind), closing everything it held.
  Future<void> detach(String rigId) async {
    final exec = _execs.remove(rigId);
    if (exec != null) {
      exec.poll?.cancel();
      exec.brokerTunnel?.stop();
      for (final bridge in exec.bridges.values) {
        await bridge.close();
      }
      exec.bridges.clear();
      _router.removeRig(rigId);
      // The browser-side listeners pointed at this rig's forwards.
      for (final browser in _browsers.values) {
        if (_sameConversation(browser, exec)) {
          _syncBrowser(browser);
        }
      }
    }
    final browser = _browsers.remove(rigId);
    if (browser != null) {
      browser.domainTunnel?.stop();
      browser.domainTlsTunnel?.stop();
      for (final tunnel in browser.tunnels.values) {
        tunnel.stop();
      }
      browser.tunnels.clear();
    }
  }

  /// Tears everything down (server shutdown).
  Future<void> dispose() async {
    _disposed = true;
    for (final rigId in [..._execs.keys, ..._browsers.keys]) {
      await detach(rigId);
    }
    await _router.dispose();
    await _changes.close();
  }

  // ── Snapshots ─────────────────────────────────────────────────────────────

  /// The current snapshot for [rigId], or null when it is not an attached
  /// exec rig in [workspaceId].
  RigPortsSnapshot? snapshotFor(String workspaceId, String rigId) {
    final state = _execs[rigId];
    if (state == null || state.workspaceId != workspaceId) {
      return null;
    }
    return _snapshot(state);
  }

  /// Live snapshots for [rigId], current value first.
  Stream<RigPortsSnapshot> watch(String workspaceId, String rigId) async* {
    final current = snapshotFor(workspaceId, rigId);
    if (current != null) {
      yield current;
    }
    yield* _changes.stream.where(
      (s) => s.rigId == rigId && _execs[rigId]?.workspaceId == workspaceId,
    );
  }

  RigPortsSnapshot _snapshot(_ExecPorts state) {
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
    return RigPortsSnapshot(
      rigId: state.rigId,
      autoForward: state.autoForward,
      tlsEnabled: _router.tlsPort != null,
      ports: ports,
    );
  }

  void _emit(_ExecPorts state) {
    if (!_changes.isClosed) {
      _changes.add(_snapshot(state));
    }
    for (final browser in _browsers.values) {
      if (_sameConversation(browser, state)) {
        _syncBrowser(browser);
      }
    }
  }

  // ── Mutations (panel actions) ─────────────────────────────────────────────

  /// Turns auto-forwarding on or off for [rigId].
  Future<bool> setAutoForward(
    String workspaceId,
    String rigId, {
    required bool enabled,
  }) async {
    final state = _stateOf(workspaceId, rigId);
    if (state == null) {
      return false;
    }
    state.autoForward = enabled;
    if (enabled) {
      state.dismissed.clear();
      await _reconcile(state);
    } else {
      // Existing forwards stay: the toggle governs NEW ports, exactly like
      // the editor feature it mirrors. Removing live forwards is `remove`.
      _emit(state);
    }
    return true;
  }

  /// Forwards [guestPort] by hand. Idempotent.
  Future<bool> addForward(
    String workspaceId,
    String rigId,
    int guestPort,
  ) async {
    final state = _stateOf(workspaceId, rigId);
    if (state == null ||
        guestPort <= 0 ||
        guestPort > 65535 ||
        state.hiddenPorts.contains(guestPort)) {
      return false;
    }
    state.manual.add(guestPort);
    state.dismissed.remove(guestPort);
    await _ensureBridge(state, guestPort);
    _emit(state);
    return true;
  }

  /// Removes [guestPort]'s forward. An auto forward is suppressed until the
  /// guest port disappears, so it does not respawn on the next poll.
  Future<bool> removeForward(
    String workspaceId,
    String rigId,
    int guestPort,
  ) async {
    final state = _stateOf(workspaceId, rigId);
    if (state == null) {
      return false;
    }
    state.manual.remove(guestPort);
    if (state.listening.containsKey(guestPort)) {
      state.dismissed.add(guestPort);
    }
    final domain = state.domains.remove(guestPort);
    if (domain != null) {
      _router.removeRoute(domain);
    }
    final bridge = state.bridges.remove(guestPort);
    await bridge?.close();
    _emit(state);
    return true;
  }

  /// Exposes (or unexposes) [guestPort] on the LAN.
  Future<bool> setLanExposed(
    String workspaceId,
    String rigId,
    int guestPort, {
    required bool exposed,
  }) async {
    final state = _stateOf(workspaceId, rigId);
    final bridge = state?.bridges[guestPort];
    if (state == null || bridge == null) {
      return false;
    }
    await bridge.setLanExposed(exposed);
    _emit(state);
    return true;
  }

  /// Assigns (or clears, with null) a dev domain for [guestPort].
  ///
  /// Throws [ArgumentError] on a malformed domain or one already routed to a
  /// different port — silently stealing a name someone else's panel shows
  /// would leave two rows claiming the same URL.
  Future<bool> setDomain(
    String workspaceId,
    String rigId,
    int guestPort,
    String? domain,
  ) async {
    final state = _stateOf(workspaceId, rigId);
    if (state == null || !state.bridges.containsKey(guestPort)) {
      return false;
    }
    final previous = state.domains.remove(guestPort);
    if (previous != null) {
      _router.removeRoute(previous);
    }
    if (domain == null || domain.isEmpty) {
      _emit(state);
      return true;
    }
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
    await _router.start();
    state.domains[guestPort] = normalized;
    _router.setRoute(normalized, rigId: rigId, guestPort: guestPort);
    _emit(state);
    return true;
  }

  _ExecPorts? _stateOf(String workspaceId, String rigId) {
    final state = _execs[rigId];
    // A foreign workspace's rig must read as absent, exactly like RigService.
    return state != null && state.workspaceId == workspaceId ? state : null;
  }

  // ── Discovery ─────────────────────────────────────────────────────────────

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
    _emit(state);
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

  // ── Browser-side listeners ────────────────────────────────────────────────

  bool _sameConversation(_BrowserPorts browser, _ExecPorts exec) =>
      browser.workspaceId == exec.workspaceId &&
      browser.conversationId != null &&
      browser.conversationId == exec.conversationId;

  _ExecPorts? _execForBrowser(_BrowserPorts browser) {
    for (final exec in _execs.values) {
      if (_sameConversation(browser, exec)) {
        return exec;
      }
    }
    return null;
  }

  /// Reconciles the in-browser-guest listeners with the conversation's
  /// forwarded ports: one guest-loopback listener per forward, dialing the
  /// exec rig's mux.
  void _syncBrowser(_BrowserPorts browser) {
    if (_disposed || !_browsers.containsKey(browser.rigId)) {
      return;
    }
    final exec = _execForBrowser(browser);
    final wanted = <int>{
      if (exec != null)
        for (final port in exec.bridges.keys)
          if (!kNeverForwardPorts.contains(port) &&
              !kBrowserDomainLanePorts.contains(port))
            port,
    };
    for (final port in browser.tunnels.keys.toList()) {
      if (!wanted.contains(port)) {
        browser.tunnels.remove(port)?.stop();
      }
    }
    if (exec == null) {
      return;
    }
    for (final port in wanted) {
      if (browser.tunnels.containsKey(port)) {
        continue;
      }
      browser.tunnels[port] = GuestReverseTunnel(
        guestPort: port,
        // A browser page-load bursts a handful of parallel fetches; four
        // slots absorb it without holding a process pool per port.
        slots: 4,
        startChannel: (argv) => _startInGuest(browser.machineName, argv),
        dialTarget: () => _dialMux(exec, port),
      )..start();
    }
  }

  Future<void> _armBrowserDomainTunnel(_BrowserPorts browser) async {
    GuestReverseTunnel arm(int guestPort, int routerPort) => GuestReverseTunnel(
      guestPort: guestPort,
      slots: 4,
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
}
