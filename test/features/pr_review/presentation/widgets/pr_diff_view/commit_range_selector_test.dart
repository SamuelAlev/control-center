import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/commit_range_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

PrCommit _commit(String sha, String title, DateTime date) {
  return PrCommit(sha: sha, message: title, author: null, date: date);
}

void _expectVersionBeside(String title, String version) {
  final row = find.ancestor(of: find.text(title), matching: find.byType(Row));
  expect(row, findsWidgets);
  expect(
    find.descendant(of: row.first, matching: find.text(version)),
    findsOneWidget,
  );
}

void main() {
  final commits = [
    _commit('aaaaaaa1', 'oldest', DateTime(2026, 6, 1)),
    _commit('bbbbbbb2', 'middle', DateTime(2026, 7, 1)),
    _commit('ccccccc3', 'latest', DateTime(2026, 8, 1)),
  ];

  testWidgets('numbers commits oldest-first so the tip is the highest version', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        CommitRangeSelector(
          commits: commits,
          selectedShas: const {},
          onSelectionChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    // Closed chip: the whole range is the tip.
    _expectVersionBeside('All commits', 'v3');

    await tester.tap(find.text('All commits'));
    await tester.pumpAndSettle();

    _expectVersionBeside('oldest', 'v1');
    _expectVersionBeside('middle', 'v2');
    _expectVersionBeside('latest', 'v3');
  });

  testWidgets('the trigger badge follows the selected commit versions', (
    tester,
  ) async {
    Set<String> selected = {};
    await tester.pumpWidget(
      testWrap(
        StatefulBuilder(
          builder: (context, setState) {
            return CommitRangeSelector(
              commits: commits,
              selectedShas: selected,
              onSelectionChanged: (next) => setState(() => selected = next),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('All commits'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('latest'));
    await tester.pump();
    // Trigger, "All commits", and the tip row all read v3; the earlier
    // commits keep v1 and v2.
    expect(find.text('v1'), findsOneWidget);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('v3'), findsNWidgets(3));

    await tester.tap(find.text('oldest'));
    await tester.pump();
    // A non-contiguous pair still spans from the earliest version to the tip.
    expect(find.text('v1–v3'), findsOneWidget);
  });
}
