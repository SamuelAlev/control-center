// The domain router's request-sniffing subscription and the client socket it
// splices are handed off between methods (`_route` peeks, then rewires the
// same subscription onto the upstream), which the lifetime lints cannot follow.
// ignore_for_file: cancel_subscriptions, close_sinks

// Port visibility and forwarding for enclosed (smolvm) rigs.
//
// The problem this file solves, end to end: a dev server started inside the
// Terminal (VM) — `pnpm dev` listening on guest port 3000 — must be
//
//  * VISIBLE: the ports panel in the channel/PR shows "3000 (node)" moments
//    after the process binds it;
//  * REACHABLE FROM THE HOST: `localhost:3000` on the server machine (and,
//    when explicitly exposed, `<server-ip>:<random port>` on the LAN);
//  * REACHABLE FROM THE BROWSER (VM): `localhost:3000` — and `myapp.test` —
//    typed into the enclosed browser lands on the terminal VM's server.
//
// None of that comes for free from smolvm. Its `-p` forwards are fixed at
// machine-create time (`machine update` requires a stopped machine), and —
// measured on smolvm 1.8.1 — a guest under ANY egress filter
// (`--outbound-localhost-only`, `--allow-cidr 127.0.0.0/8`) CANNOT dial the
// host's loopback, and `--mount-socket` never reaches the host service. So
// every lane here is built from the two primitives that do work:
//
//  * HOST → GUEST: one `-p` forward per machine to a fixed in-guest MUX port.
//    The mux is socat forking a tiny dialer script per connection: the host
//    writes the target port as a decimal line, the dialer verifies something
//    in the guest is LISTENING on it (loop prevention — see below) and splices
//    to `127.0.0.1:<port>`. One pre-created forward serves every future port.
//
//  * GUEST → HOST: a REVERSE TUNNEL over `machine exec -i` stdio. The host
//    holds a small pool of exec channels, each running
//    `socat STDIO TCP-LISTEN:<port>,bind=127.0.0.1,reuseaddr,reuseport` in
//    the guest; when a guest process connects and sends its first bytes, the
//    host dials the real target and splices. This is also what makes the git
//    credential broker reachable from inside an exec rig at all — the
//    "loopback maps to the host" assumption the credential helper shipped
//    with is simply not true under a filtered NIC.
//
// The listener check in the mux dialer is not cosmetic: without it, a host
// bridge on `127.0.0.1:3000` whose guest server just died would dial the
// guest's 3000, TSI could carry that BACK to host loopback 3000 — the bridge
// itself — and one stray connection becomes a connect loop.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:meta/meta.dart';

/// The fixed in-guest TCP port the port mux listens on.
///
/// Forwarded to a host loopback port at machine create (`-p <host>:7911`).
/// 7911 sits in the unassigned range and is excluded from discovery, so the
/// mux never lists — or forwards to — itself.
const int kRigPortMuxGuestPort = 7911;

/// Where the mux dialer script lands inside the guest.
const String kRigPortMuxDialerPath = '/usr/local/bin/cc-portmux';

/// The per-connection mux dialer installed into every exec guest.
///
/// socat invokes it with stdin/stdout wired to the accepted connection. It
/// reads one decimal port line, refuses anything that is not a port, refuses
/// a port NOTHING in the guest is listening on (the loop guard — a dial to a
/// dead port would otherwise be carried back out to the host by TSI, where it
/// can land on the very bridge that sent it), then execs a splice to the
/// guest-local target.
///
/// Deliberately a FILE, not an inline `SYSTEM:` argument: socat splits its
/// SYSTEM address on commas, and the awk body needs `split($2,a,":")` — the
/// inline form silently truncates at the first comma and every connection
/// dies with a reset. (Measured; the failure is invisible in socat's exit.)
const String kRigPortMuxDialer = r'''
#!/bin/sh
read -r port
port=$(printf "%s" "$port" | tr -d "\r")
case "$port" in *[!0-9]*|"") exit 1;; esac
hex=$(printf "%04X" "$port")
awk -v p="$hex" '{split($2,a,":"); if (a[2]==p && $4=="0A") f=1} END {exit !f}' /proc/net/tcp /proc/net/tcp6 2>/dev/null || exit 1
exec socat STDIO TCP:127.0.0.1:"$port"
''';

