import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiffTreeNode', () {
    test('dir node has isDirectory true, no fileIndex', () {
      const node = DiffTreeNode.dir(
        name: 'src',
        path: 'src',
        children: [],
        additions: 10,
        deletions: 5,
        fileCount: 3,
      );
      expect(node.isDirectory, isTrue);
      expect(node.fileIndex, isNull);
      expect(node.name, 'src');
      expect(node.path, 'src');
      expect(node.additions, 10);
      expect(node.deletions, 5);
      expect(node.fileCount, 3);
      expect(node.children, isEmpty);
    });

    test('file node has isDirectory false, has fileIndex', () {
      const node = DiffTreeNode.file(
        name: 'main.dart',
        path: 'src/main.dart',
        additions: 5,
        deletions: 2,
        status: 'modified',
        fileIndex: 0,
      );
      expect(node.isDirectory, isFalse);
      expect(node.fileIndex, 0);
      expect(node.name, 'main.dart');
      expect(node.path, 'src/main.dart');
      expect(node.additions, 5);
      expect(node.deletions, 2);
      expect(node.status, 'modified');
      expect(node.children, isEmpty);
      expect(node.fileCount, 1);
    });
  });

  PrFileStatus statusFromString(String value) {
    switch (value) {
      case 'added':
        return PrFileStatus.added;
      case 'removed':
        return PrFileStatus.removed;
      case 'renamed':
        return PrFileStatus.renamed;
      default:
        return PrFileStatus.modified;
    }
  }

  group('buildDiffFileTree', () {
    PrFile makeFile({
      required String filename,
      String status = 'modified',
      int additions = 0,
      int deletions = 0,
      String patch = '',
    }) {
      return PrFile(
        filename: filename,
        status: statusFromString(status),
        additions: additions,
        deletions: deletions,
        patch: patch,
      );
    }

    test('returns empty list for empty files', () {
      expect(buildDiffFileTree([]), isEmpty);
    });

    test('single file at root level', () {
      final files = [makeFile(filename: 'README.md')];
      final tree = buildDiffFileTree(files);
      expect(tree.length, 1);
      expect(tree[0].isDirectory, isFalse);
      expect(tree[0].name, 'README.md');
      expect(tree[0].path, 'README.md');
      expect(tree[0].fileIndex, 0);
    });

    test('single file in directory', () {
      final files = [makeFile(filename: 'src/main.dart')];
      final tree = buildDiffFileTree(files);
      expect(tree.length, 1);
      expect(tree[0].isDirectory, isTrue);
      expect(tree[0].name, 'src');
      expect(tree[0].fileCount, 1);
      expect(tree[0].children.length, 1);
      expect(tree[0].children[0].isDirectory, isFalse);
      expect(tree[0].children[0].name, 'main.dart');
    });

    test('nested directories', () {
      final files = [makeFile(filename: 'a/b/c/file.dart')];
      final tree = buildDiffFileTree(files, collapseSingleChildDirs: false);
      expect(tree.length, 1);
      expect(tree[0].name, 'a');
      expect(tree[0].children.length, 1);
      expect(tree[0].children[0].name, 'b');
      expect(tree[0].children[0].children.length, 1);
      expect(tree[0].children[0].children[0].name, 'c');
      expect(tree[0].children[0].children[0].children[0].name, 'file.dart');
    });

    test('multiple files in same directory', () {
      final files = [
        makeFile(filename: 'src/a.dart'),
        makeFile(filename: 'src/b.dart'),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree.length, 1);
      expect(tree[0].name, 'src');
      expect(tree[0].fileCount, 2);
      expect(tree[0].children.length, 2);
      expect(tree[0].children[0].name, 'a.dart');
      expect(tree[0].children[1].name, 'b.dart');
    });

    test('files in different root directories', () {
      final files = [
        makeFile(filename: 'src/a.dart'),
        makeFile(filename: 'test/b.dart'),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree.length, 2);
      expect(tree[0].name, 'src');
      expect(tree[0].fileCount, 1);
      expect(tree[1].name, 'test');
      expect(tree[1].fileCount, 1);
    });

    test('files are sorted by fileIndex (input order)', () {
      final files = [
        makeFile(filename: 'src/z.dart'),
        makeFile(filename: 'src/a.dart'),
        makeFile(filename: 'src/m.dart'),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree[0].children[0].name, 'z.dart');
      expect(tree[0].children[1].name, 'a.dart');
      expect(tree[0].children[2].name, 'm.dart');
    });

    test('directories are sorted by earliest fileIndex', () {
      final files = [
        makeFile(filename: 'zoo/file.dart'),
        makeFile(filename: 'alpha/file.dart'),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree[0].name, 'zoo');
      expect(tree[1].name, 'alpha');
    });

    test('accumulates additions and deletions', () {
      final files = [
        makeFile(filename: 'src/a.dart', additions: 5, deletions: 2),
        makeFile(filename: 'src/b.dart', additions: 3, deletions: 1),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree[0].additions, 8);
      expect(tree[0].deletions, 3);
    });

    test('fileCount accumulates correctly', () {
      final files = [
        makeFile(filename: 'src/a.dart'),
        makeFile(filename: 'src/b.dart'),
        makeFile(filename: 'lib/c.dart'),
      ];
      final tree = buildDiffFileTree(files);
      final totalFiles = tree.fold<int>(0, (sum, node) => sum + node.fileCount);
      expect(totalFiles, 3);
    });

    test('files at root and in directories mix', () {
      final files = [
        makeFile(filename: 'README.md'),
        makeFile(filename: 'src/main.dart'),
      ];
      final tree = buildDiffFileTree(files);
      expect(tree.length, 2);
      expect(tree.where((n) => n.isDirectory).length, 1);
      expect(tree.where((n) => !n.isDirectory).length, 1);
    });

    test('fileIndex corresponds to position in input list', () {
      final files = [
        makeFile(filename: 'src/a.dart'),
        makeFile(filename: 'src/b.dart'),
        makeFile(filename: 'src/c.dart'),
      ];
      final tree = buildDiffFileTree(files);
      final leafs = _collectLeafs(tree);
      expect(leafs[0].fileIndex, 0);
      expect(leafs[1].fileIndex, 1);
      expect(leafs[2].fileIndex, 2);
    });

    test('collapseSingleChildDirs true merges single-child dirs', () {
      final files = [makeFile(filename: 'a/b/file.dart')];
      final tree = buildDiffFileTree(files, collapseSingleChildDirs: true);
      expect(tree.length, 1);
      expect(tree[0].name, 'a/b');
      expect(tree[0].children[0].name, 'file.dart');
    });

    test('collapseSingleChildDirs false keeps single-child dirs', () {
      final files = [makeFile(filename: 'a/b/file.dart')];
      final tree = buildDiffFileTree(files, collapseSingleChildDirs: false);
      expect(tree.length, 1);
      expect(tree[0].name, 'a');
      expect(tree[0].children[0].name, 'b');
      expect(tree[0].children[0].children[0].name, 'file.dart');
    });

    test('collapse preserves branching directories', () {
      final files = [
        makeFile(filename: 'a/b/x.dart'),
        makeFile(filename: 'a/b/y.dart'),
      ];
      final tree = buildDiffFileTree(files, collapseSingleChildDirs: true);
      expect(tree.length, 1);
      expect(tree[0].name, 'a/b');
      expect(tree[0].children.length, 2);
    });

    test('status is propagated to file nodes', () {
      final files = [
        makeFile(filename: 'src/added.dart', status: 'added'),
        makeFile(filename: 'src/removed.dart', status: 'removed'),
      ];
      final tree = buildDiffFileTree(files);
      final leafs = _collectLeafs(tree);
      expect(leafs[0].status, 'added');
      expect(leafs[1].status, 'removed');
    });
  });
}

List<DiffTreeNode> _collectLeafs(List<DiffTreeNode> nodes) {
  final result = <DiffTreeNode>[];
  for (final node in nodes) {
    if (node.isDirectory) {
      result.addAll(_collectLeafs(node.children));
    } else {
      result.add(node);
    }
  }
  return result;
}
