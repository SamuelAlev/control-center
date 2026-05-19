import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Drives the server half of the pair: answers `initialize` with the given
/// capabilities block and records the clientInfo it saw.
StreamSubscription<Map<String, dynamic>> serveInitialize(
  InProcessRpcChannel server, {
  required void Function(String name, String version) onClientInfo,
  Map<String, dynamic> capabilities = const {},
}) {
  return server.incoming.listen((frame) async {
    if (frame['method'] != 'initialize') {
      return;
    }
    final info = (frame['params'] as Map)['clientInfo'] as Map;
    onClientInfo(
      info['name'] as String? ?? '',
      info['version'] as String? ?? '',
    );
    await server.send({
      'jsonrpc': '2.0',
      'id': frame['id'],
      'result': {'capabilities': capabilities},
    });
  });
}

void main() {
  test(
    'initialize sends the stamped build version and captures ServerBuild',
    () async {
      final (server, clientChannel) = InProcessRpcChannel.pair();
      final client = RemoteRpcClient(
        clientChannel,
        timeout: const Duration(seconds: 5),
      )..start();
      addTearDown(client.close);
      addTearDown(server.close);

      String? seenName;
      String? seenVersion;
      final sub = serveInitialize(
        server,
        onClientInfo: (name, version) {
          seenName = name;
          seenVersion = version;
        },
        capabilities: {
          'serverVersion': '1.4.0',
          'gitSha': 'abc1234',
          'repoRpc': {'catalogVersion': 19},
        },
      );
      addTearDown(sub.cancel);

      final result = await client.initialize();
      // The default is the CI-stamped identity, not a hand-typed constant.
      expect(seenVersion, BuildInfo.buildVersion);
      expect(seenName, 'cc-client');
      expect(result['capabilities'], isA<Map>());

      final build = client.serverBuild;
      expect(build, isNotNull);
      expect(build!.version, '1.4.0');
      expect(build.gitSha, 'abc1234');
      expect(build.catalogVersion, 19);
    },
  );

  test('serverBuild is null when the server advertises nothing', () async {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    final client = RemoteRpcClient(
      clientChannel,
      timeout: const Duration(seconds: 5),
    )..start();
    addTearDown(client.close);
    addTearDown(server.close);
    final sub = serveInitialize(
      server,
      onClientInfo: (_, _) {},
      capabilities: const {},
    );
    addTearDown(sub.cancel);

    await client.initialize();
    final build = client.serverBuild;
    expect(build, isNotNull);
    expect(build!.version, isNull);
    expect(build.gitSha, isNull);
    expect(build.catalogVersion, isNull);
  });

  test('ServerBuild.fromInitializeResult tolerates junk', () {
    expect(
      ServerBuild.fromInitializeResult({'capabilities': 'not-a-map'}).version,
      isNull,
    );
    expect(ServerBuild.fromInitializeResult(const {}).catalogVersion, isNull);
  });
}