/// The guest command that installs the mux dialer and starts the mux.
///
/// Idempotent: the dialer is rewritten (upgrades take effect on next start)
/// and the listener is only started when nothing already holds the mux port.
/// The script travels base64'd so none of it is at the mercy of shell
/// quoting — the same discipline as the credential helper.
String buildPortMuxBootstrapCommand() {
  final encoded = base64Encode(utf8.encode(kRigPortMuxDialer));
  return 'echo $encoded | base64 -d > $kRigPortMuxDialerPath && '
      'chmod 755 $kRigPortMuxDialerPath && '
      '(awk \'{split(\$2,a,":"); if (a[2]=="1EE7" && \$4=="0A") f=1} '
      'END {exit !f}\' /proc/net/tcp /proc/net/tcp6 2>/dev/null && '
      'exit 0 || true) && '
      'nohup socat TCP-LISTEN:$kRigPortMuxGuestPort,reuseaddr,fork '
      'SYSTEM:$kRigPortMuxDialerPath >/dev/null 2>&1 &';
}

/// The in-guest script that reports every listening TCP port.
///
/// Emits one `P <hexport> <pid> <comm>` line per distinct listening port
/// (state 0A in /proc/net/tcp{,6}), with `0 ?` when the owning process could
/// not be resolved. Ports are reported in HEX because busybox/mawk cannot
/// parse hex — the host converts. The inode→pid map is built in ONE pass over
/// /proc/*/fd rather than one pass per port.
const String kRigPortDiscoveryScript = r'''
ports=$(awk '$4=="0A" {split($2,a,":"); print a[2] ":" $10}' /proc/net/tcp /proc/net/tcp6 2>/dev/null | sort -u)
[ -n "$ports" ] || exit 0
inodes=$(for fd in /proc/[0-9]*/fd/*; do
  link=$(readlink "$fd" 2>/dev/null) || continue
  case "$link" in "socket:["*) ;; *) continue;; esac
  inode=${link#socket:[}; inode=${inode%]}
  pid=${fd#/proc/}; pid=${pid%%/*}
  echo "$inode $pid"
done)
seen=""
for entry in $ports; do
  hex=${entry%%:*}; inode=${entry##*:}
  case " $seen " in *" $hex "*) continue;; esac
  seen="$seen $hex"
  pid=$(printf "%s\n" "$inodes" | awk -v i="$inode" '$1==i {print $2; exit}')
  comm="?"
  [ -n "$pid" ] && comm=$(cat "/proc/$pid/comm" 2>/dev/null | tr -d "\n" | tr " " "_")
  echo "P $hex ${pid:-0} ${comm:-?}"
done
''';

/// One listening TCP port inside a guest.
class RigOpenPort {
  /// Creates a [RigOpenPort].
  const RigOpenPort({required this.port, this.pid, this.process});

  /// The guest port number.
  final int port;

  /// The owning process id inside the guest, when resolvable.
  final int? pid;

  /// The owning process name (`node`, `python3`), when resolvable.
  final String? process;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigOpenPort &&
          other.port == port &&
          other.pid == pid &&
          other.process == process;

  @override
  int get hashCode => Object.hash(port, pid, process);
}

/// Parses [kRigPortDiscoveryScript]'s output.
///
/// Tolerant: a malformed line is skipped, not thrown on — the input crossed a
/// VM boundary and a truncated read must not kill the polling loop. Output is
/// capped so a guest that binds thousands of ports cannot balloon the host's
/// bookkeeping.
List<RigOpenPort> parsePortDiscoveryOutput(String output, {int cap = 64}) {
  final ports = <RigOpenPort>[];
  for (final line in const LineSplitter().convert(output)) {
    if (ports.length >= cap) {
      break;
    }
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts[0] != 'P') {
      continue;
    }
    final port = int.tryParse(parts[1], radix: 16);
    if (port == null || port <= 0 || port > 65535) {
      continue;
    }
    final pid = parts.length > 2 ? int.tryParse(parts[2]) : null;
    final comm = parts.length > 3 ? parts.sublist(3).join(' ') : null;
    ports.add(
      RigOpenPort(
        port: port,
        pid: pid == null || pid <= 0 ? null : pid,
        process: comm == null || comm.isEmpty || comm == '?' ? null : comm,
      ),
    );
  }
  ports.sort((a, b) => a.port.compareTo(b.port));
  return ports;
}

/// How a forward came to exist.
enum RigPortOrigin {
  /// Discovered listening in the guest and auto-forwarded.
  auto,

  /// Added by hand in the ports panel. Survives the guest process dying.
  manual;

