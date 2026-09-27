@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _PrefsHost host;
  late RemoteRpcClient client;
  late ProviderContainer container;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _PrefsHost(server);
    client = RemoteRpcClient(clientChannel)..start();
    container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWith((ref) => Stream.value(client)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await client.close();
  });

  Future<void> start(Map<String, String> prefs) async {
    host.prefs = prefs;
    // Keep the stream mounted while actions and UI read it independently.
    container.listen(ownServerPrefsProvider, (_, _) {});
    await container.read(ownServerPrefsProvider.future);
  }

  Future<void> delivered() async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }

  List<Map<String, dynamic>> written(int index) =>
      (jsonDecode(host.writes[index].value) as List)
          .cast<Map<String, dynamic>>();

  test('loads desktop JSON and keeps workspace keys isolated', () async {
    await start({
      'space_folders.a': jsonEncode([
        {
          'id': 'f1',
          'name': 'First',
          'spaceIds': ['s1', 's2'],
        },
        {
          'id': 'f2',
          'name': 'Second',
          'spaceIds': ['s3'],
        },
      ]),
      'space_folders.b': jsonEncode([
        {
          'id': 'b1',
          'name': 'Other',
          'spaceIds': ['b-space'],
        },
      ]),
    });
    expect(container.read(spaceFoldersProvider('a')).map((f) => f.id), [
      'f1',
      'f2',
    ]);
    expect(container.read(spaceFoldersProvider('b')).single.spaceIds, [
      'b-space',
    ]);
    await container.read(spaceFolderActionsProvider('a')).move('s1', 'f2');
    expect(host.writes.single.key, 'space_folders.a');
    expect(written(0), [
      {
        'id': 'f1',
        'name': 'First',
        'spaceIds': ['s2'],
      },
      {
        'id': 'f2',
        'name': 'Second',
        'spaceIds': ['s3', 's1'],
      },
    ]);
    expect(container.read(spaceFoldersProvider('b')).single.spaceIds, [
      'b-space',
    ]);
    expect(container.read(spaceFoldersProvider('a'))[1].spaceIds, ['s3', 's1']);
  });

  test(
    'waits for first snapshot, creates atomically and serializes edits',
    () async {
      host.prefs = {
        'space_folders.a': jsonEncode([
          {
            'id': 'old',
            'name': 'Old',
            'spaceIds': ['a', 'b'],
          },
        ]),
      };
      host.autoSnapshot = false;
      container.listen(ownServerPrefsProvider, (_, _) {});
      final actions = container.read(spaceFolderActionsProvider('a'));
      final first = actions.create('New', spaceIds: ['a', 'a', 'c']);
      final second = actions.rename('old', 'Renamed');
      expect(host.writes, isEmpty);
      await host.subscriptionReady.future;
      expect(host._subscribed, isTrue);
      host.push(host.prefs);
      final id = await first;
      await second;
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(host.writes.length, 2);
      expect(written(0), [
        {
          'id': 'old',
          'name': 'Old',
          'spaceIds': ['b'],
        },
        {
          'id': id,
          'name': 'New',
          'spaceIds': ['a', 'c'],
        },
      ]);
      expect(written(1), [
        {
          'id': 'old',
          'name': 'Renamed',
          'spaceIds': ['b'],
        },
        {
          'id': id,
          'name': 'New',
          'spaceIds': ['a', 'c'],
        },
      ]);
      expect(container.read(spaceFoldersProvider('a'))[0].name, 'Renamed');
      expect(
        () => container.read(spaceFoldersProvider('a'))[1].spaceIds.add('x'),
        throwsUnsupportedError,
      );
      await actions.delete('old');
      expect(container.read(spaceFoldersProvider('a')).map((f) => f.id), [id]);
      await actions.move('a', null);
      expect(container.read(spaceFoldersProvider('a')).single.spaceIds, ['c']);
    },
  );

  test('late own echoes do not revert newer local edits', () async {
    await start({
      'space_folders.a': jsonEncode([
        {'id': 'f', 'name': 'Original', 'spaceIds': <String>[]},
      ]),
    });
    final actions = container.read(spaceFolderActionsProvider('a'));
    await actions.rename('f', 'First');
    await actions.rename('f', 'Latest');
    host.push({'space_folders.a': host.writes.first.value});
    await delivered();
    expect(container.read(spaceFoldersProvider('a')).single.name, 'Latest');
    await actions.move('s', 'f');
    expect(written(2).single, {
      'id': 'f',
      'name': 'Latest',
      'spaceIds': ['s'],
    });
    host.push({'space_folders.a': host.writes[1].value});
    await delivered();
    expect(container.read(spaceFoldersProvider('a')).single.spaceIds, ['s']);
  });

  test('failed write rolls back and next edit recovers', () async {
    await start({
      'space_folders.a': jsonEncode([
        {
          'id': 'f',
          'name': 'Original',
          'spaceIds': ['s'],
        },
      ]),
    });
    final actions = container.read(spaceFolderActionsProvider('a'));
    host.failNext = true;
    await expectLater(actions.rename('f', 'Failed'), throwsA(isA<Exception>()));
    expect(container.read(spaceFoldersProvider('a')).single.name, 'Original');
    await actions.move('s', null);
    expect(written(1).single, {
      'id': 'f',
      'name': 'Original',
      'spaceIds': <String>[],
    });
  });

  test(
    'invalid and empty preferences decode safely and accept later updates',
    () async {
      await start({'space_folders.a': '{invalid'});
      expect(container.read(spaceFoldersProvider('a')), isEmpty);
      host.push({
        'space_folders.a': jsonEncode([
          {
            'id': 'one',
            'name': 'A',
            'spaceIds': ['s', 's', 't'],
          },
          {
            'id': 'two',
            'name': 'B',
            'spaceIds': ['s', 'u'],
          },
          {'id': 'one', 'name': 'Duplicate', 'spaceIds': []},
          {
            'id': 'bad',
            'name': 'Invalid',
            'spaceIds': [42],
          },
        ]),
      });
      await delivered();
      expect(container.read(spaceFoldersProvider('a')).map((f) => f.spaceIds), [
        ['s', 't'],
        ['u'],
      ]);
      host.push({});
      await delivered();
      expect(container.read(spaceFoldersProvider('a')), isEmpty);
      await container.read(spaceFolderActionsProvider('a')).create('Fresh');
      expect(written(0).single['name'], 'Fresh');
    },
  );
}

