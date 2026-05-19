import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_filter_rail.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_row.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';

// ── Test doubles ─────────────────────────────────────────────────────────────

/// A test-only [ActiveWorkspaceIdNotifier] that returns a fixed workspace ID.
class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String _id;

  @override
  String? build() => _id;
}

/// Test-only notifier that reports no active workspace.
class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// A minimal pipeline run for testing.
PipelineRun _run({
  String id = 'run-1',
  String templateId = 'hello',
  PipelineRunStatus status = PipelineRunStatus.completed,
  DateTime? startedAt,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: _workspaceId,
    status: status,
    startedAt: startedAt ?? DateTime(2026, 1, 1),
  );
}

/// A minimal pipeline definition for template name lookup.
PipelineDefinition _template({
  String templateId = 'hello',
  String name = 'Hello Pipeline',
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: _workspaceId,
    name: name,
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
    ],
    isEnabled: true,
  );
}

/// Wraps [PipelinesScreen] with provider overrides.
///
/// [runs] drives [workspacePipelineRunsProvider].
/// [templates] drives [pipelineTemplatesProvider].
/// [workspaceId] drives [activeWorkspaceIdProvider]; pass null for no workspace.
Widget _wrap({
  required AsyncValue<List<PipelineRun>> runs,
  AsyncValue<List<PipelineDefinition>> templates = const AsyncValue.data([]),
  String? workspaceId,
}) {
  final workspaceOverride = workspaceId == null
      ? activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new)
      : activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspaceIdNotifier(workspaceId),
        );

  final overrides = [
    workspacePipelineRunsProvider(_workspaceId).overrideWith(
      (ref) => runs.when(
        data: Stream.value,
        loading: () => const Stream.empty(),
        error: (e, _) => Stream.error(e),
      ),
    ),
    pipelineTemplatesProvider(_workspaceId).overrideWith(
      (ref) => templates.when(
        data: Stream.value,
        loading: () => const Stream.empty(),
        error: (e, _) => Stream.error(e),
      ),
    ),
    pipelineClockProvider.overrideWith(
      (ref) => Stream.periodic(const Duration(seconds: 1), (i) => i + 1),
    ),
    workspaceOverride,
  ];

  return ProviderScope(
    overrides: overrides,
    child: testWrap(const PipelinesScreen()),
  );
}

/// Taps the rail entry labelled [label]. Scoped to the rail because a status
/// label ("Running" / "Failed") also appears in the rows' status badges.
Future<void> _tapFilter(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(PipelineRunFilterRail),
      matching: find.text(label),
    ),
  );
}

/// The count text rendered beside a rail entry.
Finder _railCount(String count) => find.descendant(
  of: find.byType(PipelineRunFilterRail),
  matching: find.text(count),
);

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PipelinesScreen', () {
    // ── No workspace ──────────────────────────────────────────────────────

    testWidgets('shows no-active-workspace message when workspaceId is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(runs: const AsyncValue.loading()));
      await tester.pumpAndSettle();

      expect(
        find.text('Select a workspace to view its pipelines'),
        findsOneWidget,
      );
    });

    // ── Loading ───────────────────────────────────────────────────────────

    testWidgets('shows page wrapper with title and run button while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(runs: const AsyncValue.loading(), workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pipelines'), findsOneWidget);
      expect(find.text('Run pipeline'), findsOneWidget);
    });

    // ── Empty list ────────────────────────────────────────────────────────

    testWidgets('shows empty state when no runs exist', (tester) async {
      await tester.pumpWidget(
        _wrap(runs: const AsyncValue.data([]), workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pipeline runs yet'), findsOneWidget);
      expect(find.text("Click 'Run pipeline' to start one."), findsOneWidget);
      expect(find.text('Run pipeline'), findsOneWidget);
    });

    // ── Populated list ────────────────────────────────────────────────────

    testWidgets('shows the filter rail with live counts over a table of runs', (
      tester,
    ) async {
      final runs = [_run(id: 'run-1'), _run(id: 'run-2'), _run(id: 'run-3')];
      final templates = [_template(templateId: 'hello', name: 'Hello')];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Rail entries: all / running / failed, always present.
      expect(
        find.descendant(
          of: find.byType(PipelineRunFilterRail),
          matching: find.text('All'),
        ),
        findsOneWidget,
      );
      expect(_railCount('3'), findsOneWidget);
      expect(_railCount('0'), findsNWidgets(2));

      // One row per run, with the friendly pipeline name and column headers.
      expect(find.byType(PipelineRunRow), findsNWidgets(3));
      expect(find.text('Hello'), findsNWidgets(3));
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Started'), findsOneWidget);
    });

    // ── Filtering: Running ────────────────────────────────────────────────

    testWidgets('shows only running runs when the running filter is active', (
      tester,
    ) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.running),
        _run(id: 'run-3', status: PipelineRunStatus.running),
        _run(id: 'run-4', status: PipelineRunStatus.failed),
      ];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data([_template()]),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      await _tapFilter(tester, 'Running');
      await tester.pumpAndSettle();

      expect(find.byType(PipelineRunRow), findsNWidgets(2));
    });

    // ── Filtering: Failed ─────────────────────────────────────────────────

    testWidgets('shows only failed runs when the failed filter is active', (
      tester,
    ) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.running),
        _run(id: 'run-3', status: PipelineRunStatus.failed),
        _run(id: 'run-4', status: PipelineRunStatus.failed),
      ];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data([_template()]),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      await _tapFilter(tester, 'Failed');
      await tester.pumpAndSettle();

      expect(find.byType(PipelineRunRow), findsNWidgets(2));
    });

    // ── Filtering: empty result ───────────────────────────────────────────

    testWidgets('shows the empty-filter message when no run matches', (
      tester,
    ) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.completed),
      ];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data([_template()]),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      await _tapFilter(tester, 'Running');
      await tester.pumpAndSettle();

      expect(find.byType(PipelineRunRow), findsNothing);
      expect(find.text('No runs match this filter'), findsOneWidget);
      // The rail never hides an entry — it is the always-complete triage map.
      expect(find.byType(PipelineRunFilterRail), findsOneWidget);
    });

    // ── Filtering: back to all ────────────────────────────────────────────

    testWidgets('switching back to all shows every run again', (tester) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.failed),
      ];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data([_template()]),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      await _tapFilter(tester, 'Failed');
      await tester.pumpAndSettle();
      expect(find.byType(PipelineRunRow), findsOneWidget);

      await _tapFilter(tester, 'All');
      await tester.pumpAndSettle();
      expect(find.byType(PipelineRunRow), findsNWidgets(2));
    });
  });
}
