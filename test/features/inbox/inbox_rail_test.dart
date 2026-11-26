import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/presentation/widgets/inbox_rail.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

bool Function(AnimatedContainer) _hasBlendedWash(Color expected) {
  return (box) {
    final decoration = box.decoration;
    return decoration is BoxDecoration && decoration.color == expected;
  };
}

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
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where(_hasBlendedWash(expected));
    expect(washes, hasLength(1));
  });

  testWidgets('hover highlight is a fluid nearest-target group', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(InboxRail(counts: counts, selected: null, onSelect: (_) {})),
    );

    expect(find.byType(CcFluidHover), findsOneWidget);
  });

  testWidgets('Tab walks the whole rail before the list beside it', (
    tester,
  ) async {
    final visited = <String>[];
    Widget listItem(String name) => Focus(
      onFocusChange: (focused) {
        if (focused) {
          visited.add(name);
        }
      },
      child: const SizedBox(height: 24, width: 200),
    );

    await tester.pumpWidget(
      testWrap(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 224,
              child: InboxRail(
                counts: counts,
                selected: null,
                onSelect: (_) {},
              ),
            ),
            // Rows whose tops fall between the rail entries, the layout the
            // geometric sort used to interleave.
            Column(
              children: [for (var i = 0; i < 4; i++) listItem('list$i')],
            ),
          ],
        ),
      ),
    );

    final railScope = find.byType(InboxRail);
    bool focusInRail() {
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null) {
        return false;
      }
      return find
          .descendant(of: railScope, matching: find.byWidget(focused.widget))
          .evaluate()
          .isNotEmpty;
    }

    for (var i = 0; i < PrInboxSection.values.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusInRail(), isTrue, reason: 'Tab ${i + 1} left the rail');
      expect(visited, isEmpty);
    }
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(visited, ['list0', 'list1', 'list2', 'list3']);
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
    final row = find.ancestor(
      of: label,
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(row.first).height, kCcSidebarItemExtent);
  });
}
