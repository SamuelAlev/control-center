import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteIdeRepository] — the editor / PR-worktree surface over RPC.
/// Pins the ops, the args shape (repo JSON, pr fields, editor id), the
/// editors decoder, the opUnknown degradation and the ensureWorktree path.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteIdeRepository.detectEditors', () {
    test('maps the editors array', () async {
      host.callResults['ide.detectEditors'] = {
        'editors': [
          {'id': 'vscode', 'display_name': 'VS Code', 'installed': true},
          {'id': 'cursor', 'display_name': 'Cursor', 'installed': false},
        ],
      };
      final repo = RemoteIdeRepository(client);
      final editors = await repo.detectEditors();
      expect(editors.length, 2);
      expect(editors.first.id, 'vscode');
      expect(editors.first.installed, isTrue);
      expect(editors.last.installed, isFalse);
    });

    test('defaults display_name to empty and installed to false', () async {
      host.callResults['ide.detectEditors'] = {
        'editors': [
          {'id': 'xcode'},
        ],
      };
      final repo = RemoteIdeRepository(client);
      final editors = await repo.detectEditors();
      expect(editors.first.id, 'xcode');
      expect(editors.first.displayName, '');
      expect(editors.first.installed, isFalse);
    });

    test('degrades to an empty list on opUnknown', () async {
      host.errorCodes['ide.detectEditors'] = RpcErrorCodes.opUnknown;
      final repo = RemoteIdeRepository(client);
      expect(await repo.detectEditors(), isEmpty);
    });

    test('rethrows a non-opUnknown error', () async {
      host.errorCodes['ide.detectEditors'] = RpcErrorCodes.unauthorized;
      final repo = RemoteIdeRepository(client);
      expect(repo.detectEditors, throwsA(isA<RemoteRpcException>()));
    });
  });

  group('RemoteIdeRepository.openPrInEditor', () {
    test('forwards the PR space fields + editor id', () async {
      final repo = RemoteIdeRepository(client);
      await repo.openPrInEditor(
        repoFullName: 'octo/repo',
        prNumber: 42,
        prExternalId: 'PR_node',
        repoId: 'r-1',
        editorId: 'vscode',
      );
      final call = host.lastCall('ide.openPrInEditor')!;
      expect(call.args['repo_full_name'], 'octo/repo');
      expect(call.args['pr_number'], 42);
      expect(call.args['pr_external_id'], 'PR_node');
      expect(call.args['repo_id'], 'r-1');
      expect(call.args['editor_id'], 'vscode');
    });
  });

  group('RemoteIdeRepository.ensureWorktree', () {
    test('returns the server path', () async {
      host.callResults['ide.ensureWorktree'] = {'path': '/srv/wt'};
      final repo = RemoteIdeRepository(client);
      expect(
        await repo.ensureWorktree(
          repoFullName: 'octo/repo',
          prNumber: 7,
          prExternalId: 'PR_node',
        ),
        '/srv/wt',
      );
      final call = host.lastCall('ide.ensureWorktree')!;
      expect(call.args['pr_number'], 7);
      expect(call.args['repo_full_name'], 'octo/repo');
      expect(call.args['pr_external_id'], 'PR_node');
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, int> errorCodes = {};

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
        final errCode = errorCodes[op];
        if (errCode != null) {
          space.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': errCode, 'message': 'scripted error'},
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
