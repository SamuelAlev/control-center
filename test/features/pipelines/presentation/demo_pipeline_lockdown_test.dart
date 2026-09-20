import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_template_editor_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipelines_screen.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';

class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String _id;

  @override
  String? build() => _id;
}

PipelineDefinition _template() {
  return PipelineDefinition(
    templateId: 'hello',
    workspaceId: _workspaceId,
    name: 'Hello Pipeline',
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

void main() {
  testWidgets('demo hides Run pipeline on the runs list', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _FixedWorkspaceIdNotifier(_workspaceId),
          ),
          workspacePipelineRunsProvider(
            _workspaceId,
          ).overrideWith((ref) => Stream.value(const [])),
          pipelineTemplatesProvider(
            _workspaceId,
          ).overrideWith((ref) => Stream.value(const [])),
          pipelineClockProvider.overrideWith(
            (ref) => const Stream<int>.empty(),
          ),
        ],
        child: testWrap(const PipelinesScreen(), isDemo: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(CcButton, 'Run pipeline'), findsNothing);
  });

  testWidgets('demo run launcher is DemoUnavailable, not a start form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _FixedWorkspaceIdNotifier(_workspaceId),
          ),
        ],
        child: testWrap(const PipelineRunScreen(), isDemo: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.textContaining('Pipelines cannot run here'), findsOneWidget);
    expect(find.widgetWithText(CcButton, 'Run pipeline'), findsNothing);
  });

  testWidgets('demo hides New template and explains why', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(
            () => _FixedWorkspaceIdNotifier(_workspaceId),
          ),
          pipelineTemplatesProvider(
            _workspaceId,
          ).overrideWith((ref) => Stream.value([_template()])),
          pipelineTriggersForWorkspaceProvider(
            _workspaceId,
          ).overrideWith((ref) => const Stream.empty()),
        ],
        child: testWrap(const PipelineTemplatesSettingsScreen(), isDemo: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New template'), findsNothing);
    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text('Hello Pipeline'), findsOneWidget);
  });

  testWidgets('demo template editor is DemoUnavailable, not a canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const PipelineTemplateEditorScreen(templateId: 'hello'),
        isDemo: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.textContaining('Pipelines cannot run here'), findsOneWidget);
  });
}
