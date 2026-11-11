import 'package:cc_domain/cc_domain.dart'
    show AuthException, ValidationException;
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/environment_host_approval.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';
import 'helpers/environment_service_harness.dart';

/// A definition that runs anything on the server itself runs only while the
/// current server owner is who approved it, whatever wrote the row: an admin
/// before the rule, an import, a previous owner. The approval is the owner's
/// save, recorded by the server, and is checked where the definition runs.
void main() {
  late String root;
  late ServiceHarness h;

  setUp(() {
    root = tempDir(addTearDown).path;
    h = ServiceHarness(root);
    addTearDown(() => h.service.stopListening());
  });

  final unapproved = throwsA(
    isA<EnvironmentHostUnapprovedException>()
        .having((e) => e.code, 'code', environmentHostUnapprovedKind)
        .having((e) => e, 'an auth refusal', isA<AuthException>())
        .having(
          (e) => e.error.code,
          'environment error code',
          environmentHostUnapprovedKind,
        ),
  );

  Map<String, dynamic> host() => definitionJson([
    composeJson(),
    taskJson('lint', ['manual']),
  ]);

  Future<EnvironmentDefinitionRecord> saveAs(
    Map<String, dynamic> definition, {
    String? id = 'def-1',
    bool owner = true,
    Principal by = principal,
  }) => h.service.saveDefinition(
    workspaceId: 'ws-a',
    definitionId: id,
    definition: definition,
    by: by,
    byServerOwner: owner,
  );

  void forgetApproval([String id = 'def-1']) {
    final record = h.definitions.records[id]!;
    h.definitions.records[id] = EnvironmentDefinitionRecord(
      id: record.id,
      workspaceId: record.workspaceId,
      name: record.name,
      definitionJson: record.definitionJson,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  group('a host definition nobody approved', () {
    test('is refused by ensure, before anything runs', () async {
      h.store(host(), hostApprovedBy: null);
      await expectLater(h.ensure(), unapproved);
      expect(h.commands, isEmpty);
      expect(h.environments.rows, isEmpty);
    });

    test('is refused by a task in an environment already running', () async {
      h.store(host());
      await h.ensure();
      forgetApproval();
      h.runner.calls.clear();
      await expectLater(
        h.service.runTask('ws-a', 'space-1', 'lint', by: principal),
        unapproved,
      );
      expect(h.commands, isEmpty);
    });

    test('is refused by its checks and its worktree tasks', () async {
      h.store(
        definitionJson(
          [
            composeJson(),
            taskJson('deps', ['provision']),
          ],
          extra: {
            'checks': [
              {
                'id': 'tool',
                'command': ['tool', '--version'],
              },
            ],
          },
        ),
        hostApprovedBy: null,
      );
      await expectLater(h.service.check('ws-a', 'def-1'), unapproved);
      await expectLater(
        h.service.runProvision(
          WorktreeTaskContext(
            workspaceId: 'ws-a',
            repoId: 'repo-app',
            worktreePath: '$root/worktrees/space-1',
            sourcePath: h.sourcePath,
            spaceId: 'space-1',
          ),
        ),
        throwsA(
          isA<WorktreeTaskException>().having(
            (e) => e.message,
            'message',
            contains('the server owner has not approved it'),
          ),
        ),
      );
      expect(h.commands, isEmpty);
    });

    test('runs once the owner saves it', () async {
      h.store(host(), hostApprovedBy: null);
      final saved = await saveAs(host());
      expect(saved.hostApprovedBy, serverOwnerId);
      expect((await h.ensure()).status, EnvironmentStatus.ready);
    });
  });

  test('an owner edit to a command keeps the owner\'s approval', () async {
    await saveAs(host());
    final edited = await saveAs(
      definitionJson([
        composeJson(),
        taskJson(
          'lint',
          ['manual'],
          extra: {
            'command': ['tool', 'lint', '--strict'],
          },
        ),
      ]),
    );
    expect(edited.hostApprovedBy, serverOwnerId);
    expect((await h.ensure()).status, EnvironmentStatus.ready);
  });

  test(
    'an approval by someone who is no longer the owner is refused',
    () async {
      h.store(host(), hostApprovedBy: 'previous-owner');
      await expectLater(h.ensure(), unapproved);
      h.serverOwner = 'previous-owner';
      expect((await h.ensure()).status, EnvironmentStatus.ready);
    },
  );

  test('with no owner recorded nothing on the host runs', () async {
    h.store(host());
    h.serverOwner = null;
    await expectLater(h.ensure(), unapproved);
  });

  group('a definition that runs nothing on the host', () {
    Map<String, dynamic> rig() => definitionJson(
      [composeJson()],
      extra: {
        'placement': 'rig',
        'checks': [
          {'id': 'file', 'file': '{home}/.tool'},
        ],
      },
    );

    test('needs no approval to run', () async {
      h.store(rig(), hostApprovedBy: null);
      await expectLater(h.service.check('ws-a', 'def-1'), completes);
    });

    test('carries none, even saved by the owner', () async {
      await saveAs(host());
      final moved = await saveAs(rig());
      expect(moved.hostApprovedBy, isNull);
    });
  });

  test('an approval in the saved definition is not an approval', () async {
    // A definition has no such field, so one that names it is not saved at
    // all: nothing a caller writes can stand in for the owner.
    for (final field in [
      'hostApprovedBy',
      'host_approved_by',
      'host_approved',
    ]) {
      await expectLater(
        saveAs({
          ...definitionJson([composeJson()], extra: {'placement': 'rig'}),
          field: serverOwnerId,
        }, owner: false),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('$field: Unknown field'),
          ),
        ),
      );
    }
    expect(h.definitions.records, isEmpty);
  });

  group('the agent gateway', () {
    test('gets no definition to run a pass-through tool from until the '
        'owner approves it', () async {
      h.store(host(), hostApprovedBy: null);
      await expectLater(h.service.definitionFor('ws-a', 'space-1'), unapproved);
      await saveAs(host());
      expect((await h.service.definitionFor('ws-a', 'space-1'))?.name, 'Shop');
    });

    test('reaches the compose project only of an approved environment on '
        'this host', () async {
      h.store(host());
      final env = await h.ensure();
      final project = await h.service.hostComposeProject('ws-a', 'space-1');
      expect(project?.name, startsWith('cc-'));
      // The state directory, which no agent writes; never a worktree.
      expect(project?.directory, '$root/data/ws-a/environments/${env.id}');
      for (final worktree in await h.service.worktreeRoots('ws-a', 'space-1')) {
        expect(p.isWithin(worktree, project!.directory), isFalse);
        expect(project.directory, isNot(worktree));
      }

      forgetApproval();
      await expectLater(
        h.service.hostComposeProject('ws-a', 'space-1'),
        unapproved,
      );

      await saveAs(host());
      h.environments.rows[env.id] = env.copyWith(placement: 'rig');
      expect(await h.service.hostComposeProject('ws-a', 'space-1'), isNull);
    });
  });

  test('a running environment whose definition lost its approval is held '
      'instead of following its PR head', () async {
    h
      ..addSpace('pr', prNumber: 7, prRepo: 'acme/shop', kind: 'pr')
      ..store(definitionJson([composeJson()]));
    await h.ensure(space: 'pr');
    await h.service.start(runRecovery: false);
    forgetApproval();
    h.runner.calls.clear();
    h.changedPaths = ['app.js'];
    h.events.publish(
      PrHeadChanged(
        repoOwner: 'acme',
        repoName: 'shop',
        prNumber: 7,
        prTitle: 'Fix',
        previousHeadSha: 'sha1',
        headSha: 'sha2',
        workspaceId: 'ws-a',
        occurredAt: h.now,
      ),
    );
    SpaceEnvironment row() =>
        h.environments.rows.values.firstWhere((item) => item.spaceId == 'pr');
    await h.until(() => row().lastError != null);
    expect(row().lastError?.code, environmentHostUnapprovedKind);
    expect(row().status, EnvironmentStatus.stopped);
    expect(h.syncs, 0);
  });
}
