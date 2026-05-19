import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_attention_card.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_section_card.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

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

/// The inbox's sliver contract, mirrored from `InboxScreen._buildBody`: the
/// attention strip is a [PinnedHeaderSliver] over an opaque canvas gap, each
/// section a pinned accordion header plus an atomic body. These tests pin the
/// pinning — a plain-box regression here is what let scrolled content linger
/// above a pinned header.
void main() {
  Widget inboxSlivers({required List<InboxAttentionItem> attention}) =>
      testWrap(
        Column(
          children: [
            // Stand-in for the hero above the scroll view.
            const SizedBox(height: 120),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverMainAxisGroup(
                    slivers: [
                      if (attention.isNotEmpty)
                        PinnedHeaderSliver(
                          child: Container(
                            color: const Color(0xFFFAFAF8),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InboxAttentionCard(items: attention),
                          ),
                        ),
                      InboxSectionCard(
                        section: PrInboxSection.needsYourReview,
                        items: [for (var i = 1; i <= 30; i++) _item(i)],
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      InboxSectionCard(
                        section: PrInboxSection.drafts,
                        items: [_item(31)],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  testWidgets(
    'the attention strip never scrolls and section headers pin beneath it',
    (tester) async {
      await tester.pumpWidget(
        inboxSlivers(
          attention: [
            InboxAttentionItem(
              id: 'a1',
              severity: InboxAttentionSeverity.blocking,
              title: 'Agent architect is asking for approval',
              icon: AppIcons.alertTriangle,
              actionLabel: 'Review',
              onAction: () {},
            ),
          ],
        ),
      );

      final stripFinder = find.text('Agent architect is asking for approval');
      final headerFinder = find.text('Needs your review');
      final stripAtRest = tester.getRect(stripFinder);
      // The pinned block's bottom edge: the strip card plus its opaque 12px
      // gap, where a pinned section header must land.
      final stripBlockBottom =
          tester.getRect(find.byType(InboxAttentionCard)).bottom + 12;

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;

      // Sweep in deliberately fractional steps: at every scroll offset the
      // strip holds its place and the first section's header pins flush
      // below the strip block — never a gap that scrolled rows can peek
      // through.
      for (
        var target = 0.0;
        target <= position.maxScrollExtent;
        target += 13.7
      ) {
        position.jumpTo(target);
        await tester.pump();
        expect(
          tester.getRect(stripFinder),
          stripAtRest,
          reason: 'offset $target: the pinned attention strip must not move',
        );
        if (target > 20) {
          final headerBoxTop = tester.getTopLeft(headerFinder).dy - 11;
          expect(
            headerBoxTop,
            closeTo(stripBlockBottom, 1.5),
            reason:
                'offset $target: the section header must pin at the bottom '
                'of the pinned strip block ($stripBlockBottom), got '
                '$headerBoxTop',
          );
        }
      }
    },
  );
}
