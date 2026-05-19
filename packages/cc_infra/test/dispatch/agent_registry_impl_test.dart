import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/registry/registry_event.dart';
import 'package:cc_infra/src/dispatch/agent_registry_impl.dart';
import 'package:test/test.dart';

RegisterAgentInput _input({
  required String id,
  required String workspaceId,
  String displayName = 'Agent',
  AgentKind kind = AgentKind.main,
  AgentStatus status = AgentStatus.running,
  String? parentId,
  String? conversationId,
  String? dispatchId,
  String? sessionFile,
}) => RegisterAgentInput(
  id: id,
  workspaceId: workspaceId,
  displayName: displayName,
  kind: kind,
  status: status,
  parentId: parentId,
  conversationId: conversationId,
  dispatchId: dispatchId,
  sessionFile: sessionFile,
);

void main() {
  group('AgentRegistryImpl global lifecycle', () {
    tearDown(AgentRegistryImpl.resetGlobalForTests);

    test('global() is a process-wide singleton', () {
      final a = AgentRegistryImpl.global();
      final b = AgentRegistryImpl.global();
      expect(identical(a, b), isTrue);
    });

    test('resetGlobalForTests replaces the singleton', () {
      final first = AgentRegistryImpl.global();
      AgentRegistryImpl.resetGlobalForTests();
      final second = AgentRegistryImpl.global();
      expect(identical(first, second), isFalse);
    });
  });

  group('AgentRegistryImpl', () {
    late AgentRegistryImpl registry;

    setUp(() {
      registry = AgentRegistryImpl();
    });

    group('register', () {
      test('emits AgentRegistered for a new agent', () async {
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);

        final ref = registry.register(
          _input(id: 'a1', workspaceId: 'ws', displayName: 'Alpha'),
        );
        await Future<void>.delayed(Duration.zero);
        expect(ref.id, 'a1');
        expect(ref.displayName, 'Alpha');
        expect(ref.workspaceId, 'ws');
        expect(ref.status, AgentStatus.running);
        expect(events, [isA<AgentRegistered>()]);
      });

      test(
        're-registration preserves createdAt and emits status change',
        () async {
          registry.register(
            _input(id: 'a1', workspaceId: 'ws', displayName: 'Alpha'),
          );
          final first = registry.get('a1')!;
          final firstSeen = first.createdAt;

          registry.register(
            _input(
              id: 'a1',
              workspaceId: 'ws',
              displayName: 'Alpha Renamed',
              status: AgentStatus.idle,
            ),
          );

          final second = registry.get('a1')!;
          expect(second.createdAt, firstSeen);
          expect(second.displayName, 'Alpha Renamed');
          expect(second.status, AgentStatus.idle);
        },
      );

      test('forwards parentId/conversationId/sessionFile when supplied', () {
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            parentId: 'p',
            conversationId: 'c',
            sessionFile: '/tmp/sess.json',
            dispatchId: 'd1',
          ),
        );
        final ref = registry.get('a1')!;
        expect(ref.parentId, 'p');
        expect(ref.conversationId, 'c');
        expect(ref.sessionFile, '/tmp/sess.json');
        expect(ref.dispatchId, 'd1');
      });

      test('re-dispatch preserves parentId/conversationId when null', () {
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            parentId: 'p',
            conversationId: 'c',
          ),
        );
        // A re-dispatch that does NOT supply parentId/conversationId.
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        final ref = registry.get('a1')!;
        expect(ref.parentId, 'p');
        expect(ref.conversationId, 'c');
      });

      test('re-dispatch while running preserves prior activity', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        registry.setActivity('a1', 'thinking');
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            status: AgentStatus.running,
            displayName: 'Alpha',
          ),
        );
        expect(registry.get('a1')!.activity, 'thinking');
      });

      test('re-dispatch after non-running clears activity', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        registry.setActivity('a1', 'thinking');
        // Re-register as idle — should drop prior activity.
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.idle),
        );
        expect(registry.get('a1')!.activity, isNull);
      });

      test('normalizes displayName to one line', () {
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            displayName: 'Multi\n  line  label',
          ),
        );
        final ref = registry.get('a1')!;
        expect(ref.displayName.contains('\n'), isFalse);
        expect(ref.displayName, isNot(contains('  ')));
      });
    });

    group('setStatus', () {
      test('no-op when unknown', () {
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        registry.setStatus('nope', AgentStatus.idle);
        expect(events, isEmpty);
      });

      test('no-op when unchanged', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        registry.setStatus('a1', AgentStatus.running);
        expect(events, isEmpty);
      });

      test('clears activity and dispatchId on non-running', () async {
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            status: AgentStatus.running,
            dispatchId: 'd1',
          ),
        );
        registry.setActivity('a1', 'working');
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        registry.setStatus('a1', AgentStatus.idle);
        await Future<void>.delayed(Duration.zero);
        final ref = registry.get('a1')!;
        expect(ref.status, AgentStatus.idle);
        expect(ref.activity, isNull);
        expect(ref.dispatchId, isNull);
        expect(events, [isA<AgentStatusChanged>()]);
      });
    });

    group('setActivity', () {
      test('no-op when unknown', () {
        registry.setActivity('nope', 'work');
        expect(registry.get('nope'), isNull);
      });

      test('dropped when not running', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.idle),
        );
        registry.setActivity('a1', 'work');
        expect(registry.get('a1')!.activity, isNull);
      });

      test('updates activity + lastActivity when running (no event)', () async {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        final before = registry.get('a1')!.lastActivity;
        // Force a tick so lastActivity can advance.
        await Future<void>.delayed(Duration.zero);
        registry.setActivity('a1', 'analyzing');
        final ref = registry.get('a1')!;
        expect(ref.activity, 'analyzing');
        expect(
          ref.lastActivity.isAfter(before) ||
              !ref.lastActivity.isBefore(before),
          isTrue,
        );
        expect(events, isEmpty);
      });

      test('collapses whitespace', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.running),
        );
        registry.setActivity('a1', 'doing\n  many   things');
        expect(registry.get('a1')!.activity, 'doing many things');
      });
    });

    group('attachDispatch / detachDispatch', () {
      test('attachDispatch no-op when unknown', () {
        registry.attachDispatch('nope', 'd1');
        expect(registry.get('nope'), isNull);
      });

      test('attachDispatch sets dispatchId/sessionFile/lastActivity', () {
        registry.register(
          _input(id: 'a1', workspaceId: 'ws', status: AgentStatus.idle),
        );
        registry.attachDispatch('a1', 'd1', sessionFile: '/x/sess.json');
        final ref = registry.get('a1')!;
        expect(ref.dispatchId, 'd1');
        expect(ref.sessionFile, '/x/sess.json');
      });

      test('detachDispatch no-op when unknown', () {
        registry.detachDispatch('nope');
        expect(registry.get('nope'), isNull);
      });

      test('detachDispatch clears dispatchId only', () {
        registry.register(
          _input(
            id: 'a1',
            workspaceId: 'ws',
            status: AgentStatus.idle,
            dispatchId: 'd1',
            sessionFile: '/x/sess.json',
          ),
        );
        registry.detachDispatch('a1');
        final ref = registry.get('a1')!;
        expect(ref.dispatchId, isNull);
        // sessionFile is retained for revival.
        expect(ref.sessionFile, '/x/sess.json');
      });
    });

    group('unregister', () {
      test('removes and emits AgentRemoved', () async {
        registry.register(_input(id: 'a1', workspaceId: 'ws'));
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        registry.unregister('a1');
        await Future<void>.delayed(Duration.zero);
        expect(registry.get('a1'), isNull);
        expect(events, [isA<AgentRemoved>()]);
      });

      test('no-op when unknown', () {
        final events = <RegistryEvent>[];
        registry.changes.listen(events.add);
        registry.unregister('nope');
        expect(events, isEmpty);
      });
    });

    group('list / listForWorkspace / listVisibleTo', () {
      test('list spans every workspace', () {
        registry.register(_input(id: 'a1', workspaceId: 'ws1'));
        registry.register(_input(id: 'a2', workspaceId: 'ws2'));
        expect(registry.list().map((r) => r.id).toSet(), {'a1', 'a2'});
      });

      test('list returns an unmodifiable view', () {
        registry.register(_input(id: 'a1', workspaceId: 'ws'));
        final view = registry.list();
        final ghost = AgentRef(
          id: 'ghost',
          displayName: 'Ghost',
          workspaceId: 'ws',
          kind: AgentKind.main,
          status: AgentStatus.running,
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
        );
        expect(() => view.add(ghost), throwsUnsupportedError);
      });

      test('listForWorkspace filters by workspace', () {
        registry.register(_input(id: 'a1', workspaceId: 'ws1'));
        registry.register(_input(id: 'a2', workspaceId: 'ws1'));
        registry.register(_input(id: 'a3', workspaceId: 'ws2'));
        final ws1 = registry.listForWorkspace('ws1').map((r) => r.id).toSet();
        expect(ws1, {'a1', 'a2'});
      });

      test('listVisibleTo returns empty when caller unknown', () {
        registry.register(_input(id: 'a1', workspaceId: 'ws'));
        expect(registry.listVisibleTo('ghost'), isEmpty);
      });

      test('listVisibleTo excludes self, other workspaces, advisors, dead', () {
        registry.register(_input(id: 'me', workspaceId: 'ws'));
        registry.register(
          _input(
            id: 'peer',
            workspaceId: 'ws',
            kind: AgentKind.sub,
            status: AgentStatus.running,
          ),
        );
        registry.register(
          _input(id: 'advisor', workspaceId: 'ws', kind: AgentKind.advisor),
        );
        registry.register(
          _input(id: 'dead', workspaceId: 'ws', status: AgentStatus.parked),
        );
        registry.register(
          _input(
            id: 'otherws',
            workspaceId: 'ws2',
            status: AgentStatus.running,
          ),
        );

        final peers = registry.listVisibleTo('me').map((r) => r.id).toSet();
        expect(peers, {'peer'});
      });

      test('listVisibleTo includes idle peers (alive = running|idle)', () {
        registry.register(_input(id: 'me', workspaceId: 'ws'));
        registry.register(
          _input(id: 'idle-peer', workspaceId: 'ws', status: AgentStatus.idle),
        );
        final peers = registry.listVisibleTo('me').map((r) => r.id).toSet();
        expect(peers, {'idle-peer'});
      });
    });

    group('watchWorkspaceRoster', () {
      test('seeds current snapshot then forwards workspace changes', () async {
        registry.register(_input(id: 'seed', workspaceId: 'ws'));
        final snapshots = <List<AgentRef>>[];
        final sub = registry.watchWorkspaceRoster('ws').listen(snapshots.add);

        // pump to let the seed emit
        await Future<void>.delayed(Duration.zero);

        // change outside this workspace — should NOT trigger a snapshot
        registry.register(_input(id: 'other', workspaceId: 'ws2'));
        // change inside this workspace
        registry.register(_input(id: 'new', workspaceId: 'ws'));
        await Future<void>.delayed(Duration.zero);

        final lastIds = snapshots.last.map((r) => r.id).toSet();
        expect(lastIds, containsAll(['seed', 'new']));
        expect(lastIds, isNot(contains('other')));

        await sub.cancel();
      });

      test('stops emitting after cancel', () async {
        final snapshots = <List<AgentRef>>[];
        final sub = registry.watchWorkspaceRoster('ws').listen(snapshots.add);
        await Future<void>.delayed(Duration.zero);
        // seed + at least one snapshot
        expect(snapshots, isNotEmpty);

        await sub.cancel();
        snapshots.clear();

        // Trigger a change in the workspace — must NOT produce a snapshot.
        registry.register(_input(id: 'post-cancel', workspaceId: 'ws'));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(snapshots, isEmpty);
      });
    });
  });
}
