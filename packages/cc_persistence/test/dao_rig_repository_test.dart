import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager manager;
  late DaoRigRepository repository;

  setUp(() async {
    global = createTestGlobalDatabase();
    manager = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, manager, 'ws1');
    await seedTestWorkspace(global, manager, 'ws2');
    repository = DaoRigRepository(manager);
  });

  tearDown(() async {
    await manager.closeAll();
    await global.close();
  });

  Rig rig({
    String id = 'rig1',
    String workspaceId = 'ws1',
    RigStatus status = const RigReady(),
    String? conversationId,
    DateTime? lastActivityAt,
  }) => Rig(
    id: id,
    workspaceId: workspaceId,
    surface: RigSurface.computer,
    backend: EnclosureBackend.qemuHvf,
    status: status,
    spec: RigSpec(
      surface: RigSurface.computer,
      egressAllowlist: const ['github.com'],
      conversationId: conversationId,
    ),
    display: RigDisplaySize(1280, 800),
    createdBy: const UserPrincipal('u1'),
    conversationId: conversationId,
    createdAt: DateTime.utc(2026, 8, 18, 10),
    lastActivityAt: lastActivityAt ?? DateTime.utc(2026, 8, 18, 10),
  );

  group('round trip', () {
    test('a rig survives a save and read', () async {
      final saved = rig(conversationId: 'c1');
      await repository.save('ws1', saved);
      final loaded = await repository.getById('ws1', 'rig1');
      expect(loaded, isNotNull);
      expect(loaded!.surface, RigSurface.computer);
      expect(loaded.backend, EnclosureBackend.qemuHvf);
      expect(loaded.status, const RigReady());
      expect(loaded.display, RigDisplaySize(1280, 800));
      expect(loaded.conversationId, 'c1');
      expect(loaded.createdBy, const UserPrincipal('u1'));
      // The spec is stored whole; its allowlist has to come back intact or a
      // reopened rig would silently lose its egress policy.
      expect(loaded.spec.egressAllowlist, ['github.com']);
    });

    test('the take-over lock round-trips', () async {
      await repository.save(
        'ws1',
        rig().copyWith(
          controller: const UserPrincipal('u2'),
          controlHeldSince: DateTime.utc(2026, 8, 18, 11),
        ),
      );
      final loaded = await repository.getById('ws1', 'rig1');
      expect(loaded!.controller, const UserPrincipal('u2'));
      expect(loaded.isHumanControlled, isTrue);
      expect(loaded.controlHeldSince, isNotNull);
    });

    test('a close reason is preserved', () async {
      await repository.save(
        'ws1',
        rig(status: const RigClosed(RigCloseReason.ttlExpired)),
      );
      final loaded = await repository.getById('ws1', 'rig1');
      expect(loaded!.status, const RigClosed(RigCloseReason.ttlExpired));
      expect(loaded.status.closeReason, RigCloseReason.ttlExpired);
    });
  });

  group('workspace isolation', () {
    test('a rig is invisible from another workspace', () async {
      await repository.save('ws1', rig());
      expect(await repository.getById('ws2', 'rig1'), isNull);
      expect(await repository.list('ws2'), isEmpty);
    });

    test('saving with a mismatched workspace is refused', () async {
      // The entity carries its own workspace, so a disagreement means a caller
      // threaded the wrong id — and writing either one puts the row in a file
      // it does not belong to.
      expect(
        () => repository.save('ws2', rig(workspaceId: 'ws1')),
        throwsArgumentError,
      );
    });

    test('listAllLive spans workspaces on purpose', () async {
      await repository.save('ws1', rig(id: 'a'));
      await repository.save('ws2', rig(id: 'b', workspaceId: 'ws2'));
      await repository.save(
        'ws1',
        rig(id: 'c', status: const RigClosed(RigCloseReason.requested)),
      );
      final live = await repository.listAllLive();
      // The reaper must find every running hypervisor on the host; a closed
      // one is not holding anything.
      expect(live.map((r) => r.id).toSet(), {'a', 'b'});
    });
  });

  group('live filtering', () {
    test('closed and failed rigs are not live', () async {
      await repository.save('ws1', rig(id: 'ready'));
      await repository.save(
        'ws1',
        rig(id: 'closed', status: const RigClosed(RigCloseReason.requested)),
      );
      await repository.save(
        'ws1',
        rig(id: 'failed', status: const RigFailed('boom')),
      );
      await repository.save('ws1', rig(id: 'parked', status: const RigParked()));
      final live = await repository.listLive('ws1');
      expect(live.map((r) => r.id).toSet(), {'ready', 'parked'});
    });
  });

  group('action log', () {
    RigActionLogEntry entry(String id, {String rigId = 'rig1'}) =>
        RigActionLogEntry(
          id: id,
          workspaceId: 'ws1',
          rigId: rigId,
          seq: 0,
          verb: 'left_click',
          args: const {
            'action': 'left_click',
            'coordinate': [10, 20],
          },
          summary: 'Clicked (10, 20)',
          actor: const UserPrincipal('u1'),
          isTakeOver: true,
          createdAt: DateTime.utc(2026, 8, 18, 12),
        );

    test('sequences are allocated monotonically per rig', () async {
      await repository.save('ws1', rig());
      final first = await repository.appendAction('ws1', entry('a1'));
      final second = await repository.appendAction('ws1', entry('a2'));
      expect(first.seq, 1);
      expect(second.seq, 2);
    });

    test('each rig has its own sequence', () async {
      await repository.save('ws1', rig(id: 'r1'));
      await repository.save('ws1', rig(id: 'r2'));
      final a = await repository.appendAction('ws1', entry('a1', rigId: 'r1'));
      final b = await repository.appendAction('ws1', entry('b1', rigId: 'r2'));
      expect(a.seq, 1);
      expect(b.seq, 1);
    });

    test('concurrent appends do not collide', () async {
      // `seq` is the authority on ordering — two actions can share a
      // millisecond, and "who clicked first" is the question the log exists to
      // answer. The unique key turns a race into a loud failure; the
      // transaction is what stops it happening.
      await repository.save('ws1', rig());
      final results = await Future.wait([
        for (var i = 0; i < 12; i++) repository.appendAction('ws1', entry('a$i')),
      ]);
      final seqs = results.map((r) => r.seq).toList()..sort();
      expect(seqs, List.generate(12, (i) => i + 1));
    });

    test('an entry round-trips with its attribution', () async {
      await repository.save('ws1', rig());
      await repository.appendAction('ws1', entry('a1'));
      final actions = await repository.actions('ws1', 'rig1');
      expect(actions.single.actor, const UserPrincipal('u1'));
      expect(
        actions.single.isTakeOver,
        isTrue,
        reason:
            'Without this the log cannot answer whether a person or the agent '
            'sent an action.',
      );
      expect(actions.single.args['coordinate'], [10, 20]);
      expect(actions.single.summary, 'Clicked (10, 20)');
    });

    test('an action log is invisible from another workspace', () async {
      await repository.save('ws1', rig());
      await repository.appendAction('ws1', entry('a1'));
      expect(await repository.actions('ws2', 'rig1'), isEmpty);
    });

    test('an entry whose workspace disagrees with the call is REFUSED',
        () async {
      // The same guard `save` enforces. Without it the entry landed in the
      // ADDRESSED workspace's file whatever it said it belonged to — and this
      // is the audit table, where a row filed under the wrong workspace is
      // worse than a missing one.
      await repository.save('ws1', rig());
      await expectLater(
        repository.appendAction(
          'ws2',
          RigActionLogEntry(
            id: 'a1',
            workspaceId: 'ws1',
            rigId: 'rig1',
            seq: 0,
            verb: 'screenshot',
            actor: const UserPrincipal('u1'),
            createdAt: DateTime.utc(2026, 8, 18, 10),
          ),
        ),
        throwsArgumentError,
      );
      expect(await repository.actions('ws1', 'rig1'), isEmpty);
      expect(await repository.actions('ws2', 'rig1'), isEmpty);
    });
  });

  group('retention', () {
    test('purging removes closed rigs and their actions', () async {
      await repository.save(
        'ws1',
        rig(id: 'old', status: const RigClosed(RigCloseReason.requested)),
      );
      await repository.appendAction(
        'ws1',
        RigActionLogEntry(
          id: 'a1',
          workspaceId: 'ws1',
          rigId: 'old',
          seq: 0,
          verb: 'screenshot',
          actor: const UserPrincipal('u1'),
          createdAt: DateTime.utc(2026, 8, 18, 10),
        ),
      );
      await repository.save('ws1', rig(id: 'live'));

      final removed = await repository.purgeClosedBefore(
        'ws1',
        DateTime.utc(2026, 8, 19),
      );
      expect(removed, 1);
      expect(await repository.getById('ws1', 'old'), isNull);
      expect(await repository.actions('ws1', 'old'), isEmpty);
      expect(
        await repository.getById('ws1', 'live'),
        isNotNull,
        reason: 'Retention must never take a machine somebody is using.',
      );
    });
  });
}
