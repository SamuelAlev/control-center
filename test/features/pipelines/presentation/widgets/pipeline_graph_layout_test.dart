import 'dart:ui' show Offset, Rect;

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const double _nodeWidth = 180;
const double _nodeHeight = 68;

PipelineStepDefinition _step({
  required String id,
  required StepKind kind,
  List<String> after = const [],
  double? x,
  double? y,
}) {
  return PipelineStepDefinition(
    id: id,
    kind: kind,
    bodyKey: 'body_$id',
    triggers: after.isEmpty
        ? const []
        : [StepTrigger(sourceStepIds: after)],
    config: PipelineNodeConfig(label: id),
    x: x,
    y: y,
  );
}

Map<String, Offset> _layout(List<PipelineStepDefinition> steps) =>
    PipelineGraphLayout.compute(
      steps,
      nodeWidth: _nodeWidth,
      nodeHeight: _nodeHeight,
    );

Rect _rect(Offset topLeft) =>
    Rect.fromLTWH(topLeft.dx, topLeft.dy, _nodeWidth, _nodeHeight);

/// Asserts no two node tiles overlap (touching edges are allowed).
void _expectNoOverlaps(Map<String, Offset> positions) {
  final entries = positions.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = _rect(entries[i].value);
      final b = _rect(entries[j].value);
      final intersection = a.intersect(b);
      final overlaps = intersection.width > 0.001 && intersection.height > 0.001;
      expect(
        overlaps,
        isFalse,
        reason: '${entries[i].key} ($a) overlaps ${entries[j].key} ($b)',
      );
    }
  }
}

void main() {
  group('PipelineGraphLayout', () {
    test('empty graph yields no positions', () {
      expect(_layout(const []), isEmpty);
    });

    test('linear chain lays out left-to-right with the trigger leftmost', () {
      final positions = _layout([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'a', kind: StepKind.listen, after: ['trigger']),
        _step(id: 'b', kind: StepKind.listen, after: ['a']),
      ]);

      _expectNoOverlaps(positions);
      // Trigger is the minimum x of the whole graph.
      final minX = positions.values.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      expect(positions['trigger']!.dx, minX);
      // Strictly increasing columns down the chain.
      expect(positions['a']!.dx, greaterThan(positions['trigger']!.dx));
      expect(positions['b']!.dx, greaterThan(positions['a']!.dx));
    });

    test('fan-out siblings share a column but never overlap', () {
      final positions = _layout([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'a', kind: StepKind.listen, after: ['trigger']),
        _step(id: 'b', kind: StepKind.listen, after: ['trigger']),
        _step(id: 'c', kind: StepKind.listen, after: ['trigger']),
      ]);

      _expectNoOverlaps(positions);
      // Same depth → same column (x), distinct rows (y).
      expect(positions['a']!.dx, positions['b']!.dx);
      expect(positions['b']!.dx, positions['c']!.dx);
      final ys = {positions['a']!.dy, positions['b']!.dy, positions['c']!.dy};
      expect(ys.length, 3);
    });

    test('ignores overlapping stored coordinates and recomputes a clean layout', () {
      // Mirrors the built-in meeting-summary template: columns packed closer
      // (130) than the node width (180), which overlapped before auto-layout.
      final positions = _layout([
        _step(id: 'trigger', kind: StepKind.trigger, x: -390, y: 120),
        _step(id: 'diarize', kind: StepKind.listen, after: ['trigger'], x: -260, y: 120),
        _step(id: 'identify', kind: StepKind.listen, after: ['diarize'], x: -130, y: 120),
        _step(id: 'summarize', kind: StepKind.listen, after: ['identify'], x: 0, y: 120),
        _step(id: 'save', kind: StepKind.listen, after: ['summarize'], x: 260, y: 0),
        _step(id: 'actions', kind: StepKind.listen, after: ['summarize'], x: 260, y: 120),
        _step(id: 'decisions', kind: StepKind.listen, after: ['summarize'], x: 260, y: 240),
      ]);

      _expectNoOverlaps(positions);
      final minX = positions.values.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      expect(positions['trigger']!.dx, minX);
    });

    test('breaks cycles without looping forever', () {
      final positions = _layout([
        _step(id: 'trigger', kind: StepKind.trigger),
        _step(id: 'a', kind: StepKind.listen, after: ['trigger', 'b']),
        _step(id: 'b', kind: StepKind.listen, after: ['a']),
      ]);

      expect(positions.keys, containsAll(['trigger', 'a', 'b']));
      _expectNoOverlaps(positions);
    });
  });
}
