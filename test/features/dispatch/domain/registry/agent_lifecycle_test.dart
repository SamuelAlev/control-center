import 'package:cc_domain/features/dispatch/domain/registry/agent_lifecycle.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSession implements AgentSessionController {
  _FakeSession(this.dispatchId);
  @override
  final String? dispatchId;
  bool disposed = false;
  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  late AgentRegistryImpl registry;
  late AgentLifecycleManager manager;

  setUp(() {
    registry = AgentRegistryImpl();
    manager = AgentLifecycleManager(registry);
  });

  tearDown(() async {
    await manager.dispose();
  });

  void register(String id, {AgentStatus status = AgentStatus.running, String? sessionFile}) {
    registry.register(RegisterAgentInput(
      id: id,
      displayName: id,
      workspaceId: 'ws-1',
      status: status,
      sessionFile: sessionFile,
    ));
  }

  test('parks an idle agent once its TTL elapses', () async {
    register('a1');
    registry.setStatus('a1', AgentStatus.idle);
    manager.adopt('a1', idleTtlMs: 20);

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(registry.get('a1')!.status, AgentStatus.parked);
  });

  test('idleTtlMs <= 0 adopts without ever parking', () async {
    register('a1');
    registry.setStatus('a1', AgentStatus.idle);
    manager.adopt('a1', idleTtlMs: 0);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(registry.get('a1')!.status, AgentStatus.idle);
  });

  test('a running agent is not parked; going idle (re)arms the timer', () async {
    register('a1');
    manager.adopt('a1', idleTtlMs: 20); // running → no timer armed
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(registry.get('a1')!.status, AgentStatus.running);

    registry.setStatus('a1', AgentStatus.idle); // arms the timer
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(registry.get('a1')!.status, AgentStatus.parked);
  });

  test('ensureLive revives a parked agent through its reviver', () async {
    register('a1');
    registry.setStatus('a1', AgentStatus.idle);
    var revives = 0;
    manager.adopt(
      'a1',
      idleTtlMs: 15,
      reviver: () async {
        revives++;
        return _FakeSession('d-revived');
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(registry.get('a1')!.status, AgentStatus.parked);

    final session = await manager.ensureLive('a1');
    expect(revives, 1);
    expect((session as _FakeSession).dispatchId, 'd-revived');
    expect(registry.get('a1')!.status, AgentStatus.idle);
    expect(registry.get('a1')!.dispatchId, 'd-revived');
  });

  test('concurrent ensureLive calls coalesce into a single revive', () async {
    register('a1');
    registry.setStatus('a1', AgentStatus.idle);
    var revives = 0;
    manager.adopt(
      'a1',
      idleTtlMs: 10,
      reviver: () async {
        revives++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _FakeSession('d');
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(registry.get('a1')!.status, AgentStatus.parked);

    await Future.wait([manager.ensureLive('a1'), manager.ensureLive('a1')]);
    expect(revives, 1);
  });

  test('ensureLive returns a held live session without reviving', () async {
    register('a1');
    final held = _FakeSession('d-held');
    manager.adopt('a1', idleTtlMs: 0, session: held);
    final session = await manager.ensureLive('a1');
    expect(identical(session, held), isTrue);
  });

  test('park disposes the live session', () async {
    register('a1');
    registry.setStatus('a1', AgentStatus.idle);
    final live = _FakeSession('d-live');
    manager.adopt('a1', idleTtlMs: 0, session: live);
    await manager.park('a1');
    expect(live.disposed, isTrue);
    expect(registry.get('a1')!.status, AgentStatus.parked);
    expect(registry.get('a1')!.dispatchId, isNull);
  });

  test('a failed cold revive drops the poisoned reviver so a retry rebuilds',
      () async {
    register('a1', status: AgentStatus.parked, sessionFile: '/s/a1.json');
    var attempts = 0;
    manager.setPersistedSubagentReviverFactory((ref) async {
      attempts++;
      final attempt = attempts;
      return () async {
        if (attempt == 1) {
          throw StateError('cold revive boom');
        }
        return _FakeSession('d-cold');
      };
    }, 0);

    await expectLater(manager.ensureLive('a1'), throwsA(isA<StateError>()));
    // The poisoned reviver was dropped; a second attempt rebuilds via factory.
    final session = await manager.ensureLive('a1');
    expect(attempts, 2);
    expect((session as _FakeSession).dispatchId, 'd-cold');
  });

  test('release disposes and unregisters', () async {
    register('a1');
    final live = _FakeSession('d');
    manager.adopt('a1', idleTtlMs: 0, session: live);
    await manager.release('a1');
    expect(live.disposed, isTrue);
    expect(registry.get('a1'), isNull);
    expect(manager.has('a1'), isFalse);
  });

  test('ensureLive throws for an unknown agent', () async {
    await expectLater(manager.ensureLive('ghost'), throwsA(isA<StateError>()));
  });
}
