import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  String bodyKey = 'pipeline.promptAgent',
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

/// Pumps [editor] into a test with a tall viewport so the ListView renders
/// all its children.
Future<void> _pumpEditor(WidgetTester tester, NodeConfigEditor editor) async {
  // Set a tall surface so the ListView renders all items.
  tester.view.physicalSize =
      Size(400 * tester.view.devicePixelRatio, 4000 * tester.view.devicePixelRatio);
  addTearDown(() => tester.view.resetPhysicalSize());
  await tester.pumpWidget(testWrap(editor));
  await tester.pumpAndSettle();
}

/// Enters text into the field labelled [labelText], using the inner
/// [EditableText] so that `enterText` works even for number and multiline
/// variants. The label and its field (a `CcTextField` or `CcTextArea`) are
/// siblings inside a `_Labeled` column, so we locate that column by walking up
/// from the label and then descend to the field's editable.
Future<void> _enterFTextField(
  WidgetTester tester,
  String labelText,
  String text,
) async {
  final labeled = find.ancestor(
    of: find.text(labelText),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Labeled',
    ),
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
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.textContaining('step-1'), findsWidgets);
    });

    testWidgets('renders delete button', (tester) async {
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('delete button calls onDelete', (tester) async {
      var deleted = false;
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () => deleted = true,
      ));

      final trashIcon = find.byIcon(LucideIcons.trash2);
      await tester.tap(find.ancestor(
        of: trashIcon,
        matching: find.byType(CcButton),
      ).first);
      // Let the tappable timer fire
      await tester.pump(const Duration(milliseconds: 150));
      expect(deleted, true);
    });

    // -----------------------------------------------------------------------
    // Rendering: common fields (all bodyKey types)
    // -----------------------------------------------------------------------

    testWidgets('shows label field', (tester) async {
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Label'), findsOneWidget);
    });

    testWidgets('shows input keys field', (tester) async {
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Input keys (comma-separated)'), findsOneWidget);
    });

    testWidgets('shows advanced section with all fields', (tester) async {
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

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

    testWidgets('promptAgent body shows agent select, prompt and output key',
        (tester) async {
      final agent = _agent();
      final step = _step(
        bodyKey: 'pipeline.promptAgent',
        config: PipelineNodeConfig(agentId: agent.id),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: [agent],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Agent'), findsOneWidget);
      expect(find.text('Prompt template'), findsOneWidget);
      expect(find.text('Output key'), findsOneWidget);
    });

    testWidgets('bashScript body shows script but not agent/prompt',
        (tester) async {
      final step = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Bash script'), findsOneWidget);
      expect(find.text('Agent'), findsNothing);
      expect(find.text('Prompt template'), findsNothing);
      expect(find.text('Output key'), findsOneWidget);
    });

    testWidgets('condition body shows ConditionConfigEditor not output key',
        (tester) async {
      final step = _step(bodyKey: 'pipeline.condition');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Output key'), findsNothing);
    });

    testWidgets('team.dispatch body shows team id and dispatch mode',
        (tester) async {
      final step = _step(bodyKey: 'team.dispatch');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Team ID'), findsOneWidget);
      expect(find.text('Dispatch mode'), findsOneWidget);
    });

    testWidgets('generic body shows output key but no agent/prompt/script',
        (tester) async {
      final step = _step(bodyKey: 'some.other.body');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

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
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Kind'), findsOneWidget);
    });

    testWidgets('join kind shows kind selector', (tester) async {
      final step = _step(kind: StepKind.join);
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Kind'), findsOneWidget);
    });

    testWidgets('trigger kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.trigger);
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('router kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.router);
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('terminal kind does NOT show kind selector', (tester) async {
      final step = _step(kind: StepKind.terminal);
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Kind'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Rendering: triggers section
    // -----------------------------------------------------------------------

    testWidgets('shows triggers section with upstream candidates',
        (tester) async {
      final current = _step(id: 'step-2');
      final upstream = _step(id: 'step-1', kind: StepKind.listen);
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, upstream],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Triggers from'), findsOneWidget);
      expect(find.text('step-1'), findsWidgets);
    });

    testWidgets('shows no-upstream message when only step exists',
        (tester) async {
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('No other nodes to connect from.'), findsOneWidget);
    });

    testWidgets('excludes terminal steps from upstream candidates',
        (tester) async {
      final current = _step(id: 'step-2');
      final terminal = _step(id: 'step-1', kind: StepKind.terminal);
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, terminal],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('No other nodes to connect from.'), findsOneWidget);
    });

    testWidgets('trigger chip uses config label when available',
        (tester) async {
      final current = _step(id: 'step-2');
      final upstream = _step(
        id: 'step-1',
        kind: StepKind.listen,
        config: const PipelineNodeConfig(label: 'My Custom Name'),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, upstream],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('My Custom Name'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Form state: single-line field callbacks
    // -----------------------------------------------------------------------

    testWidgets('label field change emits updated step', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(label: 'old'));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Label', 'New Label');

      expect(updated, isNotNull);
      expect(updated!.config.label, 'New Label');
    });

    testWidgets('input keys field change emits with parsed keys',
        (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(
          tester, 'Input keys (comma-separated)', 'keyA, keyB , keyC');

      expect(updated, isNotNull);
      expect(updated!.config.inputKeys, ['keyA', 'keyB', 'keyC']);
    });

    testWidgets('output key field change emits output key', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Output key', 'myOutput');

      expect(updated!.config.outputKey, 'myOutput');
    });

    testWidgets('timeout field change emits parsed int', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Timeout (ms)', '5000');

      expect(updated!.config.timeoutMs, 5000);
    });

    testWidgets('invalid timeout text emits null timeout', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(timeoutMs: 1000));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Timeout (ms)', 'not-a-number');

      expect(updated!.config.timeoutMs, isNull);
    });

    testWidgets('retry attempts field change emits retry policy',
        (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Retry attempts', '3');

      expect(updated!.config.retryPolicy, isNotNull);
      expect(updated!.config.retryPolicy!.maxAttempts, 3);
    });

    testWidgets('invalid retry text emits null retry policy', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Retry attempts', 'abc');

      expect(updated!.config.retryPolicy, isNull);
    });

    testWidgets('empty label text emits null label', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(label: 'Has Label'));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Label', '   ');

      expect(updated!.config.label, isNull);
    });

    // -----------------------------------------------------------------------
    // Form state: checkbox
    // -----------------------------------------------------------------------

    testWidgets('continue on fail checkbox toggles on', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      final checkbox = find.byType(CcCheckbox);
      expect(checkbox, findsOneWidget);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      expect(updated, isNotNull);
      expect(updated!.config.continueOnFail, true);
    });

    testWidgets('continue on fail starts from config value', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(config: const PipelineNodeConfig(continueOnFail: true));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await tester.tap(find.byType(CcCheckbox));
      await tester.pumpAndSettle();

      expect(updated!.config.continueOnFail, false);
    });

    // -----------------------------------------------------------------------
    // Edge / trigger interactions
    // -----------------------------------------------------------------------

    testWidgets('tapping a trigger chip connects it and calls onChange',
        (tester) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-2');
      final upstream = _step(id: 'step-1');
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, upstream],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

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
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, upstream],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers, isNotEmpty);

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers, isEmpty);
    });

    testWidgets('shows route key editors for connected router sources',
        (tester) async {
      final router = _step(id: 'step-2', kind: StepKind.router);
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'pipeline.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [const StepTrigger(sourceStepIds: ['step-2'])],
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: stepWithEdge,
        allSteps: [router, stepWithEdge],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Route keys'), findsOneWidget);
    });

    testWidgets('route key field label includes upstream step label',
        (tester) async {
      final router = _step(
        id: 'step-2',
        kind: StepKind.router,
        config: const PipelineNodeConfig(label: 'My Router'),
      );
      final stepWithEdge = PipelineStepDefinition(
        id: 'step-3',
        kind: StepKind.listen,
        bodyKey: 'pipeline.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [const StepTrigger(sourceStepIds: ['step-2'])],
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: stepWithEdge,
        allSteps: [router, stepWithEdge],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.textContaining('My Router'), findsWidgets);
    });

    testWidgets('no route keys when router is not connected', (tester) async {
      final router = _step(id: 'step-2', kind: StepKind.router);
      final current = _step(id: 'step-3');
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, router],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Route keys'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Step ID change re-initializes controllers
    // -----------------------------------------------------------------------

    testWidgets('changing step id re-initializes form fields', (tester) async {
      final step1 = _step(
          id: 'step-1', config: const PipelineNodeConfig(label: 'First'));
      final step2 = _step(
          id: 'step-2', config: const PipelineNodeConfig(label: 'Second'));

      await _pumpEditor(tester, NodeConfigEditor(
        step: step1,
        allSteps: _allSteps(step1),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));
      expect(find.text('First'), findsOneWidget);

      await _pumpEditor(tester, NodeConfigEditor(
        step: step2,
        allSteps: _allSteps(step2),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Edge: join kind sets waitForStepIds
    // -----------------------------------------------------------------------

    testWidgets('join kind emits waitForStepIds from connected edges',
        (tester) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-3', kind: StepKind.join);
      final upstream = _step(id: 'step-1');
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, upstream],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();

      expect(updated!.kind, StepKind.join);
      expect(updated!.waitForStepIds, ['step-1']);
    });

    // -----------------------------------------------------------------------
    // Schema field: JSON validation
    // -----------------------------------------------------------------------

    testWidgets('schema field with valid JSON emits parsed schema',
        (tester) async {
      PipelineStepDefinition? updated;
      final step = _step();
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      final schema = {
        'type': 'object',
        'properties': {'name': {'type': 'string'}},
      };
      await _enterFTextField(
          tester, 'Output schema (JSON)', jsonEncode(schema));

      expect(updated, isNotNull);
      expect(updated!.config.outputSchema, schema);
    });

    testWidgets('empty schema field clears schema', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        config: const PipelineNodeConfig(outputSchema: {'type': 'object'}),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Output schema (JSON)', '');

      expect(updated!.config.outputSchema, isNull);
    });

    testWidgets('invalid JSON in schema does not crash widget', (tester) async {
      final step = _step(
        config: const PipelineNodeConfig(outputSchema: {'type': 'object'}),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Output schema (JSON)', '{invalid json');

      // Widget should still render
      expect(find.text('Output schema (JSON)'), findsOneWidget);
    });

    testWidgets('non-map JSON in schema preserves prior value', (tester) async {
      PipelineStepDefinition? updated;
      final prior = {'type': 'object'};
      final step = _step(config: PipelineNodeConfig(outputSchema: prior));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(
          tester, 'Output schema (JSON)', jsonEncode([1, 2, 3]));

      // Should keep prior value since decoded value is not a Map
      expect(updated!.config.outputSchema, prior);
    });

    // -----------------------------------------------------------------------
    // Multiple upstream candidates
    // -----------------------------------------------------------------------

    testWidgets('multiple upstream candidates all shown as chips',
        (tester) async {
      final current = _step(id: 'step-4');
      final up1 = _step(id: 'step-1');
      final up2 = _step(id: 'step-2');
      final up3 =
          _step(id: 'step-3', config: const PipelineNodeConfig(label: 'Third'));
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, up1, up2, up3],
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('step-1'), findsOneWidget);
      expect(find.text('step-2'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('connecting multiple upstream steps emits separate triggers',
        (tester) async {
      PipelineStepDefinition? updated;
      final current = _step(id: 'step-3');
      final up1 = _step(id: 'step-1');
      final up2 = _step(id: 'step-2');
      await _pumpEditor(tester, NodeConfigEditor(
        step: current,
        allSteps: [current, up1, up2],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await tester.tap(find.text('step-1'));
      await tester.pumpAndSettle();
      expect(updated!.triggers.length, 1);

      await tester.tap(find.text('step-2'));
      await tester.pumpAndSettle();
      expect(updated!.triggers.length, 2);

      final ids =
          updated!.triggers.expand((t) => t.sourceStepIds).toSet();
      expect(ids, {'step-1', 'step-2'});
    });

    // -----------------------------------------------------------------------
    // Agent select interaction
    // -----------------------------------------------------------------------

    testWidgets('agent select renders with workspace agents', (tester) async {
      final agent1 = _agent(id: 'agent-1', name: 'coder');
      final agent2 = _agent(id: 'agent-2', name: 'tester');
      final step = _step(
        bodyKey: 'pipeline.promptAgent',
        config: const PipelineNodeConfig(agentId: 'agent-1'),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: [agent1, agent2],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Agent'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Prompt field editing
    // -----------------------------------------------------------------------

    testWidgets('prompt field change emits prompt text', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'pipeline.promptAgent',
        config: const PipelineNodeConfig(prompt: 'Do the thing'),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Prompt template', 'Plan carefully');

      expect(updated, isNotNull);
      expect(updated!.config.prompt, 'Plan carefully');
    });

    testWidgets('empty prompt emits null prompt', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(
        bodyKey: 'pipeline.promptAgent',
        config: const PipelineNodeConfig(prompt: 'existing'),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Prompt template', '');

      expect(updated!.config.prompt, isNull);
    });

    // -----------------------------------------------------------------------
    // Script field editing
    // -----------------------------------------------------------------------

    testWidgets('script field change emits script text', (tester) async {
      PipelineStepDefinition? updated;
      final step = _step(bodyKey: 'pipeline.bashScript');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

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
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Bash script', '');

      expect(updated!.config.script, isNull);
    });

    // -----------------------------------------------------------------------
    // Reducer select rendering
    // -----------------------------------------------------------------------

    testWidgets('reducer select renders all options', (tester) async {
      await _pumpEditor(tester, NodeConfigEditor(
        step: _step(),
        allSteps: _allSteps(_step()),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

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
        bodyKey: 'pipeline.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [const StepTrigger(sourceStepIds: ['step-2'])],
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: stepWithEdge,
        allSteps: [router, stepWithEdge],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      final tf = find.byType(TextFormField);
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
        bodyKey: 'pipeline.promptAgent',
        config: PipelineNodeConfig.empty,
        triggers: [const StepTrigger(sourceStepIds: ['step-2'], routeKey: 'was-set')],
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: stepWithEdge,
        allSteps: [router, stepWithEdge],
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      final tf = find.byType(TextFormField);
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
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

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
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (s) => updated = s,
        onDelete: () {},
      ));

      await _enterFTextField(tester, 'Team ID', '   ');

      expect(updated!.config.teamId, isNull);
    });

    testWidgets('dispatch mode select renders', (tester) async {
      final step = _step(bodyKey: 'team.dispatch');
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Dispatch mode'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Config value initialisation
    // -----------------------------------------------------------------------

    testWidgets('timeout controller initialised from config', (tester) async {
      final step = _step(config: const PipelineNodeConfig(timeoutMs: 3000));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Timeout (ms)'), findsOneWidget);
    });

    testWidgets('retry attempts controller initialised from config',
        (tester) async {
      final step = _step(
        config: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 5),
        ),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Retry attempts'), findsOneWidget);
    });

    testWidgets('input keys controller initialised from config keys',
        (tester) async {
      final step = _step(
        config: const PipelineNodeConfig(inputKeys: ['a', 'b', 'c']),
      );
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Input keys (comma-separated)'), findsOneWidget);
    });

    testWidgets('output key controller initialised from config', (tester) async {
      final step = _step(config: const PipelineNodeConfig(outputKey: 'result'));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      expect(find.text('Output key'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Continue on fail checkbox
    // -----------------------------------------------------------------------

    testWidgets('continueOnFail checkbox renders correctly when true',
        (tester) async {
      final step = _step(config: const PipelineNodeConfig(continueOnFail: true));
      await _pumpEditor(tester, NodeConfigEditor(
        step: step,
        allSteps: _allSteps(step),
        workspaceAgents: const [],
        onChange: (_) {},
        onDelete: () {},
      ));

      final cbs = tester.widgetList<CcCheckbox>(find.byType(CcCheckbox));
      expect(cbs.isNotEmpty, isTrue);
    });
  });
}
