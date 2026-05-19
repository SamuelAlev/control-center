import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      githubAuthTokenProvider.overrideWith((ref) => ''),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceIdProvider.overrideWith(_NullActiveWorkspaceIdNotifier.new),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
      prInlineCommentsControllerProvider.overrideWith2(
        _createController,
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

PrInlineCommentsController _makeController({int prNumber = 1}) {
  final container = ProviderContainer(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      githubAuthTokenProvider.overrideWith((ref) => ''),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      activeWorkspaceIdProvider.overrideWith(_NullActiveWorkspaceIdNotifier.new),
      prReviewRepositoryProvider.overrideWith((ref) => const EmptyPrReviewRepository()),
      prInlineCommentsControllerProvider.overrideWith2(
        _createController,
      ),
    ],
  );
  return container.read(prInlineCommentsControllerProvider(prNumber).notifier);
}

class _NullActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

class _FakePrInlineCommentsController extends PrInlineCommentsController {
  _FakePrInlineCommentsController(super.prNumber);

  @override
  PrInlineCommentsState build() => PrInlineCommentsState();
}

PrInlineCommentsController _createController(int prNumber) {
  return _FakePrInlineCommentsController(prNumber);
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
    entries: entries ??
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

void main() {
  group('PrInlineThreadBlock', () {
    testWidgets('renders thread with single entry', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Test Author'), findsOneWidget);
    });

    testWidgets('renders thread with multiple entries', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2 comments'), findsOneWidget);
      expect(find.text('Author1'), findsOneWidget);
      expect(find.text('Author2'), findsOneWidget);
    });

    testWidgets('renders resolved thread with check icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(resolved: true);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('renders unresolved thread with resolve icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(resolved: false);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    testWidgets('shows reply hint text', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reply…'), findsOneWidget);
    });

    testWidgets('shows sync badge for local state', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.local);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('shows sync badge for pending state', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.pending);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Posting…'), findsOneWidget);
    });

    testWidgets('shows sync badge for synced state', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows sync badge for error state', (tester) async {
      final controller = _createController(1);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Network error',
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('toggle resolved toggles icon', (tester) async {
      final controller = _createController(1);

      final thread = _thread();
      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
    });

    testWidgets('renders thread line info', (tester) async {
      final controller = _createController(1);
      final thread = _thread(line: 42, filePath: 'lib/main.dart');

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });

    testWidgets('renders suggestion thread type', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Author'), findsOneWidget);
    });

    testWidgets('renders comment thread type', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Author'), findsOneWidget);
    });

    testWidgets('reply tap opens text field', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders multiple entries sorted by time', (tester) async {
      final controller = _createController(1);
      final thread = _thread(
        entries: [
          PrInlineEntry(id: 'e1', author: 'First', body: 'Body', createdAt: DateTime(2024, 1, 1)),
          PrInlineEntry(id: 'e2', author: 'Second', body: 'Body', createdAt: DateTime(2024, 6, 1)),
          PrInlineEntry(id: 'e3', author: 'Third', body: 'Body', createdAt: DateTime(2024, 12, 1)),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('3 comments'), findsOneWidget);
    });

    testWidgets('suggestion thread has edit icon for first entry', (
      tester,
    ) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('tapping edit on suggestion opens suggestion editor', (
      tester,
    ) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.byIcon(LucideIcons.pencil));
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.byIcon(LucideIcons.pencil));
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();

      expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('cancel edit hides editor', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('comment thread does not show edit icon', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.pencil), findsNothing);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
      await tester.ensureVisible(find.byIcon(LucideIcons.check));
      await tester.tap(find.byIcon(LucideIcons.check));
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcTooltip), findsWidgets);
      await tester.ensureVisible(find.byIcon(LucideIcons.checkCircle2));
      await tester.tap(find.byIcon(LucideIcons.checkCircle2));
      await tester.pump();

      expect(controller.threads.first.resolved, isFalse);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('synced badge is clickable for retry', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'My reply');
      await tester.pump();

      await tester.ensureVisible(find.byIcon(LucideIcons.arrowUp));
      await tester.tap(find.byIcon(LucideIcons.arrowUp));
      await tester.pump();

      expect(controller.threads.first.entries.length, 2);
    });

    testWidgets('line information is consistent', (tester) async {
      final controller = _createController(1);
      final thread = _thread(line: 99, filePath: 'lib/main.dart');

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - avatar rendering', () {
    testWidgets('entry tile shows author avatar with initials', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
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
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('empty author shows question mark', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - sync badge icons', () {
    testWidgets('local badge has cloudOff icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.local);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
    });

    testWidgets('pending badge has loader icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.pending);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.loader), findsOneWidget);
    });

    testWidgets('synced badge has cloud icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(syncState: PrInlineSyncState.synced);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.cloud), findsOneWidget);
    });

    testWidgets('error badge has alertCircle icon', (tester) async {
      final controller = _createController(1);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Timeout',
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });

    testWidgets('error badge tooltip shows error message', (tester) async {
      final controller = _createController(1);
      final thread = _thread(
        syncState: PrInlineSyncState.error,
        syncError: 'Connection refused',
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      await tester.ensureVisible(find.byIcon(LucideIcons.arrowUp));
      await tester.tap(find.byIcon(LucideIcons.arrowUp));
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();
      // Extra pump to allow focus to settle after post-frame callback.
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Fast reply');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(controller.threads.first.entries.length, 2);
    });

    testWidgets('reply field focuses after tapping reply', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Reply…'));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });
  });

  group('PrInlineThreadBlock - container styling', () {
    testWidgets('thread block has margin decoration', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.margin, isNotNull);
    });

    testWidgets('resolved thread check icon is green', (tester) async {
      final controller = _createController(1);
      final thread = _thread(resolved: true);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('unresolved thread check icon is muted', (tester) async {
      final controller = _createController(1);
      final thread = _thread(resolved: false);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - divider between entries', () {
    testWidgets('multiple entries have dividers', (tester) async {
      final controller = _createController(1);
      final thread = _thread(
        entries: [
          PrInlineEntry(id: 'e1', author: 'A', body: 'First', createdAt: DateTime(2024, 1, 1)),
          PrInlineEntry(id: 'e2', author: 'B', body: 'Second', createdAt: DateTime(2024, 2, 1)),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcDivider), findsNWidgets(2));
    });

    testWidgets('single entry has no divider between entries', (tester) async {
      final controller = _createController(1);
      final thread = _thread();

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CcDivider), findsOneWidget);
    });
  });

  group('PrInlineThreadBlock - suggestions and code rendering', () {
    testWidgets('suggestion entry shows suggested code', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Reviewer'), findsOneWidget);
    });

    testWidgets('comment entry shows comment text without edit icon', (tester) async {
      final controller = _createController(1);
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
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Reviewer'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });
  });

  group('PrInlineThreadBlock - controller key handling', () {
    testWidgets('thread block has correct key from controller', (tester) async {
      final controller = _createController(1);
      final thread = _thread(id: 'custom-id', line: 5);

      await tester.pumpWidget(
        _wrap(
          PrInlineThreadBlock(
            thread: thread,
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 comment'), findsOneWidget);
    });
  });
}
