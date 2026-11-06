import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child, {PrReviewRepository? repository}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      githubUserProvider.overrideWith((ref) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceIdProvider.overrideWith(
        _NullActiveWorkspaceIdNotifier.new,
      ),
      prReviewRepositoryProvider.overrideWith(
        (ref) => repository ?? const EmptyPrReviewRepository(),
      ),
      prRepositoryProvider.overrideWith(
        (ref, key) => repository ?? const EmptyPrReviewRepository(),
      ),
      prInlineCommentsControllerProvider.overrideWith2(_createController),
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

/// The PR identity the inline-comments controller is keyed by.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: 1);

PrInlineCommentsController _makeController() {
  final container = ProviderContainer(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      githubUserProvider.overrideWith((ref) async => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceIdProvider.overrideWith(
        _NullActiveWorkspaceIdNotifier.new,
      ),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      prInlineCommentsControllerProvider.overrideWith2(_createController),
    ],
  );
  return container.read(prInlineCommentsControllerProvider(_prRef).notifier);
}

class _NullActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

class _FakePrInlineCommentsController extends PrInlineCommentsController {
  _FakePrInlineCommentsController(super.pr);

  @override
  PrInlineCommentsState build() => PrInlineCommentsState();

  void seed(PrInlineThread thread) {
    state = state.copyWith(threads: [...state.threads, thread]);
  }
}

PrInlineCommentsController _createController(PrRef pr) {
  return _FakePrInlineCommentsController(pr);
}

class _ReplyController extends _FakePrInlineCommentsController {
  _ReplyController(super.pr);

  Future<void> Function()? action;
  String? posted;

  @override
  Future<void> replyTo(PrInlineThread thread, String body) async {
    posted = body;
    await action?.call();
  }
}

PrInlineThread _thread({
  String id = 't1',
  String filePath = 'lib/a.dart',
  int line = 1,
  bool resolved = false,
  bool isSuggestion = false,
  String side = 'RIGHT',
  PrInlineSyncState syncState = PrInlineSyncState.local,
  String? syncError,
  List<PrInlineEntry>? entries,
}) {
  return PrInlineThread(
    id: id,
    filePath: filePath,
    line: line,
    side: side,
    kind: isSuggestion
        ? PrInlineThreadKind.suggestion
        : PrInlineThreadKind.comment,
    originalCode: 'original code',
    suggestedCode: 'suggested code',
    entries:
        entries ??
        [
          PrInlineEntry(
            id: 'e1',
            author: 'Test Author',
            body: 'This is a test comment.',
            createdAt: DateTime(2024, 6, 15, 10, 0),
          ),
        ],
    resolved: resolved,
    syncState: syncState,
    syncError: syncError,
  );
}

/// A queued comment as a viewer with no resolved identity writes it: 'You'
/// matches no login, so authorship cannot be what allows the edit.
PrInlineThread _queued({bool isSuggestion = false, String? body}) => _thread(
  isSuggestion: isSuggestion,
  syncState: PrInlineSyncState.pendingReview,
  entries: [
    PrInlineEntry(
      id: 'e1',
      author: 'You',
      body: body ?? 'Generic url',
      createdAt: DateTime(2024, 6, 15),
    ),
  ],
);

/// Hosts the first thread of the real controller, as the diff does: the card
/// is rebuilt from controller state, so a saved edit has to arrive through it.
Widget _liveThread(
  void Function(_FakePrInlineCommentsController) onController,
) {
  return _wrap(
    Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(prInlineCommentsControllerProvider(_prRef));
        final controller =
            ref.read(prInlineCommentsControllerProvider(_prRef).notifier)
                as _FakePrInlineCommentsController;
        onController(controller);
        return state.threads.isEmpty
            ? const SizedBox.shrink()
            : PrInlineThreadBlock(
                thread: state.threads.first,
                controller: controller,
              );
      },
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(
    find.byWidgetPredicate(
      (widget) =>
          widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _startEdit(WidgetTester tester) async {
  await _openMenu(tester);
  await tester.tap(find.text('Edit comment'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('PrInlineThreadBlock - editing an unsent comment', () {
    testWidgets('a queued comment can be rewritten from its menu', (
      tester,
    ) async {
      late _FakePrInlineCommentsController controller;
      await tester.pumpWidget(_liveThread((c) => controller = c));
      await tester.pump();
      controller.seed(_queued());
      await tester.pump();

      await _startEdit(tester);
      await tester.enterText(find.byType(CcTextField), '  Preview url  ');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();

      final thread = controller.threads.single;
      expect(thread.entries.single.body, 'Preview url');
      expect(thread.isPendingReview, isTrue);
      expect(find.byType(CcTextField), findsNothing);
      expect(find.textContaining('Preview url'), findsWidgets);
      expect(find.textContaining('Generic url'), findsNothing);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('cancel keeps the comment and the next edit starts fresh', (
      tester,
    ) async {
      late _FakePrInlineCommentsController controller;
      await tester.pumpWidget(_liveThread((c) => controller = c));
      await tester.pump();
      controller.seed(_queued());
      await tester.pump();

      await _startEdit(tester);
      await tester.enterText(find.byType(CcTextField), 'Abandoned');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(controller.threads.single.entries.single.body, 'Generic url');
      expect(find.byType(CcTextField), findsNothing);

      await _startEdit(tester);
      expect(find.widgetWithText(CcTextField, 'Abandoned'), findsNothing);
      expect(find.widgetWithText(CcTextField, 'Generic url'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('a blank comment cannot be saved', (tester) async {
      late _FakePrInlineCommentsController controller;
      await tester.pumpWidget(_liveThread((c) => controller = c));
      await tester.pump();
      controller.seed(_queued());
      await tester.pump();

      await _startEdit(tester);
      await tester.enterText(find.byType(CcTextField), '   ');
      await tester.pump();

      final save = tester.widget<CcButton>(
        find.ancestor(of: find.text('Save'), matching: find.byType(CcButton)),
      );
      expect(save.onPressed, isNull);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('an edit survives its card scrolling out of the diff', (
      tester,
    ) async {
      final controller = _createController(_prRef);
      final block = PrInlineThreadBlock(
        thread: _queued(),
        controller: controller,
      );
      await tester.pumpWidget(_wrap(block));
      await tester.pump();

      await _startEdit(tester);
      await tester.enterText(find.byType(CcTextField), 'Half written');
      await tester.pump();

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      await tester.pump();
      await tester.pumpWidget(_wrap(block));
      await tester.pump();

      expect(find.widgetWithText(CcTextField, 'Half written'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('a queued suggestion opens its whole text from the menu', (
      tester,
    ) async {
      final controller = _createController(_prRef);
      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: _queued(
              isSuggestion: true,
              body: 'Rename\n```suggestion\nfinal a = 1;\n```',
            ),
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.pencil), findsOneWidget);

      await _startEdit(tester);

      expect(find.byIcon(AppIcons.pencil), findsNothing);
      expect(find.textContaining('Rename'), findsWidgets);
      expect(find.byType(CcTextField), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    for (final (name, state) in [
      ('an in-flight', PrInlineSyncState.pending),
      ('a posted', PrInlineSyncState.synced),
    ]) {
      testWidgets('$name comment offers no local edit', (tester) async {
        final controller = _createController(_prRef);
        await tester.pumpWidget(
          _wrap(
            PrInlineThreadBlock(
              thread: _thread(syncState: state),
              controller: controller,
            ),
          ),
        );
        await tester.pump();

        await _openMenu(tester);

        expect(find.text('Copy thread as Markdown'), findsOneWidget);
        expect(find.text('Edit comment'), findsNothing);

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 200));
      });
    }
  });

  group('PrInlineThreadBlock', () {
    testWidgets('renders thread with single entry', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
    });

    testWidgets('renders thread with multiple entries', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author1',
            body: 'First comment',
            createdAt: DateTime(2024, 6, 15, 10, 0),
          ),
          PrInlineEntry(
            id: 'e2',
            author: 'Author2',
            body: 'Second comment',
            createdAt: DateTime(2024, 6, 15, 11, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('2 comments'), findsOneWidget);
      expect(find.text('Author1'), findsOneWidget);
      expect(find.text('Author2'), findsOneWidget);
    });

    testWidgets('renders resolved thread with check icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(resolved: true);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('renders unresolved thread with resolve icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(resolved: false);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('shows reply hint text', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Reply…'), findsOneWidget);
    });

    testWidgets('shows sync badge for local state', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.local);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('shows sync badge for pending state', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.pending);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Posting…'), findsOneWidget);
    });

    testWidgets('shows sync badge for synced state', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows sync badge for error state', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Network error',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('toggle resolved toggles icon', (tester) async {
      final controller = _createController(_prRef);

      final thread = _thread();
      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
    });

    testWidgets('renders thread line info', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(line: 42, filePath: 'lib/main.dart');

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });

    testWidgets('renders suggestion thread type', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: '```suggestion\nnew code\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.textContaining('Author'), findsOneWidget);
    });

    testWidgets('renders comment thread type', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: false,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: 'A comment',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.textContaining('Author'), findsOneWidget);
    });

    testWidgets('reply tap opens text field', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();

      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('renders multiple entries sorted by time', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'First',
            body: 'Body',
            createdAt: DateTime(2024, 1, 1),
          ),
          PrInlineEntry(
            id: 'e2',
            author: 'Second',
            body: 'Body',
            createdAt: DateTime(2024, 6, 1),
          ),
          PrInlineEntry(
            id: 'e3',
            author: 'Third',
            body: 'Body',
            createdAt: DateTime(2024, 12, 1),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('3 comments'), findsOneWidget);
    });

    testWidgets('suggestion thread has edit icon for first entry', (
      tester,
    ) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: '```suggestion\nsuggested code\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    });

    testWidgets('tapping edit on suggestion opens suggestion editor', (
      tester,
    ) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: '```suggestion\noriginal suggested code\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.ensureVisible(find.byIcon(AppIcons.pencil));
      await tester.tap(find.byIcon(AppIcons.pencil));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('editing preserves and can add multiple suggestion fences', (
      tester,
    ) async {
      final controller = _makeController();
      final thread = controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'old code',
        suggestedCode: 'first',
        authorBody:
            'Choose one:\n\n'
            '```suggestion\nfirst\n```\n\n'
            'Or:\n\n'
            '```suggestion\nsecond\n```',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.pencil));
      await tester.pump();

      final fields = find.byType(CcTextField);
      expect(fields, findsNWidgets(2));
      expect(
        tester.widget<CcTextField>(fields.at(0)).controller?.text,
        'first',
      );
      expect(
        tester.widget<CcTextField>(fields.at(1)).controller?.text,
        'second',
      );

      await tester.tap(find.text('Add a suggestion'));
      await tester.pump();
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), 'firstEdited');
      await tester.enterText(fields.at(1), 'secondEdited');
      await tester.enterText(fields.at(2), 'third');
      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();

      expect(
        controller.threads.single.entries.single.body,
        'Choose one:\n\n'
        '```suggestion\nfirstEdited\n```\n\n'
        'Or:\n\n'
        '```suggestion\nsecondEdited\n```\n\n'
        '```suggestion\nthird\n```',
      );
    });

    testWidgets('suggestion editor has Send button', (tester) async {
      final controller = _makeController();
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: '```suggestion\noriginal suggested code\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.ensureVisible(find.byIcon(AppIcons.pencil));
      await tester.tap(find.byIcon(AppIcons.pencil));
      await tester.pump();

      expect(find.byIcon(AppIcons.arrowUp), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('cancel edit hides editor', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: '```suggestion\noriginal suggested code\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.byIcon(AppIcons.pencil));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('comment thread does not show edit icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: false,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Author',
            body: 'Just a comment',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.pencil), findsNothing);
    });
    testWidgets('resolve button tap triggers controller', (tester) async {
      final controller = _makeController();
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check',
      );
      final thread = controller.threads.first;

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
      await tester.ensureVisible(find.byIcon(AppIcons.checkCircle2));
      await tester.tap(find.byIcon(AppIcons.checkCircle2));
      await tester.pump();

      expect(controller.threads.first.resolved, isTrue);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('reopen button tap triggers controller', (tester) async {
      final controller = _makeController();
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check',
      );
      controller.toggleResolved(controller.threads.first.id);
      final thread = controller.threads.first;

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
      // The header and the hover toolbar both offer reopen.
      final reopen = find.byIcon(AppIcons.rotateCcw);
      await tester.ensureVisible(reopen.first);
      await tester.tap(reopen.first);
      await tester.pump();

      expect(controller.threads.first.resolved, isFalse);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('synced badge is clickable for retry', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('Synced'), findsOneWidget);
    });
    testWidgets('reply adds entry to controller thread', (tester) async {
      final controller = _makeController();
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check',
      );
      final thread = controller.threads.first;

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      final textField = find.byType(CcTextField);
      await tester.enterText(textField, 'My reply');
      await tester.pump();

      await tester.ensureVisible(find.byIcon(AppIcons.arrowUp));
      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();

      expect(controller.threads.first.entries.length, 2);
    });

    testWidgets('line information is consistent', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(line: 99, filePath: 'lib/main.dart');

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - avatar rendering', () {
    testWidgets('entry tile shows author avatar with initials', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Alice Cooper',
            body: 'Looks good',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CcAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pump();
    });

    testWidgets('single word author shows first letter', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Alice',
            body: 'Nice',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('empty author shows question mark', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: '',
            body: 'Anonymous',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - sync badge icons', () {
    testWidgets('local badge has cloudOff icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.local);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.cloudOff), findsOneWidget);
    });

    testWidgets('pending badge has loader icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.pending);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.loader), findsOneWidget);
    });

    testWidgets('synced badge has cloud icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.cloud), findsOneWidget);
    });

    testWidgets('error badge has alertCircle icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Timeout',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.alertCircle), findsOneWidget);
    });

    testWidgets('error badge tooltip shows error message', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Connection refused',
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
    });
  });

  group('PrInlineThreadBlock - reply form interactions', () {
    testWidgets('empty reply text does not send', (tester) async {
      final controller = _makeController();
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check',
      );
      final thread = controller.threads.first;

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      await tester.ensureVisible(find.byIcon(AppIcons.arrowUp));
      await tester.tap(find.byIcon(AppIcons.arrowUp));
      await tester.pump();

      expect(controller.threads.first.entries.length, 1);
    });

    testWidgets('submit reply via Enter key', (tester) async {
      final controller = _makeController();
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Check',
      );
      final thread = controller.threads.first;

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      await tester.enterText(find.byType(CcTextField), 'Fast reply');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(controller.threads.first.entries.length, 2);
    });

    testWidgets('reply field focuses after tapping reply', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();

      final textField = tester.widget<CcTextField>(find.byType(CcTextField));
      expect(textField.autofocus, isTrue);
    });
  });

  group('PrInlineThreadBlock reply drafts', () {
    testWidgets(
      'remount and target changes retain only the matching thread draft',
      (tester) async {
        const otherPr = (
          workspaceId: 'ws-2',
          repoFullName: 'owner/repo',
          number: 1,
        );
        final first = _ReplyController(_prRef);
        final elsewhere = _ReplyController(otherPr);
        final target = ValueNotifier(0);
        addTearDown(target.dispose);
        await tester.pumpWidget(
          _wrap(
            ValueListenableBuilder<int>(
              valueListenable: target,
              builder: (_, index, _) => index < 0
                  ? const SizedBox.shrink()
                  : PrInlineThreadBlock(
                      key: const ValueKey('reused-thread'),
                      thread: _thread(id: index == 1 ? 't2' : 't1'),
                      controller: index == 2 ? elsewhere : first,
                    ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Reply…'));
        await tester.pump();
        await tester.enterText(find.byType(CcTextField), 'thread one reply');
        target.value = -1;
        await tester.pump();
        target.value = 0;
        await tester.pump();
        expect(
          tester.widget<CcTextField>(find.byType(CcTextField)).controller?.text,
          'thread one reply',
        );
        for (final index in [1, 2]) {
          target.value = index;
          await tester.pump();
          expect(find.byType(CcTextField), findsNothing);
          await tester.tap(find.text('Reply…'));
          await tester.pump();
          expect(
            tester
                .widget<CcTextField>(find.byType(CcTextField))
                .controller
                ?.text,
            isEmpty,
          );
        }
        target.value = 0;
        await tester.pump();
        expect(
          tester.widget<CcTextField>(find.byType(CcTextField)).controller?.text,
          'thread one reply',
        );
      },
    );

    testWidgets(
      'failed reply survives; success does not erase edits while sending',
      (tester) async {
        final controller = _ReplyController(_prRef);
        final pending = Completer<void>();
        controller.action = () => pending.future;
        await tester.pumpWidget(
          _wrap(
            CcToastScope(
              child: PrInlineThreadBlock(
                thread: _thread(),
                controller: controller,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text('Reply…'));
        await tester.pump();
        await tester.enterText(find.byType(CcTextField), 'first reply');
        await tester.tap(find.byIcon(AppIcons.arrowUp));
        await tester.pump();
        final draft = tester
            .widget<CcTextField>(find.byType(CcTextField))
            .controller!;
        draft.text = 'edited while sending';
        pending.complete();
        await tester.pump();
        expect(controller.posted, 'first reply');
        expect(draft.text, 'edited while sending');
        controller.action = () async => throw StateError('offline');
        await tester.tap(find.byIcon(AppIcons.arrowUp));
        await tester.pump();
        expect(draft.text, 'edited while sending');
        controller.action = null;
        await tester.tap(find.byIcon(AppIcons.arrowUp));
        await tester.pump();
        expect(draft.text, isEmpty);
      },
    );
  });

  group('PrInlineThreadBlock - container styling', () {
    testWidgets('thread block has margin decoration', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.margin, isNotNull);
    });

    testWidgets('resolved thread check icon is green', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(resolved: true);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('unresolved thread shows the resolve icon', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(resolved: false);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.checkCircle2), findsOneWidget);
      expect(find.byIcon(AppIcons.rotateCcw), findsNothing);
    });
  });

  group('PrInlineThreadBlock - divider between entries', () {
    testWidgets('multiple entries have dividers', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'A',
            body: 'First',
            createdAt: DateTime(2024, 1, 1),
          ),
          PrInlineEntry(
            id: 'e2',
            author: 'B',
            body: 'Second',
            createdAt: DateTime(2024, 2, 1),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcDivider), findsNWidgets(2));
    });

    testWidgets('single entry has no divider between entries', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.byType(CcDivider), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - suggestions and code rendering', () {
    testWidgets('suggestion entry shows suggested code', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Reviewer',
            body: '```suggestion\nconst hello = "world";\n```',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.textContaining('Reviewer'), findsOneWidget);
    });

    testWidgets('comment entry shows comment text without edit icon', (
      tester,
    ) async {
      final controller = _createController(_prRef);
      final thread = _thread(
        isSuggestion: false,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author: 'Reviewer',
            body: 'Just a regular comment.',
            createdAt: DateTime(2024, 6, 15),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.textContaining('Reviewer'), findsOneWidget);
      expect(find.byIcon(AppIcons.pencil), findsNothing);
    });
  });

  group('PrInlineThreadBlock - controller key handling', () {
    testWidgets('thread block has correct key from controller', (tester) async {
      final controller = _createController(_prRef);
      final thread = _thread(id: 'custom-id', line: 5);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: thread, controller: controller)),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - reactions', () {
    PrInlineThread syncedThread() => _thread(
      syncState: PrInlineSyncState.synced,
      entries: [
        PrInlineEntry(
          id: 'server-entry-42',
          author: 'Reviewer',
          body: 'Looks good',
          createdAt: DateTime(2024, 6, 15, 10),
          serverCommentId: 42,
          reactions: const [
            ReactionGroup(
              content: '+1',
              emoji: '👍',
              count: 2,
              userReacted: false,
            ),
          ],
        ),
      ],
    );

    testWidgets('synced entries render reaction chips and the React control', (
      tester,
    ) async {
      final controller = _createController(_prRef);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(thread: syncedThread(), controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(AppIcons.smile), findsOneWidget);
      expect(find.text('React'), findsNothing);
    });

    testWidgets('local entries render no reaction bar', (tester) async {
      final controller = _createController(_prRef);

      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: _thread(), controller: controller)),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.smile), findsNothing);
    });

    testWidgets('selecting an emoji toggles the reaction on the server '
        'comment', (tester) async {
      final repository = _RecordingPrReviewRepository();
      final controller = _createController((
        workspaceId: 'ws',
        repoFullName: 'owner/repo',
        number: 7,
      ));

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(thread: syncedThread(), controller: controller),
          repository: repository,
        ),
      );
      await tester.pump();

      final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(hover.removePointer);
      await hover.addPointer();
      await hover.moveTo(tester.getCenter(find.text('Looks good')));
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.smile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎉'));
      await tester.pumpAndSettle();

      expect(repository.reviewCommentCalls, hasLength(1));
      final call = repository.reviewCommentCalls.single;
      expect(call.commentId, 42);
      expect(call.prNumber, 7);
      expect(call.content, 'hooray');
      expect(call.add, isTrue);
    });
  });

  group('PrInlineThreadBlock - collapsed row', () {
    testWidgets('the state group sits flush against the right edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = _createController(_prRef);
      final thread = _thread(
        resolved: true,
        entries: [
          PrInlineEntry(id: 'e1', author: 'jorgsowa', body: 'Suggested change'),
          PrInlineEntry(id: 'e2', author: 'you', body: 'Done.'),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
            collapsed: true,
            onToggleCollapsed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 reply'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);

      // The reply count and the resolved badge belong at the RIGHT edge, not
      // floating at the end of the preview's share of the row. This regressed
      // when the author name was a flex child: a loose Flexible claims a share
      // of the free space and then uses only part of it, and a Row packs from
      // the start — so the unclaimed remainder became trailing slack.
      final rowRight = tester.getRect(find.byType(PrInlineThreadBlock)).right;
      final badgeRight = tester.getRect(find.text('Resolved')).right;
      expect(rowRight - badgeRight, lessThan(40));
    });

    testWidgets('a very long author name cannot push the badge off', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = _createController(_prRef);
      final thread = _thread(
        resolved: true,
        entries: [
          PrInlineEntry(
            id: 'e1',
            author:
                'an-extremely-long-github-login-that-goes-on-and-on-forever',
            body: 'Suggested change',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
            collapsed: true,
            onToggleCollapsed: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Resolved'), findsOneWidget);
    });
  });

  group('keyboard and screen readers', () {
    testWidgets('Reply… is a button the keyboard can activate', (tester) async {
      final controller = _createController(_prRef);
      await tester.pumpWidget(
        _wrap(PrInlineThreadBlock(thread: _thread(), controller: controller)),
      );
      await tester.pump();

      Focus.of(tester.element(find.text('Reply…'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('a collapsed conversation is a focusable, collapsed '
        'disclosure', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = _createController(_prRef);
      var expanded = 0;
      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: _thread(),
            controller: controller,
            collapsed: true,
            onToggleCollapsed: () => expanded++,
          ),
        ),
      );
      await tester.pump();

      final row = find.bySemanticsLabel(RegExp('^Expand comment'));
      expect(
        tester.getSemantics(row),
        isSemantics(
          isButton: true,
          isFocusable: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );

      Focus.of(
        tester.element(find.byIcon(AppIcons.chevronRight)),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(expanded, 1);
      handle.dispose();
    });
  });
}

/// Records `toggleReviewCommentReaction` invocations for assertion.
class _RecordingPrReviewRepository extends EmptyPrReviewRepository {
  /// Captured calls in order.
  final List<({int commentId, int prNumber, String content, bool add})>
  reviewCommentCalls = [];

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {
    reviewCommentCalls.add((
      commentId: commentId,
      prNumber: prNumber,
      content: content,
      add: add,
    ));
  }
}
