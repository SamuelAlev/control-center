import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_stack_ordering.dart';
import 'package:test/test.dart';

PullRequest _pr(
  int number, {
  required String base,
  required String head,
  String repo = 'acme/cc',
  PrState state = PrState.open,
}) => PullRequest(
  id: number,
  number: number,
  title: 'PR $number',
  body: '',
  state: state,
  isDraft: false,
  author: null,
  createdAt: null,
  updatedAt: null,
  repoFullName: repo,
  htmlUrl: '',
  baseRef: base,
  headRef: head,
);

void main() {
  group('orderPrChain', () {
    test('orders a chain bottom-first regardless of input order', () {
      final layer1 = _pr(85, base: 'main', head: 'layer-1');
      final layer2 = _pr(86, base: 'layer-1', head: 'layer-2');
      final layer3 = _pr(87, base: 'layer-2', head: 'layer-3');

      final ordered = orderPrChain([layer3, layer1, layer2]);

      expect(ordered?.map((pr) => pr.number).toList(), [85, 86, 87]);
    });

    test('rejects a single PR', () {
      expect(orderPrChain([_pr(1, base: 'main', head: 'a')]), isNull);
    });

    test('rejects PRs with unenriched refs', () {
      final a = _pr(1, base: 'main', head: 'a');
      final b = PullRequest(
        id: 2,
        number: 2,
        title: 'PR 2',
        body: '',
        state: PrState.open,
        isDraft: false,
        author: null,
        createdAt: null,
        updatedAt: null,
        repoFullName: 'acme/cc',
        htmlUrl: '',
      );
      expect(orderPrChain([a, b]), isNull);
    });

    test('rejects two independent roots', () {
      final a = _pr(1, base: 'main', head: 'a');
      final b = _pr(2, base: 'develop', head: 'b');
      expect(orderPrChain([a, b]), isNull);
    });

    test('rejects a broken chain', () {
      final a = _pr(1, base: 'main', head: 'a');
      final b = _pr(2, base: 'somewhere-else', head: 'b');
      expect(orderPrChain([a, b]), isNull);
    });

    test('rejects a fork (two PRs based on the same head)', () {
      final bottom = _pr(1, base: 'main', head: 'a');
      final fork1 = _pr(2, base: 'a', head: 'b');
      final fork2 = _pr(3, base: 'a', head: 'c');
      expect(orderPrChain([bottom, fork1, fork2]), isNull);
    });
  });

  group('groupPrsByStack', () {
    test('separates repositories and unrelated roots, ordering each chain', () {
      final bottom = _pr(10, base: 'main', head: 'data');
      final top = _pr(9, base: 'data', head: 'ui');
      final unrelated = _pr(11, base: 'main', head: 'other');
      final secondBottom = _pr(
        10,
        repo: 'acme/api',
        base: 'main',
        head: 'data',
      );
      final secondTop = _pr(9, repo: 'acme/api', base: 'data', head: 'ui');

      expect(
        groupPrsByStack([top, bottom, secondTop, unrelated, secondBottom]),
        {
          'acme/cc': [
            [bottom, top],
            [unrelated],
          ],
          'acme/api': [
            [secondBottom, secondTop],
          ],
        },
      );
    });

    test('does not infer relationships from missing branch metadata', () {
      final noRefs = _pr(1, base: '', head: '');
      final noBase = _pr(2, base: '', head: 'data');
      final child = _pr(3, base: 'data', head: 'ui');
      final noHead = _pr(4, base: 'ui', head: '');

      expect(groupPrsByStack([noRefs, noBase, child, noHead]), {
        'acme/cc': [
          [noRefs],
          [noBase],
          [child],
          [noHead],
        ],
      });
    });

    test('never connects fork siblings as successive stack layers', () {
      final bottom = _pr(1, base: 'main', head: 'data');
      final left = _pr(2, base: 'data', head: 'left');
      final right = _pr(3, base: 'data', head: 'right');

      expect(groupPrsByStack([bottom, left, right]), {
        'acme/cc': [
          [bottom],
          [left],
          [right],
        ],
      });
    });

    test('keeps cycles and self-links reachable without a false order', () {
      final a = _pr(1, base: 'b', head: 'a');
      final b = _pr(2, base: 'a', head: 'b');
      final self = _pr(3, base: 'self', head: 'self');

      expect(groupPrsByStack([self, a, b]), {
        'acme/cc': [
          [self],
          [a],
          [b],
        ],
      });
    });

    test('does not choose a parent when a head branch is reused', () {
      final a = _pr(1, base: 'main', head: 'data');
      final b = _pr(2, base: 'release', head: 'data');
      final child = _pr(3, base: 'data', head: 'ui');

      expect(groupPrsByStack([a, b, child]), {
        'acme/cc': [
          [a],
          [b],
          [child],
        ],
      });
    });

    test('retains merged and closed layers when branch links still exist', () {
      final bottom = _pr(1, base: 'main', head: 'data', state: PrState.merged);
      final middle = _pr(2, base: 'data', head: 'ui', state: PrState.closed);
      final top = _pr(3, base: 'ui', head: 'tests');

      expect(groupPrsByStack([top, bottom, middle]), {
        'acme/cc': [
          [bottom, middle, top],
        ],
      });
    });
  });
}
