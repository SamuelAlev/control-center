import 'package:control_center/features/pr_review/presentation/utils/markdown_preview_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('annotateMarkdownPreview', () {
    test('empty patch returns head unchanged', () {
      const head = '# Title\n\nHello.';
      expect(annotateMarkdownPreview(headContent: head, patch: ''), head);
    });

    test('empty head returns empty', () {
      expect(
        annotateMarkdownPreview(
          headContent: '',
          patch: '@@ -1,1 +1,1 @@\n-old\n+new\n',
        ),
        '',
      );
    });

    test('replaced list items stay as two wrapped lines', () {
      const head = '- new item\n- kept\n';
      const patch = '@@ -1,2 +1,2 @@\n-- old item\n+- new item\n - kept\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(
        result,
        contains(
          '- $kMarkdownDiffDelOpen'
          'old item$kMarkdownDiffClose',
        ),
      );
      expect(
        result,
        contains(
          '- $kMarkdownDiffInsOpen'
          'new item$kMarkdownDiffClose',
        ),
      );
      expect(result, contains('- kept'));
      // Two list items, not a word-merged single item.
      expect(result, contains('\n'));
    });

    test('prose runs word-merge deleted and added text into one paragraph', () {
      const head = 'hello new world\n';
      const patch = '@@ -1,1 +1,1 @@\n-hello old world\n+hello new world\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('hello '));
      expect(
        result,
        contains(
          '$kMarkdownDiffDelOpen'
          'old$kMarkdownDiffClose',
        ),
      );
      expect(
        result,
        contains(
          '$kMarkdownDiffInsOpen'
          'new$kMarkdownDiffClose',
        ),
      );
      expect(result, contains(' world'));
      expect(result.split('\n').length, 1);
    });

    test('unchanged context around a change is preserved', () {
      const head = 'alpha\nbeta\ngamma\n';
      const patch = '@@ -1,3 +1,3 @@\n alpha\n-beta\n+BETA\n gamma\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, startsWith('alpha\n'));
      expect(
        result,
        contains(
          '$kMarkdownDiffDelOpen'
          'beta$kMarkdownDiffClose',
        ),
      );
      expect(
        result,
        contains(
          '$kMarkdownDiffInsOpen'
          'BETA$kMarkdownDiffClose',
        ),
      );
      expect(result, anyOf(endsWith('gamma\n'), endsWith('gamma')));
    });

    test('gaps between hunks copy unchanged head lines', () {
      const head = 'one\ntwo\nthree\nfour\nfive\n';
      const patch =
          '@@ -1,1 +1,1 @@\n-one\n+ONE\n@@ -5,1 +5,1 @@\n-five\n+FIVE\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('two'));
      expect(result, contains('three'));
      expect(result, contains('four'));
      expect(
        result,
        contains(
          '$kMarkdownDiffInsOpen'
          'ONE$kMarkdownDiffClose',
        ),
      );
      expect(
        result,
        contains(
          '$kMarkdownDiffInsOpen'
          'FIVE$kMarkdownDiffClose',
        ),
      );
    });

    test('inline code spans stay outside the wrap', () {
      const head = 'use `bar` here\n';
      const patch = '@@ -1,1 +1,1 @@\n-use `foo` here\n+use `bar` here\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('`foo`'));
      expect(result, contains('`bar`'));
      expect(result, isNot(contains('`$kMarkdownDiffDelOpen')));
      expect(result, isNot(contains('`$kMarkdownDiffInsOpen')));
    });

    test('added-only prose is wrapped as an insertion', () {
      const head = 'kept\nnew line\n';
      const patch = '@@ -1,1 +1,2 @@\n kept\n+new line\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('kept'));
      expect(
        result,
        contains(
          '$kMarkdownDiffInsOpen'
          'new line$kMarkdownDiffClose',
        ),
      );
    });

    test('deleted-only prose stays visible as a deletion', () {
      const head = 'kept\n';
      const patch = '@@ -1,2 +1,1 @@\n kept\n-gone\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('kept'));
      expect(
        result,
        contains(
          '$kMarkdownDiffDelOpen'
          'gone$kMarkdownDiffClose',
        ),
      );
    });

    test('replaced fence emits the new fence without sentinels', () {
      const head = '```\nnew\n```\n';
      const patch = '@@ -1,3 +1,3 @@\n-```\n-old\n-```\n+```\n+new\n+```\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(result, contains('```'));
      expect(result, contains('new'));
      expect(result, isNot(contains(kMarkdownDiffInsOpen)));
      expect(result, isNot(contains(kMarkdownDiffDelOpen)));
    });

    test('replaced table rows wrap cell text and keep pipes', () {
      const head = '| A | B |\n| --- | --- |\n| new | y |\n';
      const patch =
          '@@ -1,3 +1,3 @@\n | A | B |\n | --- | --- |\n-| old | y |\n+| new | y |\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(
        result,
        contains(
          '| $kMarkdownDiffDelOpen'
          'old$kMarkdownDiffClose |',
        ),
      );
      expect(
        result,
        contains(
          '| $kMarkdownDiffInsOpen'
          'new$kMarkdownDiffClose |',
        ),
      );
      expect(result, contains('| --- | --- |'));
      expect(result, isNot(contains('$kMarkdownDiffDelOpen|')));
      expect(result, isNot(contains('$kMarkdownDiffInsOpen|')));
    });

    test('heading changes emit old and new wrapped headings', () {
      const head = '# New title\n';
      const patch = '@@ -1,1 +1,1 @@\n-# Old title\n+# New title\n';
      final result = annotateMarkdownPreview(headContent: head, patch: patch);
      expect(
        result,
        contains(
          '# $kMarkdownDiffDelOpen'
          'Old title$kMarkdownDiffClose',
        ),
      );
      expect(
        result,
        contains(
          '# $kMarkdownDiffInsOpen'
          'New title$kMarkdownDiffClose',
        ),
      );
    });
  });
}
