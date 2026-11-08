import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show ClaudeSessionSettingsStore;
import 'package:cc_server_core/src/catalog/claude_session_settings_ops.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late ClaudeSessionSettingsStore store;
  late Map<String, RepoOp> ops;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_settings_ops_');
    store = ClaudeSessionSettingsStore(dataDir: temp.path);
    ops = {for (final op in buildClaudeSessionSettingsOps(store)) op.name: op};
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> args = const {},
  ]) => ops[name]!.handler(
    RepoOpContext(
      args: args,
      workspaceId: null,
      deviceId: 'device-1',
      userId: 'owner',
    ),
  );

  test('both ops belong to the server owner', () {
    expect(
      ops.values.map((op) => op.serverAuthority),
      everyElement(ServerAuthority.serverOwner),
    );
  });

  test('a saved value reads back and reaches the store', () async {
    final saved = await call('claude_accounts.setSessionSettings', {
      'autoCompactWindow': 300000,
      'compactIdleBeforeCacheExpires': true,
    });

    expect(saved, await call('claude_accounts.sessionSettings'));
    expect(
      store.read(),
      ClaudeSessionSettings(
        autoCompactWindow: 300000,
        compactIdleBeforeCacheExpires: true,
      ),
    );
  });

  test('an out-of-range window is refused and changes nothing', () async {
    await expectLater(
      call('claude_accounts.setSessionSettings', {'autoCompactWindow': 5}),
      throwsArgumentError,
    );

    expect(store.read(), ClaudeSessionSettings());
  });
}
