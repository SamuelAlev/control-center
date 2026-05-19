import 'dart:async';
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
  final completer = Completer<RigPortsSnapshot>();
  late StreamSubscription<RigPortsSnapshot> sub;
  sub = service.watch(workspaceId, rigId).listen((snapshot) {
    if (until(snapshot) && !completer.isCompleted) {
      completer.complete(snapshot);
      unawaited(sub.cancel());
    }
  });
  final result = await completer.future.timeout(const Duration(seconds: 10));
  return result;
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
}
