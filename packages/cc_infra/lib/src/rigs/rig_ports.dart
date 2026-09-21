// The domain router's request-sniffing subscription and the client socket it
// splices are handed off between methods (`_route` peeks, then rewires the
// same subscription onto the upstream), which the lifetime lints cannot follow.
// ignore_for_file: cancel_subscriptions, close_sinks

// Port visibility and forwarding for enclosed (smolvm) rigs.
//
// A guest `pnpm dev` on :3000 must appear in the ports panel, be reachable as
// host `localhost:3000` (and optionally LAN), and as `localhost:3000` /
// `myapp.test` from the enclosed browser.
//
// smolvm `-p` forwards are fixed at create time; a guest under any egress
// filter cannot dial host loopback (`--mount-socket` never reaches the host).
// Host→guest: one `-p` to a fixed mux; the dialer checks the guest is
// LISTENING before splicing — without that, a dead guest server loops connect
// back through the host bridge. Guest→host: one multiplexed reverse tunnel
// over `machine exec -i` (`cc-revtun`); binds `127.0.0.1` and `[::1]` because
// Chromium/Firefox prefer `::1`. Credential broker stays one-shot socat.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/reverse_mux.dart';
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

/// Everything the ports panel renders for one rig or host-shell session.
class RigPortsSnapshot {
  /// Creates a [RigPortsSnapshot].
  const RigPortsSnapshot({
    required this.rigId,
    required this.autoForward,
    required this.ports,
    this.tlsEnabled = false,
    this.browserReachable = false,
    this.androidReachable = false,
  });

  /// The rig, or the host-shell session id.
  final String rigId;

  /// Whether newly discovered guest ports are forwarded automatically.
  final bool autoForward;

  /// Whether dev domains are served over HTTPS in the Browser (VM) — the
  /// domain router has a TLS lane, so the panel shows `https://myapp.test`
  /// rather than promising a scheme the router cannot answer.
  final bool tlsEnabled;

  /// Whether a Browser (VM) in the same space is attached, so `localhost`
  /// inside that guest reaches these ports.
  final bool browserReachable;

  /// Whether an Android rig in the same space is attached, so `localhost`
  /// inside the emulator reaches these ports via `adb reverse`.
  final bool androidReachable;

  /// Current forwards, ascending by guest port.
  final List<RigPortForward> ports;

  /// Wire form.
  Map<String, dynamic> toWire() => {
    'rig_id': rigId,
    'auto_forward': autoForward,
    'tls_enabled': tlsEnabled,
    'browser_reachable': browserReachable,
    'android_reachable': androidReachable,
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
    this.muxHostPort,
    this.directTargetPort,
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
    final loopback = await _bindLoopback(guestPort);
    return HostPortBridge._(
      guestPort: guestPort,
      muxHostPort: muxHostPort,
      loopback: loopback,
    );
  }

  /// Opens a loopback listener that splices to another HOST port, with no
  /// mux preamble — host-shell remapping (`5173 → 8080`) and nothing else.
  static Future<HostPortBridge> startDirect({
    required int preferredHostPort,
    required int targetHostPort,
  }) async {
    final loopback = await _bindLoopback(preferredHostPort);
    return HostPortBridge._(
      guestPort: preferredHostPort,
      directTargetPort: targetHostPort,
      loopback: loopback,
    );
  }

  static Future<ServerSocket> _bindLoopback(int preferred) async {
    try {
      return await ServerSocket.bind(InternetAddress.loopbackIPv4, preferred);
    } on SocketException {
      // The user's own host service (or another rig's bridge) holds it. An
      // ephemeral port still works — the panel shows the real number.
      return ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    }
  }

  /// The guest port this bridge serves (mux mode), or the preferred bind
  /// (direct mode).
  final int guestPort;

  /// The host loopback port the rig's mux was forwarded to. Null in direct
  /// mode.
  final int? muxHostPort;

