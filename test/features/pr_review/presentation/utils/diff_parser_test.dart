import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiffToken', () {
    test('creates with text and color', () {
      const token = DiffToken('hello', 0xFFFF0000);
      expect(token.text, 'hello');
      expect(token.colorValue, 0xFFFF0000);
      expect(token.backgroundColorValue, isNull);
    });

    test('creates with background color', () {
      const token = DiffToken(
        'world',
        0xFF00FF00,
        backgroundColorValue: 0x66000000,
      );
      expect(token.text, 'world');
      expect(token.colorValue, 0xFF00FF00);
      expect(token.backgroundColorValue, 0x66000000);
    });

    test('supports null color', () {
      const token = DiffToken('plain', null);
      expect(token.text, 'plain');
      expect(token.colorValue, isNull);
      expect(token.backgroundColorValue, isNull);
    });

    test('equality by value', () {
      const a = DiffToken('x', 1);
      const b = DiffToken('x', 1);
      expect(a, b);
    });

    test('hashCode consistent with equality', () {
      const a = DiffToken('x', 1);
      const b = DiffToken('x', 1);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('DiffLineSpec', () {
    test('creates with required fields', () {
      const spec = DiffLineSpec(kind: DiffLineKind.context, tokens: []);
      expect(spec.kind, DiffLineKind.context);
      expect(spec.tokens, isEmpty);
      expect(spec.oldLine, isNull);
      expect(spec.newLine, isNull);
      expect(spec.hunkHeader, isNull);
    });

    test('creates with all fields', () {
      const tokens = <DiffToken>[];
      const spec = DiffLineSpec(
        kind: DiffLineKind.addition,
        tokens: tokens,
        oldLine: 10,
        newLine: 12,
        hunkHeader: '@@ -1,5 +1,7 @@',
      );
      expect(spec.kind, DiffLineKind.addition);
      expect(spec.oldLine, 10);
      expect(spec.newLine, 12);
      expect(spec.hunkHeader, '@@ -1,5 +1,7 @@');
    });
  });

  group('DiffLineKind', () {
    test('has all expected values', () {
      expect(DiffLineKind.values.length, 5);
      expect(DiffLineKind.values, contains(DiffLineKind.hunkHeader));
      expect(DiffLineKind.values, contains(DiffLineKind.context));
      expect(DiffLineKind.values, contains(DiffLineKind.addition));
      expect(DiffLineKind.values, contains(DiffLineKind.deletion));
      expect(DiffLineKind.values, contains(DiffLineKind.expandGap));
    });
  });

  group('DiffLine', () {
    test('creates context line with line numbers', () {
      const line = DiffLine(
        kind: DiffLineKind.context,
        content: '  unchanged code',
        oldLine: 5,
        newLine: 7,
      );
      expect(line.kind, DiffLineKind.context);
      expect(line.content, '  unchanged code');
      expect(line.oldLine, 5);
      expect(line.newLine, 7);
      expect(line.hunkHeader, isNull);
    });

    test('creates addition line', () {
      const line = DiffLine(
        kind: DiffLineKind.addition,
        content: 'new line',
        newLine: 10,
      );
      expect(line.kind, DiffLineKind.addition);
      expect(line.content, 'new line');
      expect(line.newLine, 10);
      expect(line.oldLine, isNull);
    });

    test('creates deletion line', () {
      const line = DiffLine(
        kind: DiffLineKind.deletion,
        content: 'old line',
        oldLine: 3,
      );
      expect(line.kind, DiffLineKind.deletion);
      expect(line.content, 'old line');
      expect(line.oldLine, 3);
      expect(line.newLine, isNull);
    });

    test('creates hunk header line', () {
      const line = DiffLine(
        kind: DiffLineKind.hunkHeader,
        content: '@@ -1,5 +1,6 @@',
        hunkHeader: '@@ -1,5 +1,6 @@',
      );
      expect(line.kind, DiffLineKind.hunkHeader);
      expect(line.hunkHeader, '@@ -1,5 +1,6 @@');
    });
  });

  group('parseUnifiedDiff', () {
    test('returns empty list for empty string', () {
      expect(parseUnifiedDiff(''), isEmpty);
    });

    test('parses single hunk with context lines', () {
      const patch =
          '@@ -1,3 +1,3 @@\n'
          ' context line\n'
          ' unchanged\n'
          ' still same';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 4);
      expect(result[0].kind, DiffLineKind.hunkHeader);
      expect(result[0].hunkHeader, '@@ -1,3 +1,3 @@');
      expect(result[1].kind, DiffLineKind.context);
      expect(result[1].content, 'context line');
      expect(result[1].oldLine, 1);
      expect(result[1].newLine, 1);
    });

    test('parses additions and deletions', () {
      const patch =
          '@@ -1,2 +1,2 @@\n'
          '-removed line\n'
          '+added line\n';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 3);
      expect(result[0].kind, DiffLineKind.hunkHeader);
      expect(result[1].kind, DiffLineKind.deletion);
      expect(result[1].content, 'removed line');
      expect(result[2].kind, DiffLineKind.addition);
      expect(result[2].content, 'added line');
    });

    test('parses mixed diff with context', () {
      const patch =
          '@@ -5,4 +5,6 @@\n'
          ' unchanged context\n'
          '-deleted line\n'
          '+added line 1\n'
          '+added line 2\n'
          ' final context';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 7);
      expect(result[0].kind, DiffLineKind.expandGap);
      expect(result[1].kind, DiffLineKind.hunkHeader);
      expect(result[2].kind, DiffLineKind.context);
      expect(result[3].kind, DiffLineKind.deletion);
      expect(result[4].kind, DiffLineKind.addition);
      expect(result[5].kind, DiffLineKind.addition);
      expect(result[6].kind, DiffLineKind.context);
    });

    test('parses multiple hunks', () {
      const patch =
          '@@ -1,3 +1,3 @@\n'
          ' first\n'
          ' hunk\n'
          ' content\n'
          '@@ -10,3 +10,4 @@\n'
          ' second\n'
          ' hunk\n'
          '+extra\n'
          ' content';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 10);
      expect(result[0].kind, DiffLineKind.hunkHeader);
      expect(result[4].kind, DiffLineKind.expandGap);
      expect(result[5].kind, DiffLineKind.hunkHeader);
    });

    test('handles empty lines in context', () {
      const patch =
          '@@ -1,3 +1,3 @@\n'
          ' context1\n'
          '\n'
          ' context3';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 4);
      expect(result[1].content, 'context1');
      expect(result[2].content, '');
      expect(result[2].kind, DiffLineKind.context);
    });

    test('trailing newline produces no empty context line', () {
      const patch =
          '@@ -1,1 +1,1 @@\n'
          ' line\n';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 2);
    });

    test('handles no newline warning (backslash)', () {
      const patch =
          '@@ -1,2 +1,2 @@\n'
          ' context\n'
          '\\ No newline at end of file';
      final result = parseUnifiedDiff(patch);
      expect(result.length, 2);
      expect(result[1].content, 'context');
    });
  });

  group('originalCodeFromDiffHunk', () {
    test('returns empty string for empty diffHunk', () {
      expect(originalCodeFromDiffHunk('', 'RIGHT', 1, 1), '');
    });

    test('returns empty string when endLine < startLine', () {
      expect(originalCodeFromDiffHunk('content', 'RIGHT', 5, 3), '');
    });

    test('extracts right-side additions and context within range', () {
      const hunk =
          '@@ -2,3 +4,3 @@\n'
          ' common\n'
          '+added1\n'
          '+added2';
      final result = originalCodeFromDiffHunk(hunk, 'RIGHT', 5, 6);
      expect(result, 'added1\nadded2');
    });

    test('extracts left-side deletions and context within range', () {
      const hunk =
          '@@ -2,3 +4,2 @@\n'
          ' common\n'
          '-removed1\n'
          ' common2';
      final result = originalCodeFromDiffHunk(hunk, 'LEFT', 2, 3);
      expect(result, 'common\nremoved1');
    });

    test('handles side case insensitively', () {
      const hunk =
          '@@ -2,3 +4,2 @@\n'
          ' common\n'
          '+added1';
      final result = originalCodeFromDiffHunk(hunk, 'right', 5, 5);
      expect(result, 'added1');
    });

    test('filters out lines outside the specified range', () {
      const hunk =
          '@@ -1,4 +1,4 @@\n'
          ' line1\n'
          ' line2\n'
          ' line3\n'
          ' line4';
      final result = originalCodeFromDiffHunk(hunk, 'RIGHT', 2, 3);
      expect(result, 'line2\nline3');
    });

    test('returns empty string for non-matching range', () {
      const hunk =
          '@@ -1,2 +1,2 @@\n'
          ' line1\n'
          ' line2';
      final result = originalCodeFromDiffHunk(hunk, 'RIGHT', 10, 20);
      expect(result, '');
    });
  });

  group('extractFilePatch', () {
    const fullDiff =
        'diff --git a/src/main.dart b/src/main.dart\n'
        'index abc1234..def5678 100644\n'
        '--- a/src/main.dart\n'
        '+++ b/src/main.dart\n'
        '@@ -1,3 +1,3 @@\n'
        ' line1\n'
        '-line2\n'
        '+line2_modified\n'
        ' line3\n'
        'diff --git a/pubspec.yaml b/pubspec.yaml\n'
        'index 111..222 100644\n'
        '--- a/pubspec.yaml\n'
        '+++ b/pubspec.yaml\n'
        '@@ -1,2 +1,3 @@\n'
        ' dependencies:\n'
        '   http: ^1.0.0\n'
        '+  path: ^1.8.0\n';

    test('extracts a file section from full diff', () {
      final result = extractFilePatch(fullDiff, 'src/main.dart');
      expect(result, contains('@@ -1,3 +1,3 @@'));
      expect(result, contains('-line2'));
      expect(result, contains('+line2_modified'));
      expect(result, isNot(contains('pubspec.yaml')));
    });

    test('extracts the last file section', () {
      final result = extractFilePatch(fullDiff, 'pubspec.yaml');
      expect(result, contains('@@ -1,2 +1,3 @@'));
      expect(result, contains('+  path: ^1.8.0'));
      expect(result, isNot(contains('main.dart')));
    });

    test('returns empty string for missing file', () {
      final result = extractFilePatch(fullDiff, 'nonexistent.dart');
      expect(result, '');
    });

    test('returns empty string for empty inputs', () {
      expect(extractFilePatch('', 'file.dart'), '');
      expect(extractFilePatch(fullDiff, ''), '');
    });

    test('handles rename (matches via b/ path)', () {
      const renameDiff =
          'diff --git a/old_name.dart b/new_name.dart\n'
          'similarity index 90%\n'
          'rename from old_name.dart\n'
          'rename to new_name.dart\n'
          '@@ -1,2 +1,2 @@\n'
          ' line1\n'
          '-old\n'
          '+new\n';
      // Match via b/ (new name)
      final result = extractFilePatch(renameDiff, 'new_name.dart');
      expect(result, contains('-old'));
      expect(result, contains('+new'));
    });

    test('handles file with special characters in name', () {
      const specialDiff =
          'diff --git a/.dependency-cruiser-known-violations.json b/.dependency-cruiser-known-violations.json\n'
          'index aaa..bbb 100644\n'
          '--- a/.dependency-cruiser-known-violations.json\n'
          '+++ b/.dependency-cruiser-known-violations.json\n'
          '@@ -1,2 +1,3 @@\n'
          ' [\n'
          '   {"type": "dep"}\n'
          '+  ,{"type": "dep2"}\n'
          ' ]\n'
          'diff --git a/other.dart b/other.dart\n'
          '@@ -1 +1 @@\n'
          '-x\n'
          '+y\n';
      final result = extractFilePatch(
        specialDiff,
        '.dependency-cruiser-known-violations.json',
      );
      expect(result, contains('@@ -1,2 +1,3 @@'));
      expect(result, contains(',{"type": "dep2"}'));
      expect(result, isNot(contains('other.dart')));
    });

    test('strips git metadata lines (index, ---, +++)', () {
      final result = extractFilePatch(fullDiff, 'src/main.dart');
      // Must start with hunk header, not git metadata
      expect(result.startsWith('@@'), isTrue);
      expect(result, isNot(contains('index ')));
      expect(result, isNot(contains('--- a/')));
      expect(result, isNot(contains('+++ b/')));
    });

    test('returns empty for pure rename with no hunks', () {
      const renameOnlyDiff =
          'diff --git a/old.dart b/new.dart\n'
          'similarity index 100%\n'
          'rename from old.dart\n'
          'rename to new.dart\n'
          'diff --git a/other.dart b/other.dart\n'
          '@@ -1 +1 @@\n'
          '-x\n'
          '+y\n';
      final result = extractFilePatch(renameOnlyDiff, 'old.dart');
      expect(result, '');
    });
  });

  group('extractAllFilePatches', () {
    test('returns empty map for empty input', () {
      expect(extractAllFilePatches(''), isEmpty);
    });

    test('extracts all files from multi-file diff', () {
      const multiDiff =
          'diff --git a/foo.dart b/foo.dart\n'
          'index abc..def 100644\n'
          '--- a/foo.dart\n'
          '+++ b/foo.dart\n'
          '@@ -1,3 +1,3 @@\n'
          ' context\n'
          '-old\n'
          '+new\n'
          'diff --git a/bar.json b/bar.json\n'
          'index 123..456 100644\n'
          '--- a/bar.json\n'
          '+++ b/bar.json\n'
          '@@ -1 +1 @@\n'
          '-x\n'
          '+y\n';
      final patches = extractAllFilePatches(multiDiff);
      expect(patches, hasLength(2));
      expect(patches['foo.dart'], contains('@@'));
      expect(patches['foo.dart'], contains('-old'));
      expect(patches['foo.dart'], contains('+new'));
      expect(patches['bar.json'], contains('-x'));
      // Metadata stripped
      expect(patches['foo.dart'], isNot(contains('index abc')));
      expect(patches['foo.dart'], isNot(contains('--- a/')));
      expect(patches['foo.dart'], isNot(contains('+++ b/')));
    });

    test('omits pure renames with no hunks', () {
      const diffWithRename =
          'diff --git a/old.dart b/new.dart\n'
          'similarity index 100%\n'
          'rename from old.dart\n'
          'rename to new.dart\n'
          'diff --git a/real.dart b/real.dart\n'
          '@@ -1 +1 @@\n'
          '-a\n'
          '+b\n';
      final patches = extractAllFilePatches(diffWithRename);
      expect(patches, hasLength(1));
      expect(patches.containsKey('new.dart'), isFalse);
      expect(patches['real.dart'], isNotNull);
    });

    test('indexes renamed files by both a/ and b/ paths', () {
      const renameWithChanges =
          'diff --git a/old_name.dart b/new_name.dart\n'
          'index abc..def 100644\n'
          '--- a/old_name.dart\n'
          '+++ b/new_name.dart\n'
          '@@ -1 +1 @@\n'
          '-x\n'
          '+y\n';
      final patches = extractAllFilePatches(renameWithChanges);
      // Both paths should map to the same patch
      expect(patches['new_name.dart'], isNotNull);
      expect(patches['old_name.dart'], isNotNull);
      expect(patches['new_name.dart'], patches['old_name.dart']);
    });

    test('handles single-file diff', () {
      const singleDiff =
          'diff --git a/solo.txt b/solo.txt\n'
          '@@ -1 +1 @@\n'
          '-a\n'
          '+b\n';
      final patches = extractAllFilePatches(singleDiff);
      expect(patches, hasLength(1));
      expect(patches['solo.txt'], contains('-a'));
    });

    test('handles diff with leading newline', () {
      const diffWithPrefix =
          '\ndiff --git a/file.dart b/file.dart\n'
          '@@ -1 +1 @@\n'
          '-a\n'
          '+b\n';
      final patches = extractAllFilePatches(diffWithPrefix);
      expect(patches, hasLength(1));
      expect(patches['file.dart'], isNotNull);
    });
  });
}
