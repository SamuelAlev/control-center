import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_edge_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineStepDefinition _step({
  required String id,
  double x = 0,
  double y = 0,
  List<StepTrigger> triggers = const [],
}) => PipelineStepDefinition(
  id: id,
  kind: StepKind.listen,
  bodyKey: 'body_$id',
  triggers: triggers,
  config: const PipelineNodeConfig(),
  x: x,
  y: y,
);

const Map<String, double> _widths = {'a': 220, 'b': 220, 'c': 220, 'd': 220};
const double _height = 72;

void main() {
  group('PipelineEdgeGeometryCache', () {
    test('resolves one wire per trigger source, at the two port centres', () {
      final cache = PipelineEdgeGeometryCache();
      final segments = cache.sync(
        steps: [
          _step(id: 'a'),
          _step(
            id: 'b',
            x: 240,
            triggers: const [
              StepTrigger(sourceStepIds: ['a']),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
      );

      expect(segments, hasLength(1));
      expect(segments.single.fromId, 'a');
      expect(segments.single.toId, 'b');
      // a's output port, then b's input port.
      expect(segments.single.start, const Offset(220, 36));
      expect(segments.single.end, const Offset(240, 36));
      expect(cache.lastRebuiltCount, 1);
    });

    test('reuses every wire — and the whole list — when nothing moved', () {
      final cache = PipelineEdgeGeometryCache();
      final steps = [
        _step(id: 'a'),
        _step(
          id: 'b',
          x: 240,
          triggers: const [
            StepTrigger(sourceStepIds: ['a']),
          ],
        ),
      ];

      final first = cache.sync(
        steps: steps,
        nodeWidths: _widths,
        nodeHeight: _height,
      );
      final again = cache.sync(
        steps: steps,
        nodeWidths: _widths,
        nodeHeight: _height,
      );

      expect(cache.lastRebuiltCount, 0);
      expect(identical(again, first), isTrue);
    });

    test('moving one node rebuilds only its incident wires', () {
      final cache = PipelineEdgeGeometryCache();
      cache.sync(
        steps: [
          _step(id: 'a'),
          _step(
            id: 'b',
            x: 240,
            triggers: const [
              StepTrigger(sourceStepIds: ['a']),
            ],
          ),
          _step(id: 'c', y: 200),
          _step(
            id: 'd',
            x: 240,
            y: 200,
            triggers: const [
              StepTrigger(sourceStepIds: ['c']),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
      );
      expect(cache.lastRebuiltCount, 2);

      final segments = cache.sync(
        steps: [
          _step(id: 'a'),
          _step(
            id: 'b',
            x: 320,
            triggers: const [
              StepTrigger(sourceStepIds: ['a']),
            ],
          ),
          _step(id: 'c', y: 200),
          _step(
            id: 'd',
            x: 240,
            y: 200,
            triggers: const [
              StepTrigger(sourceStepIds: ['c']),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
      );

      expect(cache.lastRebuiltCount, 1);
      expect(
        segments.firstWhere((s) => s.toId == 'b').end,
        const Offset(320, 36),
      );
      // The unrelated wire never left its node.
      expect(
        segments.firstWhere((s) => s.toId == 'd').end,
        const Offset(240, 236),
      );
    });

    test('honours supplied positions over stored coordinates', () {
      final cache = PipelineEdgeGeometryCache();
      final segments = cache.sync(
        steps: [
          _step(id: 'a', x: 9_000),
          _step(
            id: 'b',
            x: 9_000,
            triggers: const [
              StepTrigger(sourceStepIds: ['a']),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
        positions: const {'a': Offset(0, 0), 'b': Offset(240, 0)},
      );

      expect(segments.single.start, const Offset(220, 36));
      expect(segments.single.end, const Offset(240, 36));
    });

    test('a rewritten route label is a new wire, not a stale one', () {
      final cache = PipelineEdgeGeometryCache();
      final a = _step(id: 'a');

      final approved = cache.sync(
        steps: [
          a,
          _step(
            id: 'b',
            x: 240,
            triggers: const [
              StepTrigger(sourceStepIds: ['a'], routeKey: 'approved'),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
      );
      expect(approved.single.routeKey, 'approved');

      final rejected = cache.sync(
        steps: [
          a,
          _step(
            id: 'b',
            x: 240,
            triggers: const [
              StepTrigger(sourceStepIds: ['a'], routeKey: 'rejected'),
            ],
          ),
        ],
        nodeWidths: _widths,
        nodeHeight: _height,
      );

      expect(rejected, hasLength(1));
      expect(rejected.single.routeKey, 'rejected');
      expect(cache.lastRebuiltCount, 1);
    });

    test(
      'a deleted node takes its wires — and its dangling edges — with it',
      () {
        final cache = PipelineEdgeGeometryCache();
        expect(
          cache.sync(
            steps: [
              _step(id: 'a'),
              _step(
                id: 'b',
                x: 240,
                triggers: const [
                  StepTrigger(sourceStepIds: ['a']),
                ],
              ),
              _step(
                id: 'c',
                x: 480,
                triggers: const [
                  StepTrigger(sourceStepIds: ['b']),
                ],
              ),
            ],
            nodeWidths: _widths,
            nodeHeight: _height,
          ),
          hasLength(2),
        );

        // `b` is gone. `c` still names it, and that edge must not survive: a
        // kept wire would still draw and still hit-test.
        final segments = cache.sync(
          steps: [
            _step(id: 'a'),
            _step(
              id: 'c',
              x: 480,
              triggers: const [
                StepTrigger(sourceStepIds: ['b']),
              ],
            ),
          ],
          nodeWidths: _widths,
          nodeHeight: _height,
        );

        expect(segments, isEmpty);
        expect(cache.lastRebuiltCount, 0);
      },
    );
  });

  group('PipelineEdgesPainter repaint', () {
    final a = _step(id: 'a');
    final b = _step(
      id: 'b',
      x: 240,
      triggers: const [
        StepTrigger(sourceStepIds: ['a']),
      ],
    );

    PipelineEdgesPainter painter(List<PipelineStepDefinition> steps) =>
        PipelineEdgesPainter(
          steps: steps,
          color: const Color(0xFF102030),
          nodeWidths: _widths,
          nodeHeight: _height,
          offset: const Offset(40, 40),
          positions: const {},
        );

    test('an equal rebuild does not repaint', () {
      // The canvases hand the painter a freshly built list on every hover and
      // every pointer move; none of those may repaint a wire.
      expect(painter([a, b]).shouldRepaint(painter([a, b])), isFalse);
    });

    test('a moved node repaints', () {
      final moved = _step(
        id: 'b',
        x: 300,
        triggers: const [
          StepTrigger(sourceStepIds: ['a']),
        ],
      );

      expect(painter([a, moved]).shouldRepaint(painter([a, b])), isTrue);
    });
  });
}
