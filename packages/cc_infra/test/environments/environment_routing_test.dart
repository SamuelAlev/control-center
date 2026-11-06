import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:test/test.dart';

/// A loopback server answering every request with its [name] and the Host it
/// received.
Future<HttpServer> _backend(String name) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) {
    request.response
      ..write('$name ${request.headers.value('host')}')
      ..close();
  });
  return server;
}

/// A raw HTTP/1.0-style GET so the test controls the Host header exactly.
Future<String> _get(int port, String host) async {
  final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
  socket.write('GET / HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n');
  await socket.flush();
  final body = await utf8.decoder.bind(socket).join();
  socket.destroy();
  return body;
}

void main() {
  late RigDomainRouter router;
  late HttpServer a;
  late HttpServer b;

  setUp(() async {
    router = RigDomainRouter(muxPortOf: (_) => null);
    a = await _backend('alpha');
    b = await _backend('beta');
  });

  tearDown(() async {
    await router.dispose();
    await a.close(force: true);
    await b.close(force: true);
  });

  RigEnvironmentRoute route(String workspace, HttpServer server) =>
      RigEnvironmentRoute(
        workspaceId: workspace,
        host: '127.0.0.1',
        port: server.port,
      );

  group('environment routes', () {
    test('the shared listener routes by Host and keeps it intact', () async {
      final port = await router.start();
      router.setEnvironmentRoutes('env-a', {
        'web--a--shop.localhost': route('w1', a),
      });
      final body = await _get(port, 'web--a--shop.localhost:$port');
      expect(body, contains('alpha web--a--shop.localhost'));
    });

    test('a workspace lane serves its own workspace', () async {
      await router.start();
      final lane = await router.startScoped('w1');
      router.setEnvironmentRoutes('env-a', {
        'web--a--shop.localhost': route('w1', a),
      });
      expect(await _get(lane, 'web--a--shop.localhost'), contains('alpha'));
    });

    test('a workspace lane can not reach another workspace by Host', () async {
      await router.start();
      final lane = await router.startScoped('w2');
      router.setEnvironmentRoutes('env-a', {
        'web--a--shop.localhost': route('w1', a),
      });
      final body = await _get(lane, 'web--a--shop.localhost');
      expect(body, contains('502'));
      expect(body, isNot(contains('alpha')));
    });

    test('a hostname can not be taken from another environment', () async {
      router.setEnvironmentRoutes('env-a', {'x.localhost': route('w1', a)});
      expect(
        () => router.setEnvironmentRoutes('env-b', {
          'x.localhost': route('w2', b),
        }),
        throwsArgumentError,
      );
      // The failed attempt changed nothing.
      expect(router.hasEnvironmentRoute('x.localhost'), isTrue);
    });

    test('replacing and clearing touch only the owner', () async {
      router
        ..setEnvironmentRoutes('env-a', {
          'old.localhost': route('w1', a),
          'keep.localhost': route('w1', a),
        })
        ..setEnvironmentRoutes('env-b', {'b.localhost': route('w1', b)})
        ..setEnvironmentRoutes('env-a', {'keep.localhost': route('w1', a)});
      expect(router.hasEnvironmentRoute('old.localhost'), isFalse);
      router.clearEnvironmentRoutes('env-a');
      expect(router.hasEnvironmentRoute('keep.localhost'), isFalse);
      expect(router.hasEnvironmentRoute('b.localhost'), isTrue);
    });

    test('an unknown host is refused', () async {
      final port = await router.start();
      expect(await _get(port, 'nope.localhost'), contains('502'));
    });

    test('a stopped upstream is a 502, not a hang', () async {
      final port = await router.start();
      final gone = await _backend('gone');
      final deadPort = gone.port;
      await gone.close(force: true);
      router.setEnvironmentRoutes('env-a', {
        'dead.localhost': RigEnvironmentRoute(
          workspaceId: 'w1',
          host: '127.0.0.1',
          port: deadPort,
        ),
      });
      expect(await _get(port, 'dead.localhost'), contains('502'));
    });

    test('the preferred port is used, and a taken one falls back', () async {
      final holder = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final taken = holder.port;
      final port = await router.start(preferredPort: taken);
      expect(port, isNot(taken));
      await holder.close();

      final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final wanted = free.port;
      await free.close();
      final other = RigDomainRouter(muxPortOf: (_) => null);
      addTearDown(other.dispose);
      expect(await other.start(preferredPort: wanted), wanted);
    });

    test('WebSocket upgrades pass through the splice', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        // Closed by the client's close, which the server echoes.
        // ignore: close_sinks
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((message) => socket.add('echo $message'));
      });
      final port = await router.start();
      router.setEnvironmentRoutes('env-a', {
        'ws.localhost': RigEnvironmentRoute(
          workspaceId: 'w1',
          host: '127.0.0.1',
          port: server.port,
        ),
      });
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:$port/'));
      request.headers
        ..set(HttpHeaders.hostHeader, 'ws.localhost')
        ..set(HttpHeaders.connectionHeader, 'Upgrade')
        ..set(HttpHeaders.upgradeHeader, 'websocket')
        ..set('Sec-WebSocket-Version', '13')
        ..set('Sec-WebSocket-Key', base64.encode(List.filled(16, 7)));
      final response = await request.close();
      expect(response.statusCode, HttpStatus.switchingProtocols);
      // Owned and closed by the WebSocket wrapping it.
      // ignore: close_sinks
      final socket = await response.detachSocket();
      final ws = WebSocket.fromUpgradedSocket(socket, serverSide: false);
      addTearDown(ws.close);
      ws.add('hi');
      expect(await ws.first.timeout(const Duration(seconds: 5)), 'echo hi');
      await ws.close();
    });
  });

  group('rig dev domains on workspace lanes', () {
    late RigDomainRouter domains;
    final owners = <String, String>{'rig-a': 'w1'};

    setUp(() {
      domains = RigDomainRouter(
        muxPortOf: (_) => null,
        hostPortOf: (id, guest) => a.port,
        workspaceOf: (id) => owners[id],
      );
    });

    tearDown(() => domains.dispose());

    test('a workspace lane serves its own rig', () async {
      final lane = await domains.startScoped('w1');
      domains.setRoute('myapp.test', rigId: 'rig-a', guestPort: 3000);
      expect(await _get(lane, 'myapp.test'), contains('alpha'));
    });

    test('a workspace lane can not reach another workspace by name', () async {
      final lane = await domains.startScoped('w2');
      domains.setRoute('myapp.test', rigId: 'rig-a', guestPort: 3000);
      final body = await _get(lane, 'myapp.test');
      expect(body, contains('502'));
      expect(body, isNot(contains('alpha')));
    });

    test('a rig nobody can place is refused', () async {
      final lane = await domains.startScoped('w1');
      domains.setRoute('myapp.test', rigId: 'rig-unknown', guestPort: 3000);
      final body = await _get(lane, 'myapp.test');
      expect(body, contains('502'));
      expect(body, isNot(contains('alpha')));
    });

    test('a router that can not name owners refuses on a lane', () async {
      final blind = RigDomainRouter(
        muxPortOf: (_) => null,
        hostPortOf: (id, guest) => a.port,
      );
      addTearDown(blind.dispose);
      final lane = await blind.startScoped('w1');
      blind.setRoute('myapp.test', rigId: 'rig-a', guestPort: 3000);
      expect(await _get(lane, 'myapp.test'), contains('502'));
    });

    test('the shared listener still routes by name', () async {
      final port = await domains.start();
      domains.setRoute('myapp.test', rigId: 'rig-a', guestPort: 3000);
      expect(await _get(port, 'myapp.test'), contains('alpha'));
    });
  });

  group('sandbox proxy pins', () {
    late SandboxHttpProxy proxy;

    setUp(() async {
      proxy = await SandboxHttpProxy.start(
        network: const NetworkConfig(allowAll: false),
      );
    });

    tearDown(() => proxy.close());

    Future<String> viaProxy(Uri url) async {
      final client = HttpClient()
        ..findProxy = (_) => 'PROXY 127.0.0.1:${proxy.port}';
      addTearDown(() => client.close(force: true));
      final request = await client.getUrl(url);
      final response = await request.close();
      return '${response.statusCode} ${await utf8.decodeStream(response)}';
    }

    test('admits a pinned host and keeps its Host header', () async {
      proxy.updateConfig(
        network: const NetworkConfig(allowAll: false),
        environmentHost: (host) async =>
            host == 'web--a--shop.localhost' ? '127.0.0.1:${a.port}' : null,
      );
      final body = await viaProxy(
        Uri.parse('http://web--a--shop.localhost:7355/'),
      );
      expect(body, startsWith('200'));
      expect(body, contains('alpha web--a--shop.localhost:7355'));
    });

    test('refuses a host this run was not given', () async {
      proxy.updateConfig(
        network: const NetworkConfig(allowAll: false),
        environmentHost: (host) async => null,
      );
      expect(
        await viaProxy(Uri.parse('http://web--b--shop.localhost:7355/')),
        startsWith('403'),
      );
    });

    test('a pin can not point off loopback', () async {
      proxy.updateConfig(
        network: const NetworkConfig(allowAll: false),
        environmentHost: (host) async => '10.0.0.1:80',
      );
      expect(
        await viaProxy(Uri.parse('http://x.localhost/')),
        startsWith('403'),
      );
    });

    test('a denied domain beats a pin', () async {
      proxy.updateConfig(
        network: const NetworkConfig(
          allowAll: false,
          deniedDomains: ['x.localhost'],
        ),
        environmentHost: (host) async => '127.0.0.1:${a.port}',
      );
      expect(
        await viaProxy(Uri.parse('http://x.localhost/')),
        startsWith('403'),
      );
    });

    test('CONNECT to a pinned host is refused', () async {
      proxy.updateConfig(
        network: const NetworkConfig(allowAll: false),
        environmentHost: (host) async =>
            host == 'x.acme.test' ? '127.0.0.1:${a.port}' : null,
      );
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        proxy.port,
      );
      addTearDown(socket.destroy);
      socket.write(
        'CONNECT x.acme.test:443 HTTP/1.1\r\nHost: x.acme.test\r\n\r\n',
      );
      await socket.flush();
      final answer = await utf8.decoder
          .bind(socket)
          .first
          .timeout(const Duration(seconds: 5));
      expect(answer, contains('403'));
    });
  });
}
