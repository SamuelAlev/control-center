import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/job_run_detail.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_checks_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_run_canvas.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

CheckRun _check({
  required String name,
  required CheckRunStatus status,
  CheckRunConclusion? conclusion,
  int? jobId,
  int? workflowRunId,
  DateTime? startedAt,
  DateTime? completedAt,
}) {
  return CheckRun(
    name: name,
    status: status,
    conclusion: conclusion,
    workflowName: 'CI',
    jobId: jobId,
    workflowRunId: workflowRunId,
    startedAt: startedAt,
    completedAt: completedAt,
  );
}

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// Cards are default-open; this flushes the expansion seed and the
/// graph/detail providers.
Future<void> _expandWorkflow(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('in-progress job tile spins; queued job tile does not', (
    tester,
  ) async {
    final checks = [_check(name: 'build', status: CheckRunStatus.inProgress)];
    await tester.pumpWidget(
      _wrap(ChecksTab(checks: checks, isLoading: false, error: null)),
    );
    await _expandWorkflow(tester);

    // The workflow header spins for a running group; the in-progress job
    // tile spins too → two spinners.
    expect(find.byType(CcSpinner), findsNWidgets(2));

    await tester.pumpWidget(
      _wrap(
        ChecksTab(
          checks: [_check(name: 'build', status: CheckRunStatus.queued)],
          isLoading: false,
          error: null,
        ),
      ),
    );
    await _expandWorkflow(tester);

    // Queued stays a static loader glyph — only the header spinner remains.
    expect(find.byType(CcSpinner), findsOneWidget);
  });

  testWidgets(
    'expanded workflow renders one node per YAML job; tapping a node shows '
    'its steps and log slice',
    (tester) async {
      final checks = [
        _check(
          name: 'Build',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          jobId: 101,
          workflowRunId: 900,
          completedAt: DateTime(2024, 6, 15, 10),
        ),
        _check(
          name: 'Test',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          jobId: 102,
          workflowRunId: 900,
          completedAt: DateTime(2024, 6, 15, 10, 5),
        ),
      ];
      final graph = WorkflowGraph(
        name: 'CI',
        jobs: [
          WorkflowJobNode(id: 'build', name: 'Build'),
          WorkflowJobNode(id: 'test', name: 'Test', needs: const ['build']),
        ],
      );
      JobRunDetail detailFor(int jobId) {
        final stepName = jobId == 101 ? 'Compile' : 'Run tests';
        return JobRunDetail(
          jobId: jobId,
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          steps: [
            JobRunStep(
              number: 1,
              name: 'Set up job',
              status: CheckRunStatus.completed,
              conclusion: CheckRunConclusion.success,
              startedAt: DateTime(2024, 6, 15, 10),
              completedAt: DateTime(2024, 6, 15, 10, 0, 10),
            ),
            JobRunStep(
              number: 2,
              name: stepName,
              status: CheckRunStatus.completed,
              conclusion: CheckRunConclusion.success,
              startedAt: DateTime(2024, 6, 15, 10, 0, 10),
              completedAt: DateTime(2024, 6, 15, 10, 1),
            ),
          ],
          logs:
              '##[group]$stepName\n'
              'log body for $stepName\n'
              '##[endgroup]\n',
        );
      }

      await tester.pumpWidget(
        _wrap(
          ChecksTab(checks: checks, isLoading: false, error: null),
          overrides: [
            prWorkflowGraphProvider.overrideWith((ref, runId) async => graph),
            prJobRunDetailProvider.overrideWith(
              (ref, jobId) => Stream.value(detailFor(jobId)),
            ),
          ],
        ),
      );
      await _expandWorkflow(tester);

      // One node per YAML job on the graph canvas.
      expect(find.byType(WorkflowRunCanvas), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);

      // Auto-selection lands on the first node → its steps render below.
      await tester.pump();
      expect(find.text('Compile'), findsOneWidget);

      // Tapping the other node swaps the detail to that job's steps.
      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Run tests'), findsOneWidget);
      expect(find.text('Compile'), findsNothing);

      // Opening a step shows its ##[group] log slice, cleaned.
      await tester.tap(find.text('Run tests'));
      await tester.pump();
      expect(find.textContaining('log body for Run tests'), findsOneWidget);
    },
  );

  testWidgets('matrix jobs group onto their node instead of trailing the '
      'selected job as a flat list', (tester) async {
    // Fondue CI's shape: two sharded matrix jobs whose YAML `name:` is a
    // `${{ … }}` template, so no check-run name ever equals it.
    const runId = 900;
    const shardTemplate =
        r' (shard ${{ matrix.shard }}/${{ strategy.job-total }})';
    final graph = WorkflowGraph(
      name: 'Fondue CI',
      jobs: [
        WorkflowJobNode(id: 'lint-typecheck', name: 'Lint & Typecheck'),
        WorkflowJobNode(
          id: 'component-tests',
          name: 'Component Tests$shardTemplate',
        ),
        WorkflowJobNode(
          id: 'rte-component-tests',
          name: 'RTE Component Tests$shardTemplate',
        ),
      ],
    );
    var jobId = 100;
    CheckRun passed(String name) => _check(
      name: name,
      status: CheckRunStatus.completed,
      conclusion: CheckRunConclusion.success,
      jobId: jobId++,
      workflowRunId: runId,
      completedAt: DateTime(2024, 6, 15, 10),
    );
    final checks = [
      passed('Lint & Typecheck'),
      for (var i = 1; i <= 4; i++) passed('Component Tests (shard $i/4)'),
      for (var i = 1; i <= 4; i++) passed('RTE Component Tests (shard $i/4)'),
    ];

    await tester.pumpWidget(
      _wrap(
        ChecksTab(checks: checks, isLoading: false, error: null),
        overrides: [
          prWorkflowGraphProvider.overrideWith(
            (ref, id) async => id == runId ? graph : null,
          ),
          prJobRunDetailProvider.overrideWith(
            (ref, id) => Stream.value(
              JobRunDetail(
                jobId: id,
                status: CheckRunStatus.completed,
                conclusion: CheckRunConclusion.success,
              ),
            ),
          ),
        ],
      ),
    );
    await _expandWorkflow(tester);

    // Every shard landed on its node, so nothing spills into the flat tail
    // under the selected job.
    for (var i = 1; i <= 4; i++) {
      expect(find.text('Component Tests (shard $i/4)'), findsNothing);
      expect(find.text('RTE Component Tests (shard $i/4)'), findsNothing);
    }

    // The two matrix nodes are labelled by their job id, GitHub-style, and
    // carry their child count.
    expect(find.text('Matrix: component-tests'), findsOneWidget);
    expect(find.text('Matrix: rte-component-tests'), findsOneWidget);
    expect(find.text('4 jobs'), findsNWidgets(2));
    // The single-run job keeps its authored name.
    expect(find.text('Lint & Typecheck'), findsOneWidget);

    // Selecting a matrix node breaks it out into one chip per shard.
    await tester.tap(find.text('Matrix: component-tests'));
    await tester.pump();
    await tester.pump();
    for (var i = 1; i <= 4; i++) {
      expect(find.text('$i/4'), findsOneWidget);
    }
  });

  testWidgets('a finished node shows its duration; the header shows '
      'completion time', (tester) async {
    const runId = 900;
    final checks = [
      _check(
        name: 'Build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        jobId: 101,
        workflowRunId: runId,
        startedAt: DateTime(2024, 6, 15, 10),
        completedAt: DateTime(2024, 6, 15, 10, 4, 14),
      ),
    ];
    final graph = WorkflowGraph(
      name: 'CI',
      jobs: [WorkflowJobNode(id: 'build', name: 'Build')],
    );

    await tester.pumpWidget(
      _wrap(
        ChecksTab(checks: checks, isLoading: false, error: null),
        overrides: [
          prWorkflowGraphProvider.overrideWith((ref, id) async => graph),
        ],
      ),
    );
    await _expandWorkflow(tester);

    // The node carries the job's duration, not its completion instant.
    expect(find.text('4m 14s'), findsOneWidget);
    // The accordion header reports when the run completed.
    expect(find.textContaining('· Completed'), findsOneWidget);
  });

  testWidgets('a running workflow header shows the started time', (
    tester,
  ) async {
    final checks = [
      _check(
        name: 'Build',
        status: CheckRunStatus.inProgress,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
    await tester.pumpWidget(
      _wrap(ChecksTab(checks: checks, isLoading: false, error: null)),
    );
    await _expandWorkflow(tester);

    expect(find.textContaining('· Started'), findsOneWidget);
  });

  testWidgets('graph provider returning null falls back to the flat list', (
    tester,
  ) async {
    final checks = [
      _check(
        name: 'Build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        jobId: 101,
        workflowRunId: 900,
        completedAt: DateTime(2024, 6, 15, 10),
      ),
    ];
    await tester.pumpWidget(
      _wrap(
        ChecksTab(checks: checks, isLoading: false, error: null),
        overrides: [
          prWorkflowGraphProvider.overrideWith((ref, runId) async => null),
        ],
      ),
    );
    await _expandWorkflow(tester);

    expect(find.byType(WorkflowRunCanvas), findsNothing);
    // The classic flat tile renders instead: job name + expansion chevron.
    expect(find.text('Build'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
  });

  testWidgets('accordion list padding is 24px on both sides', (tester) async {
    final checks = [
      _check(
        name: 'Build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
    ];
    await tester.pumpWidget(
      _wrap(ChecksTab(checks: checks, isLoading: false, error: null)),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Padding &&
            w.padding == const EdgeInsets.fromLTRB(24, 16, 24, 32),
      ),
      findsOneWidget,
    );
  });

  testWidgets('workflow cards are expanded by default; a manual collapse '
      'sticks across refetch', (tester) async {
    final checks = [
      _check(
        name: 'Build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
      ),
    ];
    await tester.pumpWidget(
      _wrap(ChecksTab(checks: checks, isLoading: false, error: null)),
    );
    await _expandWorkflow(tester);

    // Expanded without any tap: the flat job tile is visible and the header
    // chevron points up.
    expect(find.text('Build'), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);

    // Manual collapse…
    await tester.tap(find.text('CI'));
    await tester.pump();
    expect(find.text('Build'), findsNothing);

    // …sticks when the same checks arrive again (refetch): the seed is
    // one-shot, so the card stays collapsed.
    await tester.pumpWidget(
      _wrap(ChecksTab(checks: checks, isLoading: false, error: null)),
    );
    await tester.pump();
    expect(find.text('Build'), findsNothing);
  });

  testWidgets('a tall workflow starts with a taller canvas instead of 280px', (
    tester,
  ) async {
    // Six independent jobs form one six-row column: 64 + 6*96 - 28 = 612,
    // clamped to the 560 resting cap.
    const runId = 900;
    final nodes = [
      for (var i = 1; i <= 6; i++) WorkflowJobNode(id: 'j$i', name: 'Job $i'),
    ];
    final graph = WorkflowGraph(name: 'CI', jobs: nodes);
    final checks = [
      CheckRun(
        name: 'Job 1',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: 'https://github.com/o/r/actions/runs/$runId',
        workflowName: 'CI',
        workflowRunId: runId,
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        ChecksTab(checks: checks, isLoading: false, error: null),
        overrides: [
          prWorkflowGraphProvider.overrideWith(
            (ref, id) async => id == runId ? graph : null,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byType(WorkflowRunCanvas)).height, 560);
  });

  testWidgets('dragging the resize grip extends the graph height', (
    tester,
  ) async {
    const runId = 900;
    final graph = WorkflowGraph(
      name: 'CI',
      jobs: [WorkflowJobNode(id: 'build', name: 'Build')],
    );
    final checks = [
      CheckRun(
        name: 'Build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: 'https://github.com/o/r/actions/runs/$runId',
        workflowName: 'CI',
        workflowRunId: runId,
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        ChecksTab(checks: checks, isLoading: false, error: null),
        overrides: [
          prWorkflowGraphProvider.overrideWith(
            (ref, id) async => id == runId ? graph : null,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final canvas = find.byType(WorkflowRunCanvas);
    expect(tester.getSize(canvas).height, 280);

    await tester.drag(
      find.bySemanticsLabel('Drag to resize the graph'),
      const Offset(0, 150),
    );
    await tester.pump();
    // Touch slop consumes a few pixels of the gesture; the contract is that
    // the canvas grew by roughly the drag distance.
    expect(tester.getSize(canvas).height, inExclusiveRange(280, 430));

    // Clamped at 1200 no matter how far the drag goes.
    await tester.drag(
      find.bySemanticsLabel('Drag to resize the graph'),
      const Offset(0, 2000),
    );
    await tester.pump();
    expect(tester.getSize(canvas).height, 1200);

    // Flush the grip's double-tap timeout so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
