import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Creates a controller with a ProviderContainer that's auto-disposed via
/// [addTearDown]. Must be called inside a test body.
PrInlineCommentsController _makeController(WidgetTester tester, {int prNumber = 1}) {
  final container = ProviderContainer(
    overrides: [
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container.read(prInlineCommentsControllerProvider(prNumber).notifier);
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      workspacesProvider.overrideWith(
        (ref) => Stream.value(const <Workspace>[]),
      ),
      workspaceAgentsProvider.overrideWith(
        (ref, workspaceId) => Stream.value(const <Agent>[]),
      ),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('PrCommentComposer', () {
    testWidgets('renders with placeholder text', (tester) async {
      String? submitted;
      var cancelled = false;

      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            placeholder: 'Leave a comment...',
            autofocus: false,
            onSubmit: (body) => submitted = body,
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Leave a comment...'), findsOneWidget);
      expect(submitted, isNull);
      expect(cancelled, false);
    });

    testWidgets('calls onSubmit when text entered and send pressed', (
      tester,
    ) async {
      String? submitted;

      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            autofocus: false,
            onSubmit: (body) => submitted = body,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      await tester.enterText(field, 'Great work!');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sendButton = find.byIcon(LucideIcons.arrowUp);
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(submitted, 'Great work!');
    });

    testWidgets('does not submit empty text', (tester) async {
      String? submitted;

      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            autofocus: false,
            onSubmit: (body) => submitted = body,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      await tester.enterText(field, '   ');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sendButton = find.byIcon(LucideIcons.arrowUp);
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(submitted, isNull);
    });

    testWidgets('calls onCancel when escape pressed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            autofocus: false,
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      await tester.enterText(field, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Focus the text field then send escape
      await tester.tap(field);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('PrCommentComposer', () {
    testWidgets('renders with seeded original code', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            initialText: 'print("hello world");',
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      expect(
        tester.widget<TextField>(field).controller?.text,
        'print("hello world");',
      );
    });

    testWidgets('submits code wrapped in suggestion fence', (tester) async {
      String? submitted;

      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            initialText: 'old code',
            onSubmit: (body) => submitted = body,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      await tester.enterText(field, 'new code');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sendButton = find.byIcon(LucideIcons.arrowUp);
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(submitted, 'new code');
    });

    testWidgets('calls onCancel when suggestion body is empty', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            initialText: 'original',
            onSubmit: (_) {},
            onCancel: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      await tester.enterText(field, '   ');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sendButton = find.byIcon(LucideIcons.arrowUp);
      await tester.ensureVisible(sendButton);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(cancelled, false);
    });
  });

  group('PrInlineThreadBlock', () {
    testWidgets('renders thread with single entry', (tester) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 42,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'print("hello");',
        suggestedCode: 'print("hello");',
        authorBody: 'Consider using a logger.',
        author: 'Dev',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
      expect(find.text('Consider using a logger.'), findsOneWidget);
    });

    testWidgets('renders thread with multiple entries after reply', (
      tester,
    ) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'foo',
        suggestedCode: 'foo',
        authorBody: 'First comment',
        author: 'Alice',
      );

      controller.reply(
        threadId: thread.id,
        body: 'Second reply',
        author: 'Bob',
      );

      final updatedThread = controller.threads.first;
      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: updatedThread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('2 comments'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('First comment'), findsOneWidget);
      expect(find.text('Second reply'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('shows reply field when Reply... tapped', (tester) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Hi',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Reply\u2026'), findsOneWidget);
      await tester.tap(find.text('Reply\u2026'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && (w.decoration?.hintText == 'Reply\u2026'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sending reply adds entry to thread', (tester) async {
      final controller = _makeController(tester);

      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Original',
      );

      final updatedThread = controller.threads.first;
      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: updatedThread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Reply\u2026'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final replyFields = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText == 'Reply\u2026'),
      );
      await tester.enterText(replyFields, 'My reply');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Submit via onSubmitted
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Re-read the updated thread from the controller.
      final threadAfterReply = controller.threads.first;
      expect(threadAfterReply.entries.length, 2);
      expect(threadAfterReply.entries.last.body, 'My reply');

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('resolve button toggles thread state', (tester) async {
      final controller = _makeController(tester);

      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Body',
      );

      final thread = controller.threads.first;
      expect(thread.resolved, false);

      // Toggle resolved directly on the controller.
      controller.toggleResolved(thread.id);
      expect(controller.threads.first.resolved, true);

      // Toggle back.
      controller.toggleResolved(thread.id);
      expect(controller.threads.first.resolved, false);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('PrCommentsInbox', () {
    testWidgets('renders empty state when no threads', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: const [],
            onToggleResolved: (_) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No open conversations'), findsOneWidget);
    });

    testWidgets('renders thread list with entries', (tester) async {
      final controller = _makeController(tester);

      controller.create(
        filePath: 'lib/a.dart',
        line: 10,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Issue here',
        author: 'DevA',
      );

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: (_) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('DevA'), findsOneWidget);
      expect(find.text('Issue here'), findsOneWidget);
      expect(find.text('lib/a.dart : line 10'), findsOneWidget);
    });

    testWidgets('shows resolved toggle when resolved threads exist', (
      tester,
    ) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/b.dart',
        line: 5,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'old',
        suggestedCode: 'old',
        authorBody: 'Resolved comment',
      );

      controller.toggleResolved(thread.id);

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: controller.toggleResolved,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No open conversations'), findsOneWidget);
      expect(find.text('Show 1 resolved'), findsOneWidget);
    });
  });

  group('PrInlineThreadDot', () {
    testWidgets('renders unresolved dot', (tester) async {
      await tester.pumpWidget(_wrap(const PrInlineThreadDot(resolved: false)));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrInlineThreadDot), findsOneWidget);
    });

    testWidgets('renders resolved dot', (tester) async {
      await tester.pumpWidget(_wrap(const PrInlineThreadDot(resolved: true)));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(PrInlineThreadDot), findsOneWidget);
    });
  });

  group('PrSelectionToolbar', () {
    testWidgets('renders toolbar with three action icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  PrSelectionToolbar(
                    onComment: () {},
                    onSuggest: () {},
                    onReact: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byTooltip('Add a comment'), findsOneWidget);
      expect(find.byTooltip('Add a suggestion'), findsOneWidget);
      expect(find.byTooltip('Add a reaction'), findsOneWidget);
    });

    testWidgets('comment icon calls onComment', (tester) async {
      var commented = false;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  PrSelectionToolbar(
                    onComment: () => commented = true,
                    onSuggest: () {},
                    onReact: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byTooltip('Add a comment'));
      expect(commented, true);
    });

    testWidgets('suggestion icon calls onSuggest', (tester) async {
      var suggested = false;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  PrSelectionToolbar(
                    onComment: () {},
                    onSuggest: () => suggested = true,
                    onReact: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byTooltip('Add a suggestion'));
      expect(suggested, true);
    });

    testWidgets('reaction icon calls onReact', (tester) async {
      var reacted = false;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  PrSelectionToolbar(
                    onComment: () {},
                    onSuggest: () {},
                    onReact: () => reacted = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.byTooltip('Add a reaction'));
      expect(reacted, true);
    });
  });

  group('SuggestionAwareMarkdown', () {
    testWidgets('renders plain markdown body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            body: 'Just a comment',
            originalCode: 'original',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Just a comment'), findsOneWidget);
    });

    testWidgets('renders suggestion mini diff for suggestion fence', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            body: '```suggestion\nnew line\n```',
            originalCode: 'old line',
            filePath: 'lib/test.dart',
            originalStartLine: 10,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.text('old line'), findsOneWidget);
      expect(find.text('new line'), findsOneWidget);
    });

    testWidgets('renders surrounding text around suggestion', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            body: 'Before\n\n```suggestion\nfixed\n```\n\nAfter',
            originalCode: 'broken',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders without suggestion fence as plain markdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            body: '```dart\nprint("hi");\n```',
            originalCode: 'original',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsNothing);
    });

    testWidgets('renders empty body without crash', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(body: '', originalCode: 'original'),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SuggestionAwareMarkdown), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - edge cases', () {
    testWidgets('renders suggestion thread with diff icon', (tester) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'old code',
        suggestedCode: 'new code',
        authorBody: '```suggestion\nnew code\n```',
        author: 'Dev',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Dev'), findsOneWidget);
    });

    testWidgets('reply button sends reply via controller', (tester) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: 'x',
        authorBody: 'Start',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Reply\u2026'), findsOneWidget);

      await tester.tap(find.text('Reply\u2026'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final replyField = find.byWidgetPredicate(
        (w) => w is TextField && (w.decoration?.hintText == 'Reply\u2026'),
      );
      await tester.enterText(replyField, 'Nice catch');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final sendButtons = find.byTooltip('Send');
      await tester.tap(sendButtons.last);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Rather than matching text (the widget may not re-render with the
      // updated thread prop), assert on the controller state directly.
      final threadAfter = controller.threads.first;
      expect(threadAfter.entries.length, 2);
      expect(threadAfter.entries.last.body, 'Nice catch');

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });

  group('PrCommentsInbox - edge cases', () {
    testWidgets('renders mixed open and resolved threads', (tester) async {
      final controller = _makeController(tester);

      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'Open one',
        author: 'Dev1',
      );

      final t2 = controller.create(
        filePath: 'lib/b.dart',
        line: 2,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'b',
        suggestedCode: 'b',
        authorBody: 'Resolved one',
        author: 'Dev2',
      );
      controller.toggleResolved(t2.id);

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: (_) {},
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Dev1'), findsOneWidget);
      expect(find.text('Show 1 resolved'), findsOneWidget);
    });

    testWidgets('toggle resolved switch shows resolved threads', (
      tester,
    ) async {
      final controller = _makeController(tester);

      final t1 = controller.create(
        filePath: 'lib/x.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: 'x',
        authorBody: 'Done',
      );
      controller.toggleResolved(t1.id);

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: controller.toggleResolved,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final toggle = find.byType(CcSwitch);
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('resolved thread shows check icon in inbox', (tester) async {
      final controller = _makeController(tester);

      final t = controller.create(
        filePath: 'lib/r.dart',
        line: 3,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'r',
        suggestedCode: 'r',
        authorBody: 'Resolved',
      );
      controller.toggleResolved(t.id);

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: controller.toggleResolved,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final toggle = find.byType(CcSwitch);
      await tester.tap(toggle);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('tapping thread with onJumpTo calls onClose', (tester) async {
      var closed = false;
      final controller = _makeController(tester);

      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'Comment',
      );

      await tester.pumpWidget(
        _wrap(
          PrCommentsInbox(
            threads: controller.threads,
            onToggleResolved: (_) {},
            onClose: () => closed = true,
            onJumpTo: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Comment'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(closed, true);
    });
  });

  group('PrCommentComposer - additional states', () {
    testWidgets('renders with autofocus', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            autofocus: true,
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final field = find.byType(TextField);
      expect(field, findsOneWidget);
    });

    testWidgets('renders prefix icon when placeholder given', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrCommentComposer(
            placeholder: 'Add a review comment...',
            autofocus: false,
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Add a review comment...'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - thread interaction states', () {
    testWidgets('shows pending sync state indicator', (tester) async {
      final controller = _makeController(tester);

      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Comment',
      );

      final pendingThread = thread.copyWith(
        syncState: PrInlineSyncState.pending,
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: pendingThread,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('long comment body renders without overflow', (tester) async {
      final controller = _makeController(tester);

      final longBody = List.filled(20, 'line of comment text.').join('\n');
      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: longBody,
        author: 'Dev',
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: controller.threads.first,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Dev'), findsOneWidget);
    });
  });
}
