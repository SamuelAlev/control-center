import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

final _repo = Repo(
  id: 'r1',
  name: 'r1',
  path: '/tmp/r1',
  remoteOwner: 'o',
  remoteName: 'r1',
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PrInboxItem _item(int number) => PrInboxItem(
  repo: _repo,
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

Widget _view({
  required int rows,
  Map<String, int> totals = const {},
  PrRepoPaging? paging,
  ValueChanged<String>? onLoadMore,
}) => testWrap(
  SizedBox(
    width: 1000,
    height: 600,
    child: PrRepoView(
      sections: [
        (repo: _repo, items: [for (var i = 1; i <= rows; i++) _item(i)]),
      ],
      totals: totals,
      paging: {'r1': ?paging},
      onLoadMore: onLoadMore,
    ),
  ),
);

void main() {
  const more = (hasMore: true, loading: false, failed: false);

  testWidgets('the rail shows the forge total over the loaded rows', (
    tester,
  ) async {
    await tester.pumpWidget(_view(rows: 3, totals: {'r1': 109}));

    expect(find.text('109'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('scrolling near the end asks for the next page', (tester) async {
    final requested = <String>[];
    await tester.pumpWidget(
      _view(rows: 60, paging: more, onLoadMore: requested.add),
    );
    await tester.pump();
    expect(requested, isEmpty, reason: 'the first rows fill the pane');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pump();

    expect(requested, isNotEmpty);
    expect(requested.toSet(), {'r1'});
  });

  testWidgets('rows that do not fill the pane load the next page', (
    tester,
  ) async {
    final requested = <String>[];
    await tester.pumpWidget(
      _view(rows: 2, paging: more, onLoadMore: requested.add),
    );
    await tester.pump();

    expect(requested, contains('r1'));
  });

  testWidgets('nothing loads once every page is in', (tester) async {
    final requested = <String>[];
    await tester.pumpWidget(_view(rows: 2, onLoadMore: requested.add));
    await tester.pump();

    expect(requested, isEmpty);
  });

  testWidgets('a loading page shows a spinner and asks for nothing more', (
    tester,
  ) async {
    final requested = <String>[];
    await tester.pumpWidget(
      _view(
        rows: 2,
        paging: (hasMore: true, loading: true, failed: false),
        onLoadMore: requested.add,
      ),
    );
    await tester.pump();

    expect(find.byType(CcSpinner), findsOneWidget);
    expect(requested, isEmpty);
  });

  testWidgets('a failed page waits for retry', (tester) async {
    final requested = <String>[];
    await tester.pumpWidget(
      _view(
        rows: 2,
        paging: (hasMore: true, loading: false, failed: true),
        onLoadMore: requested.add,
      ),
    );
    await tester.pump();
    expect(requested, isEmpty);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(requested, ['r1']);
  });
}
