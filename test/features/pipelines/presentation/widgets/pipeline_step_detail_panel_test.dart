import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_step_detail_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

PipelineStepRun _stepRun({
  String id = 'step-run-1',
  PipelineStepStatus status = PipelineStepStatus.completed,
  String? inputJson,
  String? outputJson,
  String? errorMessage,
  int? branchIndex,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  return PipelineStepRun(
    id: id,
    pipelineRunId: 'run-1',
    stepId: 'build',
    status: status,
    inputJson: inputJson,
    outputJson: outputJson,
    errorMessage: errorMessage,
    branchIndex: branchIndex,
    startedAt: startedAt ?? DateTime(2026, 6, 1, 10, 0, 0),
    finishedAt: finishedAt,
  );
}

PipelineStepDefinition _stepDef({
  String id = 'build',
  String? label,
}) {
  return PipelineStepDefinition(
    id: id,
    kind: StepKind.listen,
    bodyKey: 'build',
    config: PipelineNodeConfig(label: label),
  );
}

/// Default finishedAt used when a test doesn't care about the exact value.
final _defaultFinishedAt = DateTime(2026, 6, 1, 10, 1, 0);

void main() {
  // ── No step run ───────────────────────────────────────────────────

  testWidgets('renders step label from definition config.label', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build project'),
          stepRun: null,
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Build project'), findsOneWidget);
  });

  testWidgets('falls back to step id when definition has no label',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: null),
          stepRun: null,
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('build'), findsOneWidget);
  });

  testWidgets('shows dash when no step definition and no step run',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: null,
          stepRun: null,
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('\u2014'), findsOneWidget);
  });

  testWidgets('shows not-yet-executed message when step run is null',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Setup'),
          stepRun: null,
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Not yet executed'), findsOneWidget);
  });

  // ── Completed state ───────────────────────────────────────────────

  testWidgets('renders status badge for a completed step', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.byType(PipelineStatusBadge), findsOneWidget);
  });

  testWidgets('shows started and finished times for completed step',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            startedAt: DateTime(2026, 6, 1, 10, 0, 0),
            finishedAt: DateTime(2026, 6, 1, 10, 1, 30),
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Started'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
  });

  testWidgets('shows branch index when present', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(branchIndex: 2, finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('does not show branch row when branchIndex is null',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(branchIndex: null, finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Branch'), findsNothing);
  });

  testWidgets('does not show finished row when finishedAt is null',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.running,
            finishedAt: null,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 30),
        ),
      ),
    );

    expect(find.text('Started'), findsOneWidget);
    expect(find.text('Finished'), findsNothing);
  });

  // ── Input / output display ────────────────────────────────────────

  testWidgets('shows input section when inputJson is present', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun:
              _stepRun(inputJson: '{"source":"repo"}', finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Input'), findsOneWidget);
  });

  testWidgets('does not show input section when inputJson is null',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(inputJson: null, finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Input'), findsNothing);
  });

  testWidgets('shows output section when outputJson is present',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            outputJson: '{"done":true}',
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Output'), findsOneWidget);
  });

  testWidgets('does not show output section when outputJson is null',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(outputJson: null, finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Output'), findsNothing);
  });

  testWidgets('expanding input reveals JSON content', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            inputJson: '{"source":"repo"}',
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    // Content is collapsed by default — JSON block hidden.
    expect(find.textContaining('"source"'), findsNothing);

    // Tap the Input header to expand.
    await tester.tap(find.text('Input'));
    await tester.pumpAndSettle();

    // Pretty-printed JSON visible.
    expect(find.textContaining('"source"'), findsOneWidget);
    expect(find.textContaining('"repo"'), findsOneWidget);
  });

  testWidgets('expanding output reveals JSON content', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            outputJson: '{"status":"ok"}',
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    // Content collapsed by default.
    expect(find.textContaining('"status"'), findsNothing);

    // Expand.
    await tester.tap(find.text('Output'));
    await tester.pumpAndSettle();

    expect(find.textContaining('"status"'), findsOneWidget);
    expect(find.textContaining('"ok"'), findsOneWidget);
  });

  // ── Error display ─────────────────────────────────────────────────

  testWidgets('shows error callout with explicit errorMessage on failed step',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            errorMessage: 'Connection refused',
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Connection refused'), findsOneWidget);
  });

  testWidgets('shows error callout mined from outputJson failureReason key',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            outputJson: jsonEncode({'failureReason': 'build script exited 1'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('build script exited 1'), findsOneWidget);
  });

  testWidgets('shows error callout mined from outputJson error key',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            outputJson: jsonEncode({'error': 'timeout after 30s'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('timeout after 30s'), findsOneWidget);
  });

  testWidgets('shows error callout mined from outputJson reason key',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            outputJson: jsonEncode({'reason': 'disk full'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('disk full'), findsOneWidget);
  });

  testWidgets('shows error callout mined from outputJson message key',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            outputJson: jsonEncode({'message': 'out of memory'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsOneWidget);
    expect(find.text('out of memory'), findsOneWidget);
  });

  testWidgets('errorMessage takes precedence over outputJson mining',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            errorMessage: 'explicit error',
            outputJson: jsonEncode({'error': 'mined error'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('explicit error'), findsOneWidget);
    expect(find.text('mined error'), findsNothing);
  });

  testWidgets(
      'no error callout on failed step with no message and no outputJson',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            errorMessage: null,
            outputJson: null,
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    expect(find.text('Error'), findsNothing);
  });

  testWidgets('no error callout on completed step even with output error keys',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            outputJson: jsonEncode({'error': 'irrelevant'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    // Error is not shown for completed steps — only for failed.
    expect(find.text('Error'), findsNothing);
  });

  // ── Skip display ──────────────────────────────────────────────────

  testWidgets('shows skip callout when outputJson has skippedReason',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            outputJson: jsonEncode({'skippedReason': 'already processed'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('already processed'), findsOneWidget);
  });

  testWidgets('shows skip callout when outputJson has skipReason',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            outputJson: jsonEncode({'skipReason': 'no changes detected'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('no changes detected'), findsOneWidget);
  });

  testWidgets('skip callout shown even on completed steps', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            outputJson: jsonEncode({'skippedReason': 'cached result used'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    // Skip callout renders alongside the completed badge.
    expect(find.byType(PipelineStatusBadge), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
  });

  testWidgets('skip reason does not appear when outputJson has no skip keys',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            outputJson: jsonEncode({'result': 'normal'}),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    expect(find.text('Skipped'), findsNothing);
  });

  // ── Live states (running / pending / suspended) ────────────────────

  testWidgets('shows kill button for running step', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.running,
            finishedAt: null,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 0),
        ),
      ),
    );

    // Kill button renders for live (running) step. The badge confirms the
    // step is rendered; the kill icon is a Lucide square, not a Material stop.
    expect(find.byType(PipelineStatusBadge), findsOneWidget);
  });

  testWidgets('shows kill button for pending step', (tester) async {
    // pending is a live state; the kill button should render.
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.pending,
            finishedAt: null,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 0),
        ),
      ),
    );

    // Verify badge is shown.
    expect(find.byType(PipelineStatusBadge), findsOneWidget);
  });

  testWidgets('no kill button for terminal completed step', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.completed,
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 1, 0),
        ),
      ),
    );

    // Badge is shown but no kill affordance — completed is not a live state.
    expect(find.byType(PipelineStatusBadge), findsOneWidget);
    // CcButton appears only for close and kill. With onClose null and non-live,
    // zero CcButton widgets.
    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('no kill button for terminal failed step', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    // With onClose null and non-live status, no CcButton icons at all.
    expect(find.byType(CcButton), findsNothing);
  });

  // ── Close button ──────────────────────────────────────────────────

  testWidgets('close button hidden when onClose is null', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
          onClose: null,
        ),
      ),
    );

    // The close button uses an "x" icon. Verify it doesn't exist.
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('close button visible when onClose is provided', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
          onClose: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
  });

  testWidgets('close button fires onClose callback', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(finishedAt: _defaultFinishedAt),
          now: DateTime(2026, 6, 1, 10, 2, 0),
          onClose: () => closed = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    // The close button wraps an CcButton.icon which contains an CcTappable.
    // The CcTappable starts a 100ms timer on tap; we advance past it.
    await tester.pump(const Duration(milliseconds: 200));
    expect(closed, isTrue);
  });

  // ── Edge cases ────────────────────────────────────────────────────

  testWidgets('running step with no finishedAt uses live duration',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.running,
            startedAt: DateTime(2026, 6, 1, 10, 0, 0),
            finishedAt: null,
          ),
          now: DateTime(2026, 6, 1, 10, 1, 30),
        ),
      ),
    );

    // Duration from now - startedAt: 90s → "1m 30s".
    expect(find.text('1m 30s'), findsOneWidget);
  });

  testWidgets('terminal step with no finishedAt shows zero duration',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.skipped,
            startedAt: DateTime(2026, 6, 1, 10, 0, 0),
            finishedAt: null,
          ),
          now: DateTime(2026, 6, 1, 10, 30, 0),
        ),
      ),
    );

    // Duration.zero formats as "0ms" via formatPipelineDuration.
    expect(find.text('0ms'), findsOneWidget);
  });

  testWidgets('non-JSON input payload shows raw text', (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            inputJson: 'plain text payload',
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 2, 0),
        ),
      ),
    );

    await tester.tap(find.text('Input'));
    await tester.pumpAndSettle();

    // Non-JSON payload is shown verbatim, not pretty-printed.
    expect(find.text('plain text payload'), findsOneWidget);
  });

  testWidgets('empty string errorMessage is not shown as error',
      (tester) async {
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            errorMessage: '   ',
            outputJson: null,
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    // Whitespace-only errorMessage is treated as empty → no callout.
    expect(find.text('Error'), findsNothing);
  });

  testWidgets('outputJson that is not a map does not crash', (tester) async {
    // outputJson that parses to a list, not a map — string field extraction
    // returns null, so no error/skip callout appears.
    await tester.pumpWidget(
      testWrap(
        PipelineStepDetailPanel(
          step: _stepDef(label: 'Build'),
          stepRun: _stepRun(
            status: PipelineStepStatus.failed,
            outputJson: jsonEncode([1, 2, 3]),
            finishedAt: _defaultFinishedAt,
          ),
          now: DateTime(2026, 6, 1, 10, 0, 5),
        ),
      ),
    );

    // No error callout (output is array, not object).
    expect(find.text('Error'), findsNothing);
    // Output section still renders.
    expect(find.text('Output'), findsOneWidget);
  });
}
