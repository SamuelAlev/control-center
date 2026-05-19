import 'package:cc_domain/features/pr_review/domain/services/cohort_layer_planner.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:test/test.dart';

void main() {
  const planner = CohortLayerPlanner();

  List<String> pathsOf(List<CohortLayer> layers) => [
    for (final l in layers) l.filePath,
  ];

  group('CohortLayerPlanner', () {
    test('returns nothing for no files', () {
      expect(planner.plan(filePaths: const []), isEmpty);
    });

    test('foundations read before their consumers', () {
      // handler depends on model → model is foundational and reads first.
      final layers = planner.plan(
        filePaths: const ['lib/handler.dart', 'lib/model.dart'],
        links: const [(a: 'lib/handler.dart', b: 'lib/model.dart')],
      );
      expect(pathsOf(layers), ['lib/model.dart', 'lib/handler.dart']);
    });

    test('orders a three-level chain foundation-first', () {
      final layers = planner.plan(
        filePaths: const ['lib/a.dart', 'lib/b.dart', 'lib/c.dart'],
        links: const [
          (a: 'lib/a.dart', b: 'lib/b.dart'),
          (a: 'lib/b.dart', b: 'lib/c.dart'),
        ],
      );
      expect(pathsOf(layers), ['lib/c.dart', 'lib/b.dart', 'lib/a.dart']);
    });

    test('tests read last even when nothing depends on them', () {
      final layers = planner.plan(
        filePaths: const ['test/auth_test.dart', 'lib/auth.dart'],
        links: const [(a: 'test/auth_test.dart', b: 'lib/auth.dart')],
      );
      expect(pathsOf(layers), ['lib/auth.dart', 'test/auth_test.dart']);
    });

    test('tests read last even when they are graph foundations', () {
      // Pathological: production code "depends on" the test file. Tests still
      // read last — reading the assertion first teaches nothing.
      final layers = planner.plan(
        filePaths: const ['lib/auth.dart', 'test/auth_test.dart'],
        links: const [(a: 'lib/auth.dart', b: 'test/auth_test.dart')],
      );
      expect(pathsOf(layers), ['lib/auth.dart', 'test/auth_test.dart']);
    });

    test('a dependency cycle still yields a stable, total order', () {
      final first = planner.plan(
        filePaths: const ['lib/a.dart', 'lib/b.dart'],
        links: const [
          (a: 'lib/a.dart', b: 'lib/b.dart'),
          (a: 'lib/b.dart', b: 'lib/a.dart'),
        ],
      );
      final second = planner.plan(
        filePaths: const ['lib/b.dart', 'lib/a.dart'],
        links: const [
          (a: 'lib/b.dart', b: 'lib/a.dart'),
          (a: 'lib/a.dart', b: 'lib/b.dart'),
        ],
      );
      expect(pathsOf(first), pathsOf(second));
      expect(pathsOf(first), hasLength(2));
    });

    test('ignores links that leave the cohort', () {
      final layers = planner.plan(
        filePaths: const ['lib/a.dart'],
        links: const [(a: 'lib/a.dart', b: 'lib/elsewhere.dart')],
      );
      expect(pathsOf(layers), ['lib/a.dart']);
    });

    test('titles and anchors a layer from the dominant symbol', () {
      final layers = planner.plan(
        filePaths: const ['lib/auth.dart'],
        dominantSymbolByFile: const {'lib/auth.dart': 'AuthService'},
        dominantSpanByFile: const {'lib/auth.dart': (start: 10, end: 80)},
      );
      expect(layers.single.title, 'AuthService');
      expect(layers.single.startLine, 10);
      expect(layers.single.endLine, 80);
      expect(layers.single.hasRange, isTrue);
    });

    test('falls back to the basename with no range when unindexed', () {
      final layers = planner.plan(filePaths: const ['lib/nested/auth.dart']);
      expect(layers.single.title, 'auth.dart');
      expect(layers.single.hasRange, isFalse);
    });

    test('deduplicates and is order-independent on its input', () {
      final a = planner.plan(
        filePaths: const ['lib/b.dart', 'lib/a.dart', 'lib/a.dart'],
      );
      final b = planner.plan(filePaths: const ['lib/a.dart', 'lib/b.dart']);
      expect(pathsOf(a), pathsOf(b));
      expect(a, hasLength(2));
    });
  });
}
