import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

SemanticHit _hit(String path, {double score = 1.0}) => SemanticHit(
  filePath: path,
  startLine: 1,
  endLine: 10,
  score: score,
  content: 'x',
);

void main() {
  group('WorktreeOverlay', () {
    late WorktreeOverlay overlay;
    final current = <String, String>{};

    setUp(() {
      current
        ..clear()
        ..addAll({'a.dart': 'h1', 'b.dart': 'h2', 'c.dart': 'h3'});
      overlay = WorktreeOverlay(
        workspacePath: '/ws',
        baseline: {'a.dart': 'h1', 'b.dart': 'h2', 'c.dart': 'h3'},
        fileHasher: (path) async => current[path],
      );
    });

    test('reconcile marks diverged files as shadows', () {
      current['b.dart'] = 'h2-changed';
      overlay.reconcile(current);
      expect(overlay.ready, isTrue);
      expect(overlay.shadows, {'b.dart'});
    });

    test('reconcile shadows deleted baseline files', () {
      current.remove('c.dart');
      overlay.reconcile(current);
      expect(overlay.shadows, contains('c.dart'));
    });

    test('baseline hit accepted when unchanged', () async {
      overlay.reconcile(current);
      expect(await overlay.acceptsBaselineHit(_hit('a.dart')), isTrue);
    });

    test('baseline hit rejected when shadowed', () async {
      current['a.dart'] = 'changed';
      overlay.reconcile(current);
      expect(await overlay.acceptsBaselineHit(_hit('a.dart')), isFalse);
    });

    test('baseline hit rejected when blocked (in flight)', () async {
      overlay.reconcile(current);
      overlay.block('a.dart');
      expect(await overlay.acceptsBaselineHit(_hit('a.dart')), isFalse);
    });

    test('delta hit accepted unless blocked', () {
      expect(overlay.acceptsDeltaHit(_hit('new.dart')), isTrue);
      overlay.block('new.dart');
      expect(overlay.acceptsDeltaHit(_hit('new.dart')), isFalse);
    });

    test('settle clears a shadow when hash matches baseline again', () {
      overlay
        ..block('a.dart')
        ..settle('a.dart', 'changed'); // diverged
      expect(overlay.shadows, contains('a.dart'));
      overlay.settle('a.dart', 'h1'); // back in sync
      expect(overlay.shadows, isNot(contains('a.dart')));
    });

    test('relative rejects paths escaping the worktree', () {
      expect(overlay.relative('/ws/sub/file.dart'), 'sub/file.dart');
      expect(overlay.relative('/elsewhere/file.dart'), isNull);
    });

    test('mergeRanked de-dups by location keeping higher score', () {
      final merged = WorktreeOverlay.mergeRanked(
        [_hit('a.dart', score: 0.5)],
        [_hit('a.dart', score: 0.9), _hit('b.dart', score: 0.7)],
        limit: 10,
      );
      expect(merged, hasLength(2));
      final a = merged.firstWhere((h) => h.filePath == 'a.dart');
      expect(a.score, 0.9);
    });
  });

  group('LineCodeChunker', () {
    test('chunks content and stamps line ranges', () {
      final content = List.generate(200, (i) => 'line $i with some text here').join('\n');
      final chunks = const LineCodeChunker().chunk('big.dart', content);
      expect(chunks, isNotEmpty);
      expect(chunks.first.startLine, 1);
      expect(chunks.every((c) => c.fileHash.isNotEmpty), isTrue);
    });

    test('empty content yields no chunks', () {
      expect(const LineCodeChunker().chunk('e.dart', '   '), isEmpty);
    });
  });
}
