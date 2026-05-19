import 'dart:convert';

import 'package:cc_domain/features/code_graph/domain/ports/code_index_run_reporter.dart';
import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late PipelineRunRepositoryImpl runs;
  late PipelineCodeIndexRunReporter reporter;

  const wsId = 'ws-test';

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, wsId);
    runs = PipelineRunRepositoryImpl(dbs, global.workspaceRouteDao);
    // Floor of 1 for the tests below: they are about the projection mechanics
    // (what a row contains, when it closes, what the reaper does), not about
    // which runs earn one. The floor gets its own group at the bottom, against
    // the production default.
    reporter = PipelineCodeIndexRunReporter(runs, publishFileFloor: 1);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  CodeIndexRun open({
    String? checkoutId,
    CodeIndexCause cause = const CodeIndexCause.initial(),
    PipelineCodeIndexRunReporter? from,
  }) => (from ?? reporter).begin(
    workspaceId: wsId,
    repoId: 'repo-a',
    repoPath: '/tmp/repo-a',
    checkoutId: checkoutId,
    cause: cause,
  );

  const progress = CodeIndexProgress(
    filesIndexed: 3,
    filesToIndex: 13,
    totalFiles: 4565,
    symbols: 120,
    edges: 40,
  );

  const result = CodeIndexResult(
    filesIndexed: 13,
    filesSkipped: 4552,
    symbols: 900,
    edges: 300,
    removedFiles: 0,
    resolvedReferences: 7,
    nativeAvailable: true,
  );

  Future<List<PipelineRun>> workspaceRuns() =>
      runs.watchForWorkspace(wsId).first;

  test('a run that finds no work leaves no trace', () async {
    // The watcher fires on every save and most fires are no-ops (a matching
    // checkpoint, or every hash unchanged). A row each would bury the runs table.
    final report = open();
    await report.finish(result);

    expect(await workspaceRuns(), isEmpty);
  });

  test('the first progress report publishes a running run', () async {
    final report = open();
    await report.report(progress);

    final published = await workspaceRuns();
    expect(published, hasLength(1));
    final run = published.single;
    expect(run.templateId, IndexCodeTemplate.id);
    expect(run.status, PipelineRunStatus.running);
    expect(run.triggerEventType, IndexCodeTemplate.watchTriggerEventType);
    expect(run.triggerPayload?['repo_id'], 'repo-a');
    expect(run.triggerPayload?['repo_local_path'], '/tmp/repo-a');

    final steps = await runs.stepRunsForPipeline(run.id);
    expect(
      steps.map((s) => s.stepId),
      containsAll([
        IndexCodeTemplate.triggerStepId,
        IndexCodeTemplate.indexStepId,
      ]),
      reason:
          'the run detail renders the template graph; a missing trigger row '
          'shows the entry node as never fired',
    );
    final index = steps.firstWhere(
      (s) => s.stepId == IndexCodeTemplate.indexStepId,
    );
    expect(index.status, PipelineStepStatus.running);
    expect(jsonDecode(index.outputJson!), containsPair('filesToIndex', 13));
  });

  test('progress reports update one run, never add rows', () async {
    final report = open();
    await report.report(progress);
    await report.report(
      const CodeIndexProgress(
        filesIndexed: 13,
        filesToIndex: 13,
        totalFiles: 4565,
        symbols: 900,
        edges: 300,
      ),
    );

    expect(await workspaceRuns(), hasLength(1));
    final run = (await workspaceRuns()).single;
    final index = (await runs.stepRunsForPipeline(
      run.id,
    )).firstWhere((s) => s.stepId == IndexCodeTemplate.indexStepId);
    expect(jsonDecode(index.outputJson!), containsPair('filesIndexed', 13));
  });

  test('finishing carries the summary the UI reads', () async {
    final report = open(checkoutId: 'wt-1');
    await report.report(progress);
    await report.finish(result);

    final run = (await workspaceRuns()).single;
    expect(run.status, PipelineRunStatus.completed);
    expect(run.finishedAt, isNotNull);
    expect(run.triggerPayload?['checkout_id'], 'wt-1');
    final summary = run.state['index_summary'] as Map<String, dynamic>;
    expect(summary['filesIndexed'], 13);
    expect(summary['nativeAvailable'], true);

    final index = (await runs.stepRunsForPipeline(
      run.id,
    )).firstWhere((s) => s.stepId == IndexCodeTemplate.indexStepId);
    expect(index.status, PipelineStepStatus.completed);
    expect(jsonDecode(index.outputJson!), contains('index_summary'));
  });

  test('a failure publishes even when nothing was reported', () async {
    // An index that threw before parsing a file (a missing grammar, an
    // unreadable tree) is exactly the run worth surfacing.
    final report = open();
    await report.fail(StateError('tree-sitter natives missing'));

    final run = (await workspaceRuns()).single;
    expect(run.status, PipelineRunStatus.failed);
    expect(run.errorMessage, contains('tree-sitter natives missing'));
    final index = (await runs.stepRunsForPipeline(
      run.id,
    )).firstWhere((s) => s.stepId == IndexCodeTemplate.indexStepId);
    expect(index.status, PipelineStepStatus.failed);
  });

  test('cancelling the published run asks the indexer to stop', () async {
    final report = open();
    await report.report(progress);
    expect(report.cancelRequested, isFalse);

    final run = (await workspaceRuns()).single;
    await runs.updateRun(
      run.copyWith(
        status: PipelineRunStatus.cancelled,
        finishedAt: DateTime.now(),
      ),
    );
    // Sampled on the next progress tick — the watcher hands cancelRequested to
    // the indexer's isCancelled, so this stops the real work, not just the row.
    await report.report(progress);

    expect(report.cancelRequested, isTrue);
  });

  test('a cancelled run is not resurrected by a later finish', () async {
    final report = open();
    await report.report(progress);
    final run = (await workspaceRuns()).single;
    await runs.updateRun(
      run.copyWith(
        status: PipelineRunStatus.cancelled,
        finishedAt: DateTime.now(),
      ),
    );

    await report.finish(result);

    expect((await workspaceRuns()).single.status, PipelineRunStatus.cancelled);
  });

  group('trigger cause', () {
    test('the changed paths that fired the run land in the payload', () async {
      // Without this the runs table is a wall of identical rows: same template,
      // same repo, minutes apart, nothing saying which save caused which.
      final report = open(
        cause: const CodeIndexCause.changes([
          'lib/foo.dart',
          'lib/bar.dart',
        ], totalChanged: 2),
      );
      await report.report(progress);

      final payload = (await workspaceRuns()).single.triggerPayload!;
      expect(payload['cause'], 'changes');
      expect(payload['changed_paths'], ['lib/foo.dart', 'lib/bar.dart']);
      expect(payload['changed_count'], 2);
    });

    test('a capped path list keeps the true count', () async {
      // A branch switch touches thousands of files. The list is capped so the
      // payload stays small, but the count must not be — "2 changed files" for
      // a 2000-file checkout would be a lie the UI then repeats.
      final report = open(
        cause: const CodeIndexCause.changes([
          'lib/a.dart',
          'lib/b.dart',
        ], totalChanged: 2000),
      );
      await report.report(progress);

      final payload = (await workspaceRuns()).single.triggerPayload!;
      expect(payload['changed_paths'], hasLength(2));
      expect(payload['changed_count'], 2000);
    });

    test('an initial pass records no paths', () async {
      final report = open();
      await report.report(progress);

      final payload = (await workspaceRuns()).single.triggerPayload!;
      expect(payload['cause'], 'initial');
      expect(payload.containsKey('changed_paths'), isFalse);
    });
  });

  group('publication floor', () {
    late PipelineCodeIndexRunReporter floored;

    setUp(() {
      floored = PipelineCodeIndexRunReporter(runs);
    });

    test('a one-file save writes no row at all', () async {
      // The reason the floor exists: 30 minutes of ordinary editing produced 77
      // rows here, 37 of them a single file in under two seconds. A projection
      // meant to make long work visible was hiding it.
      final report = open(from: floored);
      await report.report(
        const CodeIndexProgress(
          filesIndexed: 0,
          filesToIndex: 1,
          totalFiles: 4565,
          symbols: 0,
          edges: 0,
        ),
      );
      await report.finish(result);

      expect(await workspaceRuns(), isEmpty);
    });

    test('a big enough run still publishes', () async {
      final report = open(from: floored);
      await report.report(
        const CodeIndexProgress(
          filesIndexed: 0,
          filesToIndex: PipelineCodeIndexRunReporter.defaultPublishFileFloor,
          totalFiles: 4565,
          symbols: 0,
          edges: 0,
        ),
      );

      expect(await workspaceRuns(), hasLength(1));
    });

    test('a small but slow run publishes on elapsed time', () async {
      // The file count is not the only way a run earns attention: a handful of
      // very large files, a cold embedder or a loaded machine can make a
      // one-file run the slow one, and a run pinning a core must be
      // attributable however few files it touched.
      final slow = PipelineCodeIndexRunReporter(
        runs,
        publishAfter: Duration.zero,
      );
      final report = open(from: slow);
      await report.report(
        const CodeIndexProgress(
          filesIndexed: 0,
          filesToIndex: 1,
          totalFiles: 4565,
          symbols: 0,
          edges: 0,
        ),
      );

      expect(await workspaceRuns(), hasLength(1));
    });

    test('a sub-floor run that FAILS still publishes', () async {
      // The floor filters noise, not faults. A one-file reindex that died on
      // missing grammars is the run an operator most needs to see.
      final report = open(from: floored);
      await report.report(
        const CodeIndexProgress(
          filesIndexed: 0,
          filesToIndex: 1,
          totalFiles: 4565,
          symbols: 0,
          edges: 0,
        ),
      );
      await report.fail(StateError('tree-sitter natives missing'));

      final run = (await workspaceRuns()).single;
      expect(run.status, PipelineRunStatus.failed);
      expect(run.errorMessage, contains('tree-sitter natives missing'));
    });
  });

  group('reapInterrupted', () {
    test('closes a watcher run left running by a crash', () async {
      final report = open();
      await report.report(progress);

      final closed = await reporter.reapInterrupted();

      expect(closed, 1);
      final run = (await workspaceRuns()).single;
      expect(run.status, PipelineRunStatus.cancelled);
      expect(run.finishedAt, isNotNull);
      expect(
        await runs.nonTerminalRuns(),
        isEmpty,
        reason:
            'a surviving row would be adopted by PipelineEngine.resumeAll, '
            'which would index the linked checkout during boot',
      );
      final steps = await runs.stepRunsForPipeline(run.id);
      expect(
        steps.map((s) => s.status),
        everyElement(isNot(PipelineStepStatus.running)),
      );
    });

    test('leaves engine-owned runs alone', () async {
      // Only rows this reporter wrote are unresumable. Everything else is the
      // engine's to resume and closing it would silently drop real work.
      await runs.insertRun(_engineRun(workspaceId: wsId, id: 'engine-run'));

      final closed = await reporter.reapInterrupted();

      expect(closed, 0);
      expect(
        (await runs.nonTerminalRuns()).map((r) => r.id),
        contains('engine-run'),
      );
    });
  });
}

/// A run as `PipelineEngine.start` would write it: same template, no watcher
/// trigger marker.
PipelineRun _engineRun({required String workspaceId, required String id}) =>
    PipelineRun(
      id: id,
      templateId: IndexCodeTemplate.id,
      workspaceId: workspaceId,
      status: PipelineRunStatus.running,
      triggerEventType: 'manual',
      startedAt: DateTime.now(),
      lastResumedAt: DateTime.now(),
    );
