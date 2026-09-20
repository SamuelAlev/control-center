// Multiplexed guest→host reverse tunnel.
//
// A Browser (VM) loading a page often opens a handful of HTTP/1.1
// connections and then issues thousands of small fetches on them. The
// original reverse tunnel spent one `machine exec -i` per TCP connection
// (`fork` on that stdio would mix bytes), so a large burst either
// connection-refused (slot pool exhausted) or paid process-spawn latency
// on every keep-alive miss. This mux carries many guest TCP streams over
// ONE exec stdio with a length-prefixed frame, using only perl-base —
// already on Debian slim and Ubuntu cloud images, so the browser pack does
// not grow.
//
// `-i` without `-t` is a raw pipe (a PTY would mangle the frames). The host
// still dials a pre-configured target per OPEN; the guest cannot pick where
// a stream lands.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:meta/meta.dart';

/// Where the reverse mux lands inside a guest.
const String kRigReverseMuxPath = '/usr/local/bin/cc-revtun';

/// Header is `u8 type`, `u32be stream_id`, `u32be length`.
const int kReverseMuxHeaderBytes = 9;

/// Largest DATA payload. Bigger is split; a larger claimed length is a
/// protocol error and the exec is killed.
const int kReverseMuxMaxPayload = 32 * 1024;

/// Guest accepted a TCP connection.
const int kReverseMuxOpen = 1;

/// Stream payload, either direction.
const int kReverseMuxData = 2;

/// Orderly FIN.
const int kReverseMuxClose = 3;

/// Abort. The other side drops the stream.
const int kReverseMuxReset = 4;

/// Guest-side mux. Listens on `127.0.0.1` and `::1`, frames stdio.
///
/// Socket.pm + IO::Select only — perl-base, no extra packages.
const String kRigReverseMuxScript = r'''
#!/usr/bin/perl
use strict;
use warnings;
use IO::Select;
use IO::Socket::INET;
use Socket qw(
  AF_INET6 SOCK_STREAM SOL_SOCKET SO_REUSEADDR
  IPPROTO_TCP TCP_NODELAY pack_sockaddr_in6 inet_pton
);

my $port = $ARGV[0];
my $max = $ARGV[1] || 128;
die "usage: cc-revtun PORT [MAX]\n" unless defined $port && $port =~ /^[0-9]+$/;

binmode STDIN;
binmode STDOUT;
select((select(STDOUT), $| = 1)[0]);

sub nodelay {
  my ($s) = @_;
  setsockopt($s, IPPROTO_TCP, TCP_NODELAY, pack('l', 1));
}

my $s4 = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1',
  LocalPort => $port,
  Proto     => 'tcp',
  Listen    => 128,
  ReuseAddr => 1,
) or die "bind 127.0.0.1:$port: $!\n";
nodelay($s4);

my $s6;
{
  socket(my $sock, AF_INET6, SOCK_STREAM, 0) or last;
  setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, pack('l', 1));
  my $sin = eval { pack_sockaddr_in6($port, inet_pton(AF_INET6, '::1')) };
  last unless $sin;
  bind($sock, $sin) or last;
  listen($sock, 128) or last;
  $s6 = $sock;
}

my $sel = IO::Select->new(\*STDIN, $s4);
$sel->add($s6) if $s6;

my %id_of;
my %sock_of;
my $next = 1;
my $in = '';

sub frame {
  my ($type, $id, $payload) = @_;
  $payload = '' unless defined $payload;
  my $body = pack('C N N', $type, $id, length($payload)) . $payload;
  my $off = 0;
  while ($off < length($body)) {
    my $n = syswrite(STDOUT, $body, length($body) - $off, $off);
    exit 0 unless defined $n && $n > 0;
    $off += $n;
  }
}

sub drop {
  my ($id, $reply) = @_;
  my $s = delete $sock_of{$id} or return;
  my $fn = eval { fileno($s) };
  delete $id_of{$fn} if defined $fn;
  $sel->remove($s);
  close($s);
  frame($reply, $id, '') if $reply;
}

while (1) {
  my @ready = $sel->can_read();
  last unless @ready;
  for my $fh (@ready) {
    if ($fh == $s4 || (defined $s6 && $fh == $s6)) {
      my $c;
      if ($fh == $s4) {
        $c = $s4->accept;
      } else {
        my $new;
        accept($new, $s6) or next;
        $c = $new;
      }
      next unless $c;
      if (scalar(keys %sock_of) >= $max) {
        close($c);
        next;
      }
      $c->autoflush(1) if eval { $c->can('autoflush') };
      nodelay($c);
      my $id = $next++;
      $next = 1 if $next > 0x7fffffff;
      $sock_of{$id} = $c;
      $id_of{fileno($c)} = $id;
      $sel->add($c);
      frame(1, $id, '');
      next;
    }
    if (fileno($fh) == fileno(STDIN)) {
      my $n = sysread(STDIN, my $chunk, 65536);
      exit 0 if !defined $n || $n == 0;
      $in .= $chunk;
      while (length($in) >= 9) {
        my ($type, $id, $len) = unpack('C N N', $in);
        exit 1 if $len > 32768;
        last if length($in) < 9 + $len;
        my $payload = substr($in, 9, $len);
        $in = substr($in, 9 + $len);
        if ($type == 2) {
          my $s = $sock_of{$id};
          syswrite($s, $payload) if $s;
        } elsif ($type == 3 || $type == 4) {
          drop($id, 0);
        }
      }
      next;
    }
    my $fn = eval { fileno($fh) };
    next unless defined $fn;
    my $id = $id_of{$fn};
    next unless defined $id;
    my $n = sysread($fh, my $chunk, 16384);
    if (!defined $n || $n == 0) {
      drop($id, 3);
      next;
    }
    while (length($chunk) > 0) {
      my $part = substr($chunk, 0, 32768, '');
      frame(2, $id, $part);
    }
  }
}
''';

