import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

Repo _repo() => Repo(
  id: 'r1',
  name: 'r1',
  path: '/tmp/r1',
  remoteOwner: 'o',
  remoteName: 'r1',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PrInboxItem _item(int number) => PrInboxItem(
  repo: _repo(),
  pr: PullRequest(
    id: number,
    number: number,
    title: 'PR $number',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'alice', avatarUrl: ''),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
    repoFullName: 'o/r1',
    htmlUrl: '',
  ),
);

void main() {
  testWidgets('pins the column header while the rows scroll beneath', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        CustomScrollView(
          slivers: [
            PrRepoSectionCard(items: [for (var i = 1; i <= 40; i++) _item(i)]),
          ],
        ),
      ),
    );

    final headerY = tester.getTopLeft(find.text('Title')).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, greaterThan(600));
    // The checkbox / title / changes / updated header held its place at the
    // viewport's top edge instead of scrolling away with the rows.
    expect(tester.getTopLeft(find.text('Title')).dy, headerY);
    expect(tester.getTopLeft(find.text('Updated')).dy, headerY);
  });

  testWidgets('a repo with no matching PRs renders the compact empty line', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(const CustomScrollView(slivers: [PrRepoSectionCard(items: [])])),
    );

    expect(find.text('Title'), findsNothing);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('select all is a checkbox that Enter toggles for every row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testWrap(
        CustomScrollView(
          slivers: [
            PrRepoSectionCard(items: [_item(1), _item(2)], selectable: true),
          ],
        ),
      ),
    );
    await tester.pump();

    final boxes = find.bySemanticsLabel(RegExp('^Select '));
    // The header's box and one per row.
    expect(boxes, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSemantics(boxes.at(i)),
        isSemantics(isButton: true, hasCheckedState: true, isChecked: false),
      );
    }

    final header = find.descendant(
      of: boxes.first,
      matching: find.byType(Container),
    );
    Focus.of(tester.element(header.first)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      expect(
        tester.getSemantics(boxes.at(i)),
        isSemantics(isButton: true, hasCheckedState: true, isChecked: true),
      );
    }
    handle.dispose();
  });

  testWidgets('Tab from a row reaches its faded-out checkbox', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testWrap(
        CustomScrollView(
          slivers: [
            PrRepoSectionCard(items: [_item(1), _item(2)], selectable: true),
          ],
        ),
      ),
    );
    await tester.pump();

    Focus.of(tester.element(find.text('PR 1'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    final rowBox = find.bySemanticsLabel(RegExp('^Select ')).at(1);
    expect(
      tester.getSemantics(rowBox),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Select ')).at(2)),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    handle.dispose();
  });
}
