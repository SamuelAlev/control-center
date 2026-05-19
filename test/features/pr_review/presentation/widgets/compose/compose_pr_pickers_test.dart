import 'package:control_center/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/widgets/compose/compose_pr_pickers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeRepo extends Fake implements PrReviewRepository {
  _FakeRepo({
    this.assignableUsers = const [],
    this.requestableReviewers = const [],
  });

  final List<PrUser> assignableUsers;
  final List<PrReviewerCandidate> requestableReviewers;

  @override
  Future<List<PrUser>> listAssignableUsers() async => assignableUsers;

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async =>
      requestableReviewers;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PrUser _user(String login) => PrUser(login: login, avatarUrl: '');

PrReviewerCandidate _userCandidate(String login) =>
    PrReviewerCandidate.user(_user(login));

PrReviewerCandidate _teamCandidate(String slug) => PrReviewerCandidate(
      kind: ReviewerKind.team,
      key: slug,
      label: slug,
    );

Widget _wrap(Widget child, {_FakeRepo? repo}) {
  return ProviderScope(
    overrides: [
      prReviewRepositoryProvider.overrideWith(
        (ref) => repo ?? _FakeRepo(),
      ),
    ],
    child: testWrap(child),
  );
}

/// Opens the assignee flyout and waits for animations.
Future<void> _openAssigneePicker(WidgetTester tester) async {
  await tester.tap(find.text('Assignees'));
  await tester.pumpAndSettle();
}

/// Opens the reviewer flyout and waits for animations.
Future<void> _openReviewerPicker(WidgetTester tester) async {
  await tester.tap(find.text('Reviewers'));
  await tester.pumpAndSettle();
}

/// Taps the barrier to close any open flyout.
Future<void> _closeFlyout(WidgetTester tester) async {
  // The flyout's dismiss barrier is a GestureDetector covering the screen.
  // Tap at a point far from the flyout panel (bottom-left corner).
  await tester.tapAt(const Offset(1, 590));
  await tester.pumpAndSettle();
}

