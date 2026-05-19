import 'dart:convert';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_field_label.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Agent _agent({
  String id = 'agent-1',
  String name = 'coder',
  String title = 'Code Generator',
  String workspaceId = 'ws-1',
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/agents/coder.md',
    workspaceId: workspaceId,
    skills: AgentSkills(const []),
    createdAt: DateTime(2026),
  );
}

PipelineStepDefinition _step({
  String id = 'step-1',
  StepKind kind = StepKind.listen,
  String bodyKey = 'conversation.promptAgent',
  PipelineNodeConfig config = PipelineNodeConfig.empty,
  double? x,
  double? y,
  List<StepTrigger> triggers = const [],
}) {
  return PipelineStepDefinition(
    id: id,
    kind: kind,
    bodyKey: bodyKey,
    config: config,
    x: x,
    y: y,
    triggers: triggers,
  );
}

List<PipelineStepDefinition> _allSteps(PipelineStepDefinition step) {
  return [step];
}

Repo _repo(String id) {
  return Repo(
    id: id,
    name: 'o/$id',
    path: '/src/$id',
    remoteOwner: 'o',
    remoteName: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// Pumps [editor] into a test with a tall viewport so the ListView renders
/// all its children.
Future<void> _pumpEditor(WidgetTester tester, NodeConfigEditor editor) async {
  // Set a tall surface so the ListView renders all items.
  tester.view.physicalSize = Size(
    400 * tester.view.devicePixelRatio,
    4000 * tester.view.devicePixelRatio,
  );
  addTearDown(() => tester.view.resetPhysicalSize());
  await tester.pumpWidget(testWrap(editor));
  await tester.pumpAndSettle();
}

/// Enters text into the field labelled [labelText], using the inner
/// [EditableText] so that `enterText` works even for number and multiline
/// variants. The label and its field (a `CcTextField` or `CcTextArea`) are
/// siblings inside a `NodeFieldLabel` column, so we locate that column by
/// walking up from the label and then descend to the field's editable.
Future<void> _enterFTextField(
  WidgetTester tester,
  String labelText,
  String text,
) async {
  final labeled = find.ancestor(
    of: find.text(labelText),
    matching: find.byType(NodeFieldLabel),
  );
  final editable = find.descendant(
    of: labeled,
    matching: find.byType(EditableText),
  );
  await tester.showKeyboard(editable);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NodeConfigEditor', () {
    // -----------------------------------------------------------------------
    // Rendering: title and delete
    // -----------------------------------------------------------------------

    testWidgets('renders title with step id', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.textContaining('step-1'), findsWidgets);
    });

    testWidgets('renders delete button', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
    });

    testWidgets('delete button calls onDelete', (tester) async {
      var deleted = false;
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () => deleted = true,
        ),
      );

      final trashIcon = find.byIcon(AppIcons.trash2);
      await tester.tap(
        find.ancestor(of: trashIcon, matching: find.byType(CcIconButton)).first,
      );
      // Let the tappable timer fire
      await tester.pump(const Duration(milliseconds: 150));
      expect(deleted, true);
    });

    // -----------------------------------------------------------------------
    // Rendering: common fields (all bodyKey types)
    // -----------------------------------------------------------------------

    testWidgets('shows label field', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Label'), findsOneWidget);
    });

    testWidgets('shows input keys field', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Input keys (comma-separated)'), findsOneWidget);
    });

    testWidgets('shows advanced section with all fields', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Reducer'), findsOneWidget);
      expect(find.text('Timeout (ms)'), findsOneWidget);
      expect(find.text('Retry attempts'), findsOneWidget);
      expect(find.text('Continue if this step fails'), findsOneWidget);
      expect(find.text('Output schema (JSON)'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Rendering: bodyKey variants
    // -----------------------------------------------------------------------

    testWidgets('promptAgent body shows agent select, prompt and output key', (
      tester,
    ) async {
      final agent = _agent();
      final step = _step(
        bodyKey: 'conversation.promptAgent',
        config: PipelineNodeConfig(agentId: agent.id),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: [agent],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Agent'), findsOneWidget);
      expect(find.text('Prompt template'), findsOneWidget);
      expect(find.text('Output key'), findsOneWidget);
    });

    testWidgets('bashScript body shows script but not agent/prompt', (
      tester,
    ) async {
      final step = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Bash script'), findsOneWidget);
      expect(find.text('Agent'), findsNothing);
      expect(find.text('Prompt template'), findsNothing);
      expect(find.text('Output key'), findsOneWidget);
    });

    testWidgets('condition body shows ConditionConfigEditor not output key', (
      tester,
    ) async {
      final step = _step(bodyKey: 'pipeline.condition');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Output key'), findsNothing);
    });

    testWidgets('team.dispatch body shows team id and dispatch mode', (
      tester,
    ) async {
      final step = _step(bodyKey: 'team.dispatch');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Team ID'), findsOneWidget);
      expect(find.text('Dispatch mode'), findsOneWidget);
    });

    testWidgets('generic body shows output key but no agent/prompt/script', (
      tester,
    ) async {
      final step = _step(bodyKey: 'some.other.body');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Output key'), findsOneWidget);
      expect(find.text('Agent'), findsNothing);
      expect(find.text('Prompt template'), findsNothing);
      expect(find.text('Bash script'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Rendering: step kind
    // -----------------------------------------------------------------------

    testWidgets('listen kind shows kind selector', (tester) async {
      final step = _step(kind: StepKind.listen);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Kind'), findsOneWidget);
    });

    testWidgets('join kind shows kind selector', (tester) async {
      final step = _step(kind: StepKind.join);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Kind'), findsOneWidget);
    });

    testWidgets('trigger kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.trigger);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('router kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.router);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('terminal kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.terminal);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Kind'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Rendering: triggers section
    // -----------------------------------------------------------------------

    testWidgets('shows triggers section with upstream candidates', (
      tester,
    ) async {
      final current = _step(id: 'step-2');
      final upstream = _step(id: 'step-1', kind: StepKind.listen);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, upstream],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Triggers from'), findsOneWidget);
      expect(find.text('step-1'), findsWidgets);
    });

    testWidgets('shows no-upstream message when only step exists', (
      tester,
    ) async {
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('No other nodes to connect from.'), findsOneWidget);
    });

    testWidgets('excludes terminal steps from upstream candidates', (
      tester,
    ) async {
      final current = _step(id: 'step-2');
      final terminal = _step(id: 'step-1', kind: StepKind.terminal);
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, terminal],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('No other nodes to connect from.'), findsOneWidget);
    });

    testWidgets('trigger chip uses config label when available', (
      tester,
    ) async {
      final current = _step(id: 'step-2');
      final upstream = _step(
        id: 'step-1',
        kind: StepKind.listen,
        config: const PipelineNodeConfig(label: 'My Custom Name'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, upstream],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('My Custom Name'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Form state: single-line field callbacks
    // -----------------------------------------------------------------------

    testWidgets('label field change emits updated step', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(label: 'old'));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Label', 'New Label');

      expect(updated, isNotNull);
      expect(updated!.config.label, 'New Label');
    });

    testWidgets('input keys field change emits with parsed keys', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(
        tester,
        'Input keys (comma-separated)',
        'keyA, keyB , keyC',
      );

      expect(updated, isNotNull);
      expect(updated!.config.inputKeys, ['keyA', 'keyB', 'keyC']);
    });

    testWidgets('output key field change emits output key', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Output key', 'myOutput');

      expect(updated!.config.outputKey, 'myOutput');
    });

    testWidgets('timeout field change emits parsed int', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Timeout (ms)', '5000');

      expect(updated!.config.timeoutMs, 5000);
    });

    testWidgets('invalid timeout text emits null timeout', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(timeoutMs: 1000));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Timeout (ms)', 'not-a-number');

      expect(updated!.config.timeoutMs, isNull);
    });

    testWidgets('retry attempts field change emits retry policy', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Retry attempts', '3');

      expect(updated!.config.retryPolicy, isNotNull);
      expect(updated!.config.retryPolicy!.maxAttempts, 3);
    });

    testWidgets('invalid retry text emits null retry policy', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Retry attempts', 'abc');

      expect(updated!.config.retryPolicy, isNull);
    });

    testWidgets('empty label text emits null label', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(label: 'Has Label'));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Label', '   ');

      expect(updated!.config.label, isNull);
    });

    // -----------------------------------------------------------------------
    // Form state: checkbox
    // -----------------------------------------------------------------------

    testWidgets('continue on fail checkbox toggles on', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      final checkbox = find.byType(CcCheckbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.config.continueOnFail, true);
    });

    testWidgets('continue on fail starts from config value', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        config: const PipelineNodeConfig(continueOnFail: true),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await tester.tap(find.byType(CcCheckbox));
      await tester.pumpAndSettle();

      expect(updated!.config.continueOnFail, false);
    });

    // -----------------------------------------------------------------------
    // Edge / trigger interactions
    // -----------------------------------------------------------------------

    testWidgets('tapping a trigger chip connects it and calls onChange', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-2');
      final upstream = _step(id: 'step-1');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, upstream],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.triggers.length, 1);
      expect(updated!.triggers.first.sourceStepIds, ['step-1']);
      expect(updated!.triggers.first.routeKey, isNull);
    });

    testWidgets('tapping trigger chip twice disconnects edge', (tester) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-2');
      final upstream = _step(id: 'step-1');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, upstream],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers, isNotEmpty);

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers, isEmpty);
    });

    testWidgets('shows route key editors for connected router sources', (
      tester,
    ) async {
      final router = _step(id: 'step-2', kind: StepKind.router);
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'conversation.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [
          const StepTrigger(sourceStepIds: ['step-2']),
        ],
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: stepWithEdge,
          allSteps: [router, stepWithEdge],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Route keys'), findsOneWidget);
    });

    testWidgets('route key field label includes upstream step label', (
      tester,
    ) async {
      final router = _step(
        id: 'step-2',
        kind: StepKind.router,
        config: const PipelineNodeConfig(label: 'My Router'),
      );
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'conversation.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [
          const StepTrigger(sourceStepIds: ['step-2']),
        ],
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: stepWithEdge,
          allSteps: [router, stepWithEdge],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.textContaining('My Router'), findsWidgets);
    });

    testWidgets('no route keys when router is not connected', (tester) async {
      final router = _step(id: 'step-2', kind: StepKind.router);
      final current = _step(id: 'step-3');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, router],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Route keys'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Step ID change re-initializes controllers
    // -----------------------------------------------------------------------

    testWidgets('changing step id re-initializes form fields', (tester) async {
      final step1 = _step(
        id: 'step-1',
        config: const PipelineNodeConfig(label: 'First'),
      );
      final step2 = _step(
        id: 'step-2',
        config: const PipelineNodeConfig(label: 'Second'),
      );

      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step1,
          allSteps: _allSteps(step1),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('First'), findsOneWidget);

      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step2,
          allSteps: _allSteps(step2),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Edge: join kind sets waitForStepIds
    // -----------------------------------------------------------------------

    testWidgets('join kind emits waitForStepIds from connected edges', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-3', kind: StepKind.join);
      final upstream = _step(id: 'step-1');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, upstream],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();

      expect(updated!.kind, StepKind.join);
      expect(updated!.waitForStepIds, ['step-1']);
    });

    // -----------------------------------------------------------------------
    // Schema field: JSON validation
    // -----------------------------------------------------------------------

    testWidgets('schema field with valid JSON emits parsed schema', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
      };
      await _enterFTextField(
        tester,
        'Output schema (JSON)',
        jsonEncode(schema),
      );

      expect(updated, isNotNull);
      expect(updated!.config.outputSchema, schema);
    });

    testWidgets('empty schema field clears schema', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        config: const PipelineNodeConfig(outputSchema: {'type': 'object'}),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Output schema (JSON)', '');

      expect(updated!.config.outputSchema, isNull);
    });

    testWidgets('invalid JSON in schema does not crash widget', (tester) async {
      final step = _step(
        config: const PipelineNodeConfig(outputSchema: {'type': 'object'}),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Output schema (JSON)', '{invalid json');

      // Widget should still render
      expect(find.text('Output schema (JSON)'), findsOneWidget);
    });

    testWidgets('non-map JSON in schema preserves prior value', (tester) async {
      PipelineStepDefinition? updated;
      final prior = {'type': 'object'};
      final step = _step(config: PipelineNodeConfig(outputSchema: prior));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(
        tester,
        'Output schema (JSON)',
        jsonEncode([1, 2, 3]),
      );

      // Should keep prior value since decoded value is not a Map
      expect(updated!.config.outputSchema, prior);
    });

    // -----------------------------------------------------------------------
    // Multiple upstream candidates
    // -----------------------------------------------------------------------

    testWidgets('multiple upstream candidates all shown as chips', (
      tester,
    ) async {
      final current = _step(id: 'step-4');
      final up1 = _step(id: 'step-1');
      final up2 = _step(id: 'step-2');
      final up3 = _step(
        id: 'step-3',
        config: const PipelineNodeConfig(label: 'Third'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, up1, up2, up3],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('step-1'), findsOneWidget);
      expect(find.text('step-2'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('connecting multiple upstream steps emits separate triggers', (
      tester,
    ) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-3');
      final up1 = _step(id: 'step-1');
      final up2 = _step(id: 'step-2');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: current,
          allSteps: [current, up1, up2],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers.length, 1);

      await tester.tap(find.text('step-2'));
      await tester.pumpAndSettle();
      expect(updated!.triggers.length, 2);

      final ids = updated!.triggers.expand((t) => t.sourceStepIds).toSet();
      expect(ids, {'step-1', 'step-2'});
    });

    // -----------------------------------------------------------------------
    // Agent select interaction
    // -----------------------------------------------------------------------

    testWidgets('agent select renders with workspace agents', (tester) async {
      final agent1 = _agent(id: 'agent-1', name: 'coder');
      final agent2 = _agent(id: 'agent-2', name: 'tester');
      final step = _step(
        bodyKey: 'conversation.promptAgent',
        config: const PipelineNodeConfig(agentId: 'agent-1'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: [agent1, agent2],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Agent'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Prompt field editing
    // -----------------------------------------------------------------------

    testWidgets('prompt field change emits prompt text', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'conversation.promptAgent',
        config: const PipelineNodeConfig(prompt: 'Do the thing'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Prompt template', 'Plan carefully');

      expect(updated, isNotNull);
      expect(updated!.config.prompt, 'Plan carefully');
    });

    testWidgets('empty prompt emits null prompt', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'conversation.promptAgent',
        config: const PipelineNodeConfig(prompt: 'existing'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Prompt template', '');

      expect(updated!.config.prompt, isNull);
    });

    // -----------------------------------------------------------------------
    // Script field editing
    // -----------------------------------------------------------------------

    testWidgets('script field change emits script text', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Bash script', 'echo hello');

      expect(updated, isNotNull);
      expect(updated!.config.script, 'echo hello');
    });

    testWidgets('empty script emits null script', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'pipeline.bashScript',
        config: const PipelineNodeConfig(script: 'old'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Bash script', '');

      expect(updated!.config.script, isNull);
    });

    // -----------------------------------------------------------------------
    // Reducer select rendering
    // -----------------------------------------------------------------------

    testWidgets('reducer select renders all options', (tester) async {
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(),
          allSteps: _allSteps(_step()),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Reducer'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Route key text editing
    // -----------------------------------------------------------------------

    testWidgets('typing a route key emits with routeKey set', (tester) async {
      PipelineStepDefinition? updated;
      final router = _step(id: 'step-2', kind: StepKind.router);
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'conversation.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [
          const StepTrigger(sourceStepIds: ['step-2']),
        ],
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: stepWithEdge,
          allSteps: [router, stepWithEdge],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      final tf = find.byType(CcTextFormField);
      expect(tf, findsOneWidget);
      await tester.enterText(tf, 'true');
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.triggers.single.routeKey, 'true');
    });

    testWidgets('empty route key emits null routeKey', (tester) async {
      PipelineStepDefinition? updated;
      final router = _step(id: 'step-2', kind: StepKind.router);
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'conversation.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [
          const StepTrigger(sourceStepIds: ['step-2'], routeKey: 'was-set'),
        ],
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: stepWithEdge,
          allSteps: [router, stepWithEdge],
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      final tf = find.byType(CcTextFormField);
      await tester.enterText(tf, '');
      await tester.pumpAndSettle();

      expect(updated!.triggers.single.routeKey, isNull);
    });

    // -----------------------------------------------------------------------
    // Team dispatch fields
    // -----------------------------------------------------------------------

    testWidgets('teamId field change emits teamId', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(bodyKey: 'team.dispatch');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Team ID', 'alpha-team');

      expect(updated, isNotNull);
      expect(updated!.config.teamId, 'alpha-team');
    });

    testWidgets('empty teamId emits null teamId', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'team.dispatch',
        config: const PipelineNodeConfig(teamId: 'old-team'),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => updated = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Team ID', '   ');

      expect(updated!.config.teamId, isNull);
    });

    testWidgets('dispatch mode select renders', (tester) async {
      final step = _step(bodyKey: 'team.dispatch');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Dispatch mode'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Config value initialisation
    // -----------------------------------------------------------------------

    testWidgets('timeout controller initialised from config', (tester) async {
      final step = _step(config: const PipelineNodeConfig(timeoutMs: 3000));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Timeout (ms)'), findsOneWidget);
    });

    testWidgets('retry attempts controller initialised from config', (
      tester,
    ) async {
      final step = _step(
        config: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 5),
        ),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Retry attempts'), findsOneWidget);
    });

    testWidgets('input keys controller initialised from config keys', (
      tester,
    ) async {
      final step = _step(
        config: const PipelineNodeConfig(inputKeys: ['a', 'b', 'c']),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Input keys (comma-separated)'), findsOneWidget);
    });

    testWidgets('output key controller initialised from config', (
      tester,
    ) async {
      final step = _step(config: const PipelineNodeConfig(outputKey: 'result'));
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Output key'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Continue on fail checkbox
    // -----------------------------------------------------------------------

    testWidgets('continueOnFail checkbox renders correctly when true', (
      tester,
    ) async {
      final step = _step(
        config: const PipelineNodeConfig(continueOnFail: true),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      final cbs = tester.widgetList<CcCheckbox>(find.byType(CcCheckbox));
      expect(cbs.isNotEmpty, isTrue);
    });

    // -----------------------------------------------------------------------
    // Repo scope selector (conversation-starting nodes)
    // -----------------------------------------------------------------------

    testWidgets('repo selector renders on the node that opens a room', (
      tester,
    ) async {
      // A conversation IS the checkout, so its scope belongs to the node that
      // opens one. An agent node joins a room someone else opened; offering the
      // control there invites an author to set it and watch it do nothing.
      final repos = [_repo('r-1'), _repo('r-2')];
      final spaceStep = _step(bodyKey: 'messaging.createSpace');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: spaceStep,
          allSteps: _allSteps(spaceStep),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('Repositories to clone'), findsOneWidget);

      final agentStep = _step(bodyKey: 'conversation.promptAgent');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: agentStep,
          allSteps: _allSteps(agentStep),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(
        find.text('Repositories to clone'),
        findsNothing,
        reason: 'an agent node joins a room; it does not scope one',
      );

      final bashStep = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: bashStep,
          allSteps: _allSteps(bashStep),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('Repositories to clone'), findsNothing);
    });

    testWidgets('empty scope defaults to all repos; emitting the default '
        'keeps the config empty', (tester) async {
      final repos = [_repo('r-1'), _repo('r-2')];
      PipelineStepDefinition? emitted;
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(bodyKey: 'messaging.createSpace'),
          allSteps: const [],
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      final select = tester.widget<CcMultiSelect<String>>(
        find.byType(CcMultiSelect<String>),
      );
      expect(select.values, {'r-1', 'r-2'});

      // Re-emitting with everything still selected must normalize back to
      // the empty list (= clone all), not persist every id.
      select.onChanged({'r-1', 'r-2'});
      expect(emitted!.config.repoIds, isEmpty);
    });

    testWidgets('selecting a subset persists only those repo ids', (
      tester,
    ) async {
      final repos = [_repo('r-1'), _repo('r-2'), _repo('r-3')];
      PipelineStepDefinition? emitted;
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: _step(bodyKey: 'messaging.createSpace'),
          allSteps: const [],
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      tester
          .widget<CcMultiSelect<String>>(find.byType(CcMultiSelect<String>))
          .onChanged({'r-2'});
      expect(emitted!.config.repoIds, ['r-2']);
    });

    testWidgets('placeholder entries are preserved and shown as dynamic', (
      tester,
    ) async {
      final repos = [_repo('r-1'), _repo('r-2')];
      PipelineStepDefinition? emitted;
      final step = _step(
        bodyKey: 'messaging.createSpace',
        config: const PipelineNodeConfig(repoIds: ['{{repo_id}}']),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      // The placeholder is not a selectable repo: it stays out of the picker
      // and is listed as a dynamic entry instead.
      final select = tester.widget<CcMultiSelect<String>>(
        find.byType(CcMultiSelect<String>),
      );
      expect(select.values, isEmpty);
      expect(find.textContaining('{{repo_id}}'), findsOneWidget);

      // Editing the picker keeps the placeholder in the emitted scope.
      select.onChanged({'r-1'});
      expect(emitted!.config.repoIds, ['{{repo_id}}', 'r-1']);
    });

    testWidgets('a repo can be pinned to the branch it is cut from', (
      tester,
    ) async {
      final repos = [_repo('r-1'), _repo('r-2')];
      PipelineStepDefinition? emitted;
      final step = _step(
        bodyKey: 'messaging.createSpace',
        config: const PipelineNodeConfig(repoIds: ['r-1']),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      // One branch field per PICKED repo — r-2 is not in the scope.
      expect(find.text('o/r-1'), findsOneWidget);
      expect(find.text('o/r-2'), findsNothing);

      await _enterRepoBranch(tester, 'o/r-1', 'release/1.2');
      expect(emitted!.config.repoIds, ['r-1@release/1.2']);

      // Cleared, the entry goes back to the bare id: an unpinned scope must be
      // byte-identical to what it was before branches existed.
      await _enterRepoBranch(tester, 'o/r-1', '  ');
      expect(emitted!.config.repoIds, ['r-1']);
    });

    testWidgets('an existing pinned entry seeds the branch field', (
      tester,
    ) async {
      final repos = [_repo('r-1')];
      final step = _step(
        bodyKey: 'messaging.createSpace',
        config: const PipelineNodeConfig(repoIds: ['r-1@hotfix/login']),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: repos,
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      // The picker matches on the id alone — a pinned repo must not read as a
      // placeholder and drop out of the selection.
      final select = tester.widget<CcMultiSelect<String>>(
        find.byType(CcMultiSelect<String>),
      );
      expect(select.values, {'r-1'});
      expect(find.text('hotfix/login'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // The conversation toggle (space node only)
    // -----------------------------------------------------------------------

    testWidgets('the conversation toggle is off, and only on the space node', (
      tester,
    ) async {
      // A room and a stream are different things: agent nodes open their own
      // named streams, so a space node that always opened one would leave an
      // empty conversation beside them.
      final spaceStep = _step(bodyKey: 'messaging.createSpace');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: spaceStep,
          allSteps: _allSteps(spaceStep),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('Open a conversation in it'), findsOneWidget);
      expect(
        find.text('Conversation name'),
        findsNothing,
        reason: 'the name only matters once the toggle is on',
      );

      final agentStep = _step(bodyKey: 'conversation.promptAgent');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: agentStep,
          allSteps: _allSteps(agentStep),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );
      expect(find.text('Open a conversation in it'), findsNothing);
    });

    testWidgets('toggling it on emits the flag and reveals the name', (
      tester,
    ) async {
      PipelineStepDefinition? emitted;
      final step = _step(bodyKey: 'messaging.createSpace');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      _conversationCheckbox(tester).onChanged!(true);
      await tester.pumpAndSettle();

      expect(emitted!.config.createsConversation, isTrue);
      expect(find.text('Conversation name'), findsOneWidget);

      await _enterFTextField(
        tester,
        'Conversation name',
        'Architecture analysis',
      );
      expect(emitted!.config.conversationTitle, 'Architecture analysis');
    });

    testWidgets('turning it back off clears both keys', (tester) async {
      // Leaving `conversationTitle` behind would name a stream the node no
      // longer opens — and an agent step reusing that title would then find
      // nothing to reuse.
      PipelineStepDefinition? emitted;
      final step = _step(
        bodyKey: 'messaging.createSpace',
        config: const PipelineNodeConfig(
          extras: {
            'createConversation': true,
            'conversationTitle': 'Architecture analysis',
          },
        ),
      );
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );
      expect(find.text('Conversation name'), findsOneWidget);

      _conversationCheckbox(tester).onChanged!(false);
      await tester.pumpAndSettle();

      expect(emitted!.config.createsConversation, isFalse);
      expect(emitted!.config.conversationTitle, isNull);
      expect(find.text('Conversation name'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // What the room and its stream are called
    // -----------------------------------------------------------------------

    testWidgets('the space node names the room it opens', (tester) async {
      // The room's name used to be reachable only by hand-editing extras, so a
      // template's rooms were all called whatever their node label happened to
      // be — which is also the canvas caption, and the two are not the same
      // thing.
      PipelineStepDefinition? emitted;
      final step = _step(bodyKey: 'messaging.createSpace');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      await _enterFTextField(tester, 'Space name', 'Review of {{pr_number}}');
      expect(emitted!.config.extras['spaceName'], 'Review of {{pr_number}}');

      // Cleared, the room falls back to the node's label — so an empty field
      // must remove the key rather than store an empty name.
      await _enterFTextField(tester, 'Space name', '   ');
      expect(emitted!.config.extras.containsKey('spaceName'), isFalse);
    });

    testWidgets('an agent node names the stream it writes into', (
      tester,
    ) async {
      // Without a name the turn lands in the room's standing conversation, so
      // a fan-out interleaves every agent into one thread.
      PipelineStepDefinition? emitted;
      final step = _step(bodyKey: 'conversation.promptAgent');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (s) => emitted = s,
          onDelete: () {},
        ),
      );

      // The room-name field belongs to the node that OPENS a room.
      expect(find.text('Space name'), findsNothing);

      await _enterFTextField(tester, 'Conversation name', 'QA review');
      expect(emitted!.config.conversationTitle, 'QA review');

      await _enterFTextField(tester, 'Conversation name', '');
      expect(emitted!.config.conversationTitle, isNull);
    });

    testWidgets('a node that neither opens nor joins a room shows neither', (
      tester,
    ) async {
      final step = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: _allSteps(step),
          workspaceAgents: const [],
          workspaceRepos: const [],
          onChange: (_) {},
          onDelete: () {},
        ),
      );

      expect(find.text('Space name'), findsNothing);
      expect(find.text('Conversation name'), findsNothing);
    });
  });
}

/// Enters text into the branch field sitting beside [repoLabel] in the repo
/// scope's per-repo row.
Future<void> _enterRepoBranch(
  WidgetTester tester,
  String repoLabel,
  String text,
) async {
  final row = find
      .ancestor(of: find.text(repoLabel), matching: find.byType(Row))
      .first;
  final editable = find.descendant(of: row, matching: find.byType(EditableText));
  await tester.showKeyboard(editable);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

/// The "open a conversation" checkbox — the one in the same row as its label,
/// so it is not confused with the advanced section's continue-on-fail box.
CcCheckbox _conversationCheckbox(WidgetTester tester) {
  final row = find
      .ancestor(
        of: find.text('Open a conversation in it'),
        matching: find.byType(Row),
      )
      .first;
  return tester.widget<CcCheckbox>(
    find.descendant(of: row, matching: find.byType(CcCheckbox)),
  );
}
