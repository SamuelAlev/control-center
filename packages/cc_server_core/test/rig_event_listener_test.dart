import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/rig_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/repositories/rig_repository.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_server_core/src/notification_wire.dart';
import 'package:cc_server_core/src/rig_event_listener.dart';
import 'package:test/test.dart';

/// The four rig events used to have no subscribers at all: a human could take
/// the wheel of a machine an agent was mid-plan on, and the agent found out
/// only when its next click was refused. These pin the two consumers that
/// close that gap — the steering notice to the driving agent, and the
/// notification frames the clients render.
void main() {
  group('RigEventListener steering', () {
    late DomainEventBus bus;
    late _FakeRigRepository rigs;
    late _FakeRunLogRepository runLogs;
    late List<({String runId, String message})> steers;
    late RigEventListener listener;

    setUp(() {
      bus = DomainEventBus();
      rigs = _FakeRigRepository();
      runLogs = _FakeRunLogRepository();
      steers = [];
      listener = RigEventListener(
        eventBus: bus,
        rigs: rigs,
        runLogs: runLogs,
        steerRun: (runId, message) async {
          steers.add((runId: runId, message: message));
          return true;
        },
      )..start();
    });

    tearDown(() async {
      await listener.dispose();
      bus.dispose();
    });

    void seed({String? agentId = 'agent-1', bool withActiveRun = true}) {
      rigs.rig = _rig(agentId: agentId);
      if (withActiveRun && agentId != null) {
        runLogs.active[agentId] = AgentRunLog(
          id: 'run-1',
          agentId: agentId,
          workspaceId: 'ws-1',
          startedAt: DateTime(2026),
          status: RunStatus.running,
        );
      }
    }

    test('a human take-over steers the driving agent with the '
        'observation-still-works caveat', () async {
      seed();
      await listener.onControlChanged(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const UserPrincipal('user-9'),
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, hasLength(1));
      expect(steers.single.runId, 'run-1');
      expect(steers.single.message, contains('A human took control'));
      expect(steers.single.message, contains('rig-1'));
      expect(steers.single.message, contains('observation'));
    });

    test('releasing control steers the counterpart notice', () async {
      seed();
      await listener.onControlChanged(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: null,
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, hasLength(1));
      expect(steers.single.message, contains('released'));
    });

    test('an agent taking its own rig back is not told about itself', () async {
      seed();
      await listener.onControlChanged(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const AgentPrincipal('agent-1'),
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, isEmpty);
    });

    test('a rig nobody is driving steers nobody', () async {
      seed(agentId: null);
      await listener.onControlChanged(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const UserPrincipal('user-9'),
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, isEmpty);
    });

    test('an agent with no live run has nothing to interrupt', () async {
      seed(withActiveRun: false);
      await listener.onControlChanged(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const UserPrincipal('user-9'),
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, isEmpty);
    });

    test('a reap tells the agent its machine is gone and how to get '
        'another', () async {
      seed();
      await listener.onReaped(
        RigReaped(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          reason: RigCloseReason.ttlExpired,
          agentId: 'agent-1',
          occurredAt: DateTime(2026),
        ),
      );

      expect(steers, hasLength(1));
      expect(steers.single.message, contains('hard time limit'));
      expect(steers.single.message, contains('rig.open'));
    });

    test('a backend failure steers, and every other close reason does '
        'not (the reap already said it)', () async {
      seed();
      for (final reason in RigCloseReason.values) {
        await listener.onClosed(
          RigClosedEvent(
            workspaceId: 'ws-1',
            rigId: 'rig-1',
            reason: reason,
            occurredAt: DateTime(2026),
          ),
        );
      }

      expect(steers, hasLength(1));
      expect(steers.single.message, contains('hypervisor failed'));
    });

    test('subscriptions are live: publishing on the bus steers', () async {
      seed();
      bus.publish(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const UserPrincipal('user-9'),
          occurredAt: DateTime(2026),
        ),
      );
      // Two microtask hops: the bus delivery, then the repository lookup.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(steers, hasLength(1));
    });

    test('a failing rig lookup is swallowed, never thrown at the bus', () async {
      rigs.throwOnGet = true;
      bus.publish(
        RigReaped(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          reason: RigCloseReason.idleTimeout,
          agentId: 'agent-1',
          occurredAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(steers, isEmpty);
    });
  });

  group('rig notification frames', () {
    test('a take-over carries the controller so the client can suppress '
        'it for them', () {
      final frame = rigControlChangedFrame(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: const UserPrincipal('user-9'),
          occurredAt: DateTime(2026),
        ),
      );

      expect(frame.method, 'notifications/rig_control_changed');
      expect(frame.params['held'], isTrue);
      expect(frame.params['controller'], 'user:user-9');
      expect(frame.params['workspace_id'], 'ws-1');
    });

    test('a release carries no controller — the event does not record '
        'who let go', () {
      final frame = rigControlChangedFrame(
        RigControlChanged(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          controller: null,
          occurredAt: DateTime(2026),
        ),
      );

      expect(frame.params['held'], isFalse);
      expect(frame.params.containsKey('controller'), isFalse);
    });

    test('a reap frame carries the reason and the driving agent', () {
      final frame = rigReapedFrame(
        RigReaped(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          reason: RigCloseReason.idleTimeout,
          agentId: 'agent-1',
          occurredAt: DateTime(2026),
        ),
      );

      expect(frame.method, 'notifications/rig_reaped');
      expect(frame.params['reason'], 'idleTimeout');
      expect(frame.params['agent_id'], 'agent-1');
    });

    test('only a backend failure produces a close frame — the rest are '
        'expected or already covered by the reap', () {
      for (final reason in RigCloseReason.values) {
        final frame = rigClosedFrame(
          RigClosedEvent(
            workspaceId: 'ws-1',
            rigId: 'rig-1',
            reason: reason,
            occurredAt: DateTime(2026),
          ),
        );
        if (reason == RigCloseReason.backendFailure) {
          expect(frame, isNotNull, reason: '$reason should notify');
          expect(frame!.method, 'notifications/rig_closed');
        } else {
          expect(frame, isNull, reason: '$reason should not notify');
        }
      }
    });
  });
}

Rig _rig({String? agentId}) => Rig(
  id: 'rig-1',
  workspaceId: 'ws-1',
  surface: RigSurface.computer,
  backend: EnclosureBackend.qemuHvf,
  status: const RigReady(),
  spec: RigSpec(surface: RigSurface.computer, agentId: agentId),
  createdBy: const AgentPrincipal('agent-1'),
  createdAt: DateTime(2026),
  lastActivityAt: DateTime(2026),
  agentId: agentId,
);

class _FakeRigRepository implements RigRepository {
  Rig? rig;
  bool throwOnGet = false;

  @override
  Future<Rig?> getById(String workspaceId, String rigId) async {
    if (throwOnGet) {
      throw StateError('rig lookup exploded');
    }
    return rig;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}

class _FakeRunLogRepository implements AgentRunLogRepository {
  final Map<String, AgentRunLog> active = {};

  @override
  Future<AgentRunLog?> activeRunForAgent(String workspaceId, String agentId) async =>
      active[agentId];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not used by this test');
}
