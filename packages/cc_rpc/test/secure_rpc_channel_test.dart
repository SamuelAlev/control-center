import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

final _psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));
const _timeout = Duration(seconds: 5);

/// A transparent wire tap. The callback may drop or mutate raw frames to
/// simulate an untrusted network; neither peer gets access to traffic keys.
final class _Wire implements RemoteRpcChannelPort {
  _Wire(this.raw);
  final InProcessRpcChannel raw;
  Future<Map<String, dynamic>?> Function(Map<String, dynamic>)? intercept;
  final captured = <Map<String, dynamic>>[];

  @override
  Stream<Map<String, dynamic>> get incoming => raw.incoming;
  @override
  Stream<RemoteChannelState> get state => raw.state;
  @override
  bool get isOpen => raw.isOpen;
  @override
  Future<void> close() => raw.close();
  @override
  Future<void> send(Map<String, dynamic> frame) async {
    captured.add(Map<String, dynamic>.of(frame));
    final forwarded = intercept == null ? frame : await intercept!(frame);
    if (forwarded != null) await raw.send(forwarded);
  }
}

typedef _Link = ({
  SecureRpcChannel client,
  SecureRpcChannel server,
  _Wire clientWire,
  _Wire serverWire,
});

Future<_Link> _connect() async {
  final (rawServer, rawClient) = InProcessRpcChannel.pair();
  final clientWire = _Wire(rawClient);
  final serverWire = _Wire(rawServer);
  final seed = await ServerIdentityCrypto.generateSeed();
  final waiting = acceptSecureChannel(
    channel: serverWire,
    readPsk: (device) async => device == 'device-1' ? _psk : null,
    serverPublicKey: await ServerIdentityCrypto.publicKeyFromSeed(seed),
    signIdentity: (challenge) =>
        ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
    timeout: _timeout,
  );
  final client = await connectSecureChannel(
    channel: clientWire,
    deviceId: 'device-1',
    psk: _psk,
    timeout: _timeout,
  );
  final server = await waiting;
  addTearDown(client.channel.close);
  return (
    client: client.channel,
    server: server.channel,
    clientWire: clientWire,
    serverWire: serverWire,
  );
}

Future<void> _closed(SecureRpcChannel channel) async {
  if (channel.isOpen) {
    await channel.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(_timeout);
  }
  expect(channel.isOpen, isFalse);
}

