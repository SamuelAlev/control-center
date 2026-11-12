import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('cc_identity'));
  tearDown(() => dir.deleteSync(recursive: true));

  File identityFile() => File('${dir.path}/${ServerIdentityStore.fileName}');

  test(
    'a minted identity is written owner-only and reloads unchanged',
    () async {
      final first = await ServerIdentityStore.load(dir.path, serverName: 'a');
      expect(identityFile().statSync().mode & 0x1ff, 0x180, reason: '0600');
      final again = await ServerIdentityStore.load(dir.path, serverName: 'a');
      expect(again.fingerprint, first.fingerprint);
      expect(again.serverId, first.serverId);
      expect(dir.listSync(), hasLength(1), reason: 'no temp file left');
    },
    skip: Platform.isWindows ? 'POSIX modes only' : false,
  );

  test('an unreadable identity is quarantined and the boot refused', () async {
    identityFile().writeAsStringSync('{"server_id": "abc", "identity_se');

    await expectLater(
      ServerIdentityStore.load(dir.path),
      throwsA(
        isA<ServerIdentityUnreadable>().having(
          (e) => e.message,
          'message',
          contains('pair again'),
        ),
      ),
    );
    expect(identityFile().existsSync(), isFalse);
    final quarantined = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('.corrupt-'))
        .single;
    expect(
      quarantined.readAsStringSync(),
      '{"server_id": "abc", "identity_se',
      reason: 'the original bytes are kept',
    );

    // A supervisor restarting the server does not get a new identity either.
    await expectLater(
      ServerIdentityStore.load(dir.path),
      throwsA(isA<ServerIdentityUnreadable>()),
    );
    expect(identityFile().existsSync(), isFalse);

    // Deleting the quarantined copy is the deliberate way to start afresh.
    quarantined.deleteSync();
    await ServerIdentityStore.load(dir.path);
    expect(identityFile().existsSync(), isTrue);
  });

  test('an identity without its seed is not silently re-seeded', () async {
    identityFile().writeAsStringSync(jsonEncode({'server_id': 'abc'}));
    await expectLater(
      ServerIdentityStore.load(dir.path),
      throwsA(isA<ServerIdentityUnreadable>()),
    );
  });
}
