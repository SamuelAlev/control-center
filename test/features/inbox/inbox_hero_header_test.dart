import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_hero_header.dart';
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

Repo _repo() => Repo(
  id: 'r1',
  name: 'r1',
  path: '/tmp/r1',
  githubOwner: 'o',
  githubRepoName: 'r1',
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

PrInboxData _data({int needsReview = 0, int returned = 0}) => PrInboxData(
  sections: {
    for (final s in PrInboxSection.values)
      s: s == PrInboxSection.needsYourReview
          ? [for (var i = 0; i < needsReview; i++) _item(i + 1)]
          : s == PrInboxSection.returnedToYou
          ? [for (var i = 0; i < returned; i++) _item(i + 100)]
          : const <PrInboxItem>[],
  },
);

Future<void> _pumpHero(
  WidgetTester tester, {
  PrInboxData? data,
  List<Widget>? actions,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxDataProvider.overrideWith(
          (ref) => data == null
              ? const AsyncValue<PrInboxData>.loading()
              : AsyncValue.data(data),
        ),
      ],
      child: testWrap(InboxHeroHeader(actions: actions)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders the inbox title and the fallback subtitle while '
      'nothing is pending', (tester) async {
    await _pumpHero(tester, data: _data());

    expect(find.text('Inbox'), findsOneWidget);
    expect(
      find.text(
        'Every pull request that involves you, sorted by what happens next.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('falls back to the description while the snapshot loads', (
    tester,
  ) async {
    await _pumpHero(tester);

    expect(
      find.text(
        'Every pull request that involves you, sorted by what happens next.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('subtitle reports the pending review and returned counts', (
    tester,
  ) async {
    await _pumpHero(tester, data: _data(needsReview: 3, returned: 1));

    expect(
      find.text('3 pull requests need your review · 1 returned to you'),
      findsOneWidget,
    );
  });

  testWidgets('subtitle reports a single pending review', (tester) async {
    await _pumpHero(tester, data: _data(needsReview: 1));

    expect(find.text('1 pull request needs your review'), findsOneWidget);
  });

  testWidgets('renders the page actions in the title row', (tester) async {
    await _pumpHero(tester, data: _data(), actions: [const Text('ACTIONS')]);

    expect(find.text('ACTIONS'), findsOneWidget);
  });
}
