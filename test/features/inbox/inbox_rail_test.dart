import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_rail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

void main() {
  const counts = {
    PrInboxSection.needsYourReview: 3,
    PrInboxSection.returnedToYou: 1,
    PrInboxSection.approved: 0,
    PrInboxSection.drafts: 2,
    PrInboxSection.waitingForReviewers: 0,
    PrInboxSection.mergingAndMerged: 0,
    PrInboxSection.waitingForAuthor: 4,
  };

  testWidgets('renders every section label and its count', (tester) async {
    await tester.pumpWidget(
      testWrap(InboxRail(counts: counts, selected: null, onSelect: (_) {})),
    );

    expect(find.text('Needs your review'), findsOneWidget);
    expect(find.text('Returned to you'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('tapping a row reports that section', (tester) async {
    PrInboxSection? tapped;
    await tester.pumpWidget(
      testWrap(
        InboxRail(
          counts: counts,
          selected: null,
          onSelect: (section) => tapped = section,
        ),
      ),
    );

    await tester.tap(find.text('Returned to you'));
    await tester.pump();
    expect(tapped, PrInboxSection.returnedToYou);
  });

  testWidgets('selected row uses an opaque canvas-blended wash', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        InboxRail(
          counts: counts,
          selected: PrInboxSection.needsYourReview,
          onSelect: (_) {},
        ),
      ),
    );

    final tokens = DesignSystemTokens.light();
    final expected = Color.alphaBlend(tokens.hoverStrong, tokens.canvas);
    expect(expected.a, 1.0);

    final washes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color == expected);
    expect(washes, hasLength(1));
  });

  testWidgets('selected row is a fixed 32px tall and contains its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 224,
          child: InboxRail(
            counts: counts,
            selected: PrInboxSection.returnedToYou,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final label = find.text('Returned to you');
    expect(label, findsOneWidget);
    final row = find.ancestor(of: label, matching: find.byType(SizedBox));
    expect(tester.getSize(row.first).height, kCcSidebarItemExtent);
  });
}
