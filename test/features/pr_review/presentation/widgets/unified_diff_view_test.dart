import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PrFile _testFile({
  String filename = 'lib/test.dart',
  PrFileStatus status = PrFileStatus.modified,
  String patch = '@@ -1,3 +1,5 @@\n unchanged\n-old\n+new\n+extra\n',
  int additions = 5,
  int deletions = 2,
}) {
  return PrFile(
    filename: filename,
    status: status,
    additions: additions,
    deletions: deletions,
    patch: patch,
  );
}

Widget _wrap(Widget sliverChild) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
    ],
    child: testWrap(CustomScrollView(slivers: [sliverChild])),
  );
}

void main() {
  group('UnifiedDiffView', () {
    testWidgets('builds with empty files list', (tester) async {
      await tester.pumpWidget(
        _wrap(const UnifiedDiffView(files: [])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      // Empty sliver may not mount a SliverToBoxAdapter; verify no crash.
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds with a single file', (tester) async {
      final files = [_testFile()];

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(files: files)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnifiedDiffView), findsOneWidget);
    });

    testWidgets('builds with multiple files', (tester) async {
      final files = [
        _testFile(filename: 'lib/a.dart'),
        _testFile(filename: 'lib/b.dart'),
        _testFile(filename: 'lib/c.dart'),
      ];

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(files: files)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnifiedDiffView), findsOneWidget);
    });

    testWidgets('splitView=true parameter accepted', (tester) async {
      final files = [_testFile()];

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: files,
          splitView: true,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnifiedDiffView), findsOneWidget);
    });

    testWidgets('prNumber parameter accepted', (tester) async {
      final files = [_testFile()];

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: files,
          prNumber: 42,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnifiedDiffView), findsOneWidget);
    });

    testWidgets('renders files with different statuses', (tester) async {
      final files = [
        _testFile(
          filename: 'lib/added.dart',
          status: PrFileStatus.added,
          patch: '@@ -0,0 +1,3 @@\n+new file\n+content\n',
          additions: 3,
          deletions: 0,
        ),
        _testFile(
          filename: 'lib/modified.dart',
          status: PrFileStatus.modified,
        ),
        _testFile(
          filename: 'lib/removed.dart',
          status: PrFileStatus.removed,
          patch: '@@ -1,3 +0,0 @@\n-old\n-content\n',
          additions: 0,
          deletions: 3,
        ),
        _testFile(
          filename: 'lib/renamed.dart',
          status: PrFileStatus.renamed,
          patch: '@@ -1,2 +1,2 @@\n-old\n+new\n',
          additions: 1,
          deletions: 1,
        ),
      ];

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(files: files)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnifiedDiffView), findsOneWidget);
    });
  });

  group('UnifiedDiffView markdown preview toggle', () {
    Future<String> markdownFetcher(String path) async => '# Hello\n\nWorld';

    PrFile markdownFile({
      String filename = 'README.md',
      PrFileStatus status = PrFileStatus.modified,
      PrFileViewedState viewed = PrFileViewedState.unviewed,
    }) {
      return PrFile(
        filename: filename,
        status: status,
        additions: 3,
        deletions: 1,
        patch: '@@ -1,2 +1,3 @@\n # Title\n-old\n+new\n+extra\n',
        viewerViewedState: viewed,
      );
    }

    testWidgets('shows the Diff/Preview toggle for a markdown file with a '
        'fetcher', (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile()],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Diff'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('hides the toggle for a non-markdown file', (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [_testFile(filename: 'lib/test.dart')],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('hides the toggle for a markdown file with no fetcher',
        (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(files: [markdownFile()])),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('hides the toggle for a removed markdown file', (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile(status: PrFileStatus.removed)],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('tapping Preview renders the markdown body', (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile()],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StyledMarkdownBody), findsNothing);

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StyledMarkdownBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Preview expands a collapsed (viewed) file',
        (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile(viewed: PrFileViewedState.viewed)],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The file starts collapsed (viewed) but the toggle is still in the
      // header.
      expect(find.text('Preview'), findsOneWidget);
      expect(find.byType(StyledMarkdownBody), findsNothing);

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Toggling preview on a collapsed file expands it and renders the body.
      expect(find.byType(StyledMarkdownBody), findsOneWidget);
    });

    testWidgets('reserves the async content height so the next file does not '
        'overlap the preview', (tester) async {
      // A tall viewport keeps the second file's header laid out even when the
      // first file's preview is very tall.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Content far taller than the 240px pre-measure estimate — if the body
      // height weren't reserved from the (async) measured height, this would
      // overflow and overlap the next file.
      final tall = List.generate(
        40,
        (i) => 'Paragraph number $i with a few words of body text.',
      ).join('\n\n');
      Future<String> tallFetcher(String path) async => '# Heading\n\n$tall';

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [
            markdownFile(),
            _testFile(filename: 'lib/b.dart'),
          ],
          fetchFileContent: tallFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Preview'));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final previewBottom =
          tester.getRect(find.byType(StyledMarkdownBody)).bottom;
      final nextHeaderTop = tester.getRect(find.text('lib/b.dart')).top;

      // The next file's header must sit below the rendered preview, not over it.
      expect(nextHeaderTop, greaterThan(previewBottom - 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fetches preview content once across rebuilds (cached)',
        (tester) async {
      var fetchCount = 0;
      Future<String> countingFetcher(String path) async {
        fetchCount++;
        return '# Title\n\nBody paragraph.';
      }

      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile()],
          fetchFileContent: countingFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Preview'));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The height-measure → revision-bump rebuild cycle must not re-fetch; the
      // cached content is reused, which is what keeps scrolling stable.
      expect(find.byType(StyledMarkdownBody), findsOneWidget);
      expect(fetchCount, 1);
    });

    testWidgets('round-trips Preview → Diff without error', (tester) async {
      await tester.pumpWidget(
        _wrap(UnifiedDiffView(
          files: [markdownFile()],
          fetchFileContent: markdownFetcher,
        )),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(StyledMarkdownBody), findsOneWidget);

      await tester.tap(find.text('Diff'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StyledMarkdownBody), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
