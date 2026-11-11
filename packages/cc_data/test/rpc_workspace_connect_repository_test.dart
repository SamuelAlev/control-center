import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods, WorkspaceDto;
import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/features/connect/domain/value_objects/connect_health_error.dart';
import 'package:cc_domain/features/connect/domain/value_objects/workspace_connect_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Pins the client side of `workspaceConnect.*`: every call names its
/// workspace, a URL rides only with a custom Connect, and the status decodes
/// the server's shape (admin-only fields stay null when omitted).
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcWorkspaceConnectRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcWorkspaceConnectRepository(client);
  });

  tearDown(() async => client.close());

  const adminStatus = <String, dynamic>{
    'mode': 'custom',
    'url': 'https://connect.example.com',
    'server_mode': 'hosted',
    'server_url': 'https://connect.controlcenter.example',
    'effective_mode': 'custom',
    'locked': false,
    'health': 'down',
    'error': 'pins_changed',
    'stale': true,
    'epoch': 4,
    'lanes': [
      {'provider': 'github', 'source': 'connect', 'error': ''},
      {'provider': 'klipy', 'source': 'off', 'error': 'No key.'},
      {'provider': '', 'source': 'connect'},
    ],
    'install_id': 'INST',
    'pending_pins': {'github_app_id': '42'},
  };

  test('status decodes every field and names the workspace', () async {
    host.callResults['workspaceConnect.status'] = adminStatus;
    final status = await repo.status('ws-1');
    expect(host.lastCall('workspaceConnect.status')!.args, {
      'workspace_id': 'ws-1',
    });
    expect(status.mode, WorkspaceConnectMode.custom);
    expect(status.url, 'https://connect.example.com');
    expect(status.serverMode, ServerConnectChoice.hosted);
    expect(status.effectiveMode, WorkspaceConnectEffective.custom);
    expect(status.health, WorkspaceConnectHealth.down);
    expect(status.error, ConnectHealthError.pinsChanged);
    expect(status.stale, isTrue);
    expect(status.epoch, 4);
    // A lane without a provider id is dropped, not shown as a blank row.
    expect(status.lanes.map((l) => l.provider), ['github', 'klipy']);
    expect(status.laneFor('klipy')!.source, WorkspaceLaneSource.off);
    expect(status.laneFor('klipy')!.error, 'No key.');
    expect(status.installId, 'INST');
    expect(status.pendingPins, {'github_app_id': '42'});
  });

  test('a member sees no install id and no pins', () async {
    host.callResults['workspaceConnect.status'] = const {
      'mode': 'inherit',
      'server_mode': 'off',
      'effective_mode': 'server_own',
      'health': 'off',
      'lanes': [
        {'provider': 'google', 'source': 'server_own'},
      ],
    };
    final status = await repo.status('ws-1');
    expect(status.mode, WorkspaceConnectMode.inherit);
    expect(status.effectiveMode, WorkspaceConnectEffective.serverOwn);
    expect(status.lanes.single.source, WorkspaceLaneSource.serverOwn);
    expect(status.installId, isNull);
    expect(status.pendingPins, isNull);
    expect(status.epoch, isNull);
  });

  test('set sends the URL only for a custom Connect', () async {
    host.callResults['workspaceConnect.set'] = adminStatus;
    await repo.set(
      'ws-1',
      WorkspaceConnectMode.custom,
      url: 'https://connect.example.com',
    );
    expect(host.lastCall('workspaceConnect.set')!.args, {
      'workspace_id': 'ws-1',
      'mode': 'custom',
      'url': 'https://connect.example.com',
    });
    await repo.set('ws-1', WorkspaceConnectMode.own, url: 'https://stale');
    expect(host.lastCall('workspaceConnect.set')!.args, {
      'workspace_id': 'ws-1',
      'mode': 'own',
    });
  });

  test('test and confirmPins name the workspace', () async {
    host.callResults['workspaceConnect.test'] = adminStatus;
    host.callResults['workspaceConnect.confirmPins'] = adminStatus;
    await repo.test('ws-2');
    await repo.confirmPins('ws-2');
    expect(host.lastCall('workspaceConnect.test')!.args, {
      'workspace_id': 'ws-2',
    });
    expect(host.lastCall('workspaceConnect.confirmPins')!.args, {
      'workspace_id': 'ws-2',
    });
  });

  test('the workspace row carries the Connect choice', () {
    final dto = WorkspaceDto.fromJson(const {
      'id': 'ws-1',
      'name': 'Acme',
      'connect_mode': 'own',
    });
    expect(
      WorkspaceConnectMode.fromWire(dto.connectMode),
      WorkspaceConnectMode.own,
    );
  });
}

class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
