import 'dart:io';

import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// Proves the server-side workspace bootstrap: [WorkspaceSeeder] seeds the CEO +
/// specialist agents AND the built-in pipeline templates/triggers for a new
/// workspace. This is what `runCcServer` runs on `WorkspaceCreated` so a thin
/// client's freshly created workspace comes up with pipelines (the old in-process
/// desktop seeder no longer runs on a thin client).
void main() {
  test(
    'WorkspaceSeeder seeds CEO + specialists + built-in pipeline templates',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_seeder');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));
      final seed = openSeedDatabases(tmp.path);
      addTearDown(seed.close);
      final global = seed.global;
      final dbs = seed.workspaces;

      const workspaceId = 'ws-seed';
      await global.workspaceRegistryDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Seeded'),
        ),
      );
      await dbs.create(workspaceId);

      final agentRepo = DaoAgentRepository(dbs);
      final templateRepo = PipelineTemplateRepositoryImpl(dbs);
      final triggerRepo = PipelineTriggerRepositoryImpl(
        dbs,
        global.workspaceRouteDao,
      );

      final seeder = WorkspaceSeeder(
        agentRepository: agentRepo,
        filesystem: WorkspaceFilesystemService(CcPaths(tmp.path)),
        templateRepository: templateRepo,
        triggerRepository: triggerRepo,
      );

      await seeder.seed(workspaceId);

      // CEO + the four specialists are created.
      final agents = await agentRepo.watchByWorkspace(workspaceId).first;
      expect(
        agents.map((a) => a.name).toSet(),
        containsAll(<String>[
          'ceo',
          'qa',
          'architect',
          'engineer',
          'librarian',
        ]),
      );

      // Built-in pipeline templates are seeded — the agentless index_code AND
      // the agent-bearing ones (specialists exist, so they aren't skipped).
      final templates = await templateRepo.forWorkspace(workspaceId);
      expect(
        templates.any((t) => t.templateId == 'index_code'),
        isTrue,
        reason: 'the agentless index_code template must always seed',
      );
      expect(
        templates.length,
        greaterThan(1),
        reason: 'agent-bearing templates seed once specialists exist',
      );

      // Idempotent: a second seed (e.g. an event re-fire) does not duplicate.
      await seeder.seed(workspaceId);
      final agentsAfter = await agentRepo.watchByWorkspace(workspaceId).first;
      expect(agentsAfter.length, agents.length);
      final templatesAfter = await templateRepo.forWorkspace(workspaceId);
      expect(templatesAfter.length, templates.length);
    },
  );
}
