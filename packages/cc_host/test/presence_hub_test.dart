import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

void main() {
  group('PresenceHub', () {
    test('a human update lands on the workspace roster; identity comes from '
        'the session, never client args', () {
      final hub = PresenceHub();
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: {
          'a': 'online',
          'l': {'t': 'sp', 'c': 'chan-1'},
          'ty': 'chan-1',
        },
      );
      final roster = hub.snapshot('ws1');
      expect(roster, hasLength(1));
      expect(roster.single['p'], 'user:u1');
      expect(roster.single['n'], 'Sam');
      expect((roster.single['l'] as Map)['c'], 'chan-1');
      expect(roster.single['ty'], 'chan-1');
      hub.dispose();
    });

    test('workspaces are isolated — one roster never leaks into another', () {
      final hub = PresenceHub();
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      expect(hub.snapshot('ws2'), isEmpty);
      hub.dispose();
    });

    test('humans and agents share ONE roster (co-equal principals)', () {
      final hub = PresenceHub();
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      hub.publishAgent(
        workspaceId: 'ws1',
        agentId: 'a1',
        displayName: 'Architect',
        status: const AgentLiveStatus(
          state: AgentLiveState.running,
          costUsd: 0.42,
        ),
      );
      final roster = hub.snapshot('ws1');
      expect(roster, hasLength(2));
      final agent = roster.firstWhere((e) => e['p'] == 'agent:a1');
      expect((agent['ag'] as Map)['s'], 'running');
      expect((agent['ag'] as Map)['c'], 0.42);
      hub.dispose();
    });

    test('entries expire after ~30s (three missed heartbeats) and never '
        'touch a database', () {
      var now = DateTime(2026, 7, 10, 12);
      final hub = PresenceHub(now: () => now);
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      now = now.add(const Duration(seconds: 29));
      expect(hub.sweep(), 0);
      expect(hub.snapshot('ws1'), hasLength(1));
      now = now.add(const Duration(seconds: 2));
      expect(hub.sweep(), 1);
      expect(hub.snapshot('ws1'), isEmpty);
      hub.dispose();
    });

    test('an offline/invisible update removes the entry immediately (DND)', () {
      final hub = PresenceHub();
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'offline'},
      );
      expect(hub.snapshot('ws1'), isEmpty);
      hub.dispose();
    });

    test('watch emits the current snapshot, then coalesced updates', () async {
      final hub = PresenceHub();
      final emissions = <List<Map<String, dynamic>>>[];
      final sub = hub
          .watch('ws1', minInterval: const Duration(milliseconds: 1))
          .listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(emissions, hasLength(1));
      expect(emissions.single, isEmpty);

      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.length, 2);
      expect(emissions.last, hasLength(1));
      await sub.cancel();
      hub.dispose();
    });

    test('the per-consumer throttle coalesces a burst into few emissions '
        '(phone-tier melt guard)', () async {
      final hub = PresenceHub();
      final emissions = <List<Map<String, dynamic>>>[];
      final sub = hub
          .watch('ws1', minInterval: const Duration(milliseconds: 200))
          .listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // A 10 Hz-ish burst of cursor-cadence updates…
      for (var i = 0; i < 20; i++) {
        hub.publishHuman(
          workspaceId: 'ws1',
          userId: 'u1',
          displayName: 'Sam',
          update: {
            'a': 'online',
            'l': {'t': 'file', 'r': 'repo', 'p': 'a.dart', 'l': i},
          },
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
      // …arrives as at most a couple of coalesced snapshots, not 20.
      expect(emissions.length, lessThanOrEqualTo(3));
      await sub.cancel();
      hub.dispose();
    });

    test('solo mode idles: a single silent participant produces no further '
        'emissions', () async {
      final hub = PresenceHub();
      hub.publishHuman(
        workspaceId: 'ws1',
        userId: 'u1',
        displayName: 'Sam',
        update: const {'a': 'online'},
      );
      final emissions = <List<Map<String, dynamic>>>[];
      final sub = hub
          .watch('ws1', minInterval: const Duration(milliseconds: 1))
          .listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(emissions, hasLength(1));
      await sub.cancel();
      hub.dispose();
    });
  });
}
