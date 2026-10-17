import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/native_staging.dart';

/// A paired demo visitor sees fictional runners and redacted provider accounts.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for demo server boot',
      () => fail('run scripts/natives/build_natives.sh'),
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test('a demo visitor sees runners and redacted provider accounts', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_demo_surface');
    addTearDown(() => deleteDirBestEffort(tmp));
    await stageServerNatives(tmp.path);
    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0', '--code-index', 'off'],
      demoBuilder: buildDemoWiring,
    );
    addTearDown(server.shutdown);

    // Redeem so the client is a real, member-scoped session.
    final recipient = await CredentialSeal.newRecipient();
    final http = HttpClient();
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo', 'handoff_key': recipient.publicKey}));
    final resp = await req.close();
    final wire = await resp.transform(utf8.decoder).join();
    http.close(force: true);
    expect(resp.statusCode, HttpStatus.ok, reason: wire);
    final body = jsonDecode(wire) as Map<String, dynamic>;
    final credential = await CredentialSeal.open(
      recipientPrivateKey: recipient.privateKey,
      envelope: (body['box'] as Map).cast<String, dynamic>(),
      context: 'cc-public-demo-v1',
    );

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: credential['device_id'] as String,
      psk: credential['psk'] as String,
    );
    addTearDown(client.close);
    await client.initialize();

    // The agent form and Detected runners read these. A denied probe used to
    // answer opUnknown, which the client renders as "no runners" — including
    // the built-in harness, which has no CLI to find.
    final harness = await client.call('adapter.detectOne', {
      'adapter': {
        'id': 'cc-harness',
        'name': 'Control Center',
        'cli_name': 'cc-harness',
      },
    });
    expect(harness['status'], 'found');
    final claudeRunner = await client.call('adapter.detectOne', {
      'adapter': {
        'id': 'claude-code',
        'name': 'Claude Code',
        'cli_name': 'claude',
      },
    });
    expect(claudeRunner['status'], 'found');
    expect(claudeRunner['path'], isNull);

    final accounts = await client.call('claude_accounts.list', const {});
    final accountList = accounts['accounts'] as List;
    expect(accountList.length, greaterThan(1));
    expect(accountList.every((a) => (a as Map)['logged_in'] == true), isTrue);

    final providers = await client.call('providers.list', const {});
    final byId = {
      for (final raw in providers['providers'] as List) (raw as Map)['id']: raw,
    };
    for (final id in ['anthropic', 'zai-coding', 'kimi-code']) {
      final provider = byId[id] as Map;
      expect(provider['has_credential'], isTrue, reason: id);
      expect((provider['credentials'] as List).length, greaterThan(1));
    }
    expect((byId['openai'] as Map)['enabled_via'], 'disabled');
    expect(jsonEncode(providers), isNot(contains('not-a-real')));
    expect(jsonEncode(accounts), isNot(contains('not-a-real')));

    final models = await client.call('providers.listModels', const {});
    final modelIds = {
      for (final raw in models['models'] as List) (raw as Map)['id'],
    };
    expect(
      modelIds,
      containsAll([
        'anthropic/claude-sonnet-4-5',
        'zai-coding/glm-5.3',
        'kimi-code/kimi-for-coding',
      ]),
    );
    expect(modelIds.where((id) => '$id'.startsWith('openai/')), isEmpty);
    final claudeModels = await client.call('acp.listModels', {
      'adapter_id': 'claude-code',
    });
    expect(claudeModels['models'] as List, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