void main() {
  test(
    'all application frames and credits are ciphertext; concurrent sends retain order',
    () async {
      final link = await _connect();
      final received = <Map<String, dynamic>>[];
      final done = Completer<void>();
      final sub = link.server.incoming.listen((frame) {
        received.add(frame);
        if (received.length == 20) done.complete();
      });
      addTearDown(sub.cancel);
      await Future.wait([
        for (var i = 0; i < 20; i++)
          link.client.send({
            'jsonrpc': '2.0',
            'id': i,
            'method': 'repo/call',
            'params': {'secret': 'private-message-$i'},
          }),
      ]);
      await done.future.timeout(_timeout);
      expect(received.map((f) => f['id']), List<int>.generate(20, (i) => i));
      final records = link.clientWire.captured.where(
        (f) => f['type'] == 'secure',
      );
      expect(records.length, greaterThanOrEqualTo(21)); // ready + 20 requests
      final credits = link.serverWire.captured
          .where((f) => f['type'] == 'secure')
          .toList();
      expect(
        credits,
        isNotEmpty,
        reason: '16 received records return encrypted credit',
      );
      expect(credits.single.keys, containsAll(['type', 'v', 'c']));
      for (final record in [...records, ...credits]) {
        expect(record['v'], SecureRpcChannel.version);
        expect(record.keys, containsAll(['type', 'v', 'c']));
        expect(jsonEncode(record), isNot(contains('private-message-')));
        expect(record['c'], isA<String>());
      }
    },
  );

  test(
    'subscription bursts leave the encrypted connection usable for mutations',
    () async {
      final link = await _connect();
      final client = RemoteRpcClient(link.client, timeout: _timeout)..start();
      addTearDown(client.close);
      final connection = link.client.state.listen((state) {
        if (state == RemoteChannelState.closed) {
          unawaited(client.close());
        }
      });
      addTearDown(connection.cancel);
      final preferences = <String, String>{};
      final server = link.server.incoming.asyncMap((frame) async {
        final params = (frame['params'] as Map).cast<String, dynamic>();
        if (frame['method'] == RpcMethods.subscribe) {
          final spaceId = (params['args'] as Map)['space_id'] as String;
          await link.server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': {'subscriptionId': spaceId, 'rev': 0},
          });
          await link.server.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': spaceId,
              'data': {'space_id': spaceId, 'status': 'ready'},
            },
          });
        } else if (frame['method'] == RpcMethods.repoCall) {
          final args = params['args'] as Map;
          if (params['op'] == 'prefs.set') {
            preferences[args['key'] as String] = args['value'] as String;
          }
          await link.server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': {
              'data': {'prefs': preferences},
            },
          });
        } else if (frame['method'] == RpcMethods.unsubscribe) {
          await link.server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': {'ok': true},
          });
        }
      }).listen((_) {});
      addTearDown(server.cancel);

      const count = SecureRpcChannel.windowRecords * 2 + 1;
      final snapshots = await Future.wait([
        for (var i = 0; i < count; i++)
          client.subscribe('spaces.watch', {'space_id': 'space-$i'}).first,
      ]).timeout(_timeout);
      expect(snapshots, [
        for (var i = 0; i < count; i++)
          {'space_id': 'space-$i', 'status': 'ready'},
      ]);

      const folders = '[{"id":"folder","spaceIds":["space-0"]}]';
      await client.call('prefs.set', {
        'key': 'space_folders.ws-1',
        'value': folders,
      });
      expect(await client.call('prefs.getAll', const {}), {
        'prefs': {'space_folders.ws-1': folders},
      });
      expect(link.client.failure, isNull);
      expect(link.server.failure, isNull);
    },
  );

  test(
    'two-way transfers exceed one credit window without deadlock or corruption',
    () async {
      final link = await _connect();
      final fromClient = link.server.incoming.first;
      final fromServer = link.client.incoming.first;
      final payloadA =
          'a' *
          (SecureRpcChannel.chunkBytes * (SecureRpcChannel.windowRecords + 20));
      final payloadB =
          'b' *
          (SecureRpcChannel.chunkBytes * (SecureRpcChannel.windowRecords + 25));
      await Future.wait([
        link.client.send({'from': 'client', 'body': payloadA}),
        link.server.send({'from': 'server', 'body': payloadB}),
        expectLater(
          fromClient,
          completion({'from': 'client', 'body': payloadA}),
        ),
        expectLater(
          fromServer,
          completion({'from': 'server', 'body': payloadB}),
        ),
      ]).timeout(const Duration(seconds: 20));
      expect(link.client.isOpen, isTrue);
      expect(link.server.isOpen, isTrue);
    },
  );

  test(
    'ciphertext alteration fails closed without delivering a frame',
    () async {
      final link = await _connect();
      final delivered = <Map<String, dynamic>>[];
      final sub = link.server.incoming.listen(delivered.add);
      addTearDown(sub.cancel);
      link.clientWire.intercept = (frame) async {
        if (frame['type'] != 'secure') return frame;
        final bytes = base64Url.decode(frame['c'] as String)..[0] ^= 1;
        return {...frame, 'c': base64Url.encode(bytes)};
      };
      await link.client.send({'secret': 'must-never-arrive'});
      await _closed(link.server);
      expect(link.server.failure, isNotNull);
      expect(
        link.server.failure.toString(),
        isNot(contains('must-never-arrive')),
      );
      expect(delivered, isEmpty);
    },
  );

  test(
    'replayed record is rejected and a plaintext/downgraded record is never accepted',
    () async {
      for (final forged in [
        <String, dynamic>{'type': 'approved'},
        <String, dynamic>{'type': 'secure', 'v': 0, 'c': 'AAAA'},
      ]) {
        final link = await _connect();
        await link.clientWire.raw.send(forged);
        await _closed(link.server);
        expect(link.server.failure, isNotNull);
      }
      final link = await _connect();
      final frame = link.server.incoming.first;
      await link.client.send({'id': 1, 'secret': 'one-time'});
      expect(await frame, {'id': 1, 'secret': 'one-time'});
      final captured = link.clientWire.captured.last;
      expect(captured['type'], 'secure');
      await link.clientWire.raw.send(captured);
      await _closed(link.server);
      expect(link.server.failure, isNotNull);
    },
  );

  test('out-of-order records and direction substitution fail closed', () async {
    final reordered = await _connect();
    final withheld = <Map<String, dynamic>>[];
    reordered.clientWire.intercept = (frame) async {
      if (frame['type'] == 'secure') {
        withheld.add(frame);
        return null;
      }
      return frame;
    };
    await reordered.client.send({'id': 1});
    await reordered.client.send({'id': 2});
    expect(withheld, hasLength(2));
    await reordered.clientWire.raw.send(withheld.last);
    await _closed(reordered.server);
    expect(reordered.server.failure, isNotNull);

    final reflected = await _connect();
    await reflected.client.send({'id': 1});
    final clientRecord = reflected.clientWire.captured.last;
    await reflected.serverWire.raw.send(clientRecord);
    await _closed(reflected.client);
    expect(reflected.client.failure, isNotNull);
  });

  test(
    'reconnect has fresh traffic keys: old records cannot open a new session',
    () async {
      final old = await _connect();
      await old.client.send({'id': 1});
      final replay = old.clientWire.captured.last;
      await old.client.close();
      final next = await _connect();
      await next.clientWire.raw.send(replay);
      await _closed(next.server);
      expect(next.server.failure, isNotNull);
      expect(
        next.clientWire.captured.first['handshake'],
        isNot(old.clientWire.captured.first['handshake']),
      );
    },
  );

  test(
    'closing during a blocked transfer cancels sender and releases both ends',
    () async {
      final link = await _connect();
      final windowFull = Completer<void>();
      var records = link.clientWire.captured
          .where((f) => f['type'] == 'secure')
          .length;
      link.clientWire.intercept = (frame) async {
        if (frame['type'] != 'secure') return frame;
        if (++records == SecureRpcChannel.windowRecords) windowFull.complete();
        return null;
      };
      final pending = link.client.send({
        'body':
            'x' *
            (SecureRpcChannel.chunkBytes *
                (SecureRpcChannel.windowRecords + 1)),
      });
      final rejected = expectLater(pending, throwsA(isA<StateError>()));
      // Sender reaches the bounded 64-record window and waits for a credit that
      // the deliberately stalled network can never provide.
      await windowFull.future.timeout(_timeout);
      await link.client.close();
      await rejected;
      await _closed(link.server);
    },
  );

  test(
    'final encrypted response arrives before done despite immediate raw EOF',
    () async {
      final link = await _connect();
      final received = link.client.incoming.toList();
      await link.server.send({'id': 1, 'result': 'last reply'});
      await link.serverWire.raw.close();
      expect(await received.timeout(_timeout), [
        {'id': 1, 'result': 'last reply'},
      ]);
      expect(link.client.failure, isNull);
    },
  );

  test('multi-record final response drains before raw EOF', () async {
    final link = await _connect();
    // Cross a credit boundary while the final reply is still assembling.
    final body = 'response' * (SecureRpcChannel.chunkBytes * 17 ~/ 8);
    final received = link.client.incoming.toList();
    await link.server.send({'id': 2, 'result': body});
    await link.serverWire.raw.close();
    expect(await received.timeout(_timeout), [
      {'id': 2, 'result': body},
    ]);
    expect(link.client.failure, isNull);
  });

  test(
    'EOF during a final encrypted assembly fails without delivering data',
    () async {
      final link = await _connect();
      final received = link.client.incoming.toList();
      var records = 0;
      link.serverWire.intercept = (frame) async {
        if (frame['type'] == 'secure' && ++records == 2) return null;
        return frame;
      };
      await link.server.send({
        'id': 3,
        'result': 'missing end' * (SecureRpcChannel.chunkBytes ~/ 4),
      });
      await link.serverWire.raw.close();
      expect(await received.timeout(_timeout), isEmpty);
      expect(link.client.failure, isA<NoiseProtocolException>());
    },
  );

  test(
    'explicit close cancels queued decryption even with a paused consumer',
    () async {
      final link = await _connect();
      final delivered = <Map<String, dynamic>>[];
      final subscription = link.client.incoming.listen(delivered.add)..pause();
      addTearDown(subscription.cancel);
      link.serverWire.intercept = (frame) async => null;
      await link.server.send({'id': 4, 'result': 'must not arrive'});
      final record = link.serverWire.captured.last;
      final queued = link.serverWire.raw.send(record);
      await link.client.close().timeout(_timeout);
      await queued;
      subscription.resume();
      expect(delivered, isEmpty);
      expect(link.clientWire.isOpen, isFalse);
    },
  );

  test(
    'close releases the network without waiting for paused consumers',
    () async {
      final link = await _connect();
      final subscription = link.client.incoming.listen((_) {})..pause();
      addTearDown(subscription.cancel);
      await link.server.send({'private': 'queued before disconnect'});
      await link.client.close().timeout(_timeout);
      expect(link.clientWire.isOpen, isFalse);
      await expectLater(
        link.client.send({'private': 'after close'}),
        throwsStateError,
      );
      await _closed(link.server);
    },
  );

  test(
    'receiver without a consumer has a bounded pending-frame queue',
    () async {
      final link = await _connect();
      for (var i = 0; i < SecureRpcChannel.windowRecords + 1; i++) {
        await link.client.send({'id': i});
      }
      await _closed(link.server);
      expect(link.server.failure, isA<NoiseProtocolException>());
    },
  );

  test(
    'concurrent send queue is bounded rather than growing behind stalled I/O',
    () async {
      final link = await _connect();
      link.clientWire.intercept = (frame) async =>
          frame['type'] == 'secure' ? null : frame;
      final body =
          'z' *
          (SecureRpcChannel.chunkBytes * (SecureRpcChannel.windowRecords + 1));
      final pending = <Future<void>>[];
      for (var i = 0; i < SecureRpcChannel.windowRecords; i++) {
        pending.add(
          link.client.send({'body': body, 'id': i}).catchError((Object _) {}),
        );
      }
      await expectLater(
        link.client.send({'id': 'overflow'}),
        throwsA(isA<StateError>()),
      );
      await _closed(link.client);
      await Future.wait(pending);
    },
  );
}
