import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_sliver.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

const _prNumber = 7;

/// The PR identity the inline-comments controller is keyed by.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: _prNumber);

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

Widget _wrap(List<PrCodeReviewComment> comments) {
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
              files: [_file],
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

      // Expanded: the full card, with the reply box back.
      expect(find.text('Reply…'), findsOneWidget);
      expect(find.byIcon(AppIcons.rotateCcw), findsOneWidget);
    });

    testWidgets('an open conversation renders expanded', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap([_comment(body: 'Why this cast?')]));
      await _settle(tester);

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Reply…'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);
      // The card names the range the forge anchored, not just its last line.
      expect(find.text('Lines 13 to 19'), findsOneWidget);

      // Collapsing it leaves the one-line summary behind.
      await tester.tap(find.byIcon(AppIcons.chevronDown).first);
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
}
