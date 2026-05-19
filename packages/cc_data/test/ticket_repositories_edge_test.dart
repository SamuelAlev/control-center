import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RemoteTicketRepository] and [RpcTicketRepository]:
/// the branches the broad `remote_repositories_test.dart` host stub doesn't
/// drive — `assign`/`patchFields` non-Map -> null, list/watch skip non-Map
/// rows, `getById` notFound -> null / rethrow, enum fallbacks, epoch timestamp
/// fallbacks, collaborator decode, and the `update` conflict mapping.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteTicketRepository', () {
    test('list skips non-Map rows', () async {
      host.callResults['tickets.list'] = {
        'tickets': ['junk', 5],
      };
      expect(await RemoteTicketRepository(client).list(), isEmpty);
    });

    test('list tolerates a missing tickets key', () async {
      expect(await RemoteTicketRepository(client).list(), isEmpty);
    });

    test('get returns the ticket DTO', () async {
      host.callResults['tickets.get'] = {
        'ticket': {
          'ticket_id': 't1',
          'title': 'T',
          'status': 'inProgress',
          'priority': 'high',
        },
      };
      final dto = await RemoteTicketRepository(client).get('ws1', 't1');
      expect(dto.id, 't1');
      // A ticket id is a uuid, not a scoping boundary: the workspace that owns
      // it selects the database file.
      expect(host.lastCall('tickets.get')!.args, {
        'workspace_id': 'ws1',
        'ticket_id': 't1',
      });
    });

    test('assign returns null when ticket is not a Map', () async {
      final dto = await RemoteTicketRepository(
        client,
      ).assign('t1', agentId: 'a1');
      expect(dto, isNull);
    });

    test('assign returns the updated ticket DTO', () async {
      host.callResults['tickets.assign'] = {
        'ticket': {'ticket_id': 't1', 'title': 'T', 'assignee': 'a1'},
      };
      final dto = await RemoteTicketRepository(
        client,
      ).assign('t1', agentId: 'a1', teamId: 'tm1');
      expect(dto?.assignee, 'a1');
      final args = host.lastCall('tickets.assign')!.args;
      expect(args['agent_id'], 'a1');
      expect(args['team_id'], 'tm1');
    });

    test('patchFields returns null when ticket is not a Map', () async {
      final dto = await RemoteTicketRepository(
        client,
      ).patchFields('ws1', 't1', {'title': 'X'});
      expect(dto, isNull);
    });

    test('patchFields forwards an idempotency key when supplied', () async {
      host.callResults['tickets.patch'] = {
        'ticket': {'ticket_id': 't1', 'title': 'X'},
      };
      final dto = await RemoteTicketRepository(
        client,
      ).patchFields('ws1', 't1', {'title': 'X'}, idempotencyKey: 'k-1');
      expect(dto?.title, 'X');
    });

    test('addCollaborator / removeCollaborator forward the args', () async {
      final repo = RemoteTicketRepository(client);
      await repo.addCollaborator(
        workspaceId: 'ws1',
        id: 'tc1',
        ticketId: 't1',
        principalId: 'a1',
        collaboratorType: 'agent',
        role: 'reviewer',
        joinedAt: '2026-01-01T00:00:00.000',
      );
      var args = host.lastCall('tickets.addCollaborator')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['id'], 'tc1');
      expect(args['collaborator_type'], 'agent');

      await repo.removeCollaborator('ws1', 't1', 'a1');
      args = host.lastCall('tickets.removeCollaborator')!.args;
      expect(args['workspace_id'], 'ws1');
      expect(args['ticket_id'], 't1');
      expect(args['principal_id'], 'a1');
    });

    test('getCollaborators decodes the rows + skips non-Map', () async {
      host.callResults['tickets.getCollaborators'] = {
        'collaborators': [
          {'id': 'tc1', 'ticket_id': 't1', 'principal_id': 'a1'},
          'bad',
        ],
      };
      final list = await RemoteTicketRepository(
        client,
      ).getCollaborators('ws1', 't1');
      expect(list.length, 1);
      expect(list.first['id'], 'tc1');
      expect(
        host.lastCall('tickets.getCollaborators')!.args['workspace_id'],
        'ws1',
      );
    });
  });

  group('RpcTicketRepository', () {
    test('getById returns null on notFound', () async {
      host.errorCodes['tickets.get'] = RpcErrorCodes.notFound;
      expect(
        await RpcTicketRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('getById rethrows non-notFound errors', () async {
      host.errorCodes['tickets.get'] = RpcErrorCodes.internalError;
      expect(
        () => RpcTicketRepository(client).getById('ws1', 'boom'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('getById maps enum fallbacks + epoch timestamps', () async {
      host.callResults['tickets.get'] = {
        'ticket': {
          'ticket_id': 't1',
          'title': 'T',
          'status': 'bogus',
          'priority': 'bogus',
          'provider': 'bogus',
          'origin_kind': 'bogus',
        },
      };
      final t = await RpcTicketRepository(client).getById('ws1', 't1');
      expect(t, isNotNull);
      expect(host.lastCall('tickets.get')!.args['workspace_id'], 'ws1');
      // Unknown enums degrade to the documented defaults.
      expect(t!.status, TicketStatus.values.first);
      expect(t.priority, TicketPriority.none);
      expect(t.provider, TicketProvider.local);
      expect(t.originKind, TicketOriginKind.manual);
      // Missing required timestamps fall back to the epoch.
      expect(t.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(t.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test(
      'watchByStatus / watchByAssignee filter the workspace stream',
      () async {
        host.snapshotFor('tickets.watchForWorkspace', {
          'tickets': [
            {
              'ticket_id': 't1',
              'title': 'A',
              'status': 'inProgress',
              'priority': 'high',
              'assignee': 'a1',
            },
            {
              'ticket_id': 't2',
              'title': 'B',
              'status': 'blocked',
              'priority': 'low',
              'assignee': 'a2',
            },
          ],
        });
        final repo = RpcTicketRepository(client);
        final byStatus = await repo
            .watchByStatus('ws1', TicketStatus.blocked)
            .first;
        expect(byStatus.single.id, 't2');

        final byAssignee = await repo.watchByAssignee('ws1', 'a1').first;
        expect(byAssignee.single.id, 't1');
      },
    );

    test('forAgent / childrenOf filter the snapshot', () async {
      host.snapshotFor('tickets.watchForWorkspace', {
        'tickets': [
          {
            'ticket_id': 't1',
            'title': 'A',
            'assignee': 'a1',
            'parent_ticket_id': 'p1',
          },
          {
            'ticket_id': 't2',
            'title': 'B',
            'assignee': 'a2',
            'parent_ticket_id': 'p1',
          },
        ],
      });
      final repo = RpcTicketRepository(client);
      expect((await repo.forAgent('ws1', 'a1')).single.id, 't1');
      expect((await repo.childrenOf('ws1', 'p1')).length, 2);
    });

    test(
      'update maps a host conflict to ConcurrencyConflictException',
      () async {
        host.errorCodes['tickets.update'] = RpcErrorCodes.conflict;
        final repo = RpcTicketRepository(client);
        final ticket = Ticket(
          id: 't1',
          workspaceId: 'ws1',
          title: 'T',
          status: TicketStatus.inProgress,
          priority: TicketPriority.high,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        expect(
          () => repo.update(ticket, expectedVersion: 3),
          throwsA(isA<ConcurrencyConflictException>()),
        );
      },
    );

    test('update rethrows non-conflict errors', () async {
      host.errorCodes['tickets.update'] = RpcErrorCodes.internalError;
      final repo = RpcTicketRepository(client);
      final ticket = Ticket(
        id: 't1',
        workspaceId: 'ws1',
        title: 'T',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(() => repo.update(ticket), throwsA(isA<RemoteRpcException>()));
    });

    test('host-only ops throw UnsupportedError', () async {
      final repo = RpcTicketRepository(client);
      expect(
        () => repo.getByExternal(TicketProvider.local, 'k'),
        throwsUnsupportedError,
      );
      expect(
        () => repo.upsertMirror(
          Ticket(
            id: 't1',
            workspaceId: 'ws1',
            title: 'T',
            status: TicketStatus.inProgress,
            priority: TicketPriority.high,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('collaborators round-trip', () async {
      host.callResults['tickets.getCollaborators'] = {
        'collaborators': [
          {
            'id': 'tc1',
            'ticket_id': 't1',
            'principal_id': 'a1',
            'collaborator_type': 'agent',
            'role': 'reviewer',
            'joined_at': '2026-01-01T00:00:00.000',
          },
        ],
      };
      final repo = RpcTicketRepository(client);
      final list = await repo.getCollaborators('ws1', 't1');
      expect(list.single.id, 'tc1');
      expect(list.single.collaboratorType, PrincipalType.agent);
      expect(
        host.lastCall('tickets.getCollaborators')!.args['workspace_id'],
        'ws1',
      );

      // watchCollaborators maps the same way.
      host.snapshotFor('tickets.watchCollaborators', {
        'collaborators': [
          {
            'id': 'tc1',
            'ticket_id': 't1',
            'principal_id': 'a1',
            'collaborator_type': 'agent',
            'role': 'reviewer',
          },
        ],
      });
      final watched = await repo.watchCollaborators('ws1', 't1').first;
      // Missing joined_at falls back to the epoch.
      expect(watched.single.joinedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(host.lastSubscribe!.args, {
        'workspace_id': 'ws1',
        'ticket_id': 't1',
      });
    });

    test('insert forwards the wire DTO', () async {
      final repo = RpcTicketRepository(client);
      await repo.insert(
        Ticket(
          id: 't1',
          workspaceId: 'ws1',
          title: 'T',
          status: TicketStatus.inProgress,
          priority: TicketPriority.high,
          externalKey: 'EXT-1',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final wire = host.lastCall('tickets.insert')!.args['ticket'] as Map;
      expect(wire['ticket_id'], 't1');
      // externalKey maps to the wire `key`.
      expect(wire['key'], 'EXT-1');
    });

    test('delete forwards the ticket id', () async {
      final repo = RpcTicketRepository(client);
      await repo.delete('t1', workspaceId: 'ws1');
      expect(host.lastCall('tickets.delete')!.args['ticket_id'], 't1');
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
