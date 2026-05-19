import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Sinks (the HttpServer + WebSockets) are created in setUp and closed in
// tearDown; the close_sinks lint can't see that lifecycle.
// ignore_for_file: close_sinks

import 'package:cc_host/src/transport/ws_remote_transport.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// End-to-end coverage for [WsRemoteTransport] over a real loopback
/// `WebSocket`. A tiny `HttpServer` upgrades the inbound socket, hands the
/// server-side [WebSocket] to [WsRemoteTransport] and a client `WebSocket`
/// drives frames at it. This exercises the real `dart:io` paths (readyState,
/// text/binary handling, close) without any mocking.
void main() {
  group('WsRemoteTransport', () {
    late HttpServer server;
    late WebSocket clientSocket;
    late WebSocket serverSocket;
    late WsRemoteTransport transport;

    /// Spins up the upgrade server, accepts one connection and wires the
    /// transport to the upgraded server-side socket. The client socket is
    /// returned ready to send.
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = server.transform(WebSocketTransformer());
      final serverSide = accepted.first;
      clientSocket = await WebSocket.connect(
        'ws://${server.address.address}:${server.port}',
      );
      serverSocket = await serverSide;
      transport = WsRemoteTransport(serverSocket, label: 'test');
    });

    tearDown(() async {
      await transport.close();
      await clientSocket.close();
      await server.close(force: true);
    });

    test('start is idempotent (a second start is a no-op)', () async {
      transport.start();
      final subBefore = transport.toString(); // just touch the instance
      transport.start();
      expect(subBefore, isNotEmpty);
      await pumpEventQueue();
    });

    test(
      'state emits open for a freshly-upgraded socket, then closed',
      () async {
        final states = <RemoteChannelState>[];
        final sub = transport.state.listen(states.add);
        transport.start();
        // Give the broadcast stream a turn to deliver.
        await pumpEventQueue(times: 10);
        expect(states, contains(RemoteChannelState.open));

        await transport.close();
        await pumpEventQueue(times: 10);
        await sub.cancel();
        expect(states, contains(RemoteChannelState.closed));
      },
    );

    test('a valid text frame is decoded onto incoming', () async {
      transport.start();
      final received = <Map<String, dynamic>>[];
      final frameArrived = Completer<void>();
      final sub = transport.incoming.listen((frame) {
        received.add(frame);
        if (!frameArrived.isCompleted) {
          frameArrived.complete();
        }
      });

      clientSocket.add(jsonEncode({'method': 'ping', 'id': 1}));
      // A real loopback WebSocket frame needs real event-loop turns to be
      // delivered; a fixed `pumpEventQueue` count flakes on a loaded runner
      // (observed on a macos-14 CI runner), so wait for the frame itself.
      await frameArrived.future.timeout(const Duration(seconds: 5));
      await sub.cancel();
      expect(received, [
        {'method': 'ping', 'id': 1},
      ]);
    });

    test(
      'a frame buffered before a listener attaches flushes on listen',
      () async {
        transport.start();
        // Send before any listener is attached — must buffer, not drop.
        clientSocket.add(jsonEncode({'method': 'buffered', 'id': 2}));
        final frameArrived = Completer<void>();
        final received = <Map<String, dynamic>>[];
        // Now attach; the onListen hook flushes the pending frame.
        final sub = transport.incoming.listen((frame) {
          received.add(frame);
          if (!frameArrived.isCompleted) {
            frameArrived.complete();
          }
        });
        await frameArrived.future.timeout(const Duration(seconds: 5));
        await sub.cancel();
        expect(received, [
          {'method': 'buffered', 'id': 2},
        ]);
      },
    );

    test('a non-text (binary) frame is ignored and never decoded', () async {
      transport.start();
      final received = <Map<String, dynamic>>[];
      final frameArrived = Completer<void>();
      final sub = transport.incoming.listen((frame) {
        received.add(frame);
        if (!frameArrived.isCompleted) {
          frameArrived.complete();
        }
      });

      clientSocket.add(<int>[0, 1, 2, 3]); // binary, not text
      // Follow it with a valid frame so we know the listener is alive.
      clientSocket.add(jsonEncode({'method': 'after-binary', 'id': 3}));
      await frameArrived.future.timeout(const Duration(seconds: 5));
      await sub.cancel();
      expect(received, [
        {'method': 'after-binary', 'id': 3},
      ], reason: 'binary frame must be dropped, text frame still delivered');
    });

    test(
      'a malformed JSON text frame is dropped (never reaches incoming)',
      () async {
        transport.start();
        final received = <Map<String, dynamic>>[];
        final frameArrived = Completer<void>();
        final sub = transport.incoming.listen((frame) {
          received.add(frame);
          if (!frameArrived.isCompleted) {
            frameArrived.complete();
          }
        });

        clientSocket.add('not-json');
        clientSocket.add(jsonEncode({'method': 'after-bad', 'id': 4}));
        // Wait for the frame itself, not a fixed pump count — a loaded runner
        // needs more event-loop turns than any fixed number (same flake the
        // sibling tests in this file already wait out).
        await frameArrived.future.timeout(const Duration(seconds: 5));
        await sub.cancel();
        expect(received, [
          {'method': 'after-bad', 'id': 4},
        ]);
      },
    );

    test('send writes a frame back to the client as JSON text', () async {
      transport.start();
      final clientFrames = <dynamic>[];
      final sub = clientSocket.listen(clientFrames.add);

      await transport.send({
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'ok': true},
      });
      await pumpEventQueue(times: 20);
      await sub.cancel();
      expect(clientFrames, isNotEmpty);
      expect(jsonDecode(clientFrames.last as String), {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'ok': true},
      });
    });

    test('send throws StateError once the transport is closed', () async {
      transport.start();
      await pumpEventQueue(times: 5);
      await transport.close();
      await expectLater(transport.send({'a': 1}), throwsA(isA<StateError>()));
    });

    test('close is idempotent', () async {
      transport.start();
      await pumpEventQueue(times: 5);
      await transport.close();
      // A second close must not throw.
      await transport.close();
    });

    test('isOpen reflects open vs closed', () async {
      transport.start();
      await pumpEventQueue(times: 5);
      expect(transport.isOpen, isTrue);
      await transport.close();
      expect(transport.isOpen, isFalse);
    });

    test('a frame over the size cap closes the transport', () async {
      transport.start();
      final closed = Completer<void>();
      final sub = transport.state.listen((s) {
        if (s == RemoteChannelState.closed && !closed.isCompleted) {
          closed.complete();
        }
      });

      // Build a string well past the 256 KiB cap declared in the transport.
      const maxFrameBytes = 256 * 1024;
      final oversized = 'x' * (maxFrameBytes + 1);
      clientSocket.add(oversized);
      // The close is a real socket round-trip away; waiting for the event
      // (not a fixed pump count) is what a loaded runner needs.
      await closed.future.timeout(const Duration(seconds: 5));
      await sub.cancel();
      expect(transport.isOpen, isFalse);
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('pending buffer overflow closes the transport', () async {
      transport.start();
      final closed = Completer<void>();
      final sub = transport.state.listen((s) {
        if (s == RemoteChannelState.closed && !closed.isCompleted) {
          closed.complete();
        }
      });
      // No incoming listener attached → frames buffer. Flood past the cap of 64.
      const maxPendingFrames = 64;
      for (var i = 0; i <= maxPendingFrames; i++) {
        clientSocket.add(jsonEncode({'i': i}));
      }
      await closed.future.timeout(const Duration(seconds: 10));
      await sub.cancel();
      expect(transport.isOpen, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