  /// Host loopback port to splice to, with no mux preamble. Null in mux mode.
  final int? directTargetPort;

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
    final target = muxHostPort ?? directTargetPort;
    if (target == null) {
      client.destroy();
      return;
    }
    final Socket upstream;
    try {
      upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        target,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      // The rig is parked, closing or gone; the panel reports its state.
      client.destroy();
      return;
    }
    // The mux preamble: which guest port this connection is for. Direct
    // mode is already on the host — no preamble, or the process would
    // read a "5173\n" line as the start of its HTTP request.
    if (muxHostPort != null) {
      upstream.add(utf8.encode('$guestPort\n'));
    }
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

/// A LAN-only splice onto an existing host loopback listener.
///
/// Host-shell same-number mapping does not own a [HostPortBridge] (the
/// process is already bound on loopback), but the user can still share it
/// on the LAN: this binds `0.0.0.0:<ephemeral>` and forwards to
/// `127.0.0.1:<targetHostPort>` with no mux preamble.
class HostLanRelay {
  HostLanRelay._(this._targetHostPort, this._lan) {
    _lan.listen(
      (client) => unawaited(_relay(client)),
      onError: (_) {},
      cancelOnError: false,
    );
  }

  /// Opens the LAN listener.
  static Future<HostLanRelay> start({required int targetHostPort}) async {
    final lan = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    return HostLanRelay._(targetHostPort, lan);
  }

  final int _targetHostPort;
  final ServerSocket _lan;
  bool _closed = false;

  /// The LAN port this relay answers on.
  int get lanPort => _lan.port;

  Future<void> _relay(Socket client) async {
    final Socket upstream;
    try {
      upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _targetHostPort,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      client.destroy();
      return;
    }
    spliceSockets(client, upstream);
  }

  /// Closes the LAN listener. Idempotent.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _lan.close();
  }
}

/// Starts one guest-side reverse-tunnel channel: an interactive process whose
/// stdio is wired to an in-guest listener.
typedef GuestChannelStart = Future<Process> Function(List<String> guestArgv);

/// Concurrent TCP streams one Browser (VM) reverse mux will accept.
///
/// Used to be one `machine exec` per connection. Four of those refused the
/// rest of a page's fetches (white page); sixteen still respawned an exec on
/// every keep-alive miss. The mux carries this many streams over one exec.
const kBrowserReverseTunnelSlots = 128;

/// socat listen address for one reverse-tunnel slot.
///
/// IPv4 and IPv6 are separate listeners. Chromium and Firefox resolve
/// `localhost` to `::1` first; a `bind=127.0.0.1` listener then fails as
/// connection-refused rather than falling back to IPv4.
String guestReverseTunnelListen(int port, {required bool ipv6}) {
  // TCP4-LISTEN matches the DevTools relay in the same guest. Plain
  // `TCP-LISTEN` is PF_UNSPEC and has failed to bind IPv4 on Debian.
  // `reuseport` is what lets every slot share the port; without it only
  // one connection is accepted at a time, the document loads, and every
  // parallel module/HMR fetch is connection-refused — a white page.
  if (ipv6) {
    return 'TCP6-LISTEN:$port,bind=[::1],reuseaddr,reuseport,nodelay';
  }
  return 'TCP4-LISTEN:$port,bind=127.0.0.1,reuseaddr,reuseport,nodelay';
}

/// Guest argv for one reverse-tunnel slot: a login-less shell so `socat` is
/// found on PATH, then stdio spliced to a one-shot listen.
List<String> guestReverseTunnelArgv(int port, {required bool ipv6}) => [
  'sh',
  '-c',
  r'exec "$(command -v socat)" STDIO "$1"',
  'socat',
  guestReverseTunnelListen(port, ipv6: ipv6),
];

/// A guest-loopback listener whose connections are served by the HOST.
///
/// The only guest→host lane that exists under a filtered NIC (see the file
/// header). [slots] `<= 1` is the credential-broker path: one one-shot
/// socat. Anything larger (the Browser (VM)) is one multiplexed exec that
/// accepts up to [slots] TCP streams, so a burst of fetches is not one
/// process spawn per connection.
class GuestReverseTunnel {
  /// Creates a [GuestReverseTunnel].
  GuestReverseTunnel({
    required this.guestPort,
    required this._startChannel,
    required this._dialTarget,
    this.slots = 2,
    this.ensureMux,
  });

