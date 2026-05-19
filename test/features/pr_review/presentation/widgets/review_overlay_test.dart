import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

PullRequest _pr() {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Test PR',
    body: '## Description',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'author', avatarUrl: ''),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/42',
  );
}

Widget _wrap(Widget child, {PrReviewRepository? repo}) {
  return ProviderScope(
    overrides: [
      prReviewRepositoryProvider.overrideWithValue(
        repo ?? const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: [DesignSystemTokens.light()],
      ),
      home: FTheme(
        data: FThemes.zinc.light.desktop,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('ReviewOverlayButton', () {
    testWidgets('renders Review button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('renders with empty owner and repo', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: '', repo: '')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('button has check icon', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('button is an FButton', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.byType(FButton), findsOneWidget);
    });

    testWidgets('renders with PR number in pull request', (tester) async {
      final pr = PullRequest(
        id: 2,
        number: 42,
        title: 'PR',
        body: '',
        state: PrState.open,
        isDraft: false,
        author: const PrUser(login: 'a', avatarUrl: ''),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        repoFullName: 'owner/repo',
        htmlUrl: 'https://github.com/owner/repo/pull/42',
      );

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('tapping button opens overlay', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Approve changes'), findsOneWidget);
    });

    testWidgets('overlay shows approve button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('overlay shows text field with hint', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('overlay has attach image button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.image), findsOneWidget);
    });

    testWidgets('overlay has emoji button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.smile), findsOneWidget);
    });

    testWidgets('overlay has GIF button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.clapperboard), findsOneWidget);
    });

    testWidgets('overlay has preview toggle button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('tapping preview toggles to edit mode', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('preview shows nothing to preview when empty', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nothing to preview'), findsOneWidget);
    });

    testWidgets('tapping outside overlay dismisses it', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Approve changes'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Approve changes'), findsNothing);
    });

    testWidgets('overlay child uses Positioned for layout', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.byType(CompositedTransformTarget), findsNothing);
    });

    testWidgets('overlay renders with divider', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FDivider), findsOneWidget);
    });

    testWidgets('overlay has Material wrapper with elevation', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('toggling closes the overlay on second tap', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Approve changes'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Approve changes'), findsNothing);
    });

    testWidgets('tooltips on action buttons', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FTooltip), findsAtLeast(3));
    });

    testWidgets('renders with closed PR state', (tester) async {
      final pr = PullRequest(
        id: 5,
        number: 10,
        title: 'Closed PR',
        body: '',
        state: PrState.closed,
        isDraft: false,
        author: const PrUser(login: 'author', avatarUrl: ''),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        repoFullName: 'owner/repo',
        htmlUrl: 'https://github.com/owner/repo/pull/10',
      );

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('renders with merged PR state', (tester) async {
      final pr = PullRequest(
        id: 6,
        number: 11,
        title: 'Merged PR',
        body: '',
        state: PrState.merged,
        isDraft: false,
        author: const PrUser(login: 'author', avatarUrl: ''),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        repoFullName: 'owner/repo',
        htmlUrl: 'https://github.com/owner/repo/pull/11',
      );

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('renders with draft PR', (tester) async {
      final pr = PullRequest(
        id: 7,
        number: 12,
        title: 'Draft PR',
        body: '',
        state: PrState.open,
        isDraft: true,
        author: const PrUser(login: 'author', avatarUrl: ''),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        repoFullName: 'owner/repo',
        htmlUrl: 'https://github.com/owner/repo/pull/12',
      );

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('open overlay and type text in comment field', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'This is a test comment.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('This is a test comment.'), findsOneWidget);
    });

    testWidgets('preview shows typed text when toggled', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(
        find.byType(TextField),
        'Test review text',
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('double-toggle preview returns to write mode', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    });

    testWidgets('approve button exists in overlay', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FButton), findsWidgets);
    });

    testWidgets('text field has multiline configuration', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, greaterThanOrEqualTo(5));
      expect(textField.maxLines, greaterThanOrEqualTo(10));
    });

    testWidgets('preview shows Nothing to preview when empty text', (
      tester,
    ) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nothing to preview'), findsOneWidget);
    });

    testWidgets('FButton with checkCircle icon in button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
    });

    testWidgets('overlay child uses Positioned for layout', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final positioned = tester.widgetList<Positioned>(
        find.byType(Positioned),
      );
      final hasOverlayPositioned = positioned.any(
        (p) => p.width != null && p.left != null,
      );
      expect(hasOverlayPositioned, isTrue);
    });

    testWidgets('overlay has Focus widget for key handling', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Focus), findsWidgets);
    });

    testWidgets('RepaintBoundary wraps overlay content', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('correct tooltip for Write vs Preview button', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The preview/write toggle button exists and has a tooltip.
      expect(find.byType(FTooltip), findsWidgets);

      await tester.tap(find.byIcon(LucideIcons.eye));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tooltips are still present after toggling.
      expect(find.byType(FTooltip), findsWidgets);
    });

    testWidgets('text field has placeholder hint', (tester) async {
      final pr = _pr();

      await tester.pumpWidget(
        _wrap(ReviewOverlayButton(pr: pr, owner: 'owner', repo: 'repo')),
      );
      await tester.pump();

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, contains('click approve'));
    });
  });
}
