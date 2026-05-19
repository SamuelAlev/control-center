import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_pipelines_panel.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

// ── Test helpers ──

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

final _fixedDateTime = DateTime(2026, 6, 10);

PipelineStepDefinition _step({
  String id = 's1',
  StepKind kind = StepKind.trigger,
}) {
  return PipelineStepDefinition(id: id, kind: kind, bodyKey: 'noop');
}

PipelineRun _run({
  String id = 'run-1',
  String templateId = 't1',
  String workspaceId = 'ws1',
  PipelineRunStatus status = PipelineRunStatus.completed,
  DateTime? startedAt,
}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: workspaceId,
    status: status,
    startedAt: startedAt ?? _fixedDateTime,
  );
}

PipelineDefinition _template({
  String templateId = 't1',
  String name = 'PR Review',
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: 'ws1',
    name: name,
    steps: [_step()],
  );
}

// ── Tests ──

void main() {
  const codeFont = 'JetBrains Mono';

  testWidgets('renders nothing when no workspace', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId(null)),
        ],
        child: testWrap(const DashboardPipelinesPanel(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pipelines'), findsNothing);
  });

  testWidgets('renders nothing when no runs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId('ws1')),
          workspacePipelineRunsProvider('ws1').overrideWith(
            (ref) => Stream.value(const <PipelineRun>[]),
          ),
          pipelineTemplatesProvider('ws1').overrideWith(
            (ref) => Stream.value(const <PipelineDefinition>[]),
          ),
        ],
        child: testWrap(const DashboardPipelinesPanel(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pipelines'), findsNothing);
  });

  testWidgets('renders pipeline runs when runs exist', (tester) async {
    final runs = [_run()];
    final templates = [_template()];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId('ws1')),
          workspacePipelineRunsProvider('ws1').overrideWith(
            (ref) => Stream.value(runs),
          ),
          pipelineTemplatesProvider('ws1').overrideWith(
            (ref) => Stream.value(templates),
          ),
        ],
        child: testWrap(const DashboardPipelinesPanel(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pipelines'), findsOneWidget);
    expect(find.text('PR Review'), findsOneWidget);
  });

  testWidgets('shows failed count when failed runs exist', (tester) async {
    final runs = [
      _run(status: PipelineRunStatus.failed),
    ];
    final templates = [_template()];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(() => _FixedWorkspaceId('ws1')),
          workspacePipelineRunsProvider('ws1').overrideWith(
            (ref) => Stream.value(runs),
          ),
          pipelineTemplatesProvider('ws1').overrideWith(
            (ref) => Stream.value(templates),
          ),
        ],
        child: testWrap(const DashboardPipelinesPanel(codeFont: codeFont)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pipelines'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