  /// The guest loopback port to listen on.
  final int guestPort;

  /// Max in-flight TCP streams (mux) or exec slots (one-shot).
  final int slots;

  /// Installs `cc-revtun` in the guest before the mux exec starts.
  final Future<void> Function()? ensureMux;

  final GuestChannelStart _startChannel;
  final Future<Socket?> Function() _dialTarget;

  final List<Process> _channels = [];
  bool _stopped = false;

  /// Arms the listener. One-shot socat when [slots] is 1; otherwise the
  /// multiplexed reverse mux.
  void start() {
    if (slots <= 1) {
      unawaited(_runSlot(ipv6: false));
      return;
    }
    unawaited(_runMux());
  }

  Future<void> _runMux() async {
    var consecutiveFailures = 0;
    while (!_stopped) {
      Process? process;
      ReverseMuxHost? host;
      var sawTraffic = false;
      try {
        await ensureMux?.call();
        if (_stopped) {
          return;
        }
        process = await _startChannel(
          guestReverseMuxArgv(guestPort, maxStreams: slots),
        );
        _channels.add(process);
        host = ReverseMuxHost(
          stdin: process.stdin,
          stdout: process.stdout,
          stderr: process.stderr,
          dialTarget: _dialTarget,
          onTraffic: () => sawTraffic = true,
        );
        unawaited(
          process.exitCode.then((_) {
            host?.close();
          }),
        );
        await host.done;
        sawTraffic = sawTraffic || host.sawTraffic;
      } on Object catch (e) {
        if (!_stopped) {
          CcInfraLog.debug('rig/ports: reverse-mux :$guestPort failed: $e');
        }
      } finally {
        host?.close();
        if (process != null) {
          _channels.remove(process);
          process.kill(ProcessSignal.sigkill);
        }
      }
      if (_stopped) {
        return;
      }
      if (sawTraffic) {
        consecutiveFailures = 0;
      } else {
        consecutiveFailures++;
        final delay = consecutiveFailures.clamp(1, 10);
        await Future<void>.delayed(Duration(seconds: delay));
      }
    }
  }

  Future<void> _runSlot({required bool ipv6}) async {
    var consecutiveFailures = 0;
    while (!_stopped) {
      Process? process;
      var sawTraffic = false;
      try {
        process = await _startChannel(
          guestReverseTunnelArgv(guestPort, ipv6: ipv6),
        );
        _channels.add(process);
        unawaited(
          process.stderr.transform(const Utf8Decoder()).forEach((line) {
            final text = line.trim();
            if (text.isNotEmpty && !_stopped) {
              CcInfraLog.warning(
                'rig/ports: reverse-tunnel :$guestPort '
                '${ipv6 ? 'IPv6' : 'IPv4'} stderr: $text',
              );
            }
          }),
        );
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
  /// Creates a [RigDomainRouter].
  ///
  /// [_muxPortOf] resolves an exec rig's mux forward. [_hostPortOf] resolves
  /// a host-shell source's published host port when there is no mux — the
  /// domain then dials that loopback address with no preamble.
  RigDomainRouter({
    required int? Function(String sourceId) muxPortOf,
    int? Function(String sourceId, int guestPort)? hostPortOf,
  }) : _muxPortOf = muxPortOf,
       _hostPortOf = hostPortOf;

  final int? Function(String sourceId) _muxPortOf;
  final int? Function(String sourceId, int guestPort)? _hostPortOf;
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
    final hostPort = (target == null || muxPort != null)
        ? null
        : _hostPortOf?.call(target.rigId, target.guestPort);
    if (target == null || (muxPort == null && hostPort == null)) {
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
        muxPort ?? hostPort!,
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      await sub.cancel();
      client.destroy();
      return;
    }
    unawaited(upstream.done.catchError((_) {}));
    if (muxPort != null) {
      upstream.add(utf8.encode('${target.guestPort}\n'));
    }
    // Replay what was consumed while sniffing the Host header.
    upstream.add(head);
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
