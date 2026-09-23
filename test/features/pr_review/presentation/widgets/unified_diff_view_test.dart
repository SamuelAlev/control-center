import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Tokenize on the main isolate: widget tests must not spawn real diff
  // workers (their fallback watchdog Timer would pend at FakeAsync teardown).
  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() => DiffWorkerPool.debugForceInline = false);

  group('UnifiedDiffView', () {
    testWidgets('first frame parses only the opening file of a mid-size PR', (
      tester,
    ) async {
      // 12 files × ~80 lines is well under the old 20k eager-parse budget,
      // so the previous path parsed EVERY file in initState and froze the
      // Diff-tab click. The last file must stay unparsed after the first
      // layout — only the opening viewport is allowed to pay parse cost.
      final tallPatch =
          '@@ -1,80 +1,80 @@\n${List.filled(80, ' line\n').join()}';
      final files = [
        _testFile(filename: 'lib/a.dart'),
        for (var i = 1; i <= 12; i++)
          _testFile(filename: 'lib/f$i.dart', patch: tallPatch),
      ];
      final key = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(_wrap(UnifiedDiffView(key: key, files: files)));
      await tester.pump();

      final doc = key.currentState!.debugDocument;
      expect(doc.structureOf(0), isNotNull);
      expect(doc.structureOf(doc.fileCount - 1), isNull);
    });

    testWidgets('marking a file viewed keeps its diff expanded', (
      tester,
    ) async {
      String? toggledPath;
      bool? toggledViewed;
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [_testFile()],
            onToggleViewed: ({required path, required viewed}) {
              toggledPath = path;
              toggledViewed = viewed;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);
      await tester.tap(find.byIcon(AppIcons.circle));
      await tester.pump();

      expect(toggledPath, 'lib/test.dart');
      expect(toggledViewed, isTrue);
      expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);
    });

    testWidgets('cmd or ctrl while hovering an empty patch does not throw', (
      tester,
    ) async {
      // A rename, binary, or mode-only file parses to an empty structure.
      // cellAt still reports line 0, and the global goto handler used to
      // index that line when a selection chord arrived with the pointer
      // resting on the diff. The shared controller is what lets the hover
      // overlay attach in this harness: the view reads the primary
      // controller from inside the scrollable, which hides one the scroll
      // view itself adopted.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            codeFontFamilyProvider.overrideWithValue('Fira Code'),
            diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
          ],
          child: testWrap(
            PrimaryScrollController(
              controller: controller,
              child: CustomScrollView(
                controller: controller,
                primary: false,
                slivers: [
                  UnifiedDiffView(
                    files: [
                      _testFile(
                        filename: 'lib/renamed.dart',
                        status: PrFileStatus.renamed,
                        patch: '',
                        additions: 0,
                        deletions: 0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(CustomScrollView));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(center + const Offset(8, 4));
      await tester.pump();

      final modifier = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('dependency lockfiles start collapsed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [_testFile(filename: 'packages/app/pubspec.lock')],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
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
        _wrap(
          UnifiedDiffView(
            files: [markdownFile()],
            fetchFileContent: markdownFetcher,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Diff'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('hides the toggle for a non-markdown file', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [_testFile(filename: 'lib/test.dart')],
            fetchFileContent: markdownFetcher,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('hides the toggle for a markdown file with no fetcher', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(UnifiedDiffView(files: [markdownFile()])));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('hides the toggle for a removed markdown file', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [markdownFile(status: PrFileStatus.removed)],
            fetchFileContent: markdownFetcher,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('tapping Preview renders the markdown body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [markdownFile()],
            fetchFileContent: markdownFetcher,
          ),
        ),
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

    testWidgets('a viewed file stays expanded and can switch to Preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [markdownFile(viewed: PrFileViewedState.viewed)],
            fetchFileContent: markdownFetcher,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Viewed state does not auto-collapse the file.
      expect(find.byIcon(AppIcons.chevronUp), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.byType(StyledMarkdownBody), findsNothing);

      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

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
        _wrap(
          UnifiedDiffView(
            files: [
              markdownFile(),
              _testFile(filename: 'lib/b.dart'),
            ],
            fetchFileContent: tallFetcher,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Preview'));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final previewBottom = tester
          .getRect(find.byType(StyledMarkdownBody))
          .bottom;
      final nextHeaderTop = tester.getRect(find.text('lib/b.dart')).top;

      // The next file's header must sit below the rendered preview, not over it.
      expect(nextHeaderTop, greaterThan(previewBottom - 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fetches preview content once across rebuilds (cached)', (
      tester,
    ) async {
      var fetchCount = 0;
      Future<String> countingFetcher(String path) async {
        fetchCount++;
        return '# Title\n\nBody paragraph.';
      }

      await tester.pumpWidget(
        _wrap(
          UnifiedDiffView(
            files: [markdownFile()],
            fetchFileContent: countingFetcher,
          ),
        ),
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
        _wrap(
          UnifiedDiffView(
            files: [markdownFile()],
            fetchFileContent: markdownFetcher,
          ),
        ),
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
