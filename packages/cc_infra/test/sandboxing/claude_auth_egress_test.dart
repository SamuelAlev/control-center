import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:test/test.dart';

Future<int> _connect(SandboxHttpProxy proxy, String host) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, proxy.port);
  try {
    socket.write('CONNECT $host:443 HTTP/1.1\r\nHost: $host:443\r\n\r\n');
    await socket.flush();
    final status = await socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .first
        .timeout(const Duration(seconds: 5));
    return int.parse(status.split(' ')[1]);
  } finally {
    socket.destroy();
  }
}

void main() {
  late HttpServer upstream;
  late SandboxHttpProxy proxy;
  late List<String> targets;
  late List<Socket> tunnels;

  Future<void> configure({required bool networkEnabled}) async {
    final policy = const SandboxPolicyResolver().resolve(
      spec: SandboxSpec(
        sessionId: 'claude-auth-egress',
        workspaceId: 'workspace',
        bindMounts: const [],
        networkEnabled: networkEnabled,
      ),
    );
    final config = await const SandboxConfigBuilder().build(policy);
    proxy.updateConfig(
      network: config.network,
      parentProxy: 'http://127.0.0.1:${upstream.port}',
    );
  }

  setUp(() async {
    targets = [];
    tunnels = [];
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((request) async {
      targets.add(request.uri.toString());
      final socket = await request.response.detachSocket(writeHeaders: false);
      tunnels.add(socket);
      socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      await socket.flush();
      socket.listen((_) {}, onError: (_) {}, onDone: socket.destroy);
    });
    proxy = await SandboxHttpProxy.start();
  });

  tearDown(() async {
    for (final socket in tunnels) {
      socket.destroy();
    }
    await proxy.close();
    await upstream.close(force: true);
  });

  test(
    'subscription refresh reaches its exact host through the sandbox',
    () async {
      await configure(networkEnabled: true);

      expect(await _connect(proxy, 'platform.claude.com'), HttpStatus.ok);
      expect(
        await _connect(proxy, 'unrelated.claude.com'),
        HttpStatus.forbidden,
      );
      expect(
        await _connect(proxy, 'platform.claude.com.attacker.example'),
        HttpStatus.forbidden,
      );
      expect(
        await _connect(proxy, 'statsig.anthropic.com'),
        HttpStatus.forbidden,
      );
      expect(targets, ['platform.claude.com:443']);
    },
  );

  test('network-off still blocks subscription refresh', () async {
    await configure(networkEnabled: false);

    expect(await _connect(proxy, 'platform.claude.com'), HttpStatus.forbidden);
    expect(targets, isEmpty);
  });
}
