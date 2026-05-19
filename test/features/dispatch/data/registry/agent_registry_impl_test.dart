import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/registry/registry_event.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterAgentInput _input(
  String id, {
  String workspaceId = 'ws-1',
  String displayName = 'Agent',
  AgentKind kind = AgentKind.main,
  AgentStatus status = AgentStatus.running,
  String? parentId,
  String? conversationId,
  String? dispatchId,
}) =>
    RegisterAgentInput(
      id: id,
      displayName: displayName,
      workspaceId: workspaceId,
      kind: kind,
      status: status,
      parentId: parentId,
      conversationId: conversationId,
      dispatchId: dispatchId,
    );

void main() {
  late AgentRegistryImpl registry;

  setUp(() => registry = AgentRegistryImpl());

  group('register', () {
    test('tracks a new agent as running and emits AgentRegistered', () async {
      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);

      final ref = registry.register(_input('a1', dispatchId: 'd1'));
      await pumpEventQueue();

      expect(ref.id, 'a1');
      expect(ref.status, AgentStatus.running);
      expect(ref.dispatchId, 'd1');
      expect(ref.isAlive, isTrue);
      expect(registry.get('a1'), ref);
      expect(events.single, isA<AgentRegistered>());
      await sub.cancel();
    });

    test('normalizes the display name to one bounded line', () {
      final ref = registry.register(
        _input('a1', displayName: 'multi\nline   name'),
      );
      expect(ref.displayName, 'multi line name');
    });

    test(
        're-registering a known agent preserves createdAt and emits '
        'AgentStatusChanged, not AgentRegistered', () async {
      final first = registry.register(_input('a1', dispatchId: 'd1'));
      // Move it to idle, then re-dispatch.
      registry.setStatus('a1', AgentStatus.idle);

      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);
      final second = registry.register(_input('a1', dispatchId: 'd2'));
      await pumpEventQueue();

      expect(second.createdAt, first.createdAt);
      expect(second.status, AgentStatus.running);
      expect(second.dispatchId, 'd2');
      expect(events.single, isA<AgentStatusChanged>());
      await sub.cancel();
    });
  });

  group('setStatus', () {
    test('running -> idle clears activity and dispatch, emits change',
        () async {
      registry.register(_input('a1', dispatchId: 'd1'));
      registry.setActivity('a1', 'running tests');
      expect(registry.get('a1')!.activity, 'running tests');

      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);
      registry.setStatus('a1', AgentStatus.idle);
      await pumpEventQueue();

      final ref = registry.get('a1')!;
      expect(ref.status, AgentStatus.idle);
      expect(ref.activity, isNull);
      expect(ref.dispatchId, isNull);
      expect(ref.isAlive, isTrue);
      expect(events.single, isA<AgentStatusChanged>());
      await sub.cancel();
    });

    test('is a no-op (no event) when the status is unchanged', () async {
      registry.register(_input('a1'));
      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);
      registry.setStatus('a1', AgentStatus.running);
      await pumpEventQueue();
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('is a no-op for an unknown id', () {
      expect(() => registry.setStatus('nope', AgentStatus.idle), returnsNormally);
      expect(registry.get('nope'), isNull);
    });

    test('parked / aborted are not alive', () {
      registry.register(_input('a1'));
      registry.setStatus('a1', AgentStatus.parked);
      expect(registry.get('a1')!.isAlive, isFalse);
      registry.setStatus('a1', AgentStatus.aborted);
      expect(registry.get('a1')!.isAlive, isFalse);
    });
  });

  group('setActivity', () {
    test('records a normalized gist while running, without emitting an event',
        () async {
      registry.register(_input('a1'));
      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);

      registry.setActivity('a1', 'edit\tfile.dart');
      await pumpEventQueue();

      expect(registry.get('a1')!.activity, 'edit file.dart');
      expect(events, isEmpty, reason: 'activity is display-only');
      await sub.cancel();
    });

    test('is dropped for a non-running agent', () {
      registry.register(_input('a1', status: AgentStatus.idle));
      registry.setActivity('a1', 'should not stick');
      expect(registry.get('a1')!.activity, isNull);
    });

    test('refreshes lastActivity even when the gist is unchanged', () {
      registry.register(_input('a1'));
      registry.setActivity('a1', 'same');
      final first = registry.get('a1')!.lastActivity;
      registry.setActivity('a1', 'same');
      final second = registry.get('a1')!.lastActivity;
      expect(second.isBefore(first), isFalse);
      expect(registry.get('a1')!.activity, 'same');
    });
  });

  group('attach / detach dispatch', () {
    test('attachDispatch sets the dispatch id; detachDispatch clears it', () {
      registry.register(_input('a1'));
      registry.attachDispatch('a1', 'd9', sessionFile: '/s/a1.json');
      final attached = registry.get('a1')!;
      expect(attached.dispatchId, 'd9');
      expect(attached.sessionFile, '/s/a1.json');

      registry.detachDispatch('a1');
      expect(registry.get('a1')!.dispatchId, isNull);
    });
  });

  group('unregister', () {
    test('removes the agent and emits AgentRemoved', () async {
      registry.register(_input('a1'));
      final events = <RegistryEvent>[];
      final sub = registry.changes.listen(events.add);
      registry.unregister('a1');
      await pumpEventQueue();

      expect(registry.get('a1'), isNull);
      expect(events.single, isA<AgentRemoved>());
      await sub.cancel();
    });

    test('is a no-op for an unknown id', () {
      expect(() => registry.unregister('nope'), returnsNormally);
    });
  });

  group('global singleton', () {
    test('global() returns a stable instance; reset replaces it', () {
      final a = AgentRegistryImpl.global();
      final b = AgentRegistryImpl.global();
      expect(identical(a, b), isTrue);
      AgentRegistryImpl.resetGlobalForTests();
      expect(identical(AgentRegistryImpl.global(), a), isFalse);
      AgentRegistryImpl.resetGlobalForTests();
    });
  });

  group('workspace isolation', () {
    test('listForWorkspace returns only that workspace\'s agents', () {
      registry.register(_input('a1', workspaceId: 'ws-1'));
      registry.register(_input('a2', workspaceId: 'ws-1'));
      registry.register(_input('b1', workspaceId: 'ws-2'));

      expect(
        registry.listForWorkspace('ws-1').map((r) => r.id).toSet(),
        {'a1', 'a2'},
      );
      expect(
        registry.listForWorkspace('ws-2').map((r) => r.id).toSet(),
        {'b1'},
      );
      // The cross-workspace list spans both (by design).
      expect(registry.list().length, 3);
    });

    test('listVisibleTo only returns alive same-workspace peers', () {
      registry.register(_input('a1', workspaceId: 'ws-1'));
      registry.register(_input('a2', workspaceId: 'ws-1'));
      registry.register(_input('a3', workspaceId: 'ws-1'));
      registry.register(_input('b1', workspaceId: 'ws-2'));
      // An advisor in ws-1 is never a peer.
      registry.register(
        _input('adv', workspaceId: 'ws-1', kind: AgentKind.advisor),
      );
      // A parked agent in ws-1 is not alive.
      registry.setStatus('a3', AgentStatus.parked);

      final visible = registry.listVisibleTo('a1').map((r) => r.id).toSet();
      expect(visible, {'a2'});
      expect(visible, isNot(contains('a1')), reason: 'excludes the caller');
      expect(visible, isNot(contains('b1')), reason: 'other workspace');
      expect(visible, isNot(contains('adv')), reason: 'advisors are not peers');
      expect(visible, isNot(contains('a3')), reason: 'parked is not alive');
    });

    test('listVisibleTo returns empty for an unknown caller', () {
      registry.register(_input('a1', workspaceId: 'ws-1'));
      expect(registry.listVisibleTo('ghost'), isEmpty);
    });

    test('an advisor never sees peers and is never seen as a peer', () {
      registry.register(
        _input('adv', workspaceId: 'ws-1', kind: AgentKind.advisor),
      );
      registry.register(_input('a1', workspaceId: 'ws-1'));
      // a1 does not see the advisor.
      expect(registry.listVisibleTo('a1'), isEmpty);
      // The advisor sees a1 (it is alive + same workspace), but the advisor is
      // itself excluded from everyone else's roster — verified above.
      expect(registry.listVisibleTo('adv').map((r) => r.id), ['a1']);
    });
  });

  group('watchWorkspaceRoster', () {
    test('emits the current snapshot immediately, then on every change',
        () async {
      registry.register(_input('a1', workspaceId: 'ws-1'));

      final snapshots = <List<AgentRef>>[];
      final sub =
          registry.watchWorkspaceRoster('ws-1').listen(snapshots.add);
      await pumpEventQueue();

      expect(snapshots, hasLength(1));
      expect(snapshots.first.map((r) => r.id), ['a1']);

      registry.register(_input('a2', workspaceId: 'ws-1'));
      await pumpEventQueue();
      expect(snapshots, hasLength(2));
      expect(snapshots.last.map((r) => r.id).toSet(), {'a1', 'a2'});

      registry.setStatus('a1', AgentStatus.idle);
      await pumpEventQueue();
      expect(snapshots, hasLength(3));

      await sub.cancel();
    });

    test('does NOT re-emit when another workspace changes (isolation)',
        () async {
      registry.register(_input('a1', workspaceId: 'ws-1'));

      final snapshots = <List<AgentRef>>[];
      final sub =
          registry.watchWorkspaceRoster('ws-1').listen(snapshots.add);
      await pumpEventQueue();
      expect(snapshots, hasLength(1));

      // A change in ws-2 must not wake the ws-1 roster.
      registry.register(_input('b1', workspaceId: 'ws-2'));
      registry.setActivity('b1', 'busy');
      await pumpEventQueue();
      expect(snapshots, hasLength(1));

      await sub.cancel();
    });
  });
}
