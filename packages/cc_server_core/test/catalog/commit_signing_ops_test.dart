import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/commit_signing_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/commit_signing_keys.dart';
import 'package:test/test.dart';

/// The commit signing key ops are about the caller and nobody else: there is
/// no argument that names a person, only the public half ever leaves, and a
/// companion phone can look but not mint or delete.
void main() {
  late Directory tmp;
  late CommitSigningKeys keys;
  late List<RepoOp> ops;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cc-signing-ops-test-');
    keys = CommitSigningKeys(FileSecretsStore(dataDir: tmp.path));
    ops = buildCommitSigningOps(keys);
  });

  tearDown(() => tmp.delete(recursive: true));

  RepoOp op(String name) => ops.singleWhere((o) => o.name == name);

  Future<Map<String, Object?>> run(
    String name,
    String user, {
    Map<String, dynamic> args = const {},
  }) async =>
      (await op(name).handler(
            RepoOpContext(
              args: args,
              workspaceId: null,
              deviceId: 'dev-$user',
              userId: user,
            ),
          ))
          as Map<String, Object?>;

  test('no store, no ops', () {
    expect(buildCommitSigningOps(null), isEmpty);
  });

  test('every op is self-service and unscoped; minting and deleting need a '
      'full client', () {
    expect(ops.map((o) => o.name), [
      'credentials.commitSigningKey',
      'credentials.createCommitSigningKey',
      'credentials.deleteCommitSigningKey',
    ]);
    for (final o in ops) {
      expect(o.workspaceScoped, isFalse, reason: o.name);
      expect(o.requiredArgs, isEmpty, reason: '${o.name} names nobody');
    }
    expect(op('credentials.commitSigningKey').kind, RepoOpKind.read);
    expect(op('credentials.commitSigningKey').requiredCapability, isNull);
    for (final name in [
      'credentials.createCommitSigningKey',
      'credentials.deleteCommitSigningKey',
    ]) {
      expect(op(name).kind, RepoOpKind.mutate, reason: name);
      expect(
        op(name).requiredCapability,
        SessionCapability.fullClient,
        reason: name,
      );
    }
  });

  test('a person creates, reads and deletes their own key, and only its '
      'public half is ever answered', () async {
    expect(await run('credentials.commitSigningKey', 'ada'), {'key': null});

    final created = await run('credentials.createCommitSigningKey', 'ada');
    final key = created['key']! as Map<String, Object?>;
    expect(key.keys, {'public_key', 'fingerprint', 'created_at'});
    expect(key['public_key'], startsWith('ssh-ed25519 '));
    expect(key['fingerprint'], startsWith('SHA256:'));
    expect(DateTime.parse(key['created_at']! as String).isUtc, isTrue);

    expect(await run('credentials.commitSigningKey', 'ada'), created);
    // Nothing answered contains the stored private half.
    final stored =
        jsonDecode(
              (await FileSecretsStore(
                dataDir: tmp.path,
              ).readFresh(CommitSigningKeys.keyFor('ada')))!,
            )
            as Map<String, dynamic>;
    expect(jsonEncode(created), isNot(contains(stored['seed'] as String)));

    expect(await run('credentials.deleteCommitSigningKey', 'ada'), {
      'deleted': true,
    });
    expect(await run('credentials.deleteCommitSigningKey', 'ada'), {
      'deleted': false,
    });
    expect(await run('credentials.commitSigningKey', 'ada'), {'key': null});
  });

  test(
    'a second key is a validation error, not a silent replacement',
    () async {
      final first = await run('credentials.createCommitSigningKey', 'ada');
      await expectLater(
        run('credentials.createCommitSigningKey', 'ada'),
        throwsA(isA<ValidationException>()),
      );
      expect(await run('credentials.commitSigningKey', 'ada'), first);
    },
  );

  test('nobody reaches another person\'s key, whatever they pass', () async {
    final adas = await run('credentials.createCommitSigningKey', 'ada');
    for (final args in [
      {'user_id': 'ada'},
      {'userId': 'ada'},
      {'target_user_id': 'ada', 'workspace_id': 'ws1'},
    ]) {
      expect(await run('credentials.commitSigningKey', 'bo', args: args), {
        'key': null,
      }, reason: '$args');
      expect(
        await run('credentials.deleteCommitSigningKey', 'bo', args: args),
        {'deleted': false},
        reason: '$args',
      );
    }
    expect(await run('credentials.commitSigningKey', 'ada'), adas);
    final bos = await run('credentials.createCommitSigningKey', 'bo');
    expect(
      (bos['key']! as Map)['public_key'],
      isNot((adas['key']! as Map)['public_key']),
    );
  });
}
