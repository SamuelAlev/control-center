import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A minimal in-process host answering the `pairing.*` ops with canned data,
/// to prove [RemotePairingRepository] encodes requests + decodes responses.
class _PairingHost {
  _PairingHost(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<({String op, Map<String, dynamic> args})> calls = [];

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (method == 'initialize') {
      _reply(id, {'capabilities': <String, dynamic>{}});
      return;
    }
    if (method != RpcMethods.repoCall) {
      _reply(id, <String, dynamic>{});
      return;
    }
    final op = params['op'] as String;
    final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
    calls.add((op: op, args: args));
    switch (op) {
      case 'pairing.mint':
        _data(id, op, {
          'device_id': 'dev-new',
          'psk': 'psk-secret',
          'workspace_id': 'ws1',
          'workspace_name': 'Alpha',
          'server_url': 'wss://host:9030/rpc',
          'platform': args['platform'],
          'created_at': '2026-06-22T00:00:00.000Z',
        });
      case 'pairing.list':
        _data(id, op, {
          'devices': [_deviceJson('dev1', 'iPhone', 'ios')],
        });
      case 'pairing.rename':
        _data(id, op, {
          'device': _deviceJson(
            args['device_id'] as String,
            args['label'] as String,
            'desktop',
          ),
        });
      case 'pairing.revoke':
        _data(id, op, {'ok': true});
      default:
        _data(id, op, <String, dynamic>{});
    }
  }

  Map<String, dynamic> _deviceJson(String id, String label, String platform) => {
    'device_id': id,
    'label': label,
    'platform': platform,
    'status': 'active',
    'workspace_id': 'ws1',
    'workspace_name': 'Alpha',
    'paired_at': '2026-06-20T10:00:00.000Z',
    'last_seen_at': '2026-06-21T11:00:00.000Z',
  };

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});

  void _data(dynamic id, String op, Map<String, dynamic> data) =>
      _reply(id, {'op': op, 'data': data});
}

void main() {
  late _PairingHost host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _PairingHost(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('mint sends label + platform and parses the minted credential', () async {
    final repo = RemotePairingRepository(client);
    final mint = await repo.mint(label: 'Sam laptop', platform: 'desktop');
    expect(host.calls.single.op, 'pairing.mint');
    expect(host.calls.single.args['label'], 'Sam laptop');
    expect(host.calls.single.args['platform'], 'desktop');
    expect(mint.deviceId, 'dev-new');
    expect(mint.psk, 'psk-secret');
    expect(mint.serverUrl, 'wss://host:9030/rpc');
    expect(mint.platform, 'desktop');
    expect(mint.isDirectlyReachable, isTrue);
    expect(mint.workspaceName, 'Alpha');
  });

  test('mint defaults the platform to web', () async {
    final repo = RemotePairingRepository(client);
    final mint = await repo.mint(label: 'A browser');
    expect(host.calls.single.args['platform'], 'web');
    expect(mint.platform, 'web');
  });

  test('list parses paired devices', () async {
    final repo = RemotePairingRepository(client);
    final devices = await repo.list();
    expect(devices.single.id, 'dev1');
    expect(devices.single.label, 'iPhone');
    expect(devices.single.platform, 'ios');
    expect(devices.single.status, 'active');
    expect(devices.single.workspaceId, 'ws1');
    expect(devices.single.lastSeenAt, isNotNull);
  });

  test('rename sends device_id + label and parses the updated device', () async {
    final repo = RemotePairingRepository(client);
    final d = await repo.rename('dev1', 'Work laptop');
    expect(host.calls.single.args, {'device_id': 'dev1', 'label': 'Work laptop'});
    expect(d.label, 'Work laptop');
  });

  test('revoke sends the device_id', () async {
    final repo = RemotePairingRepository(client);
    await repo.revoke('dev1');
    expect(host.calls.single.op, 'pairing.revoke');
    expect(host.calls.single.args['device_id'], 'dev1');
  });
}
