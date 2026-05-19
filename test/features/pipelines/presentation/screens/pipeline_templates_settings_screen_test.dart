import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String _id;

  @override
  String? build() => _id;
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

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

/// Wraps [PipelineTemplatesSettingsScreen] with provider overrides.
///
/// [templates] drives [pipelineTemplatesProvider].
/// [workspaceId] drives [activeWorkspaceIdProvider]; pass null for no workspace.
Widget _wrap({
  List<PipelineDefinition> templates = const [],
  String? workspaceId,
}) {
  final workspaceOverride = workspaceId == null
      ? activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new)
      : activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspaceIdNotifier(workspaceId),
        );

  final overrides = [
    workspaceOverride,
  ];

  if (workspaceId != null) {
    overrides.add(
      pipelineTemplatesProvider(workspaceId)
          .overrideWith((ref) => Stream.value(templates)),
    );
    overrides.add(
      pipelineTriggersForWorkspaceProvider(workspaceId)
          .overrideWith((ref) => const Stream.empty()),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: testWrap(const PipelineTemplatesSettingsScreen()),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('PipelineTemplatesSettingsScreen', () {
    testWidgets('renders no-workspace message when workspaceId is null',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('Select a workspace to view its pipelines'),
        findsOneWidget,
      );
    });

    testWidgets('renders template names when templates exist', (tester) async {
      final templates = [
        _template(templateId: 'hello', name: 'Hello Pipeline'),
        _template(templateId: 'world', name: 'World Pipeline'),
      ];

      await tester.pumpWidget(
        _wrap(templates: templates, workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello Pipeline'), findsOneWidget);
      expect(find.text('World Pipeline'), findsOneWidget);
    });

    testWidgets('renders empty state when no templates exist', (tester) async {
      await tester.pumpWidget(
        _wrap(templates: const [], workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No pipeline templates yet. Create one to get started.'),
        findsOneWidget,
      );
    });
  });
}