/// Installs [kRigReverseMuxScript] into the guest. Idempotent.
String buildReverseMuxBootstrapCommand() {
  final encoded = base64Encode(utf8.encode(kRigReverseMuxScript));
  return 'echo $encoded | base64 -d > $kRigReverseMuxPath && '
      'chmod 755 $kRigReverseMuxPath';
}

/// Guest argv: perl with unicode stdio layers off, then the installed mux.
List<String> guestReverseMuxArgv(int port, {int maxStreams = 128}) => [
  'perl',
  '-C0',
  kRigReverseMuxPath,
  '$port',
  '$maxStreams',
];

/// One decoded mux frame.
@immutable
class ReverseMuxFrame {
  /// Creates a [ReverseMuxFrame].
  const ReverseMuxFrame({
    required this.type,
    required this.streamId,
    required this.payload,
  });

  /// [kReverseMuxOpen], [kReverseMuxData], [kReverseMuxClose] or
  /// [kReverseMuxReset].
  final int type;

  /// Guest-allocated stream id (never 0).
  final int streamId;

  /// DATA bytes; empty for OPEN/CLOSE/RESET.
  final Uint8List payload;
}

/// Encodes one mux frame.
Uint8List encodeReverseMuxFrame({
  required int type,
  required int streamId,
  Uint8List? payload,
}) {
  final data = payload ?? Uint8List(0);
  if (data.length > kReverseMuxMaxPayload) {
    throw ArgumentError.value(data.length, 'payload');
  }
  final out = Uint8List(kReverseMuxHeaderBytes + data.length);
  final view = ByteData.sublistView(out);
  view.setUint8(0, type);
  view.setUint32(1, streamId);
  view.setUint32(5, data.length);
  if (data.isNotEmpty) {
    out.setRange(kReverseMuxHeaderBytes, out.length, data);
  }
  return out;
}

/// Incremental decoder for the mux byte stream.
class ReverseMuxReader {
  final BytesBuilder _pending = BytesBuilder(copy: false);

  /// Consumes [chunk] and returns every complete frame.
  List<ReverseMuxFrame> add(List<int> chunk) {
    if (chunk.isEmpty) {
      return const [];
    }
    _pending.add(chunk);
    final bytes = _pending.takeBytes();
    var offset = 0;
    final frames = <ReverseMuxFrame>[];
    while (offset + kReverseMuxHeaderBytes <= bytes.length) {
      final view = ByteData.sublistView(bytes, offset);
      final type = view.getUint8(0);
      final id = view.getUint32(1);
      final len = view.getUint32(5);
      if (len > kReverseMuxMaxPayload) {
        throw StateError('reverse-mux frame too large ($len)');
      }
      if (offset + kReverseMuxHeaderBytes + len > bytes.length) {
        break;
      }
      final start = offset + kReverseMuxHeaderBytes;
      frames.add(
        ReverseMuxFrame(
          type: type,
          streamId: id,
          payload: Uint8List.fromList(bytes.sublist(start, start + len)),
        ),
      );
      offset += kReverseMuxHeaderBytes + len;
    }
    if (offset < bytes.length) {
      _pending.add(bytes.sublist(offset));
    }
    return frames;
  }
}