class _Write {
  const _Write(this.key, this.value);
  final String key;
  final String value;
}

class _PrefsHost {
  _PrefsHost(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  Map<String, String> prefs = {};
  final List<_Write> writes = [];
  bool failNext = false;
  bool autoSnapshot = true;
  int _revision = 0;
  bool _subscribed = false;
  final subscriptionReady = Completer<void>();

  void push(Map<String, String> prefs) {
    this.prefs = prefs;
    if (!_subscribed) return;
    channel.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {
        'subscriptionId': 'prefs',
        'rev': ++_revision,
        'full': true,
        'data': {'prefs': prefs},
      },
    });
  }

  void _reply(Object? id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (frame['method']) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        if (params['query'] != 'prefs.watchOwn') {
          throw StateError('Unexpected subscription ${params['query']}');
        }
        _subscribed = true;
        if (!subscriptionReady.isCompleted) subscriptionReady.complete();
        _reply(id, {'subscriptionId': 'prefs', 'rev': 0});
        if (autoSnapshot) push(prefs);
      case RpcMethods.unsubscribe:
        _subscribed = false;
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        if (params['op'] != 'prefs.set') {
          throw StateError('Unexpected call ${params['op']}');
        }
        final args = (params['args'] as Map).cast<String, dynamic>();
        writes.add(_Write(args['key'] as String, args['value'] as String));
        if (failNext) {
          failNext = false;
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32000, 'message': 'Write failed'},
          });
        } else {
          _reply(id, {'op': 'prefs.set', 'data': <String, dynamic>{}});
        }
      default:
        _reply(id, const {});
    }
  }
}
