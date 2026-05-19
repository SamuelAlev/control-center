import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// [FileChatConnectionStore]: where a workspace's chat credentials live and what
/// that placement buys.
///
/// The location is the design decision under test. Credentials sit in the
/// workspace's own directory beside `workspace.db` — not inside it — so deleting a
/// workspace takes its bot with it and exporting or backing up a workspace hands
/// over the data without handing over a live chat app.
void main() {
  const slack = ChatProvider.slack;
  late Directory dataDir;
  late FileChatConnectionStore store;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_chat_store_');
    store = FileChatConnectionStore(dataDir: dataDir.path);
  });

  tearDown(() => dataDir.deleteSync(recursive: true));

  File credentialsFile(String workspaceId, [String name = 'slack.json']) =>
      File(p.join(dataDir.path, workspaceId, 'chat_credentials', name));

  test('round-trips a connection, secrets included', () async {
    await store.save(_connection());

    final loaded = await store.load('w-1', slack);
    expect(loaded?.credential('botToken'), 'xoxb-1');
    expect(loaded?.credential('appToken'), 'xapp-1');
    expect(loaded?.credential('configRefreshToken'), 'xoxe-1');
    expect(loaded?.teamName, 'Acme');
    expect(loaded?.enabled, isTrue);
  });

  test('lives beside the workspace database, not inside it', () async {
    await store.save(_connection());

    final file = credentialsFile('w-1');
    expect(file.existsSync(), isTrue);
    // The whole point: a `workspace.db` export carries no bot token.
    expect(jsonDecode(file.readAsStringSync()), isA<Map<String, dynamic>>());
    if (!Platform.isWindows) {
      // Owner-only, best effort — tokens should not inherit a 0644 umask.
      expect(file.statSync().modeString(), 'rw-------');
    }
  });

  test('has() answers without parsing anything', () {
    expect(store.has('w-1', slack), isFalse);
  });

  test('one file per provider, so a revoked app is one unlink', () async {
    await store.save(_connection());

    // Only Slack exists today; the shape is what matters — the file is named
    // after the provider, so a second provider cannot clobber the first.
    expect(credentialsFile('w-1').existsSync(), isTrue);
    expect(credentialsFile('w-1', 'discord.json').existsSync(), isFalse);
  });

  test('a workspace only ever sees its own connection', () async {
    await store.save(_connection());
    await store.save(_connection(workspaceId: 'w-2', teamName: 'Other'));

    expect((await store.load('w-1', slack))?.teamName, 'Acme');
    expect((await store.load('w-2', slack))?.teamName, 'Other');
    expect(await store.load('w-3', slack), isNull);
  });

  test('the file it was read from out-votes its own claims', () async {
    await store.save(_connection());
    final file = credentialsFile('w-1');
    final json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
          ..['workspaceId'] = 'w-999'
          ..['provider'] = 'discord';
    file.writeAsStringSync(jsonEncode(json));

    // A hand-edited or copied file must not smuggle another workspace's id — or
    // another provider — in.
    final loaded = await store.load('w-1', slack);
    expect(loaded?.workspaceId, 'w-1');
    expect(loaded?.provider, slack);
  });

  test('a corrupt file reads as “not connected” rather than throwing', () async {
    final file = credentialsFile('w-1')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{ this is not json');

    expect(await store.load('w-1', slack), isNull);
    // And it is replaceable: a bad file must not wedge the workspace.
    await store.save(_connection());
    expect((await store.load('w-1', slack))?.credential('botToken'), 'xoxb-1');
    expect(file.existsSync(), isTrue);
  });

  test('clear() forgets the credentials', () async {
    await store.save(_connection());

    await store.clear('w-1', slack);

    expect(store.has('w-1', slack), isFalse);
    expect(await store.load('w-1', slack), isNull);
    // Clearing twice is not an error (disconnect is idempotent).
    await store.clear('w-1', slack);
  });

  group('legacy Slack file', () {
    /// The pre-generalization layout, as a developer machine still has it.
    void writeLegacy(String workspaceId) =>
        File(p.join(dataDir.path, workspaceId, 'slack_credentials.json'))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'workspaceId': workspaceId,
              'appId': 'A1',
              'teamId': 'T1',
              'teamName': 'Acme',
              'botUserId': 'UBOT',
              'botName': 'controlcenter',
              'botToken': 'xoxb-legacy',
              'appToken': 'xapp-legacy',
              'configRefreshToken': 'xoxe-legacy',
              'enabled': true,
              'connectedAt': '2026-01-01T00:00:00.000Z',
            }),
          );

    test('is migrated in place on first load, tokens intact', () async {
      writeLegacy('w-1');

      // The probe has to see it too, or boot would skip a working connection.
      expect(store.has('w-1', slack), isTrue);
      final loaded = await store.load('w-1', slack);
      expect(loaded?.credential('botToken'), 'xoxb-legacy');
      expect(loaded?.credential('appToken'), 'xapp-legacy');
      expect(loaded?.credential('configRefreshToken'), 'xoxe-legacy');
      expect(loaded?.teamName, 'Acme');
      expect(loaded?.provider, slack);

      // Migrated, not copied: the old file is gone and the new one is canonical.
      expect(credentialsFile('w-1').existsSync(), isTrue);
      expect(
        File(p.join(dataDir.path, 'w-1', 'slack_credentials.json')).existsSync(),
        isFalse,
      );
      expect((await store.load('w-1', slack))?.credential('botToken'),
          'xoxb-legacy');
    });

    test('a legacy setup file is still readable across the rename', () async {
      File(p.join(dataDir.path, 'w-1', 'slack_app_setup.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({'configRefreshToken': 'xoxe-2', 'appId': 'A1'}),
        );

      final setup = await store.loadSetup('w-1', slack);
      expect(setup?.managementCredential, 'xoxe-2');
      expect(setup?.appId, 'A1');
    });
  });

  group('guided create hand-off', () {
    test('carries the rotated credential across the install gap', () async {
      await store.saveSetup(
        'w-1',
        slack,
        const ChatAppSetup(
          managementCredential: 'xoxe-2',
          appId: 'A1',
          installUrl: 'https://slack.com/oauth/v2/authorize?x=1',
        ),
      );

      final setup = await store.loadSetup('w-1', slack);
      expect(setup?.managementCredential, 'xoxe-2');
      expect(setup?.appId, 'A1');
      expect(setup?.installUrl, contains('oauth'));
    });

    test('a setup without a credential is worthless and reads as absent',
        () async {
      await store.saveSetup(
        'w-1',
        slack,
        const ChatAppSetup(managementCredential: '', appId: 'A1'),
      );

      expect(await store.loadSetup('w-1', slack), isNull);
    });

    test('the setup is separate from the connection and cleared alone', () async {
      await store.save(_connection());
      await store.saveSetup(
        'w-1',
        slack,
        const ChatAppSetup(managementCredential: 'x'),
      );

      await store.clearSetup('w-1', slack);

      expect(await store.loadSetup('w-1', slack), isNull);
      expect(await store.load('w-1', slack), isNotNull);
    });
  });
}

ChatBridgeConnection _connection({
  String workspaceId = 'w-1',
  String teamName = 'Acme',
}) => ChatBridgeConnection(
  provider: ChatProvider.slack,
  workspaceId: workspaceId,
  credentials: const {
    'botToken': 'xoxb-1',
    'appToken': 'xapp-1',
    'configRefreshToken': 'xoxe-1',
  },
  appId: 'A1',
  teamId: 'T1',
  teamName: teamName,
  botUserId: 'UBOT',
  botName: 'controlcenter',
  connectedAt: DateTime.utc(2026),
);
