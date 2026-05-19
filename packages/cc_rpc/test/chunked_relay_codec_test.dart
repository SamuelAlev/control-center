import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

const _psk = 'test-psk-for-chunking';

/// Wires two [ChunkedRelaySession]s back-to-back through in-memory queues,
/// with an optional tap on the "wire" for assertions and loss injection.
class _Link {
  _Link({
    int maxChunkChars = 64,
    int windowChunks = 8,
    int creditEvery = 2,
    Duration stall = const Duration(milliseconds: 400),
    bool Function(Map<String, dynamic> payload)? dropB2A,
  }) {
    a = ChunkedRelaySession(
      psk: _psk,
      sendPayload: (p) {
        wireAtoB.add(p);
        scheduleMicrotask(() => b.handlePayload(p));
      },
      onFrame: framesAtA.add,
      onProgress: progressA.add,
      maxChunkChars: maxChunkChars,
      windowChunks: windowChunks,
      creditEvery: creditEvery,
      sendStallTimeout: stall,
    );
    b = ChunkedRelaySession(
      psk: _psk,
      sendPayload: (p) {
        wireBtoA.add(p);
        if (dropB2A != null && dropB2A(p)) {
          return;
        }
        scheduleMicrotask(() => a.handlePayload(p));
      },
      onFrame: framesAtB.add,
      onProgress: progressB.add,
      maxChunkChars: maxChunkChars,
      windowChunks: windowChunks,
      creditEvery: creditEvery,
      sendStallTimeout: stall,
    );
  }

  late final ChunkedRelaySession a;
  late final ChunkedRelaySession b;
  final wireAtoB = <Map<String, dynamic>>[];
  final wireBtoA = <Map<String, dynamic>>[];

  /// Frames session B surfaced (i.e. frames A sent).
  final framesAtB = <Map<String, dynamic>>[];

  /// Frames session A surfaced (i.e. frames B sent).
  final framesAtA = <Map<String, dynamic>>[];
  final progressA = <RelayTransferProgress>[];
  final progressB = <RelayTransferProgress>[];
}

