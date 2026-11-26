import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/file_header.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/file_unresolved_badge.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_sliver.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_composer_widget.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../helpers/test_wrap.dart';

const _prNumber = 7;

/// The PR identity the inline-comments controller is keyed by.
const _prRef = (
  workspaceId: 'ws',
  repoFullName: 'owner/repo',
  number: _prNumber,
  forge: null,
);

/// A file whose only hunk adds lines 13..19 — the shape a doc-comment block
/// takes, and the one a multi-line review comment anchors to.
final _file = PrFile(
  filename: 'tests/UpdateAssetsGoldenTest.php',
  status: PrFileStatus.modified,
  additions: 7,
  deletions: 0,
  patch:
      '@@ -12,0 +13,7 @@\n'
      '+/**\n'
      '+ * Integration suite for the updateAssets mutation.\n'
      '+ * environment already seeds golden-master tests.\n'
      '+ * Rows this suite mutates are snapshotted.\n'
      '+ * tearDown; rows it creates as a side effect.\n'
      '+ * a metadata value) are deleted directly.\n'
      '+ */\n',
);

PrCodeReviewComment _comment({
  required String body,
  int? startLine = 13,
  int line = 19,
  bool isResolved = false,
  String? threadId = 'THREAD_1',
}) => PrCodeReviewComment(
  id: 4242,
  body: body,
  user: const PrUser(login: 'adrianbesleaga', avatarUrl: ''),
  path: _file.filename,
  position: line,
  createdAt: DateTime.utc(2026, 8, 17),
  startLine: startLine,
  line: line,
  threadId: threadId,
  isResolved: isResolved,
);

final _nextFile = PrFile(
  filename: 'lib/next.dart',
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 0,
  patch: '@@ -1,0 +1,1 @@\n+hello\n',
);

