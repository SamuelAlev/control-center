import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_infra/cc_infra.dart' show SshSignature;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/commit_signing_keys.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late FileSecretsStore secrets;
  late CommitSigningKeys keys;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cc-signing-keys-test-');
    secrets = FileSecretsStore(dataDir: tmp.path);
    keys = CommitSigningKeys(secrets, now: () => DateTime.utc(2026, 11, 10));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('nobody has a key until they create one', () async {
    expect(await keys.describe('u-1'), isNull);
    expect(await keys.publicKeyOf('u-1'), isNull);
    await expectLater(
      keys.sign('u-1', 'ssh-ed25519 AAAA', utf8.encode('commit')),
      throwsA(isA<CommitSigningUnavailable>()),
    );
  });

  test('a created key is described by its public half only and signs for '
      'its person', () async {
    final info = await keys.create('u-1');

    expect(info.publicKey, startsWith('ssh-ed25519 '));
    expect(info.fingerprint, startsWith('SHA256:'));
    expect(info.createdAt, DateTime.utc(2026, 11, 10));
    expect((await keys.describe('u-1'))!.publicKey, info.publicKey);
    expect(await keys.publicKeyOf('u-1'), info.publicKey);

    final commit = utf8.encode('tree 1\n\nm\n');
    expect(
      await SshSignature.signerOf(
        await keys.sign('u-1', info.publicKey, commit),
        commit,
      ),
      info.publicKey,
    );
  });

  test('keys are per person', () async {
    final one = await keys.create('u-1');
    final two = await keys.create('u-2');
    expect(one.publicKey, isNot(two.publicKey));
    expect(await keys.publicKeyOf('u-3'), isNull);
  });

  test('a second key is refused until the first is deleted', () async {
    final first = await keys.create('u-1');
    await expectLater(keys.create('u-1'), throwsStateError);
    expect(await keys.publicKeyOf('u-1'), first.publicKey);

    expect(await keys.delete('u-1'), isTrue);
    expect(await keys.delete('u-1'), isFalse);
    expect(await keys.publicKeyOf('u-1'), isNull);
    await expectLater(
      keys.sign('u-1', 'ssh-ed25519 AAAA', utf8.encode('commit')),
      throwsA(isA<CommitSigningUnavailable>()),
    );
    expect((await keys.create('u-1')).publicKey, isNot(first.publicKey));
  });

  test(
    'the key survives a restart, and lives only in the secrets file',
    () async {
      final info = await keys.create('u-1');
      final reopened = CommitSigningKeys(FileSecretsStore(dataDir: tmp.path));
      expect(await reopened.publicKeyOf('u-1'), info.publicKey);

      final stored =
          jsonDecode(
                File(
                  '${tmp.path}/${FileSecretsStore.fileName}',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(stored.keys, [CommitSigningKeys.keyFor('u-1')]);
      if (!Platform.isWindows) {
        final mode = File(
          '${tmp.path}/${FileSecretsStore.fileName}',
        ).statSync().mode;
        expect(mode & 0x3f, 0, reason: 'owner-only (0600)');
      }
    },
  );

  test('an unreadable or mismatched record signs nothing', () async {
    final info = await keys.create('u-1');
    final key = CommitSigningKeys.keyFor('u-1');
    final record =
        jsonDecode((await secrets.readFresh(key))!) as Map<String, dynamic>;

    for (final bad in [
      'not json',
      '[]',
      jsonEncode({'seed': record['seed']}),
      // A seed that is not this public key's.
      jsonEncode({...record, 'seed': base64.encode(List.filled(32, 7))}),
      jsonEncode({
        ...record,
        'seed': base64.encode([1, 2, 3]),
      }),
    ]) {
      await secrets.writePsk(key, bad);
      final fresh = CommitSigningKeys(secrets);
      expect(await fresh.publicKeyOf('u-1'), isNull, reason: bad);
      await expectLater(
        fresh.sign('u-1', info.publicKey, utf8.encode('commit')),
        throwsA(isA<CommitSigningUnavailable>()),
        reason: bad,
      );
    }
    expect(info.publicKey, isNotEmpty);
  });

  test('a signature is refused when the key is not the one the caller '
      'named', () async {
    final first = await keys.create('u-1');
    await keys.delete('u-1');
    final second = await keys.create('u-1');
    final commit = utf8.encode('tree 1\n\nm\n');

    await expectLater(
      keys.sign('u-1', first.publicKey, commit),
      throwsA(isA<CommitSigningUnavailable>()),
    );
    expect(
      await SshSignature.signerOf(
        await keys.sign('u-1', second.publicKey, commit),
        commit,
      ),
      second.publicKey,
    );
  });

  test('two creates at once leave one key: the one the first caller was '
      'shown', () async {
    final results = await Future.wait([
      keys.create('u-1').then<Object>((k) => k, onError: (Object e) => e),
      keys.create('u-1').then<Object>((k) => k, onError: (Object e) => e),
    ]);

    final made = results.whereType<CommitSigningKeyInfo>().toList();
    expect(made, hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    expect(await keys.publicKeyOf('u-1'), made.single.publicKey);
  });

  test('an empty user id names nobody', () async {
    expect(await keys.publicKeyOf(''), isNull);
    await expectLater(keys.create(''), throwsArgumentError);
  });
}