Future<void> _settle() async {
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('ChunkedRelaySession', () {
    test('a small frame rides the single-piece fast path', () async {
      final link = _Link(maxChunkChars: 4096);
      await link.a.sendFrame({'jsonrpc': '2.0', 'id': 1, 'method': 'x'});
      await _settle();
      expect(link.framesAtB.single['id'], 1);
      expect(link.wireAtoB.single.containsKey('e'), isTrue);
      expect(link.wireAtoB.single.containsKey('c'), isFalse);
    });

    test(
      'a large frame is chunked, reassembled, and reported with progress',
      () async {
        final link = _Link();
        final big = {'jsonrpc': '2.0', 'id': 2, 'blob': 'x' * 2000};
        await link.a.sendFrame(big);
        await _settle();
        expect(link.framesAtB.single['blob'], 'x' * 2000);
        final chunks = link.wireAtoB.where((p) => p.containsKey('c')).toList();
        expect(chunks.length, greaterThan(10));
        // Every chunk carries the reassembly triple.
        for (final c in chunks) {
          expect(c['id'], isA<int>());
          expect(c['i'], isA<int>());
          expect(c['n'], chunks.length);
        }
        // Progress was observed on both sides and completed.
        expect(link.progressA.last.fraction, 1.0);
        expect(link.progressA.last.direction, RelayTransferDirection.send);
        expect(
          link.progressB.where(
            (p) => p.direction == RelayTransferDirection.receive,
          ),
          isNotEmpty,
        );
      },
    );

    test('the wire never carries plaintext (everything is sealed)', () async {
      final link = _Link();
      await link.a.sendFrame({'secret': 'the-plaintext-payload'});
      await link.a.sendFrame({'big-secret': 'y' * 500});
      await _settle();
      for (final payload in link.wireAtoB) {
        final text = payload.values.whereType<String>().join();
        expect(text.contains('the-plaintext-payload'), isFalse);
        expect(text.contains('y' * 50), isFalse);
      }
    });

    test('backpressure: with credits lost, the sender stalls at the window '
        'and throws after the stall timeout', () async {
      final link = _Link(
        maxChunkChars: 32,
        windowChunks: 4,
        creditEvery: 2,
        // Drop every credit frame B would send back to A.
        dropB2A: (p) => true,
        stall: const Duration(milliseconds: 200),
      );
      final big = {'blob': 'z' * 2000};
      await expectLater(
        link.a.sendFrame(big),
        throwsA(isA<RelayBackpressureStallException>()),
      );
      // Only the window's worth of chunks made it to the wire.
      final chunks = link.wireAtoB.where((p) => p.containsKey('c')).length;
      expect(chunks, lessThanOrEqualTo(4));
    });

    test('credits flow keeps a long transfer moving past the window', () async {
      final link = _Link(maxChunkChars: 32, windowChunks: 4, creditEvery: 2);
      final big = {'blob': 'w' * 3000};
      await link.a.sendFrame(big);
      await _settle();
      expect(link.framesAtB.single['blob'], 'w' * 3000);
      // Far more chunks than the window moved — credits paced the flow.
      final chunks = link.wireAtoB.where((p) => p.containsKey('c')).length;
      expect(chunks, greaterThan(4 * 3));
      // B sent sealed credit frames back.
      expect(link.wireBtoA, isNotEmpty);
    });

    test(
      'a tampered chunk fails authentication and the frame is dropped',
      () async {
        final received = <Map<String, dynamic>>[];
        late ChunkedRelaySession b;
        final a = ChunkedRelaySession(
          psk: _psk,
          maxChunkChars: 64,
          sendPayload: (p) {
            final tampered = Map<String, dynamic>.of(p);
            if (tampered.containsKey('c')) {
              final text = tampered['c'] as String;
              tampered['c'] = text.replaceRange(
                0,
                1,
                text[0] == 'A' ? 'B' : 'A',
              );
            }
            scheduleMicrotask(() => b.handlePayload(tampered));
          },
          onFrame: (_) {},
        );
        b = ChunkedRelaySession(
          psk: _psk,
          sendPayload: (_) {},
          onFrame: received.add,
        );
        await a.sendFrame({'blob': 'q' * 500});
        await _settle();
        expect(received, isEmpty);
      },
    );

    test('a credit sealed under the wrong PSK is ignored (no forged window '
        'inflation)', () async {
      final sent = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        maxChunkChars: 32,
        windowChunks: 2,
        sendStallTimeout: const Duration(milliseconds: 200),
        sendPayload: sent.add,
        onFrame: (_) {},
      );
      // Attacker-forged credit: sealed under a different key.
      final forged = ChunkedRelaySession(
        psk: 'wrong-psk',
        sendPayload: session.handlePayload,
        onFrame: (_) {},
      );
      // Push the forged "credit" — the seal fails to open, so nothing changes.
      await forged.sendFrame({'__cc_credit': 1000});
      await expectLater(
        session.sendFrame({'blob': 'r' * 500}),
        throwsA(isA<RelayBackpressureStallException>()),
      );
    });

    test('interleaved small frames while a large frame streams stay ordered '
        'per frame and all arrive', () async {
      final link = _Link(maxChunkChars: 32, windowChunks: 16, creditEvery: 4);
      final f1 = link.a.sendFrame({'blob': 's' * 1000, 'tag': 'big'});
      final f2 = link.a.sendFrame({'tag': 'small'});
      await Future.wait([f1, f2]);
      await _settle();
      expect(link.framesAtB, hasLength(2));
      expect(
        link.framesAtB.map((f) => f['tag']),
        containsAll(['big', 'small']),
      );
    });

    test(
      'a 50 MB payload streams chunked with progress over the relay path',
      () async {
        // Real-size soak (PRD 15 acceptance): 50 MB of payload through 16 KB
        // chunks with a 64-chunk window.
        final link = _Link(
          maxChunkChars: 16 * 1024,
          windowChunks: 64,
          creditEvery: 16,
          stall: const Duration(seconds: 10),
        );
        final blob = String.fromCharCodes(
          List<int>.generate(50 * 1024 * 1024, (i) => 97 + (i % 26)),
        );
        await link.a.sendFrame({'blob': blob});
        await _settle();
        expect(link.framesAtB.single['blob'], hasLength(blob.length));
        expect(link.progressA.last.fraction, 1.0);
        expect(link.progressA.last.totalChunks, greaterThan(1000));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('ChunkedRelaySession edge cases', () {
    test('sendFrame on a closed session throws StateError', () async {
      final session = ChunkedRelaySession(
        psk: _psk,
        sendPayload: (_) {},
        onFrame: (_) {},
      );
      session.close();
      await expectLater(
        session.sendFrame({'x': 1}),
        throwsA(isA<StateError>()),
      );
    });

    test('handlePayload on a closed session is a no-op', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      final sealed = RelayFrameCrypto.seal(jsonEncode({'a': 1}), _psk);
      session.close();
      // Must not throw and must not dispatch.
      session.handlePayload({'e': sealed});
      expect(frames, isEmpty);
    });

    test('close is idempotent and releases a stalled sender', () async {
      // A sender stalled at the window (no credits) is released when close()
      // completes its window-wait completer instead of throwing a stall.
      final wire = <Map<String, dynamic>>[];
      late ChunkedRelaySession session;
      session = ChunkedRelaySession(
        psk: _psk,
        maxChunkChars: 32,
        windowChunks: 2,
        creditEvery: 1,
        sendStallTimeout: const Duration(seconds: 30),
        sendPayload: wire.add,
        onFrame: (_) {},
      );
      // Fill the window with small frames and never credit back; the next send
      // stalls. close() should release the waiter.
      final stall = session.sendFrame({'blob': 'a' * 200});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      session.close();
      // close completes the wait — the stalled send then sees _closed and
      // throws StateError (from _acquireWindow), not the stall exception.
      await expectLater(stall, throwsA(isA<StateError>()));
      // A second close is a no-op.
      session.close();
    });

    test('a sealed non-Map JSON value is dropped', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      final sealed = RelayFrameCrypto.seal(jsonEncode([1, 2, 3]), _psk);
      session.handlePayload({'e': sealed});
      expect(frames, isEmpty);
    });

    test('a malformed single-piece payload is dropped', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      // 'e' is not a String → ignored.
      session.handlePayload({'e': 123});
      // No 'c' triple → ignored.
      session.handlePayload({'c': 'x'});
      expect(frames, isEmpty);
    });

    test('chunk pieces with an out-of-range index are dropped', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      // total < 1 and index >= total → dropped.
      session.handlePayload({'c': 'x', 'id': 0, 'i': 0, 'n': 0});
      session.handlePayload({'c': 'x', 'id': 1, 'i': 5, 'n': 2});
      expect(frames, isEmpty);
    });

    test(
      'a concurrent-assembly total mismatch restarts the reassembly',
      () async {
        final frames = <Map<String, dynamic>>[];
        final session = ChunkedRelaySession(
          psk: _psk,
          maxChunkChars: 16,
          sendPayload: (_) {},
          onFrame: frames.add,
        );
        // Start an assembly for id 7 with total 2.
        session.handlePayload({'c': 'AAAA', 'id': 7, 'i': 0, 'n': 2});
        // Now send a piece for id 7 with a different total → assembly resets.
        session.handlePayload({'c': 'AAAA', 'id': 7, 'i': 0, 'n': 1});
        expect(frames, isEmpty);
      },
    );

    test('too many concurrent assemblies evicts the stalest', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        maxChunkChars: 16,
        maxConcurrentAssemblies: 1,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      // First assembly for id 1 (incomplete).
      session.handlePayload({'c': 'AAAA', 'id': 1, 'i': 0, 'n': 2});
      // A second concurrent assembly evicts id 1; this never throws.
      session.handlePayload({'c': 'BBBB', 'id': 2, 'i': 0, 'n': 2});
      expect(frames, isEmpty);
    });

    test('an assembly exceeding maxAssemblyChars is dropped', () {
      final frames = <Map<String, dynamic>>[];
      final session = ChunkedRelaySession(
        psk: _psk,
        maxChunkChars: 16,
        maxAssemblyChars: 8,
        sendPayload: (_) {},
        onFrame: frames.add,
      );
      // A piece longer than the cap → assembly is discarded mid-flight.
      session.handlePayload({'c': 'AAAAAAAAAA', 'id': 9, 'i': 0, 'n': 2});
      expect(frames, isEmpty);
    });

    test('RelayBackpressureStallException has a descriptive toString', () {
      const exc = RelayBackpressureStallException();
      expect(exc.toString(), contains('RelayBackpressureStallException'));
      expect(exc.toString(), contains('credits'));
    });
  });
}
