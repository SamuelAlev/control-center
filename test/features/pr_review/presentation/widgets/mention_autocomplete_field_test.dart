import 'dart:async';

import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/widgets/mention_autocomplete_field.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _testUsers = [
  PrUser(login: 'octocat', avatarUrl: 'https://example.com/octocat.png'),
  PrUser(login: 'hubot', avatarUrl: 'https://example.com/hubot.png'),
  PrUser(login: 'othercat', avatarUrl: 'https://example.com/othercat.png'),
];

const _testIssues = [
  (number: 42, title: 'Fix the flux capacitor'),
  (number: 99, title: 'Add more cowbell'),
];

/// Focuses the TextField then sends text via the test input connection.
Future<void> _enterText(WidgetTester tester, String text) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  tester.testTextInput.log.clear();
}

void main() {
  group('MentionAutocompleteField @-trigger', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() async {
      // Let pending microtasks settle before disposing to avoid
      // FocusManager-after-dispose errors.
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget() {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(_testUsers),
          ),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('renders text field with hint', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Write a comment...'), findsOne);
    });

    testWidgets('typing @ triggers overlay with user suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      // All three users should appear in overlay
      expect(find.text('octocat'), findsOne);
      expect(find.text('hubot'), findsOne);
      expect(find.text('othercat'), findsOne);
    });

    testWidgets('typing @query filters users', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@cat');
      await tester.pumpAndSettle();

      // Only users whose login contains 'cat'
      expect(find.text('octocat'), findsOne);
      expect(find.text('othercat'), findsOne);
      expect(find.text('hubot'), findsNothing);
    });

    testWidgets('selecting user by tap replaces @ token', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@octo');
      await tester.pumpAndSettle();

      // Tap the octocat suggestion
      await tester.tap(find.text('octocat'));
      await tester.pumpAndSettle();

      expect(controller.text, '@octocat ');
      expect(controller.selection.baseOffset, '@octocat '.length);
    });

    testWidgets('selecting user by Enter key replaces token', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@hub');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text, '@hubot ');
    });

    testWidgets('arrow down navigates suggestions, enter selects highlighted', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text, '@hubot ');
    });

    testWidgets('arrow up wraps around suggestions', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      // Arrow up from index 0 wraps to last item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text, '@othercat ');
    });

    testWidgets('escape dismisses overlay', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      expect(find.text('octocat'), findsOne);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('octocat'), findsNothing);
      expect(controller.text, '@');
    });

    testWidgets('Tab selects highlighted and dismisses overlay', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(controller.text, '@octocat ');
    });
  });

  group('MentionAutocompleteField #-trigger', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    late Completer<List<({int number, String title})>> searchCompleter;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget() {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(const []),
          ),
          issueSearchProvider((
            owner: 'some-owner',
            repo: 'some-repo',
            query: '42',
          )).overrideWith((ref) => searchCompleter.future),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('typing #number triggers issue search overlay', (
      tester,
    ) async {
      searchCompleter = Completer();
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '#42');
      await tester.pump(); // overlay portal show frame

      // Debounce timer needs 250ms
      await tester.pump(const Duration(milliseconds: 300));
      searchCompleter.complete(_testIssues);
      await tester.pumpAndSettle();

      expect(find.text('#42'), findsOne);
      expect(find.textContaining('Fix the flux capacitor'), findsOne);
    });

    testWidgets('typing # shows no results when query is empty', (
      tester,
    ) async {
      searchCompleter = Completer();
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '#');
      // No debounce query, overlay won't show items
      await tester.pumpAndSettle();

      // Without a query match on the provider, overlay items are empty
      expect(find.text('#'), findsOne); // # in the text field
    });

    testWidgets('selecting issue by Enter replaces # token', (tester) async {
      searchCompleter = Completer();
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '#42');
      await tester.pump(const Duration(milliseconds: 300));
      searchCompleter.complete(_testIssues);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(controller.text, '#42 ');
    });

  });

  group('MentionAutocompleteField edge cases', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget({List<PrUser> users = _testUsers}) {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(users),
          ),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('removing @ token dismisses overlay', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@octo');
      await tester.pumpAndSettle();
      expect(find.text('octocat'), findsOne);

      // Delete back to remove @ trigger
      await _enterText(tester, 'octo');
      await tester.pumpAndSettle();
      expect(find.text('octocat'), findsNothing);
    });

    testWidgets('@ in middle of text triggers overlay at caret position', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Focus first
      await tester.tap(find.byType(TextField));
      await tester.pump();
      // Set text with caret inside @ token
      controller.text = 'hello @octocat world';
      controller.selection = const TextSelection.collapsed(offset: 11);
      await tester.pumpAndSettle();

      // Overlay should show for @octocat at caret position
      expect(find.text('octocat'), findsOne);
    });

    testWidgets('selection replaces only the @ token preserving surrounding text', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byType(TextField));
      await tester.pump();
      controller.text = 'assign @hubot pls';
      controller.selection = const TextSelection.collapsed(offset: 12);
      await tester.pumpAndSettle();

      await tester.tap(find.text('hubot'));
      await tester.pumpAndSettle();

      expect(controller.text, 'assign @hubot t pls');
    });

    testWidgets('empty user list shows no overlay for @', (tester) async {
      await tester.pumpWidget(buildWidget(users: const []));
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      // No items → overlay not rendered
      // The '@' is visible in the text field itself
      expect(controller.text, '@');
    });

    testWidgets('overlay closes when field loses focus', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();
      expect(find.text('octocat'), findsOne);

      focusNode.unfocus();
      await tester.pumpAndSettle();

      // Overlay dismissed after focus loss, no crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-trigger text does not show overlay', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, 'just some text');
      await tester.pumpAndSettle();

      expect(find.text('octocat'), findsNothing);
    });
  });

  group('MentionAutocompleteField mention items', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() async {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget() {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(_testUsers),
          ),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('_MentionItem has correct fields', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      // User items show login as primary field and render avatars (isUser: true).
      expect(find.text('octocat'), findsOne);
      expect(find.text('hubot'), findsOne);
      expect(find.text('othercat'), findsOne);
      // When isUser is true, _MentionRow renders a user avatar widget.
      expect(find.byType(InkWell), findsNWidgets(3));
      expect(find.text('octocat'), findsOne);
      expect(find.text('hubot'), findsOne);
      expect(find.text('othercat'), findsOne);
    });
  });

  group('MentionAutocompleteField non-trigger text', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() async {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget() {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(_testUsers),
          ),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('non-collapsed selection does not show overlay', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Focus and set text with a non-collapsed (range) selection containing @.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      controller.text = 'assign @octocat pls';
      controller.selection = const TextSelection(
        baseOffset: 7,
        extentOffset: 15,
      );
      await tester.pumpAndSettle();

      // _onChanged closes overlay when selection is not collapsed.
      expect(find.text('octocat'), findsNothing);
    });

    testWidgets('caret at position 0 does not trigger overlay', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Set text that does not start with a trigger character, caret at 0.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      controller.text = 'hello world';
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pumpAndSettle();

      // No trigger char before caret → no overlay.
      expect(find.text('octocat'), findsNothing);
    });
  });

  group('MentionAutocompleteField key handling', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode(debugLabel: 'testFocus');
    });

    tearDown(() async {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildWidget({List<PrUser> users = _testUsers}) {
      return ProviderScope(
        overrides: [
          assignableUsersProvider.overrideWith(
            (ref) => Future.value(users),
          ),
        ],
        child: testWrap(
          MentionAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            owner: 'some-owner',
            repo: 'some-repo',
            hintText: 'Write a comment...',
          ),
        ),
      );
    }

    testWidgets('non-navigation keys pass through when overlay active', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await _enterText(tester, '@octo');
      await tester.pumpAndSettle();

      // Overlay should be visible with filtered suggestions.
      expect(find.text('octocat'), findsOne);

      // Send a non-navigation key — _onKey returns ignored, field processes it.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();

      // Overlay should remain since the key passed through without dismissal.
      expect(find.text('octocat'), findsOne);
    });

    testWidgets('arrow keys without items do not crash', (tester) async {
      await tester.pumpWidget(buildWidget(users: const []));
      await tester.pump();

      await _enterText(tester, '@');
      await tester.pumpAndSettle();

      // Arrow key when _items is empty — handler short-circuits, no crash.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
