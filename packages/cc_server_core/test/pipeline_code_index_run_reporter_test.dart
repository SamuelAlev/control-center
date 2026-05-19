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
    reporter = PipelineCodeIndexRunReporter(runs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  CodeIndexRun open({String? checkoutId}) => reporter.begin(
    workspaceId: wsId,
    repoId: 'repo-a',
    repoPath: '/tmp/repo-a',
    checkoutId: checkoutId,
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
    expect(run.triggerPayload?['repoId'], 'repo-a');
    expect(run.triggerPayload?['repoLocalPath'], '/tmp/repo-a');

    final steps = await runs.stepRunsForPipeline(run.id);
    expect(
      steps.map((s) => s.stepId),
      containsAll([
        IndexCodeTemplate.triggerStepId,
        IndexCodeTemplate.indexStepId,
      ]),
      reason: 'the run detail renders the template graph; a missing trigger row '
          'shows the entry node as never fired',
    );
    final index = steps.firstWhere(
      (s) => s.stepId == IndexCodeTemplate.indexStepId,
    );
    expect(index.status, PipelineStepStatus.running);
    expect(
      jsonDecode(index.outputJson!),
      containsPair('filesToIndex', 13),
    );
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
    final index = (await runs.stepRunsForPipeline(run.id)).firstWhere(
      (s) => s.stepId == IndexCodeTemplate.indexStepId,
    );
    expect(jsonDecode(index.outputJson!), containsPair('filesIndexed', 13));
  });

  test('finishing carries the summary the UI reads', () async {
    final report = open(checkoutId: 'wt-1');
    await report.report(progress);
    await report.finish(result);

    final run = (await workspaceRuns()).single;
    expect(run.status, PipelineRunStatus.completed);
    expect(run.finishedAt, isNotNull);
    expect(run.triggerPayload?['checkoutId'], 'wt-1');
    final summary = run.state['indexSummary'] as Map<String, dynamic>;
    expect(summary['filesIndexed'], 13);
    expect(summary['nativeAvailable'], true);

    final index = (await runs.stepRunsForPipeline(run.id)).firstWhere(
      (s) => s.stepId == IndexCodeTemplate.indexStepId,
    );
    expect(index.status, PipelineStepStatus.completed);
    expect(jsonDecode(index.outputJson!), contains('indexSummary'));
  });

  test('a failure publishes even when nothing was reported', () async {
    // An index that threw before parsing a file (a missing grammar, an
    // unreadable tree) is exactly the run worth surfacing.
    final report = open();
    await report.fail(StateError('tree-sitter natives missing'));

    final run = (await workspaceRuns()).single;
    expect(run.status, PipelineRunStatus.failed);
    expect(run.errorMessage, contains('tree-sitter natives missing'));
    final index = (await runs.stepRunsForPipeline(run.id)).firstWhere(
      (s) => s.stepId == IndexCodeTemplate.indexStepId,
    );
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
        reason: 'a surviving row would be adopted by PipelineEngine.resumeAll, '
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
      await runs.insertRun(
        _engineRun(workspaceId: wsId, id: 'engine-run'),
      );

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
