import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_run_screen.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// Helper: a minimal pipeline definition for testing.
PipelineDefinition _pipeline({
  String templateId = 'test-template',
  String name = 'Test Pipeline',
  String? description,
  List<PipelineInput> inputs = const [],
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: 'ws-1',
    name: name,
    description: description,
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
    ],
    inputs: inputs,
    isEnabled: true,
  );
}

/// Helper: a minimal repo for testing.
Repo _repo({
  String id = 'repo-1',
  String name = 'test/repo',
  String path = '/home/user/repo',
}) {
  return Repo(
    id: id,
    name: name,
    path: path,
    githubOwner: 'test',
    githubRepoName: 'repo',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// A test-only ActiveWorkspaceIdNotifier that returns a fixed workspace ID.
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

/// Helper: wrap the screen with provider overrides.
Widget _wrap({
  required AsyncValue<List<PipelineDefinition>> pipelines,
  List<Repo> repos = const [],
  String? workspaceId,
  String? initialTemplateId,
}) {
  final overrides = [
    manuallyRunnablePipelinesProvider('ws-1').overrideWith(
      (ref) => pipelines,
    ),
    reposForWorkspaceProvider('ws-1').overrideWith(
      (ref) => Stream.value(repos),
    ),
    if (workspaceId == null)
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new)
    else
      activeWorkspaceIdProvider.overrideWith(
        () => _FixedWorkspaceIdNotifier(workspaceId),
      ),
  ];

  return ProviderScope(
    overrides: overrides,
    child: testWrap(PipelineRunScreen(initialTemplateId: initialTemplateId)),
  );
}

void main() {
  group('PipelineRunScreen', () {
    // ── Loading ──────────────────────────────────────────────────────────

    testWidgets('shows a loading indicator while data is loading',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: const AsyncValue.loading(),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Run pipeline'), findsOneWidget);
      expect(
        find.text('Pick a pipeline and fill in its inputs to start a run.'),
        findsOneWidget,
      );
    });

    // ── Error ────────────────────────────────────────────────────────────

    testWidgets('shows error text when loading fails', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: const AsyncValue.error('Kaboom', StackTrace.empty),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.textContaining('Failed to load pipelines'), findsOneWidget);
      expect(find.textContaining('Kaboom'), findsOneWidget);
    });

    // ── No workspace ─────────────────────────────────────────────────────

    testWidgets(
        'shows no-active-workspace message when workspaceId is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(pipelines: const AsyncValue.loading()),
      );
      await tester.pump();

      expect(
        find.text('Select a workspace to view its pipelines'),
        findsOneWidget,
      );
    });

    // ── Empty ────────────────────────────────────────────────────────────

    testWidgets('shows empty state when no pipelines are runnable',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: const AsyncValue.data([]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('No pipelines ready to run'), findsOneWidget);
      expect(
        find.text(
          'Enable a pipeline and turn on manual run in its editor to launch it here.',
        ),
        findsOneWidget,
      );
      expect(find.text('Manage pipelines'), findsOneWidget);
    });

    // ── Populated: one pipeline ──────────────────────────────────────────

    testWidgets('renders pipeline list, run form, and run button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([_pipeline()]),
          workspaceId: 'ws-1',
        ),
      );

      // Pipeline name in sidebar tile AND form header.
      expect(find.text('Test Pipeline'), findsNWidgets(2));

      // No-inputs badge.
      expect(find.text('No inputs'), findsOneWidget);

      // The form says "This pipeline takes no inputs."
      expect(find.text('This pipeline takes no inputs.'), findsOneWidget);

      // Run pipeline appears as page title AND run button.
      expect(find.text('Run pipeline'), findsNWidgets(2));
    });

    testWidgets('renders multiple pipelines in the sidebar', (tester) async {
      final pipelines = [
        _pipeline(templateId: 'tmpl-a', name: 'Alpha'),
        _pipeline(templateId: 'tmpl-b', name: 'Beta'),
        _pipeline(templateId: 'tmpl-c', name: 'Gamma'),
      ];

      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data(pipelines),
          workspaceId: 'ws-1',
        ),
      );

      // Alpha is auto-selected (first), appears in sidebar AND form.
      expect(find.text('Alpha'), findsNWidgets(2));
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });

    testWidgets('pre-selects the pipeline matching initialTemplateId',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(templateId: 'tmpl-a', name: 'Alpha'),
            _pipeline(templateId: 'tmpl-b', name: 'Beta'),
          ]),
          workspaceId: 'ws-1',
          initialTemplateId: 'tmpl-b',
        ),
      );

      // Beta is pre-selected — appears in sidebar AND form header.
      expect(find.text('Beta'), findsNWidgets(2));

      // Alpha's tile uses templateId as description.
      expect(find.text('tmpl-a'), findsOneWidget);
    });

    testWidgets('pre-selects first pipeline when initialTemplateId is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(templateId: 'tmpl-a', name: 'Alpha'),
            _pipeline(templateId: 'tmpl-b', name: 'Beta'),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Alpha appears in both sidebar tile and form header.
      expect(find.text('Alpha'), findsNWidgets(2));
    });

    testWidgets('pre-selects first pipeline when initialTemplateId is unknown',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(templateId: 'tmpl-a', name: 'Alpha'),
            _pipeline(templateId: 'tmpl-b', name: 'Beta'),
          ]),
          workspaceId: 'ws-1',
          initialTemplateId: 'tmpl-unknown',
        ),
      );

      // Falls back to first → Alpha in sidebar and form.
      expect(find.text('Alpha'), findsNWidgets(2));
    });

    testWidgets('clicking a pipeline tile switches selection', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(templateId: 'tmpl-a', name: 'Alpha'),
            _pipeline(templateId: 'tmpl-b', name: 'Beta'),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Initially Alpha selected in form.
      expect(find.text('Alpha'), findsNWidgets(2));
      expect(find.text('Beta'), findsOneWidget); // sidebar only

      // Tap on Beta's tile in the sidebar.
      await tester.tap(find.text('Beta').last);
      await tester.pump();

      // Now Beta in form header too.
      expect(find.text('Beta'), findsNWidgets(2));
      // Alpha remains only in sidebar.
      expect(find.text('Alpha'), findsOneWidget);
    });

    // ── Form: inputs count badge ─────────────────────────────────────────

    testWidgets('shows input count badge for pipelines with inputs',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(key: 'x', label: 'X'),
              PipelineInput(key: 'y', label: 'Y'),
              PipelineInput(key: 'z', label: 'Z'),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('3 inputs'), findsOneWidget);
    });

    testWidgets('shows singular input count', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(key: 'x', label: 'X'),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('1 input'), findsOneWidget);
    });

    // ── Form: text input ─────────────────────────────────────────────────

    testWidgets('renders text input fields', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(key: 'name', label: 'Name', required: true),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Name *'), findsOneWidget);
      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('Run button enabled state — required field empty vs filled',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(key: 'name', label: 'Name', required: true),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Initially disabled: required field is empty.
      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);

      // Type into the text field.
      await tester.enterText(find.byType(EditableText), 'hello');
      await tester.pump();

      // Now enabled.
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Form: number input validation ────────────────────────────────────

    testWidgets(
        'Run button stays disabled when required number field is non-numeric',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'count',
                label: 'Count',
                type: PipelineInputType.number,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Type non-numeric text.
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();

      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);
    });

    testWidgets('Run button enables when required number field is valid',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'count',
                label: 'Count',
                type: PipelineInputType.number,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      await tester.enterText(find.byType(EditableText), '42');
      await tester.pump();

      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Form: boolean input ──────────────────────────────────────────────

    testWidgets('renders boolean toggle inputs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'verbose',
                label: 'Verbose',
                type: PipelineInputType.boolean,
                helpText: 'Enable verbose logging',
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Verbose'), findsOneWidget);
      expect(find.text('Enable verbose logging'), findsOneWidget);
    });

    testWidgets('Run button is enabled for boolean-only inputs',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'verbose',
                label: 'Verbose',
                type: PipelineInputType.boolean,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // A required boolean is always satisfied (default false).
      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Form: select input ───────────────────────────────────────────────

    testWidgets('renders select dropdown inputs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'env',
                label: 'Environment',
                type: PipelineInputType.select,
                required: true,
                options: ['dev', 'staging', 'prod'],
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Environment *'), findsOneWidget);
    });

    testWidgets('Run button is disabled when required select has no value',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'env',
                label: 'Environment',
                type: PipelineInputType.select,
                required: true,
                options: ['dev', 'staging', 'prod'],
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);
    });

    // ── Form: repo input ─────────────────────────────────────────────────

    testWidgets('renders repo selector when repos are available',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'repository',
                label: 'Repository',
                type: PipelineInputType.repo,
                required: true,
              ),
            ]),
          ]),
          repos: [_repo()],
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Repository *'), findsOneWidget);
    });

    testWidgets('shows no-repos message when repos list is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'repository',
                label: 'Repository',
                type: PipelineInputType.repo,
                required: true,
              ),
            ]),
          ]),
          repos: const [],
          workspaceId: 'ws-1',
        ),
      );

      expect(
        find.text('No repositories in this workspace yet.'),
        findsOneWidget,
      );

      // Run button should be disabled since no repo is available.
      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);
    });

    // ── Form: multiline input ────────────────────────────────────────────

    testWidgets('renders multiline text input', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'body',
                label: 'Body',
                type: PipelineInputType.multiline,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Body *'), findsOneWidget);
      expect(find.byType(CcTextArea), findsOneWidget);
    });

    // ── Form: placeholder and helpText ───────────────────────────────────

    testWidgets('renders input placeholder text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'email',
                label: 'Email',
                placeholder: 'user@example.com',
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      final field = tester.widget<CcTextField>(find.byType(CcTextField));
      expect(field.hintText, 'user@example.com');
    });

    testWidgets('renders input help text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'email',
                label: 'Email',
                helpText: 'Your email address',
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Your email address'), findsOneWidget);
    });

    // ── Pipeline description ─────────────────────────────────────────────

    testWidgets('shows pipeline description in sidebar tile only',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(
              name: 'My Pipe',
              description: 'Does something useful',
            ),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Description appears in both sidebar tile and form area.
      expect(find.text('Does something useful'), findsNWidgets(2));
    });

    testWidgets('falls back to templateId as description', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([_pipeline()]),
          workspaceId: 'ws-1',
        ),
      );

      // When description is null, the tile shows templateId.
      expect(find.text('test-template'), findsOneWidget);
    });

    // ── Back button ──────────────────────────────────────────────────────

    testWidgets('renders a Back button in the header', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([_pipeline()]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Back'), findsOneWidget);
    });

    // ── Header always visible ────────────────────────────────────────────

    testWidgets('shows title and subtitle in all states', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: const AsyncValue.data([]),
          workspaceId: 'ws-1',
        ),
      );

      expect(find.text('Run pipeline'), findsOneWidget);
      expect(
        find.text('Pick a pipeline and fill in its inputs to start a run.'),
        findsOneWidget,
      );
    });

    // ── Number: negative values valid ────────────────────────────────────

    testWidgets('Run button enables for negative number input',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'offset',
                label: 'Offset',
                type: PipelineInputType.number,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      await tester.enterText(find.byType(EditableText), '-5');
      await tester.pump();

      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Number: decimal values valid ─────────────────────────────────────

    testWidgets('Run button enables for decimal number input',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'ratio',
                label: 'Ratio',
                type: PipelineInputType.number,
                required: true,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      await tester.enterText(find.byType(EditableText), '3.14');
      await tester.pump();

      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Form: mixed input types ──────────────────────────────────────────

    testWidgets('renders and validates form with mixed input types',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(key: 'title', label: 'Title', required: true),
              PipelineInput(
                key: 'count',
                label: 'Count',
                type: PipelineInputType.number,
                required: true,
              ),
              PipelineInput(
                key: 'verbose',
                label: 'Verbose',
                type: PipelineInputType.boolean,
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // All three input labels are visible.
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Count *'), findsOneWidget);
      expect(find.text('Verbose'), findsOneWidget);

      // Two text inputs (text + number) rendered.
      expect(find.byType(CcTextField), findsNWidgets(2));

      // Run button disabled: required text and number are empty.
      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);

      // Fill text field.
      await tester.enterText(find.byType(EditableText).first, 'my-title');
      await tester.pump();
      // Still disabled: number field still empty.
      expect(tester.widget<CcButton>(runFinder).onPressed, isNull);

      // Fill number field.
      await tester.enterText(find.byType(EditableText).last, '10');
      await tester.pump();
      // Now both required fields filled → enabled.
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Text: default value pre-filled ───────────────────────────────────

    testWidgets('text input is pre-filled from defaultValue', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'name',
                label: 'Name',
                required: true,
                defaultValue: 'pre-filled',
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Text field shows the default value.
      final field = tester.widget<CcTextField>(find.byType(CcTextField));
      expect(field.controller?.text, 'pre-filled');

      // Run button is enabled since the required field has a value.
      final runFinder = find.widgetWithText(CcButton, 'Run pipeline');
      expect(tester.widget<CcButton>(runFinder).onPressed, isNotNull);
    });

    // ── Select: multiple options visible ─────────────────────────────────

    testWidgets('select dropdown shows all options', (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'env',
                label: 'Environment',
                type: PipelineInputType.select,
                required: true,
                options: ['dev', 'staging', 'prod'],
              ),
            ]),
          ]),
          workspaceId: 'ws-1',
        ),
      );

      // Label is rendered.
      expect(find.text('Environment *'), findsOneWidget);

      // Tap the CcSelect to open the dropdown.
      await tester.tap(find.byType(CcSelect<String>));
      await tester.pumpAndSettle();

      // All three options appear in the dropdown.
      expect(find.text('dev'), findsOneWidget);
      expect(find.text('staging'), findsOneWidget);
      expect(find.text('prod'), findsOneWidget);

      // Close the popover by tapping outside (on the Run button area).
      await tester.tapAt(const Offset(400, 500));
      await tester.pumpAndSettle();

      // After closing, dropdown options are no longer visible.
      expect(find.text('dev'), findsNothing);
    });

    // ── Repo: multiple repos selectable ──────────────────────────────────

    testWidgets('repo selector renders all repos for selection',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([
            _pipeline(inputs: [
              PipelineInput(
                key: 'repository',
                label: 'Repository',
                type: PipelineInputType.repo,
                required: true,
              ),
            ]),
          ]),
          repos: [
            _repo(id: 'r1', name: 'alpha/repo'),
            _repo(id: 'r2', name: 'beta/lib'),
          ],
          workspaceId: 'ws-1',
        ),
      );
      // Allow stream-based repos provider to emit.
      await tester.pump();
      // Tap the CcSelect to open the dropdown.
      await tester.tap(find.byType(CcSelect<String>));
      await tester.pumpAndSettle();
      // Both repo names appear as options.
      expect(find.text('alpha/repo'), findsOneWidget);
      expect(find.text('beta/lib'), findsOneWidget);
    });

    // ── Empty workspace overrides pipeline data ──────────────────────────

    testWidgets(
        'shows no-workspace message when workspace is null even with pipelines',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          pipelines: AsyncValue.data([_pipeline()]),
        ),
      );
      await tester.pump();

      expect(
        find.text('Select a workspace to view its pipelines'),
        findsOneWidget,
      );

      // Pipeline names are NOT rendered (workspace check short-circuits).
      expect(find.text('Test Pipeline'), findsNothing);
    });
  });
}
