import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_canvas.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The template editor renders each step at its STORED `(x, y)` in a
/// fixed-size tile — unlike the run canvas, which throws the stored
/// coordinates away and derives a layered layout (`PipelineGraphLayout`). So a
/// seed whose columns are pitched closer together than the tile is wide draws
/// nodes on top of each other, and nothing else catches it: the definition is
/// structurally valid, every run works, and the only symptom is an unreadable
/// editor canvas. That is exactly how the meeting-summary seed regressed when
/// `identify_speakers` was slotted between `diarize` and `summarize` at a
/// 130px pitch against a 180px tile.
void main() {
  const workspaceId = 'ws-1';
  const agentIds = BuiltInAgentIds(
    qa: 'qa-id',
    architect: 'arch-id',
    engineer: 'eng-id',
    librarian: 'lib-id',
    ceo: 'ceo-id',
  );

  /// Breathing room required between two tiles on top of the tile size, so a
  /// seed can't pass by having its nodes exactly touch.
  const gap = 16.0;

  Rect tileOf(PipelineStepDefinition step) => Rect.fromLTWH(
    step.x ?? 0,
    step.y ?? 0,
    PipelineEditorCanvas.nodeWidth,
    PipelineEditorCanvas.nodeHeight,
  ).inflate(gap / 2);

  group('built-in template editor layout', () {
    final seeds = builtInTemplateSeeds(
      workspaceId: workspaceId,
      agentIds: agentIds,
    );

    for (final def in seeds) {
      test('${def.templateId} places no two nodes on top of each other', () {
        // Terminals are sentinels the canvases filter out before rendering.
        final nodes = def.steps
            .where((s) => s.kind != StepKind.terminal)
            .toList();

        for (var i = 0; i < nodes.length; i++) {
          for (var j = i + 1; j < nodes.length; j++) {
            final a = nodes[i];
            final b = nodes[j];
            expect(
              tileOf(a).overlaps(tileOf(b)),
              isFalse,
              reason:
                  '${def.templateId}: "${a.id}" at (${a.x}, ${a.y}) overlaps '
                  '"${b.id}" at (${b.x}, ${b.y}). Node tiles are '
                  '${PipelineEditorCanvas.nodeWidth}x'
                  '${PipelineEditorCanvas.nodeHeight}, so columns need at '
                  'least ${PipelineEditorCanvas.nodeWidth + gap} between them '
                  'and stacked rows at least '
                  '${PipelineEditorCanvas.nodeHeight + gap}.',
            );
          }
        }
      });
    }

    test('every renderable node carries explicit coordinates', () {
      // A missing x/y silently collapses to (0, 0), which is a guaranteed
      // overlap the check above would only catch by accident.
      for (final def in seeds) {
        for (final step in def.steps) {
          if (step.kind == StepKind.terminal) {
            continue;
          }
          expect(
            step.x,
            isNotNull,
            reason: '${def.templateId}: "${step.id}" has no x',
          );
          expect(
            step.y,
            isNotNull,
            reason: '${def.templateId}: "${step.id}" has no y',
          );
        }
      }
    });
  });
}
