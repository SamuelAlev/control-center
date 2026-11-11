import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcCommitSigningKeyRepository]: the three self-service
/// `credentials.*CommitSigningKey` ops, which take no arguments at all.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcCommitSigningKeyRepository repo;

  const wireKey = {
    'public_key': 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA',
    'fingerprint': 'SHA256:abc',
    'created_at': '2026-11-10T09:30:00.000Z',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcCommitSigningKeyRepository(client);
  });

  tearDown(() async => client.close());

  test('get maps the key and sends no argument', () async {
    host.callResults['credentials.commitSigningKey'] = {'key': wireKey};
    final key = await repo.get();
    expect(
      key,
      CommitSigningKey(
        publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA',
        fingerprint: 'SHA256:abc',
        createdAt: DateTime.utc(2026, 11, 10, 9, 30),
      ),
    );
    expect(host.calls.single.args, isEmpty);
  });

  test('get answers null when the person has no key', () async {
    host.callResults['credentials.commitSigningKey'] = {'key': null};
    expect(await repo.get(), isNull);
  });

  test('create returns the new key', () async {
    host.callResults['credentials.createCommitSigningKey'] = {'key': wireKey};
    expect((await repo.create()).fingerprint, 'SHA256:abc');
    expect(host.calls.single.op, 'credentials.createCommitSigningKey');
  });

  test('create without a key in the answer is an error', () async {
    host.callResults['credentials.createCommitSigningKey'] = {'key': null};
    await expectLater(repo.create(), throwsFormatException);
  });

  test('delete reports whether there was a key', () async {
    host.callResults['credentials.deleteCommitSigningKey'] = {'deleted': true};
    expect(await repo.delete(), isTrue);
    host.callResults['credentials.deleteCommitSigningKey'] = {'deleted': false};
    expect(await repo.delete(), isFalse);
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
