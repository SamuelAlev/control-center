import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/comment_action_cluster.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('a thread offers resolve; a lone comment does not', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onSendToAgent: () {},
        ),
      ),
    );

    expect(find.text('React'), findsNothing);
    expect(find.byIcon(AppIcons.smile), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsNothing);

    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onResolve: () {},
          onSendToAgent: () {},
        ),
      ),
    );
    expect(find.byIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('delete stays out of the menu without permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onSendToAgent: () {},
          onCopyMarkdown: () {},
        ),
      ),
    );
    await tester.tap(_overflowButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete comment'), findsNothing);
    expect(find.text('Send to agent'), findsOneWidget);
    expect(find.text('Copy as Markdown'), findsOneWidget);
    expect(find.text('Resolve thread'), findsNothing);

    await tester.tap(find.text('Send to agent'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onSendToAgent: () {},
          onDelete: () {},
          onResolve: () {},
          threadMenu: true,
          onCopyMarkdown: () {},
        ),
      ),
    );
    await tester.tap(_overflowButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete comment'), findsOneWidget);
    expect(find.text('Resolve thread'), findsWidgets);
    expect(find.text('Copy thread as Markdown'), findsOneWidget);
  });

  testWidgets('React offers only the GitHub reaction set', (tester) async {
    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onSendToAgent: () {},
        ),
      ),
    );
    await tester.tap(find.byIcon(AppIcons.smile));
    await tester.pumpAndSettle();

    expect(
      find.text('Only GitHub-supported emojis are available'),
      findsNothing,
    );
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('👀'), findsOneWidget);
  });

  testWidgets('copy link sits beside react and stays out of the menu', (
    tester,
  ) async {
    var copies = 0;
    await tester.pumpWidget(
      testWrap(
        CommentActionCluster(
          onToggleReaction: (content, {required add}) async {},
          onCopyLink: () => copies++,
          onSendToAgent: () {},
        ),
      ),
    );

    expect(find.byIcon(AppIcons.link), findsOneWidget);
    expect(find.text('Copy link to comment'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.link));
    await tester.pump();
    expect(copies, 1);

    await tester.tap(_overflowButton);
    await tester.pumpAndSettle();
    expect(find.text('Copy link to comment'), findsNothing);
    expect(find.text('Send to agent'), findsOneWidget);
  });
}

final _overflowButton = find.byWidgetPredicate(
  (widget) => widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
);
