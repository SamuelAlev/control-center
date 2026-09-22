import 'dart:io';

import 'package:cc_infra/src/rigs/rig_port_service.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart';
import 'package:test/test.dart';

/// A scriptable guest: `runInGuest` answers the discovery script from a
/// mutable port list, and every other command succeeds. `startInGuest` never
/// actually connects (no reverse tunnels are exercised here).
class _FakeGuest {
  final Map<String, List<int>> listening = {};

  Future<ProcessResult> run(String machineName, String command) async {
    // The discovery script is the one that starts by assigning `ports=`; the
    // mux bootstrap starts with `echo <base64>`.
    if (command.startsWith('ports=')) {
      final ports = listening[machineName] ?? const [];
      final out = [
        for (final p in ports) 'P ${p.toRadixString(16)} 100 node',
      ].join('\n');
      return ProcessResult(0, 0, out, '');
    }
    // The mux bootstrap and anything else: succeed.
    return ProcessResult(0, 0, '', '');
  }

  Future<Process> start(String machineName, List<String> argv) {
    // Not exercised: these tests do not drive reverse tunnels.
    throw UnimplementedError();
  }
}

Future<RigPortsSnapshot> _nextSnapshot(
  RigPortsService service,
  String workspaceId,
  String rigId,
  bool Function(RigPortsSnapshot) until,
) async {
  // Poll snapshotFor rather than the broadcast stream: a host-shell poll
  // can finish (and emit once) before the test subscribes, and later polls
  // are silent when nothing changed.
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = service.snapshotFor(workspaceId, rigId);
    if (snapshot != null && until(snapshot)) {
      return snapshot;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('snapshot for $rigId never matched');
}

Future<int> _freeLoopbackPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _untilAndroid(
  RigPortsService service,
  String rigId,
  int devicePort,
  int hostPort,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (DateTime.now().isBefore(deadline)) {
    if (service.debugAndroidReverses(rigId)[devicePort] == hostPort) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail(
    'android $rigId never planted :$devicePort → :$hostPort; '
    'have ${service.debugAndroidReverses(rigId)}',
  );
}

void main() {
  test('discovers a listening port and auto-forwards it', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    guest.listening['ccrig-abc'] = [3000];
    service.attachExec(
      rigId: 'abc',
      workspaceId: 'ws1',
      machineName: 'ccrig-abc',
      muxHostPort: 40001,
      conversationId: 'conv1',
    );

    final snapshot = await _nextSnapshot(
      service,
      'ws1',
      'abc',
      (s) => s.ports.any((p) => p.guestPort == 3000),
    );
    final port = snapshot.ports.firstWhere((p) => p.guestPort == 3000);
    expect(port.origin, RigPortOrigin.auto);
    expect(port.active, isTrue);
    expect(port.process, 'node');
    // The bridge picked a real host loopback port.
    expect(port.hostPort, greaterThan(0));
  });

  test('a foreign workspace reads as absent', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    service.attachExec(
      rigId: 'abc',
      workspaceId: 'ws1',
      machineName: 'ccrig-abc',
      muxHostPort: 40002,
    );
    expect(service.snapshotFor('ws2', 'abc'), isNull);
    expect(await service.addForward('ws2', 'abc', 3000), isFalse);
  });

  test('a manual forward survives its guest process disappearing', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    service.attachExec(
      rigId: 'abc',
      workspaceId: 'ws1',
      machineName: 'ccrig-abc',
      muxHostPort: 40003,
    );
    expect(await service.addForward('ws1', 'abc', 5173), isTrue);

    // Never appears in discovery, so it stays inactive but present.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final snapshot = service.snapshotFor('ws1', 'abc')!;
    final port = snapshot.ports.firstWhere((p) => p.guestPort == 5173);
    expect(port.origin, RigPortOrigin.manual);
    expect(port.active, isFalse);
  });

  test('removing an auto-forward suppresses it until the port disappears',
      () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    guest.listening['ccrig-abc'] = [3000];
    service.attachExec(
      rigId: 'abc',
      workspaceId: 'ws1',
      machineName: 'ccrig-abc',
      muxHostPort: 40004,
    );
    await _nextSnapshot(
      service,
      'ws1',
      'abc',
      (s) => s.ports.any((p) => p.guestPort == 3000),
    );

    await service.removeForward('ws1', 'abc', 3000);
    // Still listening, but dismissed: it must not respawn on the next poll.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(
      service.snapshotFor('ws1', 'abc')!.ports.any((p) => p.guestPort == 3000),
      isFalse,
    );
  });

  test('setDomain rejects a bad domain and a duplicate', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    service.attachExec(
      rigId: 'abc',
      workspaceId: 'ws1',
      machineName: 'ccrig-abc',
      muxHostPort: 40005,
    );
    await service.addForward('ws1', 'abc', 3000);
    await service.addForward('ws1', 'abc', 3001);

    await expectLater(
      service.setDomain('ws1', 'abc', 3000, 'notadomain'),
      throwsA(isA<ArgumentError>()),
    );
    expect(await service.setDomain('ws1', 'abc', 3000, 'myapp.test'), isTrue);
    // The same domain on a second port is refused, not silently stolen.
    await expectLater(
      service.setDomain('ws1', 'abc', 3001, 'myapp.test'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('two spaces on :5173 do not leak into each other', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(service.dispose);

    guest.listening['ccrig-a'] = [5173];
    guest.listening['ccrig-b'] = [5173];
    service.attachExec(
      rigId: 'rig-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-a',
      muxHostPort: 41001,
      conversationId: 'space-a',
    );
    service.attachExec(
      rigId: 'rig-b',
      workspaceId: 'ws1',
      machineName: 'ccrig-b',
      muxHostPort: 41002,
      conversationId: 'space-b',
    );

    final snapA = await _nextSnapshot(
      service,
      'ws1',
      'rig-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    final snapB = await _nextSnapshot(
      service,
      'ws1',
      'rig-b',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    expect(snapA.ports.single.guestPort, 5173);
    expect(snapB.ports.single.guestPort, 5173);
    // Space B's panel must not list space A's source. The guest number
    // stays 5173 even when the host bind remaps.
    expect(service.snapshotFor('ws1', 'rig-a', spaceId: 'space-b'), isNull);
    expect(service.snapshotFor('ws1', 'rig-b', spaceId: 'space-a'), isNull);

    service.attachBrowser(
      rigId: 'br-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-a',
      conversationId: 'space-a',
    );
    service.attachBrowser(
      rigId: 'br-b',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-b',
      conversationId: 'space-b',
    );
    expect(service.debugBrowserDials('br-a')[5173], 'mux:rig-a:5173');
    expect(service.debugBrowserDials('br-b')[5173], 'mux:rig-b:5173');
    expect(service.debugBrowserDials('br-a').containsKey(5173), isTrue);
    expect(
      service.debugBrowserDials('br-a')[5173],
      isNot(service.debugBrowserDials('br-b')[5173]),
    );
  });

  test('host-shell tree listeners stay in that session', () async {
    final guest = _FakeGuest();
    final aListens = [const RigOpenPort(port: 5173, process: 'node')];
    final bListens = [const RigOpenPort(port: 5173, process: 'node')];
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (rootPid) async {
        if (rootPid == 10) {
          return aListens;
        }
        if (rootPid == 20) {
          return bListens;
        }
        return const [];
      },
    );
    addTearDown(service.dispose);

    service.attachHostShell(
      sessionId: 'tty-a',
      workspaceId: 'ws1',
      rootPid: 10,
      conversationId: 'space-a',
    );
    service.attachHostShell(
      sessionId: 'tty-b',
      workspaceId: 'ws1',
      rootPid: 20,
      conversationId: 'space-b',
    );

    final snapA = await _nextSnapshot(
      service,
      'ws1',
      'tty-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    expect(snapA.ports.single.process, 'node');
    expect(service.snapshotFor('ws1', 'tty-a', spaceId: 'space-b'), isNull);
    expect(
      service.snapshotFor('ws1', 'tty-b', spaceId: 'space-a'),
      isNull,
    );

    service.attachBrowser(
      rigId: 'br-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-a',
      conversationId: 'space-a',
    );
    expect(service.debugBrowserDials('br-a')[5173], 'host:5173');
    // Space B's browser must not inherit space A's host-shell tunnel.
    service.attachBrowser(
      rigId: 'br-b',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-b',
      conversationId: 'space-b',
    );
    expect(service.debugBrowserDials('br-b')[5173], 'host:5173');
  });

  test('host-shell remap plants guest listen and desktop ports', () async {
    final guest = _FakeGuest();
    final preferred = await _freeLoopbackPort();
    final planted = <int, int>{};
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (_) async => [
        const RigOpenPort(port: 5173, process: 'node'),
      ],
    );
    addTearDown(service.dispose);

    service.attachHostShell(
      sessionId: 'tty-a',
      workspaceId: 'ws1',
      rootPid: 10,
      conversationId: 'space-a',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'tty-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    service.attachBrowser(
      rigId: 'br-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-a',
      conversationId: 'space-a',
    );
    expect(service.debugBrowserDials('br-a')[5173], 'host:5173');

    service.attachAndroid(
      rigId: 'and-a',
      workspaceId: 'ws1',
      conversationId: 'space-a',
      reverse: ({required int devicePort, required int hostPort}) async {
        planted[devicePort] = hostPort;
      },
      removeReverse: (devicePort) async {
        planted.remove(devicePort);
      },
    );
    await _untilAndroid(service, 'and-a', 5173, 5173);

    final ok = await service.addForward(
      'ws1',
      'tty-a',
      5173,
      spaceId: 'space-a',
      hostPort: preferred,
    );
    expect(ok, isTrue);
    final host = service
        .snapshotFor('ws1', 'tty-a', spaceId: 'space-a')!
        .ports
        .single
        .hostPort;
    expect(host, isNot(5173));
    expect(service.debugBrowserDials('br-a')[5173], 'host:$host');
    expect(service.debugBrowserDials('br-a')[host], 'host:$host');
    await _untilAndroid(service, 'and-a', 5173, host);
    await _untilAndroid(service, 'and-a', host, host);
    expect(planted[5173], host);
    expect(planted[host], host);
  });

  test('same-space exec mux wins over host-shell on the same port', () async {
    final guest = _FakeGuest();
    guest.listening['ccrig-a'] = [5173];
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (_) async => [
        const RigOpenPort(port: 5173, process: 'node'),
      ],
    );
    addTearDown(service.dispose);

    service.attachHostShell(
      sessionId: 'tty-a',
      workspaceId: 'ws1',
      rootPid: 10,
      conversationId: 'space-a',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'tty-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    service.attachBrowser(
      rigId: 'br-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-a',
      conversationId: 'space-a',
    );
    expect(service.debugBrowserDials('br-a')[5173], 'host:5173');

    service.attachExec(
      rigId: 'rig-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-a',
      muxHostPort: 41003,
      conversationId: 'space-a',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'rig-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    expect(service.debugBrowserDials('br-a')[5173], 'mux:rig-a:5173');
  });

  test('android reverses follow that rig conversation and drop on switch',
      () async {
    final guest = _FakeGuest();
    guest.listening['ccrig-a'] = [5173];
    final planted = <int, int>{};
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (rootPid) async {
        if (rootPid == 20) {
          return [const RigOpenPort(port: 5173, process: 'vite')];
        }
        return const [];
      },
    );
    addTearDown(service.dispose);

    service.attachExec(
      rigId: 'rig-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-a',
      muxHostPort: 41004,
      conversationId: 'space-a',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'rig-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    final hostPort = service.snapshotFor('ws1', 'rig-a')!.ports.single.hostPort;

    service.attachAndroid(
      rigId: 'and-a',
      workspaceId: 'ws1',
      conversationId: 'space-a',
      reverse: ({required int devicePort, required int hostPort}) async {
        planted[devicePort] = hostPort;
      },
      removeReverse: (devicePort) async {
        planted.remove(devicePort);
      },
    );
    await _untilAndroid(service, 'and-a', 5173, hostPort);
    expect(planted[5173], hostPort);

    await service.detach('and-a');
    expect(planted.containsKey(5173), isFalse);

    service.attachHostShell(
      sessionId: 'tty-b',
      workspaceId: 'ws1',
      rootPid: 20,
      conversationId: 'space-b',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'tty-b',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    service.attachAndroid(
      rigId: 'and-b',
      workspaceId: 'ws1',
      conversationId: 'space-b',
      reverse: ({required int devicePort, required int hostPort}) async {
        planted[devicePort] = hostPort;
      },
      removeReverse: (devicePort) async {
        planted.remove(devicePort);
      },
    );
    await _untilAndroid(service, 'and-b', 5173, 5173);
    expect(service.debugAndroidReverses('and-a'), isEmpty);
    expect(planted[5173], 5173);
  });

  test('android host-shell reverse is (port, mappedHostPort)', () async {
    final guest = _FakeGuest();
    final planted = <(int, int)>[];
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (_) async => [
        const RigOpenPort(port: 5173, process: 'vite'),
      ],
    );
    addTearDown(service.dispose);

    service.attachHostShell(
      sessionId: 'tty-a',
      workspaceId: 'ws1',
      rootPid: 10,
      conversationId: 'space-a',
    );
    await _nextSnapshot(
      service,
      'ws1',
      'tty-a',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    service.attachAndroid(
      rigId: 'and-a',
      workspaceId: 'ws1',
      conversationId: 'space-a',
      reverse: ({required int devicePort, required int hostPort}) async {
        planted.add((devicePort, hostPort));
      },
      removeReverse: (_) async {},
    );
    await _untilAndroid(service, 'and-a', 5173, 5173);
  });

  test('a host-shell with no space is never published into a browser', () async {
    final guest = _FakeGuest();
    final service = RigPortsService(
      runInGuest: guest.run,
      startInGuest: guest.start,
      pollInterval: const Duration(milliseconds: 40),
      listHostTreeListeners: (_) async => [
        const RigOpenPort(port: 5173, process: 'node'),
      ],
    );
    addTearDown(service.dispose);

    service.attachHostShell(
      sessionId: 'tty-orphan',
      workspaceId: 'ws1',
      rootPid: 10,
    );
    await _nextSnapshot(
      service,
      'ws1',
      'tty-orphan',
      (s) => s.ports.any((p) => p.guestPort == 5173),
    );
    service.attachBrowser(
      rigId: 'br-a',
      workspaceId: 'ws1',
      machineName: 'ccrig-br-a',
      conversationId: 'space-a',
    );
    expect(service.debugBrowserDials('br-a'), isEmpty);
  });
}
