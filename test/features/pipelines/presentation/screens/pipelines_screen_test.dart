import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_card.dart';
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
/// [initialRunId] is forwarded to the screen.
Widget _wrap({
  required AsyncValue<List<PipelineRun>> runs,
  AsyncValue<List<PipelineDefinition>> templates =
      const AsyncValue.data([]),
  String? workspaceId,
  String? initialRunId,
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
    child: testWrap(PipelinesScreen(initialRunId: initialRunId)),
  );
}

/// Taps the filter segment labelled [label] inside the `_RunFilterBar`.
///
/// The [label] text may also appear in [PipelineRunCard] status badges, so we
/// target the [CcTappable] ancestor of the segment's text — the filter bar
/// places each segment inside an [CcTappable.static] wrapper.
Future<void> _tapFilterSegment(WidgetTester tester, String label) async {
  final tappable = find.ancestor(
    of: find.text(label),
    matching: find.byType(CcTappable),
  );
  await tester.tap(tappable.first);
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('PipelinesScreen', () {
    // ── No workspace ──────────────────────────────────────────────────────

    testWidgets('shows no-active-workspace message when workspaceId is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(runs: const AsyncValue.loading()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select a workspace to view its pipelines'),
          findsOneWidget);
    });

    // ── Loading ───────────────────────────────────────────────────────────

    testWidgets('shows page wrapper with title and run button while loading',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          runs: const AsyncValue.loading(),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // PageWrapper with title and action button should render during load.
      expect(find.text('Pipelines'), findsOneWidget);
      expect(find.text('Run pipeline'), findsOneWidget);
    });

    // ── Empty list ────────────────────────────────────────────────────────

    testWidgets('shows empty state when no runs exist', (tester) async {
      await tester.pumpWidget(
        _wrap(
          runs: const AsyncValue.data([]),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pipeline runs yet'), findsOneWidget);
      expect(find.text("Click 'Run pipeline' to start one."), findsOneWidget);
      expect(find.text('Run pipeline'), findsOneWidget);
    });

    // ── Populated list ────────────────────────────────────────────────────

    testWidgets('shows filter bar and run cards for populated data',
        (tester) async {
      final runs = [
        _run(id: 'run-1'),
        _run(id: 'run-2'),
        _run(id: 'run-3'),
      ];
      final templates = [_template(templateId: 'hello', name: 'Hello')];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Filter bar segments: All, Running, Failed are always present.
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      // All-count and running/failed counts are 0 (all completed).
      expect(find.text('3'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));

      // Run cards.
      expect(find.byType(PipelineRunCard), findsNWidgets(3));

      // "Run pipeline" button in actions.
      expect(find.text('Run pipeline'), findsOneWidget);

      // Sidebar / detail pane placeholder (no run selected).
      expect(find.text('Select a pipeline run to view steps'), findsOneWidget);
    });

    // ── Filtering: Running ────────────────────────────────────────────────

    testWidgets('shows only running runs when running filter is active',
        (tester) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.running),
        _run(id: 'run-3', status: PipelineRunStatus.running),
        _run(id: 'run-4', status: PipelineRunStatus.failed),
      ];
      final templates = [_template()];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Running filter segment.
      await _tapFilterSegment(tester, 'Running');
      await tester.pumpAndSettle();

      // Only the 2 running runs should be visible.
      expect(find.byType(PipelineRunCard), findsNWidgets(2));
    });

    // ── Filtering: Failed ─────────────────────────────────────────────────

    testWidgets('shows only failed runs when failed filter is active',
        (tester) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.running),
        _run(id: 'run-3', status: PipelineRunStatus.failed),
        _run(id: 'run-4', status: PipelineRunStatus.failed),
      ];
      final templates = [_template()];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Failed filter segment.
      await _tapFilterSegment(tester, 'Failed');
      await tester.pumpAndSettle();

      // Only the 2 failed runs should be visible.
      expect(find.byType(PipelineRunCard), findsNWidgets(2));
    });

    // ── Filtering: Empty filter result ────────────────────────────────────

    testWidgets('shows empty filter state when no runs match filter',
        (tester) async {
      // Only completed runs — no running ones.
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.completed),
      ];
      final templates = [_template()];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Running filter segment.
      await _tapFilterSegment(tester, 'Running');
      await tester.pumpAndSettle();

      // No run cards, instead the empty-filter message.
      expect(find.byType(PipelineRunCard), findsNothing);
      expect(find.text('No runs match this filter'), findsOneWidget);
    });

    // ── Filtering: cycle back to All ──────────────────────────────────────

    testWidgets('switching back to all filter shows all runs again',
        (tester) async {
      final runs = [
        _run(id: 'run-1', status: PipelineRunStatus.completed),
        _run(id: 'run-2', status: PipelineRunStatus.failed),
      ];
      final templates = [_template()];

      await tester.pumpWidget(
        _wrap(
          runs: AsyncValue.data(runs),
          templates: AsyncValue.data(templates),
          workspaceId: _workspaceId,
        ),
      );
      await tester.pumpAndSettle();

      // Filter to failed.
      await _tapFilterSegment(tester, 'Failed');
      await tester.pumpAndSettle();
      expect(find.byType(PipelineRunCard), findsOneWidget);

      // Back to All.
      await _tapFilterSegment(tester, 'All');
      await tester.pumpAndSettle();
      expect(find.byType(PipelineRunCard), findsNWidgets(2));
    });
  });
}
