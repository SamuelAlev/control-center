import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  late _Host host;
  late RemoteRpcClient client;

  final state = FilterListUpdateState.fromJson(const {
    'lastCheck': '2026-01-01T00:00:00.000',
    'lastSuccess': '2026-01-02T00:00:00.000',
    'isUpdating': false,
    'errors': ['easylist: no cached version available'],
    'cookieHidingRules': 4,
    'adHidingRules': 12,
    'networkBlockRules': 3,
    'removeParamsCount': 7,
  });

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('readState maps newsfeed.filterLists.state', () async {
    host.callResults['newsfeed.filterLists.state'] = state.toJson();
    final port = RpcFilterListPort(client);
    expect(await port.readState(), state);
    expect(
      host.lastCall('newsfeed.filterLists.state')?.op,
      'newsfeed.filterLists.state',
    );
  });

  test('refresh forwards force to newsfeed.filterLists.refresh', () async {
    host.callResults['newsfeed.filterLists.refresh'] = state.toJson();
    final got = await RpcFilterListPort(client).refresh(force: true);
    expect(got, state);
    expect(
      host.lastCall('newsfeed.filterLists.refresh')!.args['force'],
      isTrue,
    );
  });

  test('readBlocklist maps the rules list', () async {
    host.callResults['newsfeed.filterLists.blocklist'] = {
      'rules': [
        {
          'action': {'type': 'block'},
          'trigger': {'url-filter': '.*ads.*'},
        },
      ],
    };
    final rules = await RpcFilterListPort(client).readBlocklist();
    expect(rules, hasLength(1));
    expect((rules.first['action'] as Map)['type'], 'block');
  });

  test('readBlocklist returns [] when rules is missing', () async {
    host.callResults['newsfeed.filterLists.blocklist'] = <String, dynamic>{};
    expect(await RpcFilterListPort(client).readBlocklist(), isEmpty);
  });

  test('readRemoveParams maps the params list', () async {
    host.callResults['newsfeed.filterLists.removeParams'] = {
      'params': ['utm_source', 'fbclid', 1, ''],
    };
    expect(await RpcFilterListPort(client).readRemoveParams(), {
      'utm_source',
      'fbclid',
    });
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

  _Call? lastCall(String op) {
    for (var i = calls.length - 1; i >= 0; i--) {
      if (calls[i].op == op) {
        return calls[i];
      }
    }
    return null;
  }

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
