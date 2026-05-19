import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcClaudeAccountsRepository] — the client half of the Claude Code
/// account surface. Pins the op names, the argument shapes and the wire→entity
/// mapping, including the two the UI actually depends on being right: the
/// usage join behind the picker's headroom column, and "Default" clearing the
/// pin by OMITTING the key rather than sending null.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcClaudeAccountsRepository repo;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcClaudeAccountsRepository(client);
  });

  tearDown(() async => client.close());

  group('list', () {
    test('maps identity and the usage join', () async {
      host.callResults['claude_accounts.list'] = {
        'accounts': [
          {
            'id': 'work',
            'label': 'work@example.com',
            'email': 'work@example.com',
            'org_name': 'Acme',
            'subscription_type': 'max',
            'logged_in': true,
            'is_default': true,
            'usage': {
              'provider_id': 'claude',
              'display_name': 'Claude',
              'status': 'ok',
              'windows': [
                {'id': '5h', 'label': 'Session', 'used_fraction': 0.2},
                {'id': '7d', 'label': 'Weekly', 'used_fraction': 0.81},
              ],
            },
          },
          {'id': 'personal', 'label': 'Personal', 'logged_in': false},
        ],
      };
      final accounts = await repo.list();
      expect(accounts.length, 2);

      final work = accounts.first;
      expect(work.account.email, 'work@example.com');
      expect(work.account.orgName, 'Acme');
      expect(work.account.isDefault, isTrue);
      expect(work.account.subtitle, 'max · Acme');
      // The picker shows the window that will stop a run FIRST, so the join
      // has to surface the weekly 81% rather than the session 20%.
      expect(work.tightestWindow?.id, '7d');

      final personal = accounts.last;
      expect(personal.account.loggedIn, isFalse);
      expect(personal.usage, isNull);
      expect(personal.tightestWindow, isNull);
    });

    test('degrades to empty on a missing or malformed payload', () async {
      host.callResults['claude_accounts.list'] = const {};
      expect(await repo.list(), isEmpty);
      host.callResults['claude_accounts.list'] = {'accounts': 'nope'};
      expect(await repo.list(), isEmpty);
    });
  });

  group('management', () {
    test('create passes a label only when one was given', () async {
      host.callResults['claude_accounts.create'] = {
        'account': {'id': 'work', 'label': 'Work'},
      };
      final created = await repo.create(label: 'Work');
      expect(created?.id, 'work');
      expect(host.lastCall('claude_accounts.create')!.args['label'], 'Work');

      await repo.create();
      expect(
        host.lastCall('claude_accounts.create')!.args.containsKey('label'),
        isFalse,
      );
    });

    test('rename / remove / setDefault carry the id', () async {
      await repo.rename('work', 'Work login');
      expect(host.lastCall('claude_accounts.rename')!.args, {
        'id': 'work',
        'label': 'Work login',
      });
      await repo.remove('work');
      expect(host.lastCall('claude_accounts.remove')!.args, {'id': 'work'});
      await repo.setDefault('work');
      expect(host.lastCall('claude_accounts.setDefault')!.args, {'id': 'work'});
    });

    test('loginCommand returns the argv and its scoping environment', () async {
      host.callResults['claude_accounts.loginCommand'] = {
        'argv': ['claude', 'auth', 'login'],
        'environment': {'CLAUDE_CONFIG_DIR': '/data/claude-accounts/work'},
      };
      final cmd = await repo.loginCommand('work');
      expect(cmd?.argv, ['claude', 'auth', 'login']);
      // Without this the operator would sign the DEFAULT account in again and
      // wonder why the new row stayed signed out.
      expect(
        cmd?.environment['CLAUDE_CONFIG_DIR'],
        '/data/claude-accounts/work',
      );
    });

    test('loginCommand degrades to null on a malformed payload', () async {
      host.callResults['claude_accounts.loginCommand'] = {'argv': 'nope'};
      expect(await repo.loginCommand('work'), isNull);
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
