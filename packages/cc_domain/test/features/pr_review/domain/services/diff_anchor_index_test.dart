import 'package:cc_domain/features/pr_review/domain/services/diff_anchor_index.dart';
import 'package:test/test.dart';

/// A two-hunk patch: lines 10-12 and 40-42 on the new side.
const _patch = '''
@@ -8,3 +8,4 @@ class Widget {
   final a = 1;
+  final b = 2;
   final c = 3;
@@ -38,3 +39,4 @@ void build() {
   render();
+  flush();
   done();
''';

void main() {
  group('DiffAnchorIndex', () {
    final index = DiffAnchorIndex.fromPatches({'lib/a.dart': _patch});

    test('admits an added line', () {
      expect(index.admits('lib/a.dart', 9), isTrue);
    });

    test('admits a context line inside a hunk', () {
      // Context lines are commentable on GitHub and are genuinely part of the
      // change's neighbourhood.
      expect(index.admits('lib/a.dart', 8), isTrue);
    });

    test('rejects a line the diff never touches', () {
      expect(index.admits('lib/a.dart', 500), isFalse);
    });

    test('rejects a file the pull request did not change', () {
      // A finding here is a finding about the repository, not about this PR.
      expect(index.admits('lib/untouched.dart', 3), isFalse);
    });

    test('admits a span that overlaps changed lines at either end', () {
      // A finding about a block where only part changed is still about the
      // change.
      expect(index.admits('lib/a.dart', 5, lineEnd: 9), isTrue);
      expect(index.admits('lib/a.dart', 9, lineEnd: 30), isTrue);
      expect(index.admits('lib/a.dart', 100, lineEnd: 120), isFalse);
    });

    test('admits a file-level finding on a changed file', () {
      expect(index.admits('lib/a.dart', null), isTrue);
    });

    test('rejects a file-level finding on an unchanged file', () {
      expect(index.admits('lib/untouched.dart', null), isFalse);
    });

    test('knows which files the pull request changed', () {
      expect(index.isKnownFile('lib/a.dart'), isTrue);
      expect(index.isKnownFile('lib/untouched.dart'), isFalse);
      expect(index.paths, ['lib/a.dart']);
    });

    test('a changed file with no patch is known but places nothing', () {
      // A binary, or one GitHub truncated. "Changed but unplaceable" is not
      // the same mistake as "never changed".
      final binary = DiffAnchorIndex.fromPatches({'assets/logo.png': null});
      expect(binary.isKnownFile('assets/logo.png'), isTrue);
      expect(binary.admits('assets/logo.png', 3), isFalse);
      expect(binary.admits('assets/logo.png', null), isTrue);
    });

    test('the permissive index admits everything', () {
      // The fallback when the diff could not be fetched. An empty index would
      // demote every finding and turn one failed API call into a review that
      // looks like it found nothing.
      expect(DiffAnchorIndex.permissive.isEmpty, isTrue);
      expect(DiffAnchorIndex.permissive.admits('anything.dart', 999), isTrue);
    });

    test('an index built from no files is permissive, not empty-rejecting', () {
      expect(const DiffAnchorIndex({}).admits('a.dart', 1), isTrue);
    });
  });
}
