import 'package:cc_data/cc_data.dart' show RemoteAuditLog;
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// [RemoteAuditLog] over an in-process host: the `audit.watchLog` args shape
/// and the page decode.
void main() {
  late RemoteRpcChannelPort server;
  late RemoteRpcClient client;
  final subscribed = <Map<String, dynamic>>[];
  Map<String, dynamic>? snapshot;

  setUp(() {
    subscribed.clear();
    snapshot = null;
    final (host, clientChannel) = InProcessRpcChannel.pair();
    server = host;
    server.incoming.listen((frame) {
      final id = frame['id'];
      final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
      void reply(Map<String, dynamic> result) =>
          server.send({'jsonrpc': '2.0', 'id': id, 'result': result});
      switch (frame['method']) {
        case RpcMethods.subscribe:
          expect(params['query'], 'audit.watchLog');
          subscribed.add((params['args'] as Map).cast<String, dynamic>());
          reply({'subscriptionId': 's1', 'rev': 0});
          if (snapshot case final data?) {
            server.send({
              'jsonrpc': '2.0',
              'method': RpcMethods.subSnapshot,
              'params': {
                'subscriptionId': 's1',
                'rev': 1,
                'full': true,
                'data': data,
              },
            });
          }
        default:
          reply(const {'capabilities': <String, dynamic>{}});
      }
    });
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('the query sends only what it filters on', () async {
    snapshot = const {'entries': [], 'scopes': [], 'total': 0};
    await RemoteAuditLog(client).watchPage(const AuditLogQuery()).first;
    expect(subscribed.single, {'limit': 25});

    final at = DateTime.utc(2026, 11, 10, 12);
    await RemoteAuditLog(client)
        .watchPage(
          AuditLogQuery(
            cursor: 'c-1',
            limit: 10,
            search: '  deploy ',
            searchUserIds: const {'u-2'},
            actorIds: const {'u-1'},
            sources: const {'server', 'ws:ws-a'},
            outcomes: const {AuditOutcome.denied},
            ip: '10.0.0.1',
            localNetwork: true,
            time: [AuditTimeCondition(op: AuditTimeOperator.after, at: at)],
          ),
        )
        .first;
    expect(subscribed.last, {
      'cursor': 'c-1',
      'limit': 10,
      'query': 'deploy',
      'search_user_ids': ['u-2'],
      'actor_ids': ['u-1'],
      'sources': ['server', 'ws:ws-a'],
      'outcomes': ['denied'],
      'ip': '10.0.0.1',
      'local_network': true,
      'time': [
        {'op': 'gt', 'at': '2026-11-10T12:00:00.000Z'},
      ],
    });
  });

  test('a page decodes rows, scopes, cursors and facets', () async {
    snapshot = {
      'entries': [
        {
          'id': 's-1',
          'source': 'server',
          'user_id': 'u-1',
          'action': 'connect.setChoice',
          'outcome': 'denied',
          'arg_names': ['mode'],
          'ip': '127.0.0.1',
          'created_at': '2026-11-10T12:00:00.000Z',
        },
        {
          'id': 'a-1',
          'source': 'ws:ws-a',
          'workspace_id': 'ws-a',
          'user_id': 'u-2',
          'action': 'agents.upsert',
          'outcome': 'ok',
          'target_type': 'agent',
          'target_id': 'ag-1',
          'details': {'name': 'Bot'},
          'country_code': 'FR',
          'created_at': '2026-11-10T11:00:00.000Z',
        },
        // Malformed rows are dropped, not thrown on.
        {'id': 'x', 'source': 'server'},
      ],
      'scopes': [
        {'key': 'server', 'kind': 'server'},
        {
          'key': 'ws:ws-a',
          'kind': 'workspace',
          'workspace_id': 'ws-a',
          'name': 'Alpha',
        },
        {'key': 'odd', 'kind': 'planet'},
      ],
      'total': 12,
      'start': 1,
      'next_cursor': 'n-1',
      'facets': {
        'actors': {'u-1': 7, 'u-2': 5},
        'sources': {'server': 7, 'ws:ws-a': 5},
        'outcomes': {'ok': 11, 'denied': 1, 'bogus': 4},
      },
    };
    final page = await RemoteAuditLog(
      client,
    ).watchPage(const AuditLogQuery(limit: 2)).first;

    expect([for (final e in page.entries) e.id], ['s-1', 'a-1']);
    final server = page.entries.first;
    expect(server.isServer, isTrue);
    expect(server.outcome, AuditOutcome.denied);
    expect(server.argNames, ['mode']);
    expect(server.createdAt, DateTime.utc(2026, 11, 10, 12));
    final ws = page.entries.last;
    expect(ws.isServer, isFalse);
    expect(ws.workspaceId, 'ws-a');
    expect(ws.countryCode, 'FR');
    expect(ws.details, {'name': 'Bot'});

    expect([for (final s in page.scopes) s.key], ['server', 'ws:ws-a']);
    expect(page.scopes.last.kind, AuditLogScopeKind.workspace);
    expect(page.scopes.last.name, 'Alpha');

    expect(page.total, 12);
    expect(page.start, 1);
    expect(page.end, 2);
    expect(page.nextCursor, 'n-1');
    expect(page.prevCursor, isNull);
    expect(page.actorCounts, {'u-1': 7, 'u-2': 5});
    expect(page.sourceCounts, {'server': 7, 'ws:ws-a': 5});
    expect(page.outcomeCounts, {AuditOutcome.ok: 11, AuditOutcome.denied: 1});
  });

  test('queries with the same filters are equal', () {
    final at = DateTime.utc(2026);
    AuditLogQuery q(Set<String> actors) => AuditLogQuery(
      actorIds: actors,
      time: [AuditTimeCondition(op: AuditTimeOperator.before, at: at)],
    );
    expect(q(const {'a', 'b'}), q(const {'b', 'a'}));
    expect(q(const {'a', 'b'}).hashCode, q(const {'b', 'a'}).hashCode);
    expect(q(const {'a'}), isNot(q(const {'b'})));
  });
}
