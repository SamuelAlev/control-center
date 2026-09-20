import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/features/pr_review/presentation/utils/markdown_preview_diff.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/markdown_diff_annotation.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_preview.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

void main() {
  group('MarkdownDiffInlinePlugin', () {
    final parser = CcParser(plugins: markdownPreviewDiffPlugins);

    test('parses addition and deletion sentinels as custom inlines', () {
      final blocks = parser.parse(
        'hello $kMarkdownDiffDelOpen'
        'old$kMarkdownDiffClose$kMarkdownDiffInsOpen'
        'new$kMarkdownDiffClose world',
      );
      expect(blocks, hasLength(1));
      final children = (blocks.single as CcParagraph).children;
      final diffs = children.whereType<MarkdownDiffInline>().toList();
      expect(diffs, hasLength(2));
      expect(diffs[0].added, isFalse);
      expect(diffs[0].children, [const CcText('old')]);
      expect(diffs[1].added, isTrue);
      expect(diffs[1].children, [const CcText('new')]);
    });

    test('re-parses inner markdown so code spans survive', () {
      final blocks = parser.parse(
        '- $kMarkdownDiffInsOpen'
        '`execute-exact` — added$kMarkdownDiffClose',
      );
      final item = (blocks.single as CcList).items.single;
      final para = item.children.single as CcParagraph;
      final diff = para.children.whereType<MarkdownDiffInline>().single;
      expect(diff.added, isTrue);
      expect(
        diff.children.whereType<CcInlineCode>().single.code,
        'execute-exact',
      );
    });
  });

  group('MarkdownPreviewBody rich diff', () {
    testWidgets('paints added and deleted list items in the preview', (
      tester,
    ) async {
      const head = '- new item\n- kept\n';
      const patch = '@@ -1,2 +1,2 @@\n-- old item\n+- new item\n - kept\n';
      await tester.pumpWidget(
        testWrap(
          MarkdownPreviewBody(
            path: 'README.md',
            fetch: (_) async => head,
            cachedContent: head,
            onLoaded: (_) {},
            patch: patch,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(StyledMarkdownBody), findsOneWidget);
      expect(find.byType(MarkdownDiffBlockWash), findsNWidgets(2));
      expect(
        find.textContaining('old item', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('new item', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('kept', findRichText: true), findsOneWidget);
    });

    testWidgets('an added file is not washed green', (tester) async {
      const head = '# Brand new\n';
      await tester.pumpWidget(
        testWrap(
          MarkdownPreviewBody(
            path: 'NEW.md',
            fetch: (_) async => head,
            cachedContent: head,
            onLoaded: (_) {},
            patch: '@@ -0,0 +1,1 @@\n+# Brand new\n',
            status: PrFileStatus.added,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MarkdownDiffBlockWash), findsNothing);
      expect(
        find.textContaining('Brand new', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('mixed prose shows deleted and added words in one paragraph', (
      tester,
    ) async {
      const head = 'hello new world';
      const patch = '@@ -1,1 +1,1 @@\n-hello old world\n+hello new world\n';
      await tester.pumpWidget(
        testWrap(
          MarkdownPreviewBody(
            path: 'NOTE.md',
            fetch: (_) async => head,
            cachedContent: head,
            onLoaded: (_) {},
            patch: patch,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MarkdownDiffBlockWash), findsNothing);
      expect(find.textContaining('hello', findRichText: true), findsOneWidget);
      expect(find.textContaining('old', findRichText: true), findsOneWidget);
      expect(find.textContaining('new', findRichText: true), findsOneWidget);
      expect(find.textContaining('world', findRichText: true), findsOneWidget);
    });
  });
}
