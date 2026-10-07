import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/comment_action_cluster.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  group('CommentActionsHost keyboard', () {
    Widget host() => testWrap(
      Column(
        children: [
          CcButton(onPressed: () {}, child: const Text('before')),
          SizedBox(
            width: 400,
            height: 100,
            child: CommentActionsHost(
              actions: (onPinned) => CommentActionCluster(
                onPinnedChanged: onPinned,
                onCopyLink: () {},
                onResolve: () {},
              ),
              child: const SizedBox(width: 400, height: 100),
            ),
          ),
          CcButton(onPressed: () {}, child: const Text('after')),
        ],
      ),
    );

    String? focusedButtonText() {
      final context = FocusManager.instance.primaryFocus?.context;
      final child = context?.findAncestorWidgetOfExactType<CcButton>()?.child;
      return child is Text ? child.data : null;
    }

    String? focusedIconTooltip() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<CcIconButton>()
        ?.tooltip;

    testWidgets('Tab passes through the toolbar instead of cycling in it', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      final visited = <String?>[];
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        visited.add(focusedButtonText() ?? focusedIconTooltip());
      }
      // before → entry stub → copy link → resolve → overflow → after. The
      // toolbar used to be a FocusScope whose closed loop never let go.
      expect(visited.first, 'before');
      expect(visited.last, 'after');
    });

    testWidgets('Enter on the entry stub moves into the toolbar; Escape '
        'steps back out', (tester) async {
      await tester.pumpWidget(host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // before
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // entry stub
      await tester.pumpAndSettle();
      final entry = FocusManager.instance.primaryFocus;
      expect(entry?.debugLabel, 'comment-actions-entry');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedIconTooltip(), isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, entry);
    });
  });
}

final _overflowButton = find.byWidgetPredicate(
  (widget) => widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
);
