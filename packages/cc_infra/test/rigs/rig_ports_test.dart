import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/rigs/rig_ports.dart';
import 'package:test/test.dart';

void main() {
  group('parsePortDiscoveryOutput', () {
    test('parses port, pid and process from the discovery lines', () {
      // 0BB8 = 3000, 1F90 = 8080.
      final ports = parsePortDiscoveryOutput(
        'P 0BB8 412 node\nP 1F90 99 python3\n',
      );
      expect(ports, hasLength(2));
      expect(ports[0].port, 3000);
      expect(ports[0].pid, 412);
      expect(ports[0].process, 'node');
      expect(ports[1].port, 8080);
      expect(ports[1].process, 'python3');
    });

    test('sorts ascending and tolerates an unresolved process', () {
      final ports = parsePortDiscoveryOutput('P 1F90 0 ?\nP 0050 7 nginx\n');
      expect(ports.map((p) => p.port), [80, 8080]);
      // pid 0 / '?' both read as "unknown", not as data.
      expect(ports[1].pid, isNull);
      expect(ports[1].process, isNull);
    });

    test('skips malformed lines rather than throwing', () {
      final ports = parsePortDiscoveryOutput(
        'garbage\nP nothex 1 x\nP 0BB8 1 node\n\n',
      );
      expect(ports, hasLength(1));
      expect(ports.single.port, 3000);
    });

    test('caps the number of ports so a scan cannot balloon state', () {
      final many = [
        for (var i = 1; i <= 200; i++) 'P ${i.toRadixString(16)} 1 x',
      ].join('\n');
      expect(parsePortDiscoveryOutput(many, cap: 16), hasLength(16));
    });

    test('rejects out-of-range ports', () {
      // 1_0000 hex is 65536, above the 16-bit ceiling.
      expect(parsePortDiscoveryOutput('P 10000 1 x'), isEmpty);
      expect(parsePortDiscoveryOutput('P 0000 1 x'), isEmpty);
    });
  });

  group('kRigPortDomainPattern', () {
    test('accepts .test and .localhost dev domains', () {
      expect(kRigPortDomainPattern.hasMatch('myapp.test'), isTrue);
      expect(kRigPortDomainPattern.hasMatch('api.localhost'), isTrue);
      expect(kRigPortDomainPattern.hasMatch('a.test'), isTrue);
    });

    test('refuses real TLDs and malformed names', () {
      // A real TLD would shadow a live name inside the browser VM.
      expect(kRigPortDomainPattern.hasMatch('myapp.com'), isFalse);
      expect(kRigPortDomainPattern.hasMatch('example.dev'), isFalse);
      expect(kRigPortDomainPattern.hasMatch('.test'), isFalse);
      expect(kRigPortDomainPattern.hasMatch('my app.test'), isFalse);
      expect(kRigPortDomainPattern.hasMatch('MYAPP.test'), isFalse);
    });
  });

  group('buildPortMuxBootstrapCommand', () {
    test('installs the dialer and is guarded against a double-start', () {
      final cmd = buildPortMuxBootstrapCommand();
      expect(cmd, contains(kRigPortMuxDialerPath));
      expect(cmd, contains('base64 -d'));
      // 1EE7 = 7911 (the mux port), so a warm start with the mux already up
      // exits before spawning a second socat.
      expect(cmd, contains('1EE7'));
      expect(cmd, contains('socat TCP-LISTEN:$kRigPortMuxGuestPort'));
    });
  });

  group('hostHeaderOf', () {
    test('extracts the host and strips the port', () {
      final head =
          'GET / HTTP/1.1\r\nHost: myapp.test:8080\r\nAccept: */*\r\n\r\n'
              .codeUnits;
      expect(hostHeaderOf(head), 'myapp.test');
    });

    test('lower-cases and returns null without a Host header', () {
      expect(
        hostHeaderOf('GET / HTTP/1.1\r\nHost: MyApp.Test\r\n\r\n'.codeUnits),
        'myapp.test',
      );
      expect(
        hostHeaderOf('GET / HTTP/1.1\r\nAccept: text/html\r\n\r\n'.codeUnits),
        isNull,
      );
    });
  });

  group('HostPortBridge', () {
    test('bridges a client connection through the mux to a target', () async {
      // A fake "mux": reads the guest-port preamble line, then echoes it back
      // followed by whatever the client sends — enough to prove the bridge
      // dials the mux, writes the preamble, and splices both directions.
      final mux = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final muxDone = Completer<String>();
      mux.listen((socket) {
        final buffer = <int>[];
        socket.listen((chunk) {
          buffer.addAll(chunk);
          final text = String.fromCharCodes(buffer);
          if (text.contains('\n') && !muxDone.isCompleted) {
            final preamble = text.split('\n').first;
            muxDone.complete(preamble);
            socket.add('echo:$preamble'.codeUnits);
          }
        });
      });

      final bridge = await HostPortBridge.start(
        guestPort: 3000,
        muxHostPort: mux.port,
      );
      addTearDown(() async {
        await bridge.close();
        await mux.close();
      });

      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        bridge.hostPort,
      );
      final reply = Completer<String>();
      client.listen((chunk) {
        if (!reply.isCompleted) {
          reply.complete(String.fromCharCodes(chunk));
        }
      });
      client.add('hi'.codeUnits);

      // The bridge wrote the guest port as the preamble to the mux...
      expect(await muxDone.future.timeout(const Duration(seconds: 5)), '3000');
      // ...and relayed the mux's reply back to the client.
      expect(
        await reply.future.timeout(const Duration(seconds: 5)),
        'echo:3000',
      );
      await client.close();
    });

    test('LAN listener opens and closes on demand', () async {
      final mux = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final bridge = await HostPortBridge.start(
        guestPort: 4000,
        muxHostPort: mux.port,
      );
      addTearDown(() async {
        await bridge.close();
        await mux.close();
      });

      expect(bridge.lanPort, isNull);
      await bridge.setLanExposed(true);
      expect(bridge.lanPort, isNotNull);
      final lanPort = bridge.lanPort;
      await bridge.setLanExposed(false);
      expect(bridge.lanPort, isNull);
      // Re-exposing gets a fresh listener (idempotent, no double-bind crash).
      await bridge.setLanExposed(true);
      expect(bridge.lanPort, isNotNull);
      expect(bridge.lanPort, isNot(lanPort));
    });
  });

  group('RigDomainRouter', () {
    test('routes by Host header to the mapped guest port', () async {
      // The "mux" the router dials: capture the preamble to prove which guest
      // port the router selected from the Host header.
      final mux = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final preamble = Completer<String>();
      mux.listen((socket) {
        final buffer = <int>[];
        socket.listen((chunk) {
          buffer.addAll(chunk);
          final text = String.fromCharCodes(buffer);
          if (text.contains('\n') && !preamble.isCompleted) {
            preamble.complete(text.split('\n').first);
            socket.add(
              'HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\nok'.codeUnits,
            );
          }
        });
      });

      final router = RigDomainRouter(muxPortOf: (_) => mux.port);
      final port = await router.start();
      router.setRoute('myapp.test', rigId: 'rig1', guestPort: 3000);
      addTearDown(() async {
        await router.dispose();
        await mux.close();
      });

      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
      );
      client.add(
        'GET /health HTTP/1.1\r\nHost: myapp.test\r\n\r\n'.codeUnits,
      );
      expect(
        await preamble.future.timeout(const Duration(seconds: 5)),
        '3000',
      );
      await client.close();
    });

    test('answers 502 for an unrouted host', () async {
      final router = RigDomainRouter(muxPortOf: (_) => null);
      final port = await router.start();
      addTearDown(router.dispose);

      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
      );
      final reply = Completer<String>();
      final buffer = <int>[];
      client.listen((chunk) {
        buffer.addAll(chunk);
        if (!reply.isCompleted) {
          reply.complete(String.fromCharCodes(buffer));
        }
      });
      client.add('GET / HTTP/1.1\r\nHost: nope.test\r\n\r\n'.codeUnits);
      expect(
        await reply.future.timeout(const Duration(seconds: 5)),
        contains('502'),
      );
      await client.close();
    });
  });
}
