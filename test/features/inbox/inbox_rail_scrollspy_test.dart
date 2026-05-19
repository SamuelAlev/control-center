import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:control_center/features/inbox/presentation/inbox_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A short list: two sections, everything visible without scrolling.
  const shortList = {
    PrInboxSection.needsYourReview: 0.0,
    PrInboxSection.waitingForAuthor: 220.0,
  };

  group('resolveInboxRailSection', () {
    test('highlights the first section at the top of an unscrollable list', () {
      // Regression: with maxScrollExtent == 0, top == bottom, so the bottom
      // pin used to fire and select the LAST section ("Waiting for author").
      expect(
        resolveInboxRailSection(
          offset: 0,
          maxScrollExtent: 0,
          revealOffsets: shortList,
        ),
        PrInboxSection.needsYourReview,
      );
    });

    test(
      'highlights the first section at the top of a barely scrollable list',
      () {
        // Scroll range smaller than the activation lead: still at the top.
        expect(
          resolveInboxRailSection(
            offset: 0,
            maxScrollExtent: 40,
            revealOffsets: shortList,
          ),
          PrInboxSection.needsYourReview,
        );
      },
    );

    test('pins the last section once scrolled to the bottom', () {
      const tallList = {
        PrInboxSection.needsYourReview: 0.0,
        PrInboxSection.returnedToYou: 400.0,
        PrInboxSection.waitingForAuthor: 900.0,
      };
      expect(
        resolveInboxRailSection(
          offset: 500,
          maxScrollExtent: 500,
          revealOffsets: tallList,
        ),
        PrInboxSection.waitingForAuthor,
      );
    });

    test('tracks the deepest section past the activation line mid-scroll', () {
      const tallList = {
        PrInboxSection.needsYourReview: 0.0,
        PrInboxSection.returnedToYou: 400.0,
        PrInboxSection.waitingForAuthor: 1200.0,
      };
      // Offset 400 puts "Returned to you" at the top; the bottom pin must not
      // fire because the list is far from its end.
      expect(
        resolveInboxRailSection(
          offset: 400,
          maxScrollExtent: 1500,
          revealOffsets: tallList,
        ),
        PrInboxSection.returnedToYou,
      );
    });

    test('falls back to the first present section above the topmost card', () {
      // Viewing the attention strip: no card has crossed the activation line.
      expect(
        resolveInboxRailSection(
          offset: 0,
          maxScrollExtent: 800,
          revealOffsets: const {
            PrInboxSection.drafts: 300.0,
            PrInboxSection.waitingForAuthor: 900.0,
          },
        ),
        PrInboxSection.drafts,
      );
    });

    test('returns null when no section is present', () {
      expect(
        resolveInboxRailSection(
          offset: 0,
          maxScrollExtent: 0,
          revealOffsets: const {},
        ),
        isNull,
      );
    });
  });
}