  /// Stable wire string.
  String get wire => name;
}

/// One forwarded port: the guest port and every address it answers on.
class RigPortForward {
  /// Creates a [RigPortForward].
  const RigPortForward({
    required this.guestPort,
    required this.hostPort,
    required this.origin,
    this.lanPort,
    this.domain,
    this.process,
    this.active = true,
  });

  /// The port inside the guest.
  final int guestPort;

  /// The host LOOPBACK port the bridge answers on. Same as [guestPort]
  /// whenever that port was free on the host, so `localhost:3000` means the
  /// same thing on both sides of the boundary.
  final int hostPort;

  /// The LAN-visible port, when this forward has been explicitly exposed.
  /// Null means loopback only — the default, because a dev server on shared
  /// wifi is not something to publish by accident.
  final int? lanPort;

  /// How it came to exist.
  final RigPortOrigin origin;

  /// A dev domain (`myapp.test`) routed to this port inside the Browser (VM),
  /// when one was assigned.
  final String? domain;

  /// The guest process listening on it, when known.
  final String? process;

  /// Whether something in the guest is listening right now. A manual forward
  /// outlives its process and reports itself inactive instead of vanishing.
  final bool active;

  /// Wire form for the `rig.ports` ops.
  Map<String, dynamic> toWire() => {
    'guest_port': guestPort,
    'host_port': hostPort,
    if (lanPort != null) 'lan_port': lanPort,
    'origin': origin.wire,
    if (domain != null) 'domain': domain,
    if (process != null) 'process': process,
    'active': active,
  };
}

/// Everything the ports panel renders for one rig.
class RigPortsSnapshot {
  /// Creates a [RigPortsSnapshot].
  const RigPortsSnapshot({
    required this.rigId,
    required this.autoForward,
    required this.ports,
    this.tlsEnabled = false,
  });

  /// The rig.
  final String rigId;

  /// Whether newly discovered guest ports are forwarded automatically.
  final bool autoForward;

  /// Whether dev domains are served over HTTPS in the Browser (VM) — the
  /// domain router has a TLS lane, so the panel shows `https://myapp.test`
  /// rather than promising a scheme the router cannot answer.
  final bool tlsEnabled;

  /// Current forwards, ascending by guest port.
  final List<RigPortForward> ports;

  /// Wire form.
  Map<String, dynamic> toWire() => {
    'rig_id': rigId,
    'auto_forward': autoForward,
    'tls_enabled': tlsEnabled,
    'ports': [for (final p in ports) p.toWire()],
  };
}

/// A dev domain that may be routed into a rig: `myapp.test` or
/// `myapp.localhost`. `.test` is reserved for exactly this (RFC 2606) and
/// `*.localhost` already resolves to loopback inside Chromium; anything else
/// would shadow a real (or future-real) name inside the browser VM.
final RegExp kRigPortDomainPattern = RegExp(
  r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.(test|localhost)$',
);

/// Splices two sockets until either side finishes.
///
/// The same hardening as the sandbox proxies: both `done` futures get a
/// listener BEFORE any write, because a peer that resets mid-tunnel reports
/// the failure there and an unobserved `done` error is an unhandled async
/// exception that takes the whole server down.
void spliceSockets(Socket a, Socket b) {
  unawaited(a.done.catchError((_) {}));
  unawaited(b.done.catchError((_) {}));
  void forward(Socket from, Socket to) {
    from.listen(
      (chunk) {
        try {
          to.add(chunk);
        } on Object {
          // Write side already gone; the other direction tears the pair down.
        }
      },
      onError: (_) {},
      onDone: () {
        try {
          unawaited(to.close().catchError((_) {}));
        } on Object {
          // Already closed.
        }
      },
      cancelOnError: false,
    );
  }

  forward(a, b);
  forward(b, a);
}

/// One host listener relaying every connection into a guest port through the
/// rig's mux.
///
/// Loopback always; a LAN listener only when explicitly exposed. The LAN port
/// is OS-assigned (never the guest port) so exposure is always a deliberate,
/// visible address — `<server-ip>:<random>` — rather than a guessable one.
class HostPortBridge {
  HostPortBridge._({
    required this.guestPort,
    required this.muxHostPort,
    required ServerSocket loopback,
  }) : _loopback = loopback {
    _accept(loopback, isLan: false);
  }

