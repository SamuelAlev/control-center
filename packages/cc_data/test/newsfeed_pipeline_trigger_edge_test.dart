import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RpcNewsfeedRepository] /
/// [RemoteNewsfeedRepository] and [RpcPipelineTriggerRepository] /
/// [RemotePipelineTriggerRepository] — the branches the broad
/// `remote_repositories_test.dart` host stub doesn't drive: notFound -> null,
/// non-notFound rethrow, missing-field fallbacks, saved/read filtering,
/// empty-result tolerances and the server-only UnsupportedError guards.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteNewsfeedRepository', () {
    test('listArticles skips non-Map rows + tolerates missing key', () async {
      host.callResults['newsfeed.listArticles'] = {
        'articles': ['junk'],
      };
      expect(await RemoteNewsfeedRepository(client).listArticles(), isEmpty);

      // Missing key entirely.
      host.callResults.remove('newsfeed.listArticles');
      expect(await RemoteNewsfeedRepository(client).listArticles(), isEmpty);
    });

    test('addFeed omits empty description + user_agent', () async {
      host.callResults['newsfeed.addFeed'] = {
        'feed': {'id': 'f1', 'name': 'X', 'url': 'https://x'},
      };
      await RemoteNewsfeedRepository(
        client,
      ).addFeed(name: 'X', url: 'https://x');
      final args = host.lastCall('newsfeed.addFeed')!.args;
      expect(args.containsKey('description'), isFalse);
      expect(args.containsKey('user_agent'), isFalse);
    });

    test('addFeed forwards non-empty description + user_agent', () async {
      host.callResults['newsfeed.addFeed'] = {
        'feed': {'id': 'f1', 'name': 'X', 'url': 'https://x'},
      };
      await RemoteNewsfeedRepository(
        client,
      ).addFeed(name: 'X', url: 'https://x', description: 'd', userAgent: 'ua');
      final args = host.lastCall('newsfeed.addFeed')!.args;
      expect(args['description'], 'd');
      expect(args['user_agent'], 'ua');
    });

    test('feed-management ops forward their args', () async {
      final repo = RemoteNewsfeedRepository(client);
      await repo.setFeedEnabled('f1', enabled: false);
      expect(host.lastCall('newsfeed.setFeedEnabled')!.args['enabled'], false);

      await repo.deleteFeed('f1');
      expect(host.lastCall('newsfeed.deleteFeed')!.args['feed_id'], 'f1');

      await repo.refreshFeed('f1');
      expect(host.lastCall('newsfeed.refreshFeed')!.args['feed_id'], 'f1');

      await repo.refreshAll();
      expect(host.lastCall('newsfeed.refreshAll'), isNotNull);

      await repo.markAllRead();
      expect(host.lastCall('newsfeed.markAllRead'), isNotNull);
    });

    test('watchFeeds skips non-Map rows', () async {
      host.snapshotFor('newsfeed.watchFeeds', {
        'feeds': ['bad'],
      });
      expect(
        await RemoteNewsfeedRepository(client).watchFeeds().first,
        isEmpty,
      );
    });
  });

  group('RpcNewsfeedRepository', () {
    test('watchArticles applies the limit', () async {
      host.snapshotFor('newsfeed.watchArticles', {
        'articles': [
          {'id': 'a1', 'feed_id': 'f1', 'title': 'One', 'url': 'https://x/1'},
          {'id': 'a2', 'feed_id': 'f1', 'title': 'Two', 'url': 'https://x/2'},
          {'id': 'a3', 'feed_id': 'f1', 'title': 'Three', 'url': 'https://x/3'},
        ],
      });
      final list = await RpcNewsfeedRepository(
        client,
      ).watchArticles(limit: 2).first;
      expect(list.length, 2);
    });

    test(
      'watchArticles fills read-safe fallbacks for missing optional fields',
      () async {
        host.snapshotFor('newsfeed.watchArticles', {
          'articles': [
            {'id': 'a1', 'feed_id': 'f1', 'title': 'T', 'url': 'https://x/1'},
          ],
        });
        final a = (await RpcNewsfeedRepository(
          client,
        ).watchArticles().first).single;
        expect(a.guid, 'a1'); // guid falls back to id
        expect(a.link, 'https://x/1');
        expect(a.summary, '');
        expect(a.imageUrl, '');
        expect(a.author, '');
        expect(a.read, isFalse);
        expect(a.saved, isFalse);
      },
    );

    test('watchSavedArticles filters to saved rows', () async {
      host.snapshotFor('newsfeed.watchArticles', {
        'articles': [
          {
            'id': 'a1',
            'feed_id': 'f1',
            'title': 'One',
            'url': 'https://x/1',
            'is_saved': true,
          },
          {
            'id': 'a2',
            'feed_id': 'f1',
            'title': 'Two',
            'url': 'https://x/2',
            'is_saved': false,
          },
        ],
      });
      final saved = await RpcNewsfeedRepository(
        client,
      ).watchSavedArticles().first;
      expect(saved.single.id, 'a1');
    });

    test('getArticleById returns null when not in the list', () async {
      host.callResults['newsfeed.listArticles'] = {
        'articles': [
          {'id': 'a1', 'feed_id': 'f1', 'title': 'T', 'url': 'https://x/1'},
        ],
      };
      expect(
        await RpcNewsfeedRepository(client).getArticleById('missing'),
        isNull,
      );
    });

    test('feed management + bulk ops forward over RPC', () async {
      final repo = RpcNewsfeedRepository(client);

      await repo.setArticleRead('a1', read: true);
      expect(host.lastCall('newsfeed.setArticleRead')!.args['read'], true);

      await repo.setArticleSaved('a1', saved: true);
      expect(host.lastCall('newsfeed.setArticleSaved')!.args['saved'], true);

      host.callResults['newsfeed.addFeed'] = {
        'feed': {'id': 'f1', 'name': 'N', 'url': 'https://x'},
      };
      await repo.addFeed(name: 'N', url: 'https://x');
      expect(host.lastCall('newsfeed.addFeed')!.args['name'], 'N');

      await repo.setFeedEnabled('f1', enabled: true);
      await repo.deleteFeed('f1');
      await repo.refreshAll();
      await repo.refreshFeed('f1');
      await repo.markAllRead();
    });

    test('seedDefaultFeedsIfEmpty asks the host to seed the session user', () async {
      host.callResults['newsfeed.seedDefaultFeedsIfEmpty'] = {'ok': true};
      await RpcNewsfeedRepository(client).seedDefaultFeedsIfEmpty();
      // Seeding runs host-side for the SESSION user (per-user feed lists) —
      // the client merely triggers it.
      final call = host.lastCall('newsfeed.seedDefaultFeedsIfEmpty')!;
      expect(call.op, 'newsfeed.seedDefaultFeedsIfEmpty');
    });

    test('watchFeeds maps feed DTOs with epoch fallbacks', () async {
      host.snapshotFor('newsfeed.watchFeeds', {
        'feeds': [
          {'id': 'f1', 'name': 'X', 'url': 'https://x', 'enabled': true},
        ],
      });
      final feeds = await RpcNewsfeedRepository(client).watchFeeds().first;
      expect(feeds.single.id, 'f1');
      expect(feeds.single.description, '');
      expect(feeds.single.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('RemotePipelineTriggerRepository', () {
    test('forWorkspace skips non-Map rows + tolerates missing key', () async {
      host.callResults['pipeline_trigger.forWorkspace'] = {
        'triggers': ['junk'],
      };
      expect(
        await RemotePipelineTriggerRepository(client).forWorkspace('ws1'),
        isEmpty,
      );
      expect(host.lastCall('pipeline_trigger.forWorkspace')!.args, {
        'workspace_id': 'ws1',
      });

      host.callResults.remove('pipeline_trigger.forWorkspace');
      expect(
        await RemotePipelineTriggerRepository(client).forWorkspace('ws1'),
        isEmpty,
      );
    });

    test('getById returns null when trigger is not a Map', () async {
      expect(
        await RemotePipelineTriggerRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('getById names the workspace that owns the trigger id', () async {
      host.callResults['pipeline_trigger.getById'] = {
        'trigger': {
          'id': 'pt1',
          'event_type': 'PrMerged',
          'template_id': 'tmpl-1',
        },
      };
      final dto = await RemotePipelineTriggerRepository(
        client,
      ).getById('ws1', 'pt1');
      expect(dto?.id, 'pt1');
      // A trigger id resolves only inside its own workspace's database file.
      expect(host.lastCall('pipeline_trigger.getById')!.args, {
        'workspace_id': 'ws1',
        'id': 'pt1',
      });
    });

    test('insert/update/deleteById forward the trigger JSON / id', () async {
      final repo = RemotePipelineTriggerRepository(client);
      final dto = PipelineTriggerDto(
        id: 'pt9',
        eventType: 'PrMerged',
        templateId: 'tmpl-1',
        workspaceId: 'ws1',
        enabled: true,
        createdAt: '2026-01-01T00:00:00.000',
      );
      await repo.insert(dto);
      final wire =
          host.lastCall('pipeline_trigger.insert')!.args['trigger'] as Map;
      expect(wire['id'], 'pt9');
      // insert/update carry the workspace INSIDE the trigger row — the host
      // checks it against the request's workspace before writing.
      expect(wire['workspace_id'], 'ws1');

      await repo.update(dto);
      expect(host.lastCall('pipeline_trigger.update'), isNotNull);

      await repo.deleteById('ws1', 'pt9');
      expect(host.lastCall('pipeline_trigger.deleteById')!.args, {
        'workspace_id': 'ws1',
        'id': 'pt9',
      });
    });
  });

  group('RpcPipelineTriggerRepository', () {
    const triggerWire = {
      'id': 'pt1',
      'event_type': 'PrMerged',
      'template_id': 'tmpl-1',
      'workspace_id': 'ws1',
      'enabled': true,
      'created_at': '2026-01-01T00:00:00.000',
    };

    test('getById returns null on notFound', () async {
      host.errorCodes['pipeline_trigger.getById'] = RpcErrorCodes.notFound;
      expect(
        await RpcPipelineTriggerRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('getById rethrows non-notFound errors', () async {
      host.errorCodes['pipeline_trigger.getById'] = RpcErrorCodes.internalError;
      expect(
        () => RpcPipelineTriggerRepository(client).getById('ws1', 'boom'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('getById maps a trigger with null optional timestamps', () async {
      host.callResults['pipeline_trigger.getById'] = {'trigger': triggerWire};
      final t = await RpcPipelineTriggerRepository(
        client,
      ).getById('ws1', 'pt1');
      expect(t, isNotNull);
      expect(t!.nextRunAt, isNull);
      expect(t.lastFiredAt, isNull);
      expect(
        host.lastCall('pipeline_trigger.getById')!.args['workspace_id'],
        'ws1',
      );
    });

    test('getById maps a trigger with present optional timestamps', () async {
      host.callResults['pipeline_trigger.getById'] = {
        'trigger': {
          ...triggerWire,
          'next_run_at': '2026-02-01T00:00:00.000',
          'last_fired_at': '2026-01-15T00:00:00.000',
        },
      };
      final t = await RpcPipelineTriggerRepository(
        client,
      ).getById('ws1', 'pt1');
      // DateTime.parse of a no-Z ISO string yields a LOCAL DateTime; the wire
      // round-trip keeps the wall-clock fields intact.
      expect(t!.nextRunAt, DateTime.parse('2026-02-01T00:00:00.000'));
      expect(t.lastFiredAt, DateTime.parse('2026-01-15T00:00:00.000'));
    });

    test('insert/update round-trip a PipelineTrigger through DTOs', () async {
      final repo = RpcPipelineTriggerRepository(client);
      final trigger = PipelineTrigger(
        id: 'pt9',
        eventType: 'PrMerged',
        templateId: 'tmpl-1',
        workspaceId: 'ws1',
        enabled: true,
        nextRunAt: DateTime.utc(2026, 3),
        createdAt: DateTime.utc(2026),
      );
      await repo.insert(trigger);
      final wire =
          host.lastCall('pipeline_trigger.insert')!.args['trigger'] as Map;
      expect(wire['id'], 'pt9');
      // toIso8601String() on a UTC DateTime carries the trailing Z.
      expect(wire['next_run_at'], '2026-03-01T00:00:00.000Z');

      await repo.update(trigger.copyWith(enabled: false));
      expect(
        host.lastCall('pipeline_trigger.update')!.args['trigger'],
        isA<Map>(),
      );
    });

    test('markFired forwards the workspace + id + ISO-8601 when', () async {
      await RpcPipelineTriggerRepository(
        client,
      ).markFired('ws1', 'pt9', DateTime.utc(2026, 2));
      final args = host.lastCall('pipeline_trigger.markFired')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['id'], 'pt9');
      expect(args['when'], '2026-02-01T00:00:00.000Z');
    });

    test('server-only ops throw UnsupportedError', () async {
      final repo = RpcPipelineTriggerRepository(client);
      expect(
        () => repo.setSchedule('ws1', 'pt1', nextRunAt: DateTime.utc(2026)),
        throwsUnsupportedError,
      );
      expect(() => repo.byWebhookToken('tok'), throwsUnsupportedError);
    });

    test('enabledForEvent + scheduled forward cross-workspace', () async {
      host.callResults['pipeline_trigger.enabledForEvent'] = {
        'triggers': [triggerWire],
      };
      host.callResults['pipeline_trigger.scheduled'] = {
        'triggers': [
          {
            ...triggerWire,
            'id': 'pt2',
            'event_type': 'schedule',
            'interval_seconds': 60,
          },
        ],
      };
      final repo = RpcPipelineTriggerRepository(client);
      expect((await repo.enabledForEvent('PrMerged')).single.id, 'pt1');
      expect((await repo.scheduled()).single.id, 'pt2');
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
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
  final Map<String, int> errorCodes = {};
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
        calls.add(_Call(op: op, args: args));
        final err = errorCodes[op];
        if (err != null) {
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': err, 'message': 'scripted'},
          });
        } else {
          _reply(id, {
            'op': op,
            'data': callResults[op] ?? const <String, dynamic>{},
          });
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
