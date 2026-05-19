import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_file_collapse_manager.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _file(String filename, {String patch = '@@ -1,1 +1,1 @@\n code\n'}) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 1,
    deletions: 0,
    patch: patch,
  );
}

void main() {
  group('PrDiffFileCollapseManager', () {
    late PrDiffFileCollapseManager manager;
    late int setStateCount;
    String? toggledPath;
    bool? toggledViewed;

    setUp(() {
      setStateCount = 0;
      toggledPath = null;
      toggledViewed = null;
      manager = PrDiffFileCollapseManager(
        onToggleViewed: ({required String path, required bool viewed}) {
          toggledPath = path;
          toggledViewed = viewed;
        },
      );
    });

    test('getFileKey returns unique keys per path', () {
      final key1 = manager.getFileKey('lib/a.dart');
      final key2 = manager.getFileKey('lib/b.dart');
      expect(key1, isNot(same(key2)));
    });

    test('getFileKey returns same key for same path', () {
      final key1 = manager.getFileKey('lib/a.dart');
      final key2 = manager.getFileKey('lib/a.dart');
      expect(key1, same(key2));
    });

    test('isViewed returns false for unviewed path', () {
      expect(manager.isViewed('lib/a.dart'), isFalse);
    });

    test('toggleViewed marks path as viewed', () {
      manager.toggleViewed('lib/a.dart', () => setStateCount++);
      expect(manager.isViewed('lib/a.dart'), isTrue);
      expect(setStateCount, 1);
      expect(toggledPath, 'lib/a.dart');
      expect(toggledViewed, isTrue);
    });

    test('toggleViewed unmarks already viewed path', () {
      manager.toggleViewed('lib/a.dart', () => setStateCount++);
      manager.toggleViewed('lib/a.dart', () => setStateCount++);
      expect(manager.isViewed('lib/a.dart'), isFalse);
      expect(setStateCount, 2);
    });

    test('shouldAutoCollapse returns true for large files', () {
      final lines = List.filled(501, 'line').join('\n');
      final patch = '@@ -1,501 +1,501 @@\n$lines';
      final file = _file('big.dart', patch: patch);
      expect(PrDiffFileCollapseManager.shouldAutoCollapse(file), isTrue);
    });

    test('shouldAutoCollapse returns false for small files', () {
      final file = _file('small.dart');
      expect(PrDiffFileCollapseManager.shouldAutoCollapse(file), isFalse);
    });

    test('shouldAutoCollapse returns false for empty patch', () {
      final file = _file('no_diff.dart', patch: '');
      expect(PrDiffFileCollapseManager.shouldAutoCollapse(file), isFalse);
    });

    test('patchLineCount counts newlines correctly', () {
      expect(PrDiffFileCollapseManager.patchLineCount('a\nb\nc'), 2);
      expect(PrDiffFileCollapseManager.patchLineCount(''), 0);
      expect(PrDiffFileCollapseManager.patchLineCount('single line'), 0);
    });

    test('toggleViewed without onToggleViewed callback does not throw', () {
      final mgr = PrDiffFileCollapseManager(onToggleViewed: null);
      expect(() => mgr.toggleViewed('path', () {}), returnsNormally);
    });

    test('viewedPaths tracks multiple files', () {
      manager.toggleViewed('a.dart', () {});
      manager.toggleViewed('b.dart', () {});
      expect(manager.isViewed('a.dart'), isTrue);
      expect(manager.isViewed('b.dart'), isTrue);
      expect(manager.isViewed('c.dart'), isFalse);
    });
  });
}
