import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/rigs/reverse_mux.dart';
import 'package:test/test.dart';

void main() {
  group('encodeReverseMuxFrame / ReverseMuxReader', () {
    test('a frame round-trips, including when it arrives in pieces', () {
      final payload = Uint8List.fromList(List<int>.generate(200, (i) => i));
      final encoded = encodeReverseMuxFrame(
        type: kReverseMuxData,
        streamId: 42,
        payload: payload,
      );
      expect(encoded.length, kReverseMuxHeaderBytes + 200);

      final reader = ReverseMuxReader();
      expect(reader.add(encoded.sublist(0, 3)), isEmpty);
      expect(reader.add(encoded.sublist(3, 12)), isEmpty);
      final frames = reader.add(encoded.sublist(12));
      expect(frames, hasLength(1));
      expect(frames.single.type, kReverseMuxData);
      expect(frames.single.streamId, 42);
      expect(frames.single.payload, payload);
    });

    test('OPEN has an empty payload', () {
      final encoded = encodeReverseMuxFrame(type: kReverseMuxOpen, streamId: 1);
      expect(encoded.length, kReverseMuxHeaderBytes);
      final frame = ReverseMuxReader().add(encoded).single;
      expect(frame.type, kReverseMuxOpen);
      expect(frame.payload, isEmpty);
    });

    test('a claimed length above the cap is a protocol error', () {
      final bad = Uint8List(kReverseMuxHeaderBytes);
      final view = ByteData.sublistView(bad);
      view.setUint8(0, kReverseMuxData);
      view.setUint32(1, 1);
      view.setUint32(5, kReverseMuxMaxPayload + 1);
      expect(() => ReverseMuxReader().add(bad), throwsStateError);
    });
  });

  group('buildReverseMuxBootstrapCommand', () {
    test('installs the perl mux at a fixed path', () {
      final cmd = buildReverseMuxBootstrapCommand();
      expect(cmd, contains(kRigReverseMuxPath));
      expect(cmd, contains('base64 -d'));
      expect(cmd, contains('chmod 755'));
      expect(guestReverseMuxArgv(5173, maxStreams: 128), [
        'perl',
        '-C0',
        kRigReverseMuxPath,
        '5173',
        '128',
      ]);
    });

    test('the guest script speaks the same frame layout as the host', () {
      expect(kRigReverseMuxScript, contains("pack('C N N'"));
      expect(kRigReverseMuxScript, contains('32768'));
      expect(kRigReverseMuxScript, contains("127.0.0.1"));
      expect(kRigReverseMuxScript, contains('::1'));
    });
  });

  group('ReverseMuxHost over a local perl mux', () {
    test('many parallel connections and keep-alive reuse survive', () async {
      final perl = await Process.run('perl', ['-c', '-e', '1']);
      if (perl.exitCode != 0) {
        markTestSkipped('perl is not available');
        return;
      }

      final target = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(target.close);
      target.listen((client) {
        client.listen(
          client.add,
          onDone: client.destroy,
          onError: (_) => client.destroy(),
          cancelOnError: false,
        );
      });

      final listen = await _bindFreePort();
      final script = File(
        '${Directory.systemTemp.path}/cc-revtun-${listen.port}.pl',
      );
      await script.writeAsString(kRigReverseMuxScript);
      addTearDown(() => script.deleteSync());

      final process = await Process.start('perl', [
        '-C0',
        script.path,
        '${listen.port}',
        '64',
      ]);
      addTearDown(() => process.kill(ProcessSignal.sigkill));

      final host = ReverseMuxHost(
        stdin: process.stdin,
        stdout: process.stdout,
        stderr: process.stderr,
        dialTarget: () => Socket.connect(
          InternetAddress.loopbackIPv4,
          target.port,
          timeout: const Duration(seconds: 2),
        ),
      );
      addTearDown(host.close);

      await _waitUntilOpen(listen.port);

      final payload = Uint8List.fromList(
        List<int>.generate(4096, (i) => i & 0xff),
      );

      Future<void> echoOnce(Socket client, _ByteReader reader) async {
        client.add(payload);
        await client.flush();
        expect(await reader.take(payload.length), payload);
      }

      final parallel = <Future<void>>[];
      for (var i = 0; i < 24; i++) {
        parallel.add(() async {
          final client = await Socket.connect(
            InternetAddress.loopbackIPv4,
            listen.port,
            timeout: const Duration(seconds: 2),
          );
          final reader = _ByteReader(client);
          try {
            await echoOnce(client, reader);
          } finally {
            client.destroy();
          }
        }());
      }
      await Future.wait(parallel);

      final reused = await Socket.connect(
        InternetAddress.loopbackIPv4,
        listen.port,
        timeout: const Duration(seconds: 2),
      );
      addTearDown(reused.destroy);
      final reusedReader = _ByteReader(reused);
      for (var i = 0; i < 50; i++) {
        await echoOnce(reused, reusedReader);
      }
    });
  });
}

class _ByteReader {
  _ByteReader(Stream<List<int>> source) {
    source.listen(
      (chunk) {
        _buf.add(chunk);
        _notify();
      },
      onDone: _notify,
      onError: (Object _) => _notify(),
      cancelOnError: false,
    );
  }

  final BytesBuilder _buf = BytesBuilder(copy: false);
  final List<Completer<void>> _waiters = [];

  void _notify() {
    for (final waiter in _waiters.toList()) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }

  Future<Uint8List> take(int n) async {
    while (_buf.length < n) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
      _waiters.remove(waiter);
    }
    final bytes = _buf.takeBytes();
    final out = Uint8List.fromList(bytes.sublist(0, n));
    if (bytes.length > n) {
      _buf.add(bytes.sublist(n));
    }
    return out;
  }
}

class _BoundPort {
  _BoundPort(this.port);
  final int port;
}

Future<_BoundPort> _bindFreePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return _BoundPort(port);
}

Future<void> _waitUntilOpen(int port) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  Object? last;
  while (DateTime.now().isBefore(deadline)) {
    try {
      final probe = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 100),
      );
      probe.destroy();
      return;
    } on Object catch (e) {
      last = e;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  fail('perl mux never listened on :$port ($last)');
}
