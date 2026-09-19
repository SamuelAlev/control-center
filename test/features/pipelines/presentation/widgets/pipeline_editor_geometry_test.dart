import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineStepDefinition _node({
  required String id,
  double x = 0,
  double y = 0,
}) {
  return PipelineStepDefinition(
    id: id,
    kind: StepKind.listen,
    bodyKey: 'body_$id',
    config: const PipelineNodeConfig(label: 'n'),
    x: x,
    y: y,
  );
}

void main() {
  test('extraTopLeft above or left of the graph does not rebase shift', () {
    final nodes = [_node(id: 'a')];
    const viewport = Size(800, 600);
    final base = computePipelineEditorScene(
      nodes: nodes,
      positionOverrides: const {},
      viewport: viewport,
    );
    final up = computePipelineEditorScene(
      nodes: nodes,
      positionOverrides: const {},
      viewport: viewport,
      extraTopLeft: const Offset(0, -240),
    );
    final left = computePipelineEditorScene(
      nodes: nodes,
      positionOverrides: const {},
      viewport: viewport,
      extraTopLeft: const Offset(-240, 0),
    );
    expect(up.shift, base.shift);
    expect(left.shift, base.shift);
  });

  test('shiftOverride wins over a computed shift', () {
    final nodes = [_node(id: 'a', x: -80, y: -40)];
    const viewport = Size(800, 600);
    const frozen = Offset(40, 40);
    final scene = computePipelineEditorScene(
      nodes: nodes,
      positionOverrides: const {},
      viewport: viewport,
      shiftOverride: frozen,
    );
    expect(scene.shift, frozen);
    final natural = computePipelineEditorScene(
      nodes: nodes,
      positionOverrides: const {},
      viewport: viewport,
    );
    expect(natural.shift, isNot(frozen));
  });
}