Widget _wrap(
  List<PrCodeReviewComment> comments, {
  GlobalKey<UnifiedDiffViewState>? viewKey,
  List<PrFile>? files,
}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
    ],
    child: testWrap(
      Consumer(
        builder: (context, ref, _) => CustomScrollView(
          slivers: [
            UnifiedDiffView(
              key: viewKey,
              files: files ?? [_file],
              serverComments: comments,
              inlineCommentsController: ref.watch(
                prInlineCommentsControllerProvider(_prRef).notifier,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() => DiffWorkerPool.debugForceInline = false);

  group('server review comments in the diff', () {
    testWidgets('a suggestion renders the lines it replaces', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        // An EMPTY suggestion fence is legal and means "delete these lines".
        // It has nothing to render unless the original lines come with it.
        _wrap([_comment(body: '```suggestion\n```')]),
      );
      await _settle(tester);

      expect(find.text('Suggested change'), findsOneWidget);
      // Numbered from the comment's `start_line`, not from its anchor: the
      // whole 13..19 range is what the comment is about.
      expect(find.text('13'), findsWidgets);
      expect(find.text('19'), findsWidgets);
      expect(find.textContaining('a metadata value'), findsWidgets);
    });

    testWidgets('the file header counts the open conversations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap([_comment(body: 'Why public?')], files: [_file, _nextFile]),
      );
      await _settle(tester);

      // Only the file the conversation is on carries a badge.
      final badge = find.byType(FileUnresolvedBadge);
      expect(badge, findsOneWidget);
      expect(tester.widget<FileUnresolvedBadge>(badge).count, 1);
      expect(
        find.ancestor(
          of: badge,
          matching: find.byWidgetPredicate(
            (w) => w is FastFileHeader && w.file.filename == _file.filename,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('1 unresolved conversation'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a resolved conversation leaves no badge', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap([_comment(body: 'Done', isResolved: true)]),
      );
      await _settle(tester);

      expect(find.byType(FileUnresolvedBadge), findsNothing);
    });

    testWidgets('a resolved conversation arrives collapsed', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap([_comment(body: 'Please rename this.', isResolved: true)]),
      );
      await _settle(tester);

      // Collapsed, but still on screen: a settled conversation that vanished
      // would be one nobody could find again.
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Reply…'), findsNothing);
      expect(find.textContaining('Please rename this.'), findsOneWidget);

      await tester.tap(find.text('Please rename this.'));
      await _settle(tester);

      // Expanded: the full card, with the reply box back. The thread header
      // and the hover toolbar each offer reopen.
      expect(find.text('Reply…'), findsOneWidget);
      expect(find.byIcon(AppIcons.rotateCcw), findsNWidgets(2));
    });

    testWidgets('an open conversation renders expanded', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap([_comment(body: 'Why this cast?')]));
      await _settle(tester);

      expect(find.text('Reply…'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);
      // The card names the range the forge anchored, not just its last line.
      expect(find.text('Lines 13 to 19'), findsOneWidget);

      // Collapsing it leaves the one-line summary behind.
      await tester.tap(
        find.descendant(
          of: find.byType(PrInlineThreadBlock),
          matching: find.byIcon(AppIcons.chevronRight),
        ),
      );
      await _settle(tester);

      expect(find.text('Reply…'), findsNothing);
      expect(find.textContaining('Why this cast?'), findsOneWidget);
    });

    testWidgets('every row of the range carries the conversation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap([_comment(body: 'Whole block.')]));
      await _settle(tester);

      final sliver = tester.renderObject<RenderUnifiedDiffSliver>(
        find.byType(UnifiedDiffSliver),
      );
      final marked = <int>[
        for (var d = 0; d < 24; d++)
          if (sliver.commentGroupAt(0, d) != null) d,
      ];

      // Seven added lines, one comment: the highlight is the conversation's
      // whole range, not just the row the card hangs off.
      expect(marked, hasLength(7));
      expect(
        {for (final d in marked) sliver.commentGroupAt(0, d)},
        {'server-4242'},
      );
    });

    testWidgets('clicking the highlight reopens a collapsed conversation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap([_comment(body: 'Settled here.', isResolved: true)]),
      );
      await _settle(tester);
      expect(find.text('Reply…'), findsNothing);

      final sliver = tester.renderObject<RenderUnifiedDiffSliver>(
        find.byType(UnifiedDiffSliver),
      );
      final firstMarked = [
        for (var d = 0; d < 24; d++)
          if (sliver.commentGroupAt(0, d) != null) d,
      ].first;

      // The highlight is the only trace a collapsed conversation leaves on the
      // code, so clicking ANY of its rows — not just the anchor — reopens it.
      sliver.onCommentTap!(sliver.commentGroupAt(0, firstMarked)!);
      await _settle(tester);

      expect(find.text('Reply…'), findsOneWidget);
    });

    testWidgets(
      'opening reply reserves composer height without a later rebuild',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final viewKey = GlobalKey<UnifiedDiffViewState>();
        await tester.pumpWidget(
          _wrap(
            [_comment(body: 'Why this cast?')],
            viewKey: viewKey,
            files: [_file, _nextFile],
          ),
        );
        await _settle(tester);

        expect(find.text('Reply…'), findsOneWidget);
        final beforeNext = viewKey.currentState!.debugDocument.offsetOfFile(1);

        await tester.tap(find.text('Reply…'));
        // HeightReporter reports on the expansion layout; the host defers
        // the Fenwick update to the next frame. No highlight click.
        await _settle(tester);

        expect(find.byIcon(AppIcons.arrowUp), findsOneWidget);
        final afterNext = viewKey.currentState!.debugDocument.offsetOfFile(1);
        expect(
          afterNext,
          greaterThan(beforeNext + 40),
          reason: 'the next file must move down for the reply composer',
        );

        final threadRect = tester.getRect(find.byType(PrInlineThreadBlock));
        final nextHeader = tester.getRect(find.byType(FastFileHeader).at(1));
        expect(
          threadRect.bottom,
          lessThanOrEqualTo(nextHeader.top + 0.5),
          reason: 'the composer must not paint under the next file header',
        );
      },
    );

    testWidgets('revealing a thread far down lands on its row, not near it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Twenty long files above the target, each with its own conversation:
      // their heights are estimates until parsed and measured, which is
      // what used to move the row after the jump had aimed at it.
      final filler = [
        for (var f = 0; f < 20; f++)
          PrFile(
            filename: 'lib/filler_$f.dart',
            status: PrFileStatus.modified,
            additions: 80,
            deletions: 0,
            patch:
                '@@ -0,0 +1,80 @@\n'
                '${[for (var l = 1; l <= 80; l++) '+final v$l = $l;'].join('\n')}\n',
          ),
      ];
      // The hunk starts at line 200, so file line 205 is display row 6:
      // a file line used as a row index points past the end of the file.
      // Files after the target, so its row can reach the top of the viewport
      // instead of the scroll clamping at the end of the diff.
      final after = [
        for (var f = 0; f < 3; f++)
          PrFile(
            filename: 'lib/after_$f.dart',
            status: PrFileStatus.modified,
            additions: 80,
            deletions: 0,
            patch: filler[f].patch,
          ),
      ];
      final target = PrFile(
        filename: 'lib/target.dart',
        status: PrFileStatus.modified,
        additions: 10,
        deletions: 0,
        patch:
            '@@ -199,0 +200,10 @@\n'
            '${[for (var l = 200; l < 210; l++) '+final t$l = $l;'].join('\n')}\n',
      );
      final comments = [
        for (var f = 0; f < filler.length; f++)
          PrCodeReviewComment(
            id: 1000 + f,
            body: 'filler note $f\n\nwith a second paragraph',
            user: const PrUser(login: 'krishna', avatarUrl: ''),
            path: filler[f].filename,
            position: 40,
            createdAt: DateTime.utc(2026, 8, 17),
            line: 40,
          ),
        PrCodeReviewComment(
          id: 9001,
          body: 'the target note',
          user: const PrUser(login: 'krishna', avatarUrl: ''),
          path: target.filename,
          position: 6,
          createdAt: DateTime.utc(2026, 8, 17),
          line: 205,
        ),
      ];

      final controller = ScrollController();
      addTearDown(controller.dispose);
      final viewKey = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            codeFontFamilyProvider.overrideWithValue('Fira Code'),
            diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
          ],
          child: testWrap(
            Consumer(
              builder: (context, ref, _) => PrimaryScrollController(
                controller: controller,
                child: CustomScrollView(
                  controller: controller,
                  primary: false,
                  slivers: [
                    UnifiedDiffView(
                      key: viewKey,
                      files: [...filler, target, ...after],
                      serverComments: comments,
                      inlineCommentsController: ref.watch(
                        prInlineCommentsControllerProvider(_prRef).notifier,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('the target note'), findsNothing);

      final revealed = viewKey.currentState!.revealThread(
        'server-9001',
        fileIndex: filler.length,
      );
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(await revealed, isTrue);

      final sliver = tester.renderObject<RenderUnifiedDiffSliver>(
        find.byType(UnifiedDiffSliver),
      );
      // Row 0 is the hunk header, so file line 205 is display row 6.
      expect(
        controller.offset,
        moreOrLessEquals(
          sliver.revealOffsetForLine(filler.length, 6),
          epsilon: 1,
        ),
      );
      final card = tester.getRect(find.text('the target note'));
      expect(card.top, greaterThan(0));
      expect(card.bottom, lessThan(800));
    });

    testWidgets('an unknown thread reports that it has no row', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final viewKey = GlobalKey<UnifiedDiffViewState>();
      await tester.pumpWidget(
        _wrap([_comment(body: 'Why this cast?')], viewKey: viewKey),
      );
      await _settle(tester);

      final revealed = viewKey.currentState!.revealThread(
        'server-404',
        fileIndex: 0,
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(await revealed, isFalse);
    });

    testWidgets('the collapsed row height stays one line', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap([_comment(body: 'Settled.', isResolved: true)]),
      );
      await _settle(tester);

      final block = tester.widget<PrInlineThreadBlock>(
        find.byType(PrInlineThreadBlock),
      );
      expect(block.collapsed, isTrue);
      expect(block.thread.resolved, isTrue);
      // The range came through, so the highlight covers all seven rows.
      expect(block.thread.line, 13);
      expect(block.thread.lineEnd, 19);
      expect(block.thread.threadId, 'THREAD_1');
    });
  });

  group('a file with no rows', () {
    // A move without changes: GitHub sends no patch, so the body has no rows.
    final renamed = PrFile(
      filename: 'src/assistant/markdownToHtml.spec.ts',
      previousFilename: 'src/helpers/markdownToHtml.spec.ts',
      status: PrFileStatus.renamed,
      additions: 0,
      deletions: 0,
      patch: '',
    );

    Finder chevronIn(Finder header) => find.descendant(
      of: header,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == AppIcons.chevronUp || w.icon == AppIcons.chevronDown),
      ),
    );

    testWidgets('a rename without changes has no collapse toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const [], files: [renamed, _nextFile]));
      await _settle(tester);

      final headers = find.byType(FastFileHeader);
      expect(headers, findsNWidgets(2));
      expect(chevronIn(headers.at(0)), findsNothing);
      expect(
        tester.widget<FastFileHeader>(headers.at(0)).onToggleExpanded,
        isNull,
      );
      // A file with rows keeps it.
      expect(chevronIn(headers.at(1)), findsOneWidget);
    });

    testWidgets('commenting on it opens a file comment', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const [], files: [renamed]));
      await _settle(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(FastFileHeader),
          matching: find.byIcon(AppIcons.messageSquarePlus),
        ),
      );
      await _settle(tester);

      final composer = find.byType(PrCommentComposer);
      expect(composer, findsOneWidget);
      final widget = tester.widget<PrCommentComposer>(composer);
      // No lines to suggest a change to, and a review takes line comments
      // only, so neither is offered.
      expect(widget.onSuggest, isNull);
      expect(widget.onSubmitBatched, isNull);

      widget.onSubmit('Why was this moved?');
      await _settle(tester);

      final block = tester.widget<PrInlineThreadBlock>(
        find.byType(PrInlineThreadBlock),
      );
      expect(block.thread.isFileLevel, isTrue);
      expect(block.thread.filePath, renamed.filename);
      expect(find.text('Why was this moved?'), findsOneWidget);
      // Now there is something under the header to fold.
      expect(chevronIn(find.byType(FastFileHeader)), findsOneWidget);
    });

    testWidgets('the comment button puts the cursor in the composer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const [], files: [renamed]));
      await _settle(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(FastFileHeader),
          matching: find.byIcon(AppIcons.messageSquarePlus),
        ),
      );
      await _settle(tester);

      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<PrCommentComposer>(),
        isNotNull,
      );
      tester.testTextInput.enterText('Why was this moved?');
      await tester.pump();
      expect(find.text('Why was this moved?'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(PrCommentComposer), findsNothing);
    });

    testWidgets('a forge file comment renders as a thread, not outdated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final comment = PrCodeReviewComment(
        id: 77,
        body: 'Keep the old name?',
        user: const PrUser(login: 'reviewer', avatarUrl: ''),
        path: renamed.filename,
        position: null,
        createdAt: DateTime.utc(2026, 11, 17),
        isFileLevel: true,
      );
      await tester.pumpWidget(_wrap([comment], files: [renamed]));
      await _settle(tester);

      final block = tester.widget<PrInlineThreadBlock>(
        find.byType(PrInlineThreadBlock),
      );
      expect(block.thread.isFileLevel, isTrue);
      expect(block.thread.serverId, 77);
      expect(
        tester
            .widget<FastFileHeader>(find.byType(FastFileHeader))
            .outdatedComments,
        isEmpty,
      );
    });

    testWidgets(
      'an outdated comment thread with originalLine is not anchored inline and goes to outdatedComments',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // _file has lines 13..19 in the current diff. A comment whose `line`
        // became null after a new commit still carries `originalLine: 19` from
        // the old commit; it must NOT render inline at line 19.
        final root = PrCodeReviewComment(
          id: 501,
          body: 'No TerrificComponentWrapper allowed anymore, please migrate.',
          user: const PrUser(login: 'SamuelAlev', avatarUrl: ''),
          path: _file.filename,
          position: null,
          createdAt: DateTime.utc(2026, 11, 25, 2),
          line: null,
          originalLine: 19,
          threadId: 'THREAD_OUTDATED',
          isResolved: true,
          isOutdated: true,
          diffHunk: '@@ -18,2 +18,2 @@\n+<TerrificComponentWrapper />',
        );
        final reply = PrCodeReviewComment(
          id: 502,
          body: 'Done in abf8196.',
          user: const PrUser(login: 'akuma91-frontify', avatarUrl: ''),
          path: _file.filename,
          position: null,
          createdAt: DateTime.utc(2026, 11, 25, 13),
          inReplyToId: 501,
          line: null,
          originalLine: 19,
          threadId: 'THREAD_OUTDATED',
          isResolved: true,
          isOutdated: true,
        );

        await tester.pumpWidget(_wrap([root, reply]));
        await _settle(tester);

        expect(find.byType(PrInlineThreadBlock), findsNothing);
        expect(find.textContaining('TerrificComponentWrapper'), findsNothing);
        expect(
          tester
              .widget<FastFileHeader>(find.byType(FastFileHeader))
              .outdatedComments
              .map((c) => c.id),
          [501, 502],
        );
        expect(find.text('1 outdated'), findsOneWidget);
      },
    );
  });
}