/// Finder for text inside a flyout list row (not in a chip).
Finder _rowText(String text) =>
    find.descendant(of: find.byType(ListView), matching: find.text(text));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --- Sidebar rendering ---------------------------------------------------

  testWidgets('renders assignees and reviewers headers', (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    expect(find.text('Assignees'), findsOneWidget);
    expect(find.text('Reviewers'), findsOneWidget);
  });

  testWidgets('shows no chips when no assignees or reviewers are staged',
      (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    // No X icons → no chips.
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  // --- Assignee picker: empty state ----------------------------------------

  testWidgets('assignee flyout shows empty state when no users', (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    await _openAssigneePicker(tester);

    expect(find.text('Add assignees'), findsOneWidget);
    expect(find.text('No matching people'), findsOneWidget);
  });

  // --- Assignee picker: selection (flyout open, chip outside) --------------

  testWidgets('selecting assignee adds a chip', (tester) async {
    final repo = _FakeRepo(assignableUsers: [_user('alice')]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);
    expect(_rowText('alice'), findsOneWidget);

    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();

    // Chip appears outside the flyout.
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    // Close flyout; chip stays.
    await _closeFlyout(tester);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);
  });

  testWidgets('toggling assignee off removes the chip', (tester) async {
    final repo = _FakeRepo(assignableUsers: [_user('alice')]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);

    // Select → chip appears.
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    // Deselect (tap the row in the flyout, not the chip outside).
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('removing assignee chip via X button', (tester) async {
    final repo = _FakeRepo(assignableUsers: [_user('alice')]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();

    // MUST close flyout first — its dismiss barrier covers the chips.
    await _closeFlyout(tester);

    // Now tap the X on the chip (now visible without the barrier).
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('multiple assignees can be selected', (tester) async {
    final repo = _FakeRepo(assignableUsers: [
      _user('alice'),
      _user('bob'),
      _user('carol'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);

    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    await tester.tap(_rowText('carol'));
    await tester.pumpAndSettle();

    // Two chips.
    expect(find.byIcon(LucideIcons.x), findsNWidgets(2));
  });

  // --- Assignee picker: search ---------------------------------------------

  testWidgets('assignee search filters candidates', (tester) async {
    final repo = _FakeRepo(assignableUsers: [
      _user('alice'),
      _user('bob'),
      _user('ali'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);

    // Type "ali" — should show alice and ali, not bob.
    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pumpAndSettle();

    expect(_rowText('alice'), findsOneWidget);
    expect(_rowText('ali'), findsOneWidget);
    expect(_rowText('bob'), findsNothing);
  });

  testWidgets('assignee search is case-insensitive', (tester) async {
    final repo = _FakeRepo(assignableUsers: [_user('Alice')]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openAssigneePicker(tester);

    await tester.enterText(find.byType(TextField), 'alice');
    await tester.pumpAndSettle();

    expect(_rowText('Alice'), findsOneWidget);
  });

  // --- Reviewer picker: empty state ----------------------------------------

  testWidgets('reviewer flyout shows empty state when no candidates',
      (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    await _openReviewerPicker(tester);

    expect(find.text('Add reviewers'), findsOneWidget);
    expect(find.text('No matching people'), findsOneWidget);
  });

  // --- Reviewer picker: selection ------------------------------------------

  testWidgets('reviewer flyout shows user candidates and selecting adds chip',
      (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _userCandidate('alice'),
      _userCandidate('bob'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);

    expect(_rowText('alice'), findsOneWidget);
    expect(_rowText('bob'), findsOneWidget);

    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.x), findsOneWidget);
  });

  testWidgets('reviewer flyout shows team candidates', (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _teamCandidate('eng'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);

    expect(_rowText('eng'), findsOneWidget);
  });

  testWidgets('team reviewer chip shows users icon instead of avatar',
      (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _teamCandidate('eng'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);
    await tester.tap(_rowText('eng'));
    await tester.pumpAndSettle();

    await _closeFlyout(tester);

    // The chip for a team uses LucideIcons.users (size 14).
    // The section header also uses LucideIcons.users — so at least 2.
    expect(find.byIcon(LucideIcons.users), findsAtLeast(2));
  });

  testWidgets('toggling reviewer off removes the chip', (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _userCandidate('alice'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    // Deselect (tap row in flyout).
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('removing reviewer chip via X button', (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _userCandidate('alice'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();

    // Close flyout so barrier doesn't block the chip's X.
    await _closeFlyout(tester);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  // --- Reviewer picker: search ---------------------------------------------

  testWidgets('reviewer search filters candidates', (tester) async {
    final repo = _FakeRepo(requestableReviewers: [
      _userCandidate('alice'),
      _userCandidate('bob'),
      _teamCandidate('android'),
    ]);
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    await _openReviewerPicker(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pumpAndSettle();

    expect(_rowText('alice'), findsOneWidget);
    expect(_rowText('android'), findsOneWidget);
    expect(_rowText('bob'), findsNothing);
  });

  // --- Integration: assignees + reviewers together -------------------------

  testWidgets('assignee and reviewer chips coexist independently',
      (tester) async {
    final repo = _FakeRepo(
      assignableUsers: [_user('alice')],
      requestableReviewers: [_userCandidate('bob')],
    );
    await tester.pumpWidget(_wrap(const ComposePrSidebar(), repo: repo));

    // Add assignee.
    await _openAssigneePicker(tester);
    await tester.tap(_rowText('alice'));
    await tester.pumpAndSettle();
    await _closeFlyout(tester);

    // Add reviewer.
    await _openReviewerPicker(tester);
    await tester.tap(_rowText('bob'));
    await tester.pumpAndSettle();
    await _closeFlyout(tester);

    // Both chips visible.
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.byIcon(LucideIcons.x), findsNWidgets(2));
  });

  // --- Open / close robustness ---------------------------------------------

  testWidgets('opening and closing assignee flyout does not crash',
      (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    await _openAssigneePicker(tester);
    expect(find.text('Add assignees'), findsOneWidget);

    await _closeFlyout(tester);

    await _openAssigneePicker(tester);
    expect(find.text('Add assignees'), findsOneWidget);
  });

  testWidgets('opening and closing reviewer flyout does not crash',
      (tester) async {
    await tester.pumpWidget(_wrap(const ComposePrSidebar()));

    await _openReviewerPicker(tester);
    expect(find.text('Add reviewers'), findsOneWidget);

    await _closeFlyout(tester);

    await _openReviewerPicker(tester);
    expect(find.text('Add reviewers'), findsOneWidget);
  });
}
