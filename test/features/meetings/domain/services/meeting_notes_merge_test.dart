import 'package:cc_domain/features/meetings/domain/services/meeting_notes_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeManualNotes', () {
    test('returns null when there are no enhanced notes to merge into', () {
      expect(mergeManualNotes(userNotes: 'anything', enhanced: null), isNull);
    });

    test('leaves enhanced notes untouched when every user line survived', () {
      const enhanced = '# Notes\n\nThe team agreed to ship on Friday.';
      expect(
        mergeManualNotes(userNotes: 'ship on friday', enhanced: enhanced),
        enhanced,
      );
    });

    test('appends dropped user lines under a Written notes section', () {
      const enhanced = '# Notes\n\nThe team discussed the roadmap.';
      final merged = mergeManualNotes(
        userNotes: 'remember to call the vendor about pricing',
        enhanced: enhanced,
      );
      expect(merged, contains(writtenNotesHeading));
      expect(merged, contains('remember to call the vendor about pricing'));
    });

    test('matches a bulleted user note against its prose form (no dup)', () {
      const enhanced = 'We will ship the release on Friday after QA signs off.';
      final merged = mergeManualNotes(
        userNotes: '- ship the release on Friday',
        enhanced: enhanced,
      );
      expect(merged, isNot(contains(writtenNotesHeading)));
    });

    test('is idempotent — re-running does not stack Written notes sections', () {
      const enhanced = 'Some AI notes.';
      const userNotes = 'a private reminder the AI ignored';
      final once = mergeManualNotes(userNotes: userNotes, enhanced: enhanced)!;
      final twice = mergeManualNotes(userNotes: userNotes, enhanced: once)!;
      expect(once, twice);
      expect(writtenNotesHeading.allMatches(twice).length, 1);
    });

    test('ignores empty user notes', () {
      const enhanced = 'AI notes only.';
      expect(mergeManualNotes(userNotes: '   ', enhanced: enhanced), enhanced);
    });
  });
}
