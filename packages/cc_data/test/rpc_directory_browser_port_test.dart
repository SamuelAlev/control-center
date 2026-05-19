import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcDirectoryBrowserPort] — the add-repo filesystem browser over
/// RPC. Pins the op name, the path arg (incl. null) and the wire→entity
/// mapping (roots + entries).
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcDirectoryBrowserPort.browse', () {
    test('maps path/parent/roots/entries', () async {
      host.callResults['fs.browseDirectory'] = {
        'path': '/srv',
        'parent': '/',
        'is_git_repo': false,
        'roots': ['/srv', '/home'],
        'entries': [
          {'name': 'repo-a', 'path': '/srv/repo-a', 'is_git_repo': true},
          {'name': 'dir-b', 'path': '/srv/dir-b', 'is_git_repo': false},
        ],
      };
      final port = RpcDirectoryBrowserPort(client);
      final listing = await port.browse(path: '/srv');
      expect(listing.path, '/srv');
      expect(listing.parent, '/');
      expect(listing.isGitRepo, isFalse);
      expect(listing.roots, ['/srv', '/home']);
      expect(listing.entries.length, 2);
      expect(listing.entries.first.name, 'repo-a');
      expect(listing.entries.first.isGitRepo, isTrue);
      expect(host.lastCall('fs.browseDirectory')!.args['path'], '/srv');
    });

    test('maps a null parent and defaults booleans to false', () async {
      host.callResults['fs.browseDirectory'] = {'path': '/srv', 'entries': []};
      final port = RpcDirectoryBrowserPort(client);
      final listing = await port.browse();
      expect(listing.parent, isNull);
      expect(listing.isGitRepo, isFalse);
      expect(listing.entries, isEmpty);
      expect(
        host.lastCall('fs.browseDirectory')!.args.containsKey('path'),
        isFalse,
      );
    });

    test('filters non-String roots', () async {
      host.callResults['fs.browseDirectory'] = {
        'path': '/srv',
        'roots': ['/srv', 42, '/home'],
        'entries': [],
      };
      final port = RpcDirectoryBrowserPort(client);
      final listing = await port.browse();
      expect(listing.roots, ['/srv', '/home']);
    });

    test('ignores non-Map entries', () async {
      host.callResults['fs.browseDirectory'] = {
        'path': '/srv',
        'entries': [
          'nope',
          {'name': 'ok', 'path': '/srv/ok'},
        ],
      };
      final port = RpcDirectoryBrowserPort(client);
      final listing = await port.browse();
      expect(listing.entries.length, 1);
      expect(listing.entries.first.name, 'ok');
      expect(listing.entries.first.isGitRepo, isFalse);
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
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
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
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
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
