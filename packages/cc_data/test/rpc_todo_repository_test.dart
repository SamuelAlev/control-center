import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcTodoRepository]'s goal surface and [RemoteMessagingDispatch]'s
/// pause/resume wire decoding against an in-process JSON-RPC host. The host
/// scripts `repo/call` results and `sub/subscribe` snapshots so the repository
/// is tested through its real `RemoteRpcClient` — proving the wire shape it
/// sends and decodes matches what the server catalog emits.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcTodoRepository goals', () {
    test('setGoal sends todos.setGoal with the trimmed title', () async {
      final repo = RpcTodoRepository(client);
      await repo.setGoal('ws-1', 'c-1', '  ship it  ');
      final call = host.lastCall('todos.setGoal')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['conversation_id'], 'c-1');
      expect(call.args['title'], '  ship it  ');
    });

    test('clearGoal sends todos.clearGoal', () async {
      final repo = RpcTodoRepository(client);
      await repo.clearGoal('ws-1', 'c-1');
      final call = host.lastCall('todos.clearGoal')!;
      expect(call.args['conversation_id'], 'c-1');
      expect(call.args['workspace_id'], 'ws-1');
    });

    test('watchGoal decodes a goal snapshot and maps to the entity', () async {
      host.goalSnapshot = {
        'goal': {
          'conversation_id': 'c-1',
          'workspace_id': 'ws-1',
          'title': 'Ship it',
          'created_at': '2026-07-01T09:00:00.000',
          'updated_at': '2026-07-01T10:00:00.000',
        },
      };
      final repo = RpcTodoRepository(client);
      final g = await repo.watchGoal('ws-1', 'c-1').first;
      expect(g, isNotNull);
      expect(g!.title, 'Ship it');
      expect(g.conversationId, 'c-1');
      expect(g.workspaceId, 'ws-1');
      expect(g.createdAt, DateTime(2026, 7, 1, 9));
      expect(g.updatedAt, DateTime(2026, 7, 1, 10));
    });

    test('watchGoal emits null when the snapshot has no goal', () async {
      host.goalSnapshot = const {'goal': null};
      final repo = RpcTodoRepository(client);
      expect(await repo.watchGoal('ws-1', 'c-1').first, isNull);
    });

    test('watchGoal emits null when the goal payload is not a Map', () async {
      host.goalSnapshot = const {'goal': 'not-a-map'};
      final repo = RpcTodoRepository(client);
      expect(await repo.watchGoal('ws-1', 'c-1').first, isNull);
    });

    test('watchGoal emits null when the title is blank', () async {
      host.goalSnapshot = {
        'goal': {
          'conversation_id': 'c-1',
          'workspace_id': 'ws-1',
          'title': '   ',
          'created_at': '2026-07-01T09:00:00.000',
          'updated_at': '2026-07-01T10:00:00.000',
        },
      };
      final repo = RpcTodoRepository(client);
      expect(await repo.watchGoal('ws-1', 'c-1').first, isNull);
    });

    test(
      'watchGoal tolerates a missing created_at (falls back to epoch)',
      () async {
        host.goalSnapshot = {
          'goal': {
            'conversation_id': 'c-1',
            'workspace_id': 'ws-1',
            'title': 'partial',
            'updated_at': '2026-07-01T10:00:00.000',
          },
        };
        final repo = RpcTodoRepository(client);
        final g = await repo.watchGoal('ws-1', 'c-1').first;
        expect(g, isNotNull);
        expect(g!.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test(
      'watchGoal sends the workspace + conversation on the subscribe',
      () async {
        host.goalSnapshot = const {'goal': null};
        final repo = RpcTodoRepository(client);
        await repo.watchGoal('ws-1', 'c-1').first;
        final sub = host.lastSubscribe!;
        expect(sub.query, 'todos.watchGoal');
        expect(sub.args['workspace_id'], 'ws-1');
        expect(sub.args['conversation_id'], 'c-1');
      },
    );
  });

  group('RpcTodoRepository todos (wire round-trip)', () {
    test('list decodes the todos array', () async {
      host.callResults['todos.list'] = {
        'todos': [
          {
            'id': 't-1',
            'workspace_id': 'ws-1',
            'conversation_id': 'c-1',
            'content': 'do thing',
            'status': 'in_progress',
            'position': 0,
            'created_at': '2026-07-01T09:00:00.000',
            'updated_at': '2026-07-01T09:30:00.000',
          },
        ],
      };
      final repo = RpcTodoRepository(client);
      final todos = await repo.list('ws-1', 'c-1');
      expect(todos.length, 1);
      expect(todos.first.id, 't-1');
      expect(todos.first.content, 'do thing');
      expect(todos.first.status, TodoStatus.inProgress);
      expect(todos.first.position, 0);
    });

    test('append decodes the returned todo', () async {
      host.callResults['todos.append'] = {
        'todo': {
          'id': 't-9',
          'workspace_id': 'ws-1',
          'conversation_id': 'c-1',
          'content': 'new',
          'status': 'pending',
          'position': 3,
          'created_at': '2026-07-01T09:00:00.000',
          'updated_at': '2026-07-01T09:00:00.000',
        },
      };
      final repo = RpcTodoRepository(client);
      final todo = await repo.append('ws-1', 'c-1', 'new');
      expect(todo.id, 't-9');
      expect(todo.status, TodoStatus.pending);
    });

    test('replaceAll sends the items with id/content/status', () async {
      final repo = RpcTodoRepository(client);
      await repo.replaceAll('ws-1', 'c-1', [
        TodoItem(
          id: 't-1',
          workspaceId: 'ws-1',
          conversationId: 'c-1',
          content: 'a',
          status: TodoStatus.completed,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);
      final call = host.lastCall('todos.replaceAll')!;
      final sent = call.args['todos'] as List;
      final first = (sent.first as Map).cast<String, dynamic>();
      expect(first['id'], 't-1');
      expect(first['content'], 'a');
      expect(first['status'], 'completed');
    });

    test('updateStatus sends the storage status key', () async {
      final repo = RpcTodoRepository(client);
      await repo.updateStatus('ws-1', 'c-1', 't-1', TodoStatus.completed);
      final call = host.lastCall('todos.setStatus')!;
      expect(call.args['status'], 'completed');
      expect(call.args['id'], 't-1');
    });

    test('watch decodes the snapshot todos array', () async {
      host.snapshotFor('todos.watch', {
        'todos': [
          {
            'id': 't-1',
            'workspace_id': 'ws-1',
            'conversation_id': 'c-1',
            'content': 'do thing',
            'status': 'in_progress',
            'position': 1,
            'created_at': '2026-07-01T09:00:00.000',
            'updated_at': '2026-07-01T09:30:00.000',
          },
          'bad',
        ],
      });
      final repo = RpcTodoRepository(client);
      final todos = await repo.watch('ws-1', 'c-1').first;
      expect(todos.length, 1);
      expect(todos.first.id, 't-1');
      expect(todos.first.position, 1);
      final sub = host.lastSubscribe!;
      expect(sub.args['workspace_id'], 'ws-1');
      expect(sub.args['conversation_id'], 'c-1');
    });

    test('watch falls back to an empty list when todos is absent', () async {
      host.snapshotFor('todos.watch', const {});
      final repo = RpcTodoRepository(client);
      expect(await repo.watch('ws-1', 'c-1').first, isEmpty);
    });

    test('remove forwards the id on todos.remove', () async {
      final repo = RpcTodoRepository(client);
      await repo.remove('ws-1', 'c-1', 't-1');
      final call = host.lastCall('todos.remove')!;
      expect(call.args['id'], 't-1');
      expect(call.args['conversation_id'], 'c-1');
    });

    test('reorder forwards the ordered ids on todos.reorder', () async {
      final repo = RpcTodoRepository(client);
      await repo.reorder('ws-1', 'c-1', const ['t-1', 't-2']);
      final call = host.lastCall('todos.reorder')!;
      expect(call.args['ordered_ids'], ['t-1', 't-2']);
    });

    test('clear sends the workspace + conversation on todos.clear', () async {
      final repo = RpcTodoRepository(client);
      await repo.clear('ws-1', 'c-1');
      final call = host.lastCall('todos.clear')!;
      expect(call.args['conversation_id'], 'c-1');
      expect(call.args['workspace_id'], 'ws-1');
    });
  });

  group('RemoteMessagingDispatch pause/resume', () {
    test('pauseRun returns true when the server reports paused=true', () async {
      host.callResults['dispatch.pauseRun'] = {'paused': true};
      final dispatch = RemoteMessagingDispatch(client);
      expect(await dispatch.pauseRun('run-1'), isTrue);
      final call = host.lastCall('dispatch.pauseRun')!;
      expect(call.args['run_id'], 'run-1');
    });

    test(
      'pauseRun returns false when the server reports paused=false',
      () async {
        host.callResults['dispatch.pauseRun'] = {'paused': false};
        final dispatch = RemoteMessagingDispatch(client);
        expect(await dispatch.pauseRun('run-1'), isFalse);
      },
    );

    test('pauseRun returns false when the key is absent', () async {
      host.callResults['dispatch.pauseRun'] = const {};
      final dispatch = RemoteMessagingDispatch(client);
      expect(await dispatch.pauseRun('run-1'), isFalse);
    });

    test(
      'resumeRun returns true when the server reports resumed=true',
      () async {
        host.callResults['dispatch.resumeRun'] = {'resumed': true};
        final dispatch = RemoteMessagingDispatch(client);
        expect(await dispatch.resumeRun('run-1'), isTrue);
        final call = host.lastCall('dispatch.resumeRun')!;
        expect(call.args['run_id'], 'run-1');
      },
    );

    test(
      'resumeRun returns false when the server reports resumed=false',
      () async {
        host.callResults['dispatch.resumeRun'] = {'resumed': false};
        final dispatch = RemoteMessagingDispatch(client);
        expect(await dispatch.resumeRun('run-1'), isFalse);
      },
    );
  });

  group('RpcMessagingPort pause/resume delegation', () {
    test('pauseRun delegates to the dispatch layer', () async {
      host.callResults['dispatch.pauseRun'] = {'paused': true};
      final port = RpcMessagingPort(client);
      expect(await port.pauseRun('run-1'), isTrue);
      expect(host.lastCall('dispatch.pauseRun')!.args['run_id'], 'run-1');
    });

    test('resumeRun delegates to the dispatch layer', () async {
      host.callResults['dispatch.resumeRun'] = {'resumed': true};
      final port = RpcMessagingPort(client);
      expect(await port.resumeRun('run-1'), isTrue);
      expect(host.lastCall('dispatch.resumeRun')!.args['run_id'], 'run-1');
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

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted `sub/subscribe` snapshots keyed by query. `todos.watchGoal` is
  /// special-cased by [goalSnapshot] for backwards compatibility.
  final Map<String, Map<String, dynamic>> snapshots = {};

  /// The snapshot pushed to the most-recent `todos.watchGoal` subscription.
  Map<String, dynamic> goalSnapshot = const {'goal': null};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed back for a `sub/subscribe` on [query].
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
        // Immediately push the scripted snapshot for the query.
        final snapshot =
            snapshots[query] ??
            (query == 'todos.watchGoal' ? goalSnapshot : null);
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
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
