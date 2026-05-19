import 'dart:typed_data';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The workspace that owns every channel/message these tests address. A
/// workspace id selects the database file server-side, so it is part of the
/// wire shape of every workspace-scoped op — the assertions pin it.
const _ws = 'ws1';

/// Edge-case coverage for [RemoteMessagingRepository] and
/// [RpcMessagingRepository] — the branches the broad
/// `remote_repositories_test.dart` host stub doesn't drive: searchInChannel,
/// getMessageById non-Map -> null, channelExists default false, the message
/// write arg shapes, watchTopLevelMessagesWindow hasMore, watchThread,
/// watchThreadSummaries/watchChannelActivity typed mapping, the in-memory
/// getTopLevelMessagePage pagination, and the revert default fallbacks.
///
/// Ids are uuids but a uuid is not an access boundary: every op names the
/// workspace that scopes the lookup, and these tests assert it reaches the
/// wire. The two cross-workspace dashboard watches (`watchChannels`,
/// `watchChannelActivity`) are the documented exception — they omit the arg so
/// the client's ambient active workspace applies.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteMessagingRepository', () {
    test('listChannels skips non-Map rows + tolerates missing key', () async {
      host.callResults['messaging.listChannels'] = {
        'channels': ['junk'],
      };
      expect(
        await RemoteMessagingRepository(client).listChannels(_ws),
        isEmpty,
      );
      expect(
        host.lastCall('messaging.listChannels')!.args['workspace_id'],
        _ws,
      );

      host.callResults.remove('messaging.listChannels');
      expect(
        await RemoteMessagingRepository(client).listChannels(_ws),
        isEmpty,
      );
    });

    test(
      'getMessages forwards the workspace + channel_id, skips non-Maps',
      () async {
        host.callResults['messaging.getMessages'] = {
          'messages': ['bad'],
        };
        expect(
          await RemoteMessagingRepository(client).getMessages(_ws, 'c1'),
          isEmpty,
        );
        final args = host.lastCall('messaging.getMessages')!.args;
        expect(args['workspace_id'], _ws);
        expect(args['channel_id'], 'c1');
      },
    );

    test(
      'searchInChannel forwards workspace + channel_id + query + limit',
      () async {
        host.callResults['messaging.searchInChannel'] = {
          'messages': [
            {
              'id': 'm1',
              'channel_id': 'c1',
              'sender_id': 'a',
              'sender_type': 'agent',
              'content': 'hit',
            },
          ],
        };
        final list = await RemoteMessagingRepository(
          client,
        ).searchInChannel(_ws, 'c1', 'q', limit: 7);
        expect(list.single.id, 'm1');
        final args = host.lastCall('messaging.searchInChannel')!.args;
        expect(args['workspace_id'], _ws);
        expect(args['channel_id'], 'c1');
        expect(args['query'], 'q');
        expect(args['limit'], 7);
      },
    );

    test('getMessageById returns null when message is not a Map', () async {
      host.callResults['messaging.getMessageById'] = {'message': 'nope'};
      expect(
        await RemoteMessagingRepository(client).getMessageById(_ws, 'm1'),
        isNull,
      );
      final args = host.lastCall('messaging.getMessageById')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['message_id'], 'm1');
    });

    test('channelExists defaults to false when key absent', () async {
      expect(
        await RemoteMessagingRepository(client).channelExists(_ws, 'c1'),
        isFalse,
      );
    });

    test('channelExists maps an explicit exists flag', () async {
      host.callResults['messaging.channelExists'] = {'exists': true};
      expect(
        await RemoteMessagingRepository(client).channelExists(_ws, 'c1'),
        isTrue,
      );
      final args = host.lastCall('messaging.channelExists')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['channel_id'], 'c1');
    });

    test(
      'getParticipants forwards workspace + channel_id, decodes the list',
      () async {
        host.callResults['messaging.getParticipants'] = {
          'participants': [
            {'id': 'p1', 'channel_id': 'c1', 'principal_id': 'a1'},
          ],
        };
        final list = await RemoteMessagingRepository(
          client,
        ).getParticipants(_ws, 'c1');
        expect(list.single.id, 'p1');
        final args = host.lastCall('messaging.getParticipants')!.args;
        expect(args['workspace_id'], _ws);
        expect(args['channel_id'], 'c1');
      },
    );

    test('sendMessage forwards all optional fields + returns the id', () async {
      host.callResults['messaging.sendMessage'] = {'message_id': 'm-new'};
      final id = await RemoteMessagingRepository(client).sendMessage(
        workspaceId: _ws,
        channelId: 'c1',
        content: 'hi',
        senderId: 'a1',
        senderType: 'agent',
        messageType: 'notice',
        metadata: {'k': 'v'},
        id: 'm-1',
      );
      expect(id, 'm-new');
      final args = host.lastCall('messaging.sendMessage')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['sender_id'], 'a1');
      expect(args['sender_type'], 'agent');
      expect(args['message_type'], 'notice');
    });

    test('updateMessage forwards content/metadata + idempotencyKey', () async {
      await RemoteMessagingRepository(client).updateMessage(
        _ws,
        'm1',
        content: 'edit',
        metadata: {'k': 'v'},
        idempotencyKey: 'k-1',
      );
      final call = host.lastCall('messaging.updateMessage')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['content'], 'edit');
      expect(call.args['message_id'], 'm1');
      expect(call.idempotencyKey, 'k-1');
    });

    test('setChannelMode + addParticipant forward their args', () async {
      final repo = RemoteMessagingRepository(client);
      await repo.setChannelMode(_ws, 'c1', 'agent');
      final modeArgs = host.lastCall('messaging.setChannelMode')!.args;
      expect(modeArgs['workspace_id'], _ws);
      expect(modeArgs['mode'], 'agent');

      await repo.addParticipant(_ws, 'c1', 'a1');
      final args = host.lastCall('messaging.addParticipant')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['channel_id'], 'c1');
      expect(args['agent_id'], 'a1');
    });

    test(
      'revertConversationTo forwards inclusive + decodes affected ids',
      () async {
        host.callResults['messaging.revertConversationTo'] = {
          'affected_message_ids': ['m1', 'm2'],
          'filesystem_restored': true,
        };
        final result = await RemoteMessagingRepository(
          client,
        ).revertConversationTo(_ws, 'c1', 'm0', inclusive: true);
        expect(result.affected, ['m1', 'm2']);
        expect(result.filesystemRestored, isTrue);
        final args = host.lastCall('messaging.revertConversationTo')!.args;
        expect(args['workspace_id'], _ws);
        expect(args['inclusive'], true);
      },
    );

    test(
      'revertConversationTo defaults filesystem_restored to false',
      () async {
        final result = await RemoteMessagingRepository(
          client,
        ).revertConversationTo(_ws, 'c1', 'm0');
        expect(result.affected, isEmpty);
        expect(result.filesystemRestored, isFalse);
      },
    );

    test('unrevertConversation decodes the restored ids', () async {
      host.callResults['messaging.unrevertConversation'] = {
        'affected_message_ids': ['m1'],
      };
      final ids = await RemoteMessagingRepository(
        client,
      ).unrevertConversation(_ws, 'c1');
      expect(ids, ['m1']);
      final args = host.lastCall('messaging.unrevertConversation')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['channel_id'], 'c1');
    });

    test('watchMessagesWindow maps the window + hasMore', () async {
      host.snapshotFor('messaging.watchMessagesWindow', {
        'messages': [
          {
            'id': 'm1',
            'channel_id': 'c1',
            'sender_id': 'a',
            'sender_type': 'user',
            'content': 'x',
          },
        ],
        'has_more': true,
      });
      final w = await RemoteMessagingRepository(
        client,
      ).watchMessagesWindow(_ws, 'c1', 'c1', limit: 5).first;
      expect(w.messages.single.id, 'm1');
      expect(w.hasMore, isTrue);
      final args = host.lastSubscribe!.args;
      expect(args['workspace_id'], _ws);
      expect(args['channel_id'], 'c1');
      expect(args['limit'], 5);
    });

    test('watchChannelActivity skips non-Map rows', () async {
      host.snapshotFor('messaging.watchChannelActivity', {
        'channels': [
          42,
          {'id': 'c1'},
        ],
      });
      final list = await RemoteMessagingRepository(
        client,
      ).watchChannelActivity().first;
      expect(list.length, 1);
      expect(list.first['id'], 'c1');
      // The cross-workspace dashboard view: with no workspace named the arg is
      // absent, so the client's ambient active workspace applies.
      expect(host.lastSubscribe!.args.containsKey('workspace_id'), isFalse);
    });

    test('retryChannelProvisioning forwards the channel_id', () async {
      await RemoteMessagingRepository(
        client,
      ).retryChannelProvisioning(_ws, 'c1');
      final args = host.lastCall('messaging.retryChannelProvisioning')!.args;
      expect(args['workspace_id'], _ws);
      expect(args['channel_id'], 'c1');
    });
  });

  group('RpcMessagingRepository derived reads', () {
    test('getMessageById maps a found DTO', () async {
      host.callResults['messaging.getMessageById'] = {
        'message': {
          'id': 'm1',
          'channel_id': 'c1',
          'sender_id': 'a',
          'sender_type': 'user',
          'content': 'x',
        },
      };
      expect(
        (await RpcMessagingRepository(client).getMessageById(_ws, 'm1'))?.id,
        'm1',
      );
    });

    test('getChannelById throws UnsupportedError', () async {
      expect(
        () => RpcMessagingRepository(client).getChannelById(_ws, 'c1'),
        throwsUnsupportedError,
      );
    });

    test('getMessages maps a list with fallback channelId', () async {
      host.callResults['messaging.getMessages'] = {
        'messages': [
          {'id': 'm1', 'sender_id': 'a', 'sender_type': 'user', 'content': 'x'},
        ],
      };
      final list = await RpcMessagingRepository(client).getMessages(_ws, 'c1');
      expect(list.single.channelId, 'c1');
    });

    test('searchInChannel maps results', () async {
      host.callResults['messaging.searchInChannel'] = {
        'messages': [
          {
            'id': 'm1',
            'channel_id': 'c1',
            'sender_id': 'a',
            'sender_type': 'user',
            'content': 'x',
          },
        ],
      };
      final list = await RpcMessagingRepository(
        client,
      ).searchInChannel(_ws, 'c1', 'q');
      expect(list.single.id, 'm1');
    });

    test('channelExists forwards', () async {
      host.callResults['messaging.channelExists'] = {'exists': true};
      expect(
        await RpcMessagingRepository(client).channelExists(_ws, 'c1'),
        isTrue,
      );
    });

    test('getParticipants maps the list', () async {
      host.callResults['messaging.getParticipants'] = {
        'participants': [
          {'id': 'p1', 'channel_id': 'c1', 'principal_id': 'a1'},
        ],
      };
      final list = await RpcMessagingRepository(
        client,
      ).getParticipants(_ws, 'c1');
      expect(list.single.id, 'p1');
    });

    test('watchChannelActivity maps typed activity', () async {
      host.snapshotFor('messaging.watchChannelActivity', {
        'channels': [
          {
            'channel_id': 'c1',
            'unread_count': 2,
            'last_message_at': '2026-01-01T00:00:00.000',
          },
        ],
      });
      final list = await RpcMessagingRepository(
        client,
      ).watchChannelActivity(_ws).first;
      expect(list.single.channelId, 'c1');
      // The typed activity watch is workspace-keyed: it pins the caller's id
      // rather than following the client's ambient active workspace.
      expect(host.lastSubscribe!.args['workspace_id'], _ws);
    });

    test('getTopLevelMessagePage paginates a long channel in memory', () async {
      // Build 3 top-level messages; window of 1 from the newest.
      final messages = [
        for (var i = 0; i < 3; i++)
          {
            'id': 'm$i',
            'channel_id': 'c1',
            'sender_id': 'a',
            'sender_type': 'user',
            'content': 'c$i',
            'created_at': '2026-01-0${i + 1}T00:00:00.000',
          },
      ];
      host.callResults['messaging.getMessages'] = {'messages': messages};
      final repo = RpcMessagingRepository(client);
      final page = await repo.getMessagePage(_ws, 'c1', 'c1', limit: 1);
      // limit=1 with no cursor returns the NEWEST top-level message.
      expect(page.messages.single.id, 'm2');
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotNull);

      // Fetching the next page using the cursor walks one older.
      final next = await repo.getMessagePage(
        _ws,
        'c1',
        'c1',
        limit: 1,
        cursor: page.nextCursor,
      );
      expect(next.messages.single.id, 'm1');
      expect(next.hasMore, isTrue);
      expect(next.nextCursor, isNotNull);

      // And the oldest page has no more after it.
      final oldest = await repo.getMessagePage(
        _ws,
        'c1',
        'c1',
        limit: 1,
        cursor: next.nextCursor,
      );
      expect(oldest.messages.single.id, 'm0');
      expect(oldest.hasMore, isFalse);
      expect(oldest.nextCursor, isNull);
    });

    test(
      'getTopLevelMessagePage omits nextCursor when everything fits',
      () async {
        host.callResults['messaging.getMessages'] = {
          'messages': [
            {
              'id': 'm0',
              'channel_id': 'c1',
              'sender_id': 'a',
              'sender_type': 'user',
              'content': 'only',
              'created_at': '2026-01-01T00:00:00.000',
            },
          ],
        };
        final repo = RpcMessagingRepository(client);
        final page = await repo.getMessagePage(_ws, 'c1', 'c1', limit: 50);
        expect(page.messages.single.id, 'm0');
        expect(page.hasMore, isFalse);
        expect(page.nextCursor, isNull);
      },
    );
  });

  group('RpcMessagingRepository mutations + host-only guards', () {
    test(
      'sendMessage/updateMessage/setChannelMode/addParticipant delegate',
      () async {
        host.callResults['messaging.sendMessage'] = {'message_id': 'm1'};
        final repo = RpcMessagingRepository(client);

        await repo.sendMessage(
          workspaceId: _ws,
          channelId: 'c1',
          content: 'hi',
          senderId: 'a1',
          senderType: 'agent',
        );
        expect(
          host.lastCall('messaging.sendMessage')!.args['workspace_id'],
          _ws,
        );

        await repo.updateMessage(_ws, 'm1', content: 'edit');
        expect(
          host.lastCall('messaging.updateMessage')!.args['workspace_id'],
          _ws,
        );

        await repo.setChannelMode(_ws, 'c1', Mode.review);
        final modeArgs = host.lastCall('messaging.setChannelMode')!.args;
        expect(modeArgs['workspace_id'], _ws);
        expect(modeArgs['mode'], 'review');

        await repo.addParticipant(_ws, 'c1', 'a1');
        expect(
          host.lastCall('messaging.addParticipant')!.args['workspace_id'],
          _ws,
        );
      },
    );

    test('revertConversationTo maps affected; unrevert forwards', () async {
      host.callResults['messaging.revertConversationTo'] = {
        'affected_message_ids': ['m1'],
      };
      host.callResults['messaging.unrevertConversation'] = {
        'affected_message_ids': ['m1'],
      };
      final repo = RpcMessagingRepository(client);

      final affected = await repo.revertConversationTo(
        _ws,
        'c1',
        'm0',
        inclusive: true,
      );
      expect(affected, ['m1']);

      final restored = await repo.unrevertConversation(_ws, 'c1');
      expect(restored, ['m1']);
    });

    test('host-only lifecycle ops throw UnsupportedError', () async {
      final repo = RpcMessagingRepository(client);
      expect(
        () => repo.createChannel(_ws, 'n', const []),
        throwsUnsupportedError,
      );
      expect(() => repo.deleteChannel(_ws, 'c1'), throwsUnsupportedError);
      expect(
        () => repo.updateChannelName(_ws, 'c1', 'n'),
        throwsUnsupportedError,
      );
      expect(
        () => repo.clearChannelMessages(_ws, 'c1'),
        throwsUnsupportedError,
      );
      expect(
        () => repo.removeParticipant(_ws, 'c1', 'a1'),
        throwsUnsupportedError,
      );
      expect(
        () => repo.markCompacted(_ws, const ['m1']),
        throwsUnsupportedError,
      );
      expect(
        () => repo.updateMessageEmbedding(_ws, 'm1', Uint8List(0)),
        throwsUnsupportedError,
      );
      expect(
        () => repo.getMessagesWithEmbedding(_ws, 'c1'),
        throwsUnsupportedError,
      );
      expect(
        () => repo.getMessagesWithoutEmbedding(_ws),
        throwsUnsupportedError,
      );
    });
  });
}

/// Records a `repo/call` invocation (with optional idempotency key).
class _Call {
  const _Call({required this.op, required this.args, this.idempotencyKey});
  final String op;
  final Map<String, dynamic> args;
  final String? idempotencyKey;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        final snapshot = snapshots[query];
        if (snapshot != null) {
          channel.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        final idem =
            (params['idempotency_key'] as String?) ??
            (params['idempotencyKey'] as String?);
        calls.add(_Call(op: op, args: args, idempotencyKey: idem));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
