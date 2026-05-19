import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_infra/src/git/git_diff_z_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// `git diff -z` separates fields and terminates records with NUL bytes.
const nul = '\x00';

void main() {
  group('parseGitNameStatusZ', () {
    test('parses adds, modifies and deletes', () {
      const out = 'M${nul}a.dart${nul}A${nul}b.dart${nul}D${nul}c.dart$nul';
      final map = parseGitNameStatusZ(out);
      expect(map['a.dart'], (PrFileStatus.modified, null));
      expect(map['b.dart'], (PrFileStatus.added, null));
      expect(map['c.dart'], (PrFileStatus.removed, null));
    });

    test('parses a rename into the new path with its previous path', () {
      const out = 'R100${nul}old/path.dart${nul}new/path.dart$nul';
      final map = parseGitNameStatusZ(out);
      expect(map['new/path.dart'], (PrFileStatus.renamed, 'old/path.dart'));
      // The old path must NOT appear as its own entry.
      expect(map.containsKey('old/path.dart'), isFalse);
    });

    test('treats a copy as an added new file (no rename source)', () {
      const out = 'C100${nul}src.dart${nul}copy.dart$nul';
      final map = parseGitNameStatusZ(out);
      expect(map['copy.dart'], (PrFileStatus.added, null));
    });
  });

  group('parseGitNumstatZ', () {
    test('parses a plain modified file', () {
      const out = '3\t1\ta.dart$nul';
      final files = parseGitNumstatZ(out, {
        'a.dart': (PrFileStatus.modified, null),
      });
      expect(files, hasLength(1));
      expect(files.single.filename, 'a.dart');
      expect(files.single.additions, 3);
      expect(files.single.deletions, 1);
      expect(files.single.status, PrFileStatus.modified);
      expect(files.single.previousFilename, isNull);
    });

    test('binary files report zero additions/deletions', () {
      const out = '-\t-\timg.png$nul';
      final files = parseGitNumstatZ(out, const {});
      expect(files.single.additions, 0);
      expect(files.single.deletions, 0);
    });

    test('parses a rename record (empty path field + old/new tokens)', () {
      // `0\t0\t\0old/path.dart\0new/path.dart\0`
      const out = '0\t0\t${nul}old/path.dart${nul}new/path.dart$nul';
      final files = parseGitNumstatZ(out, {
        'new/path.dart': (PrFileStatus.renamed, 'old/path.dart'),
      });
      expect(files, hasLength(1));
      final f = files.single;
      expect(f.filename, 'new/path.dart');
      expect(f.status, PrFileStatus.renamed);
      expect(f.previousFilename, 'old/path.dart');
    });

    test(
      'handles a directory rename that git would compact to brace notation',
      () {
        // The exact shape from the reported PR: a deep directory move. With -z,
        // numstat emits the full old/new paths, not `{old => new}` brace syntax.
        const oldPath = 'foo/bar/baz.dart';
        const newPath = 'qux/quux/corge.dart';
        const nameStatus = 'R100$nul$oldPath$nul$newPath$nul';
        const numstat = '0\t0\t$nul$oldPath$nul$newPath$nul';

        final statusMap = parseGitNameStatusZ(nameStatus);
        final files = parseGitNumstatZ(numstat, statusMap);

        expect(files, hasLength(1));
        final f = files.single;
        expect(f.filename, newPath);
        expect(f.previousFilename, oldPath);
        expect(f.status, PrFileStatus.renamed);
        // The mangled brace path must never surface.
        expect(f.filename.contains('=>'), isFalse);
        expect(f.filename.contains('{'), isFalse);
      },
    );

    test('parses a mixed batch of normal files and renames in order', () {
      const out = '5\t2\tkeep.dart$nul'
          '0\t0\t${nul}from.dart${nul}to.dart$nul'
          '9\t0\tnew.dart$nul';
      final files = parseGitNumstatZ(out, {
        'keep.dart': (PrFileStatus.modified, null),
        'to.dart': (PrFileStatus.renamed, 'from.dart'),
        'new.dart': (PrFileStatus.added, null),
      });
      expect(files.map((f) => f.filename).toList(),
          ['keep.dart', 'to.dart', 'new.dart']);
      expect(files[1].previousFilename, 'from.dart');
      expect(files[2].status, PrFileStatus.added);
    });

    test('falls back to modified when status info is missing', () {
      const out = '1\t1\torphan.dart$nul';
      final files = parseGitNumstatZ(out, const {});
      expect(files.single.status, PrFileStatus.modified);
    });
  });
}
