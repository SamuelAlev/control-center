import 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('BlockSpan', () {
    test('value equality and hashCode', () {
      expect(
        const BlockSpan(startLine: 1, endLine: 4),
        const BlockSpan(startLine: 1, endLine: 4),
      );
      expect(
        const BlockSpan(startLine: 1, endLine: 4).hashCode,
        const BlockSpan(startLine: 1, endLine: 4).hashCode,
      );
      expect(
        const BlockSpan(startLine: 1, endLine: 4),
        isNot(const BlockSpan(startLine: 1, endLine: 5)),
      );
    });

    test('toString is readable', () {
      expect(
        const BlockSpan(startLine: 2, endLine: 7).toString(),
        'BlockSpan(2..7)',
      );
    });
  });

  group('BlockResolutionException', () {
    test('carries its message', () {
      const ex = BlockResolutionException('nope');
      expect(ex.message, 'nope');
      expect(ex.toString(), contains('nope'));
    });
  });
}