/// Host half of the mux: stdout is frames from the guest, stdin is frames
/// to the guest, each OPEN dials [dialTarget].
class ReverseMuxHost {
  /// Creates a [ReverseMuxHost].
  ReverseMuxHost({
    required IOSink stdin,
    required Stream<List<int>> stdout,
    required Future<Socket?> Function() dialTarget,
    this.onTraffic,
    Stream<List<int>>? stderr,
  }) : _stdin = stdin,
       _dialTarget = dialTarget {
    _stdoutSub = stdout.listen(
      _onStdout,
      onDone: close,
      onError: (_) => close(),
      cancelOnError: false,
    );
    if (stderr != null) {
      _stderrSub = stderr
          .transform(const Utf8Decoder())
          .listen(
            (line) {
              final text = line.trim();
              if (text.isNotEmpty) {
                CcInfraLog.warning('rig/ports: reverse-mux stderr: $text');
              }
            },
            onError: (_) {},
            cancelOnError: false,
          );
    }
  }

  final IOSink _stdin;
  final Future<Socket?> Function() _dialTarget;

  /// Called the first time a stream carries a byte, so the respawn loop can
  /// tell a live mux from a guest that never listened.
  final void Function()? onTraffic;

  final ReverseMuxReader _reader = ReverseMuxReader();
  final Map<int, Socket> _streams = {};
  final Completer<void> _done = Completer<void>();
  StreamSubscription<List<int>>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  Future<void> _chain = Future<void>.value();
  var _closed = false;
  var _sawTraffic = false;

  /// Completes when the guest exec dies or [close] is called.
  Future<void> get done => _done.future;

  /// Whether any stream carried a byte.
  bool get sawTraffic => _sawTraffic;

  void _markTraffic() {
    if (!_sawTraffic) {
      _sawTraffic = true;
      onTraffic?.call();
    }
  }

  void _onStdout(List<int> chunk) {
    if (_closed) {
      return;
    }
    _chain = _chain.then(
      (_) async {
        if (_closed) {
          return;
        }
        final List<ReverseMuxFrame> frames;
        try {
          frames = _reader.add(chunk);
        } on Object catch (e) {
          CcInfraLog.debug('rig/ports: reverse-mux decode failed: $e');
          close();
          return;
        }
        // DATA can follow OPEN on the same pipe in the same read. The socket
        // for that stream must be dialled before those bytes are written.
        for (final frame in frames) {
          await _onFrame(frame);
        }
      },
      onError: (Object e) {
        CcInfraLog.debug('rig/ports: reverse-mux host failed: $e');
        close();
      },
    );
  }

  Future<void> _onFrame(ReverseMuxFrame frame) async {
    if (_closed) {
      return;
    }
    switch (frame.type) {
      case kReverseMuxOpen:
        await _onOpen(frame.streamId);
      case kReverseMuxData:
        _markTraffic();
        final socket = _streams[frame.streamId];
        if (socket == null) {
          return;
        }
        try {
          socket.add(frame.payload);
        } on Object {
          _drop(frame.streamId, reply: kReverseMuxReset);
        }
      case kReverseMuxClose:
      case kReverseMuxReset:
        _drop(frame.streamId, reply: 0);
      default:
        break;
    }
  }

  Future<void> _onOpen(int streamId) async {
    Socket? socket;
    try {
      socket = await _dialTarget();
    } on Object {
      socket = null;
    }
    if (_closed) {
      socket?.destroy();
      return;
    }
    if (socket == null) {
      _write(kReverseMuxReset, streamId);
      return;
    }
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } on Object {
      // Some loopback stacks refuse the option; the splice still works.
    }
    _streams[streamId] = socket;
    unawaited(socket.done.catchError((_) {}));
    socket.listen(
      (bytes) {
        _markTraffic();
        var offset = 0;
        while (offset < bytes.length) {
          final end = min(offset + kReverseMuxMaxPayload, bytes.length);
          _write(
            kReverseMuxData,
            streamId,
            Uint8List.fromList(bytes.sublist(offset, end)),
          );
          offset = end;
        }
      },
      onDone: () => _drop(streamId, reply: kReverseMuxClose),
      onError: (_) => _drop(streamId, reply: kReverseMuxReset),
      cancelOnError: false,
    );
  }

  void _write(int type, int streamId, [Uint8List? payload]) {
    if (_closed) {
      return;
    }
    try {
      _stdin.add(
        encodeReverseMuxFrame(type: type, streamId: streamId, payload: payload),
      );
    } on Object {
      close();
    }
  }

  void _drop(int streamId, {required int reply}) {
    final socket = _streams.remove(streamId);
    if (socket != null) {
      try {
        socket.destroy();
      } on Object {
        // Already gone.
      }
    }
    if (reply != 0) {
      _write(reply, streamId);
    }
  }

  /// Tears the mux down. Idempotent.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    unawaited(_stdoutSub?.cancel());
    unawaited(_stderrSub?.cancel());
    for (final id in _streams.keys.toList()) {
      _drop(id, reply: 0);
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}
