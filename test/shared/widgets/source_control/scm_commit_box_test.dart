import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/source_control/scm_commit_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScmCommitBox smart commit', () {
    testWidgets('empty index with working-tree changes can commit', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      ScmCommitAction? chosen;
      await tester.pumpWidget(
        _wrap(
          ScmCommitBox(
            controller: controller,
            busy: false,
            stagedCount: 0,
            unstagedCount: 15,
            canPush: true,
            onAction: (action) => chosen = action,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commit message'), findsOneWidget);
      expect(find.text('Stage changes to commit'), findsNothing);
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Commit'))
            .onPressed,
        isNull,
      );

      controller.text = 'Ship the working tree';
      await tester.pump();

      final button = tester.widget<CcButton>(
        find.widgetWithText(CcButton, 'Commit'),
      );
      expect(button.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(CcButton, 'Commit'));
      expect(chosen, ScmCommitAction.commit);
    });

    testWidgets('commit and push lives in the menu', (tester) async {
      final controller = TextEditingController(text: 'Ship it');
      addTearDown(controller.dispose);
      ScmCommitAction? chosen;
      await tester.pumpWidget(
        _wrap(
          ScmCommitBox(
            controller: controller,
            busy: false,
            stagedCount: 1,
            unstagedCount: 0,
            canPush: true,
            onAction: (action) => chosen = action,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commit & push'), findsNothing);
      await tester.tap(find.byIcon(AppIcons.chevronDown));
      await tester.pumpAndSettle();

      expect(find.text('Commit & push'), findsOneWidget);
      await tester.tap(find.text('Commit & push'));
      await tester.pumpAndSettle();
      expect(chosen, ScmCommitAction.commitAndPush);
    });

    testWidgets('staged files still enable commit alongside other changes', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Only the index');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          ScmCommitBox(
            controller: controller,
            busy: false,
            stagedCount: 2,
            unstagedCount: 4,
            canPush: true,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Commit'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'nothing to commit keeps the stage hint and a disabled button',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _wrap(
            ScmCommitBox(
              controller: controller,
              busy: false,
              stagedCount: 0,
              unstagedCount: 0,
              canPush: true,
              onAction: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Stage changes to commit'), findsOneWidget);

        controller.text = 'No files';
        await tester.pump();
        expect(
          tester
              .widget<CcButton>(find.widgetWithText(CcButton, 'Commit'))
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('a clean tree can offer publish instead of a disabled commit', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          ScmCommitBox(
            controller: controller,
            busy: false,
            stagedCount: 0,
            unstagedCount: 0,
            canPush: true,
            branch: 'space/6b2256bb',
            idleAction: ScmIdleAction(
              label: 'Publish branch',
              icon: AppIcons.upload,
              onPressed: () => pressed = true,
            ),
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publish branch'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Commit'), findsNothing);
      expect(find.textContaining('space/6b2256bb'), findsOneWidget);
      await tester.tap(find.text('Publish branch'));
      expect(pressed, isTrue);
    });
  });

  group('scmCanOpenPullRequest', () {
    bool open({
      bool statusKnown = true,
      bool hasUpstream = true,
      int ahead = 0,
      int aheadOfBase = 0,
      bool aheadOfBaseKnown = true,
      String branch = 'space/abc',
      int dirtyFiles = 0,
      bool hasExistingPr = false,
    }) {
      return scmCanOpenPullRequest(
        hasForgeRemote: true,
        hasExistingPr: hasExistingPr,
        dirtyFiles: dirtyFiles,
        statusKnown: statusKnown,
        hasUpstream: hasUpstream,
        ahead: ahead,
        aheadOfBase: aheadOfBase,
        aheadOfBaseKnown: aheadOfBaseKnown,
        branch: branch,
      );
    }

    test('a published branch with commits against the base can open a PR', () {
      expect(open(aheadOfBase: 1), isTrue);
    });

    test('a published branch that matches the base cannot', () {
      expect(open(), isFalse);
    });

    test(
      'an older server still offers a PR for a published feature branch',
      () {
        expect(open(aheadOfBaseKnown: false), isTrue);
      },
    );

    test('publishing main does not offer a pull request of main', () {
      expect(open(aheadOfBaseKnown: false, branch: 'main'), isFalse);
    });
  });
}
