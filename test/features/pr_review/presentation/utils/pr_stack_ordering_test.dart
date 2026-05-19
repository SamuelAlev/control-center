import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_stack_ordering.dart';
import 'package:test/test.dart';

PullRequest _pr(int number, {required String base, required String head}) =>
    PullRequest(
      id: number,
      number: number,
      title: 'PR $number',
      body: '',
      state: PrState.open,
      isDraft: false,
      author: null,
      createdAt: null,
      updatedAt: null,
      repoFullName: 'acme/cc',
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
}
