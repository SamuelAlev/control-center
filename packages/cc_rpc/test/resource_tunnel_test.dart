import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'streams Range response and request body with original metadata',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final server = RemoteResourceServer(
        serverChannel,
        onRequest: (request) async {
          expect(request.method, 'PUT');
          expect(request.uri.toString(), '/media/item?download=1');
          expect(request.headers['range'], ['bytes=1024-2047']);
          final bytes = await request.body.fold<int>(
            0,
            (sum, part) => sum + part.length,
          );
          expect(bytes, 1024 * 1024);
          return RemoteResourceResponse(
            statusCode: 206,
            headers: const {
              'content-range': ['bytes 1024-2047/4096'],
              'etag': ['"original"'],
            },
            body: Stream<Uint8List>.fromIterable([
              Uint8List.fromList([4, 5, 6]),
            ]),
          );
        },
        onWebSocket: (_) => throw StateError('Unexpected websocket'),
      );
      final client = RemoteResourceClient(clientChannel);
      final response = await client.request(
        'PUT',
        Uri.parse('/media/item?download=1'),
        headers: const {
          'range': ['bytes=1024-2047'],
        },
        body: Stream<List<int>>.fromIterable(
          List.generate(32, (_) => Uint8List(32 * 1024)),
        ),
      );
      expect(response.statusCode, 206);
      expect(response.headers['content-range'], ['bytes 1024-2047/4096']);
      expect(response.headers['etag'], ['"original"']);
      expect(await response.body.expand((bytes) => bytes).toList(), [4, 5, 6]);
      await client.close();
      await server.close();
      await clientChannel.close();
    },
  );

  test('resource IDs do not resolve same-numbered RPC errors', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final rpcSubscription = serverChannel.incoming.listen((frame) {
      if (frame['method'] == 'initialize') {
        unawaited(
          serverChannel.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'error': {'code': -32001, 'message': 'RPC intentionally failed'},
          }),
        );
      }
    });
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (_) async => RemoteResourceResponse(
        statusCode: 206,
        headers: const {
          'content-range': ['bytes 0-0/2'],
        },
        body: Stream<Uint8List>.value(Uint8List.fromList([8])),
      ),
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteRpcClient(clientChannel)..start();
    final rpcError = expectLater(
      client.initialize(),
      throwsA(isA<RemoteRpcException>()),
    );
    final resource = await client.resources.request('GET', Uri.parse('/media'));
    expect(resource.statusCode, 206);
    expect(await resource.body.single, [8]);
    await rpcError;
    await client.close();
    await server.close();
    await rpcSubscription.cancel();
    await clientChannel.close();
  });

  test(
    'closing RPC client aborts peer work without closing its transport',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final arrived = Completer<RemoteResourceRequest>();
      final server = RemoteResourceServer(
        serverChannel,
        onRequest: (request) async {
          arrived.complete(request);
          await request.cancelled;
          return RemoteResourceResponse(
            statusCode: 204,
            headers: const {},
            body: const Stream<Uint8List>.empty(),
          );
        },
        onWebSocket: (_) => throw StateError('Unexpected websocket'),
      );
      final client = RemoteRpcClient(clientChannel)..start();
      addTearDown(() async {
        await client.close();
        await server.close();
        await clientChannel.close();
      });
      final pending = expectLater(
        client.resources.request('GET', Uri.parse('/buffering-image')),
        throwsA(isA<StateError>()),
      );
      final request = await arrived.future;
      await client.close();
      await request.cancelled.timeout(const Duration(seconds: 2));
      await pending;
      expect(request.isCancelled, isTrue);
      expect(clientChannel.isOpen, isTrue);
      expect(serverChannel.isOpen, isTrue);
    },
  );

  test('download stops at independent receive window while paused', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    var produced = 0;
    var dataFrames = 0;
    final observer = clientChannel.incoming.listen((frame) {
      if (frame['type'] == 'resource' && frame['op'] == 'data') dataFrames++;
    });
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (_) async => RemoteResourceResponse(
        statusCode: 200,
        headers: const {},
        body: () async* {
          for (var i = 0; i < 64; i++) {
            produced++;
            yield Uint8List(32 * 1024);
          }
        }(),
      ),
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteResourceClient(clientChannel);
    final response = await client.request('GET', Uri.parse('/blob'));
    late StreamSubscription<Uint8List> subscription;
    var consumed = 0;
    final completed = Completer<void>();
    subscription = response.body.listen((_) {
      consumed++;
      if (consumed == 1) subscription.pause();
    }, onDone: completed.complete);
    await _settle();
    expect(consumed, 1);
    expect(dataFrames, lessThanOrEqualTo(8));
    expect(produced, lessThanOrEqualTo(9));
    subscription.resume();
    await completed.future.timeout(const Duration(seconds: 5));
    expect(consumed, 64);
    await observer.cancel();
    await client.close();
    await server.close();
    await clientChannel.close();
  });

  test(
    'duplex websocket transfers multi-fragment text and binary without deadlock',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final serverMessages = StreamController<Object>.broadcast(sync: true);
      final server = RemoteResourceServer(
        serverChannel,
        onRequest: (_) => throw StateError('Unexpected HTTP'),
        onWebSocket: (request) async {
          expect(request.protocols, ['vscode-remote']);
          return RemoteResourceSocket(
            incoming: serverMessages.stream,
            protocol: 'vscode-remote',
            onSend: (message) async {
              serverMessages.add(message);
            },
            onClose: (_, __) async => serverMessages.close(),
          );
        },
      );
      final client = RemoteResourceClient(clientChannel);
      final socket = await client.connectWebSocket(
        Uri.parse('/editor/socket'),
        protocols: const ['vscode-remote'],
      );
      expect(socket.protocol, 'vscode-remote');
      final received = socket.incoming.take(2).toList();
      final text = 'editor-state-' * 32000;
      final binary = Uint8List(1500000)..[0] = 214;
      await Future.wait([
        socket.send(text),
        socket.send(binary),
      ]).timeout(const Duration(seconds: 5));
      final messages = await received.timeout(const Duration(seconds: 5));
      expect(messages[0], text);
      expect(messages[1], binary);
      await socket.close();
      await client.close();
      await server.close();
      await clientChannel.close();
    },
  );

  test('remote websocket close exposes adapter code and reason', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final fromServer = StreamController<Object>.broadcast();
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (_) => throw StateError('Unexpected HTTP'),
      onWebSocket: (_) async => RemoteResourceSocket(
        incoming: fromServer.stream,
        protocol: '',
        readCloseCode: () => 4001,
        readCloseReason: () => 'workspace removed',
        onSend: (_) async {},
        onClose: (_, __) async => fromServer.close(),
      ),
    );
    final client = RemoteResourceClient(clientChannel);
    final socket = await client.connectWebSocket(Uri.parse('/editor'));
    final closed = socket.incoming.drain<void>();
    await fromServer.close();
    await closed.timeout(const Duration(seconds: 5));
    expect(socket.closeCode, 4001);
    expect(socket.closeReason, 'workspace removed');
    await client.close();
    await server.close();
    await clientChannel.close();
  });

  test('client close forwards its code and reason to upstream', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final fromServer = StreamController<Object>();
    final upstreamClosed = Completer<(int, String)>();
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (_) => throw StateError('Unexpected HTTP'),
      onWebSocket: (_) async => RemoteResourceSocket(
        incoming: fromServer.stream,
        protocol: '',
        onSend: (_) async {},
        onClose: (code, reason) async {
          if (!upstreamClosed.isCompleted)
            upstreamClosed.complete((code, reason));
          await fromServer.close();
        },
      ),
    );
    final client = RemoteResourceClient(clientChannel);
    final socket = await client.connectWebSocket(Uri.parse('/editor'));
    await socket.close(4002, 'editor window closed');
    expect(await upstreamClosed.future.timeout(const Duration(seconds: 2)), (
      4002,
      'editor window closed',
    ));
    await client.close();
    await server.close();
    await clientChannel.close();
  });

  test(
    'close bypasses withheld send credit while inbound traffic continues',
    () async {
      final (peer, channel) = InProcessRpcChannel.pair();
      final client = RemoteResourceClient(channel);
      final closed = Completer<Map<String, dynamic>>();
      final heartbeat = Completer<void>();
      var id = 0;
      var credits = 0;
      final raw = peer.incoming.listen((frame) {
        if (frame['op'] == 'open') {
          id = frame['id'] as int;
          unawaited(
            peer.send({
              'type': 'resource',
              'v': 1,
              'id': id,
              'op': 'headers',
              'status': 101,
              'headers': <String, List<String>>{},
              'protocol': '',
            }),
          );
        } else if (frame['op'] == 'credit') {
          credits += frame['n'] as int;
        } else if (frame['op'] == 'wsClose' && !closed.isCompleted) {
          closed.complete(frame);
        }
        // Deliberately never grant data credit to the client.
      });
      final socket = await client.connectWebSocket(Uri.parse('/editor'));
      final incoming = socket.incoming.listen((_) {
        if (!heartbeat.isCompleted) heartbeat.complete();
      }, onError: (Object _) {});
      final timer = Timer.periodic(const Duration(milliseconds: 2), (_) {
        if (credits == 0 || closed.isCompleted) return;
        credits--;
        unawaited(
          peer.send({
            'type': 'resource',
            'v': 1,
            'id': id,
            'op': 'data',
            'b': base64.encode(utf8.encode('still receiving')),
            'text': true,
            'last': true,
          }),
        );
      });
      addTearDown(() async {
        timer.cancel();
        await client.close();
        await incoming.cancel();
        await raw.cancel();
        await channel.close();
      });
      await heartbeat.future.timeout(const Duration(seconds: 2));
      final rejectedSend = expectLater(
        socket.send('blocked upload'),
        throwsStateError,
      );
      await socket
          .close(4002, 'stop upload')
          .timeout(const Duration(seconds: 2));
      await rejectedSend;
      final frame = await closed.future.timeout(const Duration(seconds: 2));
      expect(frame['code'], 4002);
      expect(frame['reason'], 'stop upload');
    },
  );

  test(
    'consumer cancellation terminates the upstream and other transfers remain usable',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final cancelled = Completer<void>();
      final server = RemoteResourceServer(
        serverChannel,
        onRequest: (request) async {
          if (request.uri.path == '/slow') {
            unawaited(request.cancelled.then((_) => cancelled.complete()));
            return RemoteResourceResponse(
              statusCode: 200,
              headers: const {},
              body: Stream<Uint8List>.periodic(
                const Duration(milliseconds: 1),
                (_) => Uint8List(32 * 1024),
              ),
            );
          }
          return RemoteResourceResponse(
            statusCode: 200,
            headers: const {},
            body: Stream<Uint8List>.value(Uint8List.fromList([7])),
          );
        },
        onWebSocket: (_) => throw StateError('Unexpected websocket'),
      );
      final client = RemoteResourceClient(clientChannel);
      final slow = await client.request('GET', Uri.parse('/slow'));
      final subscription = slow.body.listen((_) {});
      await subscription.cancel();
      await cancelled.future.timeout(const Duration(seconds: 5));
      final next = await client.request('GET', Uri.parse('/next'));
      expect(await next.body.single, [7]);
      await client.close();
      await server.close();
      await clientChannel.close();
    },
  );

  test(
    'membership revocation cancels existing response but allows later requests',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final cancelled = Completer<void>();
      final cleanup = Completer<void>();
      final server = RemoteResourceServer(
        serverChannel,
        onRequest: (request) async {
          if (request.uri.path == '/revoked') {
            unawaited(request.cancelled.then((_) => cancelled.complete()));
            return RemoteResourceResponse(
              statusCode: 200,
              headers: const {},
              body: Stream<Uint8List>.periodic(
                const Duration(milliseconds: 1),
                (_) => Uint8List(32 * 1024),
              ),
              onClose: () => cleanup.future,
            );
          }
          return RemoteResourceResponse(
            statusCode: 200,
            headers: const {},
            body: Stream<Uint8List>.value(Uint8List.fromList([9])),
          );
        },
        onWebSocket: (_) => throw StateError('Unexpected websocket'),
      );
      final client = RemoteResourceClient(clientChannel);
      final active = await client.request('GET', Uri.parse('/revoked'));
      final failure = active.body.listen((_) {}, onError: (Object _) {});
      var finishedCancellation = false;
      final cancelling = server.cancelAll().then(
        (_) => finishedCancellation = true,
      );
      await cancelled.future.timeout(const Duration(seconds: 5));
      await _settle();
      expect(finishedCancellation, isFalse);
      cleanup.complete();
      await cancelling;
      await failure.cancel();
      final fresh = await client.request('GET', Uri.parse('/fresh'));
      expect(await fresh.body.single, [9]);
      await client.close();
      await server.close();
      await clientChannel.close();
    },
  );

  test('unwindowed resource data fail-closes the entire channel', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final heldBody = StreamController<Uint8List>();
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (_) async => RemoteResourceResponse(
        statusCode: 200,
        headers: const {},
        body: heldBody.stream,
      ),
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteResourceClient(clientChannel);
    final response = await client.request('GET', Uri.parse('/bounded'));
    expect(response.statusCode, 200);
    // The body has no listener and has granted zero fragments.
    await serverChannel.send({
      'type': 'resource',
      'v': 1,
      'id': 1,
      'op': 'data',
      'b': 'AQ==',
    });
    await server.done.timeout(const Duration(seconds: 5));
    expect(clientChannel.isOpen, isFalse);
    await client.close();
    await heldBody.close();
  });

  test('channel teardown aborts pending opening and server callback', () async {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final cancelled = Completer<void>();
    final server = RemoteResourceServer(
      serverChannel,
      onRequest: (request) async {
        await request.cancelled;
        cancelled.complete();
        throw StateError('upstream aborted');
      },
      onWebSocket: (_) => throw StateError('Unexpected websocket'),
    );
    final client = RemoteResourceClient(clientChannel);
    final pending = client.request('GET', Uri.parse('/wait'));
    final rejection = expectLater(pending, throwsStateError);
    await _settle();
    await clientChannel.close();
    await rejection;
    await cancelled.future.timeout(const Duration(seconds: 5));
    await server.done;
    await client.close();
  });
}