  /// Opens the loopback listener, preferring `127.0.0.1:<guestPort>` and
  /// falling back to an OS-assigned port when it is taken.
  static Future<HostPortBridge> start({
    required int guestPort,
    required int muxHostPort,
  }) async {
    ServerSocket loopback;
    try {
      loopback = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        guestPort,
      );
    } on SocketException {
      // The user's own host service (or another rig's bridge) holds it. An
      // ephemeral port still works — the panel shows the real number.
      loopback = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    }
    return HostPortBridge._(
      guestPort: guestPort,
      muxHostPort: muxHostPort,
      loopback: loopback,
    );
  }

  /// The guest port this bridge serves.
  final int guestPort;

  /// The host loopback port the rig's mux was forwarded to.
  final int muxHostPort;

  final ServerSocket _loopback;
  ServerSocket? _lan;
  bool _closed = false;

  /// The host loopback port this bridge answers on.
  int get hostPort => _loopback.port;

  /// The LAN port, when exposed.
  int? get lanPort => _lan?.port;

  /// Opens (or closes) the LAN listener.
  Future<void> setLanExposed(bool exposed) async {
    if (exposed == (_lan != null) || _closed) {
      return;
    }
    if (!exposed) {
      final lan = _lan;
      _lan = null;
      await lan?.close();
      return;
    }
    final lan = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _lan = lan;
    _accept(lan, isLan: true);
  }

  void _accept(ServerSocket server, {required bool isLan}) {
    server.listen(
      (client) => unawaited(_relay(client)),
      onError: (Object e) {
        if (!_closed) {
          CcInfraLog.warning(
            'rig/ports: ${isLan ? 'LAN' : 'loopback'} listener for '
            ':$guestPort failed: $e',
          );
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _relay(Socket client) async {
    final Socket upstream;
    try {
      upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        muxHostPort,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      // The rig is parked, closing or gone; the panel reports its state.
      client.destroy();
      return;
    }
    // The mux preamble: which guest port this connection is for.
    upstream.add(utf8.encode('$guestPort\n'));
    spliceSockets(client, upstream);
  }

  /// Closes every listener. Idempotent; in-flight connections finish on their
  /// own.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _loopback.close();
    await _lan?.close();
    _lan = null;
  }
}

/// Starts one guest-side reverse-tunnel channel: an interactive process whose
/// stdio is wired to an in-guest listener.
typedef GuestChannelStart = Future<Process> Function(List<String> guestArgv);

/// A guest-loopback listener whose connections are served by the HOST.
///
/// The only guest→host lane that exists under a filtered NIC (see the file
/// header). Each slot is one `machine exec -i` running a one-shot socat
/// listener; the first bytes a guest client sends wake the slot, the host
/// dials the real target and splices, and the slot respawns for the next
/// connection. [slots] bounds concurrency — a browser bursts a handful of
/// parallel fetches, a credential helper never needs more than one.
class GuestReverseTunnel {
  /// Creates a [GuestReverseTunnel].
  GuestReverseTunnel({
    required this.guestPort,
    required GuestChannelStart startChannel,
    required Future<Socket?> Function() dialTarget,
    this.slots = 2,
  }) : _startChannel = startChannel,
       _dialTarget = dialTarget;

  /// The guest loopback port to listen on.
  final int guestPort;

  /// How many connections can be in flight at once.
  final int slots;

  final GuestChannelStart _startChannel;
  final Future<Socket?> Function() _dialTarget;

  final List<Process> _channels = [];
  bool _stopped = false;

  /// Arms every slot.
  void start() {
    for (var i = 0; i < slots; i++) {
      unawaited(_runSlot());
    }
  }

  Future<void> _runSlot() async {
    var consecutiveFailures = 0;
    while (!_stopped) {
      Process? process;
      var sawTraffic = false;
      try {
        process = await _startChannel([
          'socat',
          'STDIO',
          // reuseport lets every slot share the port; the kernel picks one
          // listener per connection. One-shot (no fork): the connection's
          // bytes must reach THIS channel's stdio, and a fork would strand
          // children with nowhere to send.
          'TCP-LISTEN:$guestPort,bind=127.0.0.1,reuseaddr,reuseport',
        ]);
        _channels.add(process);
        unawaited(process.stderr.drain<void>());
        Socket? upstream;
        final done = Completer<void>();
        late StreamSubscription<List<int>> sub;
        sub = process.stdout.listen(
          (chunk) {
            sawTraffic = true;
            final open = upstream;
            if (open != null) {
              try {
                open.add(chunk);
              } on Object {
                // Target gone; the exec is killed below.
              }
              return;
            }
            // First bytes: dial the target, replay them, then stream.
            sub.pause();
            unawaited(() async {
              try {
                final socket = await _dialTarget();
                if (socket == null) {
                  process!.kill(ProcessSignal.sigkill);
                  return;
                }
                upstream = socket;
                unawaited(socket.done.catchError((_) {}));
                socket.add(chunk);
                // Target → guest.
                socket.listen(
                  (bytes) => process!.stdin.add(bytes),
                  onDone: () => process!.kill(ProcessSignal.sigkill),
                  onError: (_) => process!.kill(ProcessSignal.sigkill),
                  cancelOnError: false,
                );
              } on Object {
                process!.kill(ProcessSignal.sigkill);
              } finally {
                sub.resume();
              }
            }());
          },
          onDone: () {
            if (!done.isCompleted) {
              done.complete();
            }
          },
          onError: (Object _) {
            if (!done.isCompleted) {
              done.complete();
            }
          },
          cancelOnError: false,
        );
        await done.future;
        try {
          upstream?.destroy();
        } on Object {
          // Already gone.
        }
      } on Object catch (e) {
        if (!_stopped) {
          CcInfraLog.debug('rig/ports: reverse-tunnel slot failed: $e');
        }
      } finally {
        if (process != null) {
          _channels.remove(process);
          process.kill(ProcessSignal.sigkill);
        }
      }
      if (_stopped) {
        return;
      }
      // A channel that died without ever carrying a byte is a broken guest
      // (or a machine going down): back off so the respawn loop is not a
      // process-spawn storm, but keep trying while the rig lives.
      if (sawTraffic) {
        consecutiveFailures = 0;
      } else {
        consecutiveFailures++;
        final delay = consecutiveFailures.clamp(1, 10);
        await Future<void>.delayed(Duration(seconds: delay));
      }
    }
  }

  /// Kills every channel and stops respawning.
  void stop() {
    _stopped = true;
    for (final process in _channels.toList()) {
      process.kill(ProcessSignal.sigkill);
    }
    _channels.clear();
  }
}

/// Resolves the `Host` header from an HTTP request head. Returns null when
/// there is none — an anonymous request gets no dev-domain route.
@visibleForTesting
String? hostHeaderOf(List<int> head) {
  final text = ascii.decode(head, allowInvalid: true);
  for (final line in const LineSplitter().convert(text).skip(1)) {
    if (line.isEmpty) {
      break;
    }
    final colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    if (line.substring(0, colon).trim().toLowerCase() == 'host') {
      var value = line.substring(colon + 1).trim().toLowerCase();
      final port = value.lastIndexOf(':');
      if (port > 0 && !value.contains(']')) {
        value = value.substring(0, port);
      }
      return value;
    }
  }
  return null;
}

/// Routes dev domains (`myapp.test`) to forwarded guest ports by HTTP Host
/// header.
///
/// Listens on ONE host loopback port. Inside the Browser (VM), a reverse
/// tunnel pins guest port 80 to it and Chromium resolves `*.test`/
/// `*.localhost` to loopback, so `http://myapp.test/` becomes: guest :80 →
/// reverse tunnel → this router → the mapped rig's mux → the terminal VM's
/// dev server. Nothing here terminates TLS — this is a dev convenience for
/// plain HTTP, which is what dev servers speak.
class RigDomainRouter {
  /// Creates a [RigDomainRouter]. [muxPortOf] resolves a rig's mux forward.
  RigDomainRouter({required int? Function(String rigId) muxPortOf})
    : _muxPortOf = muxPortOf;

  final int? Function(String rigId) _muxPortOf;
  final Map<String, ({String rigId, int guestPort})> _routes = {};
  ServerSocket? _server;
  SecureServerSocket? _tlsServer;

  /// The router's host loopback port, once started.
  int? get port => _server?.port;

  /// The router's TLS port, once [startTls] succeeded. Null means the HTTPS
  /// lane is not available and only plain HTTP is routed.
  int? get tlsPort => _tlsServer?.port;

  /// Starts the listener. Idempotent.
  Future<int> start() async {
    final existing = _server;
    if (existing != null) {
      return existing.port;
    }
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(
      (client) => unawaited(_route(client)),
      onError: (_) {},
      cancelOnError: false,
    );
    return server.port;
  }

  /// Starts the HTTPS lane: the same Host-header routing behind a TLS
  /// handshake. Idempotent.
  ///
  /// One [SecurityContext] for every domain — the dev leaf carries wildcard
  /// SANs for both dev TLDs, because a Dart listener has no per-SNI
  /// certificate selection and a shared wildcard leaf never needs a rebind
  /// when a domain is added. A [SecureSocket] IS a [Socket], so everything
  /// after the handshake is the exact `_route` path the HTTP lane uses.
  Future<int?> startTls(SecurityContext context) async {
    final existing = _tlsServer;
    if (existing != null) {
      return existing.port;
    }
    try {
      final server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      _tlsServer = server;
      server.listen(
        (client) => unawaited(_route(client)),
        // A handshake against a client that pins some OTHER key (or speaks
        // something that is not TLS) fails per connection; the listener must
        // outlive every such failure.
        onError: (_) {},
        cancelOnError: false,
      );
      return server.port;
    } on Object catch (e) {
      CcInfraLog.warning('rig/ports: HTTPS lane failed to start: $e');
      return null;
    }
  }

  /// Maps [domain] to [guestPort] on [rigId]. Replaces any previous mapping.
  void setRoute(
    String domain, {
    required String rigId,
    required int guestPort,
  }) {
    _routes[domain.toLowerCase()] = (rigId: rigId, guestPort: guestPort);
  }

  /// Removes [domain]'s mapping.
  void removeRoute(String domain) => _routes.remove(domain.toLowerCase());

  /// Removes every mapping into [rigId].
  void removeRig(String rigId) =>
      _routes.removeWhere((_, target) => target.rigId == rigId);

  /// Whether [domain] is currently routed.
  bool hasRoute(String domain) => _routes.containsKey(domain.toLowerCase());

  Future<void> _route(Socket client) async {
    // Peek the request head. 16 KB is far above any dev request line +
    // headers; a head that will not finish inside it is not HTTP.
    final head = <int>[];
    StreamSubscription<List<int>>? sub;
    final headDone = Completer<void>();
    sub = client.listen(
      (chunk) {
        head.addAll(chunk);
        if (_headComplete(head) || head.length > 16384) {
          sub!.pause();
          if (!headDone.isCompleted) {
            headDone.complete();
          }
        }
      },
      onDone: () {
        if (!headDone.isCompleted) {
          headDone.complete();
        }
      },
      onError: (_) {
        if (!headDone.isCompleted) {
          headDone.complete();
        }
      },
      cancelOnError: false,
    );
    try {
      await headDone.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      await sub.cancel();
      client.destroy();
      return;
    }

    final host = hostHeaderOf(head);
    final target = host == null ? null : _routes[host];
    final muxPort = target == null ? null : _muxPortOf(target.rigId);
    if (target == null || muxPort == null) {
      try {
        client.add(
          utf8.encode('HTTP/1.1 502 Bad Gateway\r\ncontent-length: 0\r\n\r\n'),
        );
        await client.flush();
      } on Object {
        // Client already gone.
      }
      await sub.cancel();
      client.destroy();
      return;
    }

    final Socket upstream;
    try {
      upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        muxPort,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      await sub.cancel();
      client.destroy();
      return;
    }
    unawaited(upstream.done.catchError((_) {}));
    upstream
      ..add(utf8.encode('${target.guestPort}\n'))
      // Replay what was consumed while sniffing the Host header.
      ..add(head);
    // Hand the rest of the client stream over.
    sub
      ..onData((chunk) {
        try {
          upstream.add(chunk);
        } on Object {
          // Upstream gone.
        }
      })
      ..onDone(() => unawaited(upstream.close().catchError((_) {})))
      ..onError((Object _) => upstream.destroy())
      ..resume();
    upstream.listen(
      (chunk) {
        try {
          client.add(chunk);
        } on Object {
          // Client gone.
        }
      },
      onDone: () => unawaited(client.close().catchError((_) {})),
      onError: (_) => client.destroy(),
      cancelOnError: false,
    );
  }

  static bool _headComplete(List<int> head) {
    for (var i = 3; i < head.length; i++) {
      if (head[i] == 10 &&
          head[i - 1] == 13 &&
          head[i - 2] == 10 &&
          head[i - 3] == 13) {
        return true;
      }
    }
    return false;
  }

  /// Closes both listeners and every mapping.
  Future<void> dispose() async {
    _routes.clear();
    final server = _server;
    _server = null;
    await server?.close();
    final tls = _tlsServer;
    _tlsServer = null;
    await tls?.close();
  }
}
