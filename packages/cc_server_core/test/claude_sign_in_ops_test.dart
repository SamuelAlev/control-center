import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ClaudeAccountStore;
import 'package:cc_server_core/src/catalog/claude_sign_in_ops.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late ClaudeAccountStore store;
  late RepoOp op;

  /// Every subprocess the store asked for, as `executable arguments`.
  late List<String> spawned;

  final clock = DateTime.utc(2026, 11, 10, 21);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_sign_in_ops_');
    spawned = [];
    store = ClaudeAccountStore(
      dataDir: temp.path,
      now: () => clock,
      // No keychain item for any account: the directory's file decides.
      runProcess: (executable, arguments, {environment}) async {
        spawned.add('$executable ${arguments.join(' ')}');
        return ProcessResult(0, 44, '', 'not found');
      },
    );
    op = buildClaudeSignInOps(store).single;
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Future<Map<String, dynamic>> call([Map<String, dynamic> args = const {}]) =>
      op.handler(
        RepoOpContext(
          args: args,
          workspaceId: null,
          deviceId: 'device-1',
          userId: 'owner',
        ),
      );

  void signIn(String accountId, DateTime expiresAt) =>
      File(
        p.join(store.configDirFor(accountId), '.credentials.json'),
      ).writeAsStringSync(
        jsonEncode({
          'claudeAiOauth': {
            'accessToken': 'fake-access',
            'refreshToken': 'fake-refresh',
            'expiresAt': expiresAt.millisecondsSinceEpoch,
          },
        }),
      );

  test('is a read of the whole server that belongs to its owner', () {
    expect(op.name, 'claude_accounts.signInStates');
    expect(op.kind, RepoOpKind.read);
    expect(op.workspaceScoped, isFalse);
    expect(op.serverAuthority, ServerAuthority.serverOwner);
  });

  test('answers each registered account, in UTC', () async {
    await store.create(label: 'Work');
    await store.create(label: 'Personal');
    signIn('work', clock.add(const Duration(hours: 8)));

    expect(await call(), {
      'accounts': [
        {
          'id': 'work',
          'signed_in': true,
          'credential_expires_at': '2026-11-11T05:00:00.000Z',
        },
        {'id': 'personal', 'signed_in': false},
      ],
    });
  });

  test('carries the state and nothing of the credential', () async {
    await store.create(label: 'Work');
    signIn('work', clock.add(const Duration(hours: 8)));

    final answer = jsonEncode(await call());

    expect(answer, isNot(contains('fake-access')));
    expect(answer, isNot(contains('fake-refresh')));
    expect(answer, isNot(contains(temp.path)));
  });

  test('reads the registry, whatever account a caller names', () async {
    await store.create(label: 'Work');
    // A credential beside the registered accounts, and a caller pointing at
    // it and outside the accounts root.
    Directory(store.configDirFor('stray')).createSync(recursive: true);
    signIn('stray', clock.add(const Duration(hours: 8)));

    final answer = await call({
      'id': 'stray',
      'ids': ['stray', '../../outside'],
    });

    expect(
      [
        for (final account in answer['accounts'] as List)
          (account as Map)['id'],
      ],
      ['work'],
    );
    expect(Directory(p.join(temp.path, 'outside')).existsSync(), isFalse);
  });

  test('starts no CLI, however often it is asked', () async {
    await store.create(label: 'Work');
    signIn('work', clock.add(const Duration(hours: 8)));

    await call();
    await call();
    await call();

    expect(
      spawned.where((command) => !command.startsWith('security ')),
      isEmpty,
    );
  });
}
