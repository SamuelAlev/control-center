import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:cc_domain/features/dispatch/domain/edit/recovery.dart';
import 'package:test/test.dart';

void main() {
  group('tryRecover — noop', () {
    test('returns null when the edits produce no change on the snapshot', () {
      // Deleting a non-existent line throws inside applyEdits → caught → null.
      final result = tryRecover(
        previousText: 'a\nb',
        currentText: 'a\nb',
        edits: const [DeleteEdit(line: 99)],
      );
      expect(result, isNull);
    });
  });

  group('tryRecover — three-way merge', () {
    test('recovers an edit when the drift is outside the edited region', () {
      const previous = 'h1\nh2\ntarget\nf1\nf2';
      // The live file gained a header line above the edited region.
      const current = 'HEADER\nh1\nh2\ntarget\nf1\nf2';
      // Replace 'target' (line 3 of the snapshot) with 'CHANGED'.
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 3, endLine: 3, lines: ['CHANGED']),
      ]);

      final result = tryRecover(
        previousText: previous,
        currentText: current,
        edits: edits,
      );
      expect(result, isNotNull);
      expect(result!.text, 'HEADER\nh1\nh2\nCHANGED\nf1\nf2');
      expect(result.warnings, contains(recoveryThreeWayMergeWarning));
    });

    test('three-way merge handles a pure deletion drift-safely', () {
      const previous = 'keep1\ndrop\nkeep2\nkeep3';
      const current = 'PREFIX\nkeep1\ndrop\nkeep2\nkeep3';
      const edits = [DeleteEdit(line: 2)]; // delete 'drop'

      final result = tryRecover(
        previousText: previous,
        currentText: current,
        edits: edits,
      );
      expect(result, isNotNull);
      expect(result!.text, 'PREFIX\nkeep1\nkeep2\nkeep3');
      expect(result.warnings, contains(recoveryThreeWayMergeWarning));
    });
  });

  group('tryRecover — session-chain replay fallback', () {
    test('replays edits when line count matches and anchors are identical', () {
      // The context lines around the anchor drifted (so the 3-way merge cannot
      // locate its context), but the anchor line itself is byte-identical and
      // the line count is unchanged → session-chain replay onto current.
      const previous = 'x\nTARGET\ny';
      const current = 'X\nTARGET\nY';
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 2, lines: ['NEW']),
      ]);

      final result = tryRecover(
        previousText: previous,
        currentText: current,
        edits: edits,
        anchorLines: const [2],
      );
      expect(result, isNotNull);
      expect(result!.text, 'X\nNEW\nY');
      expect(result.warnings, contains(recoverySessionReplayWarning));
    });
  });

  group('tryRecover — unrecoverable', () {
    test('returns null when line counts differ and 3-way merge fails', () {
      // Anchor line drifted AND the context cannot be located: nothing safe.
      const previous = 'x\nTARGET\ny';
      const current = 'completely\ndifferent\nfile\nhere';
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 2, lines: ['NEW']),
      ]);

      final result = tryRecover(
        previousText: previous,
        currentText: current,
        edits: edits,
        anchorLines: const [2],
      );
      expect(result, isNull);
    });

    test('session replay declines when the anchor line content changed', () {
      // Same line count, but the targeted line differs between snapshot and
      // live: replaying would overwrite new content with stale intent.
      const previous = 'a\nOLD\nb';
      const current = 'a\nDIFFERENT\nb';
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 2, lines: ['NEW']),
      ]);

      final result = tryRecover(
        previousText: previous,
        currentText: current,
        edits: edits,
        anchorLines: const [2],
      );
      // The 3-way merge cannot locate [a,OLD,b] in current, and the session
      // replay anchor gate fails (OLD != DIFFERENT) → null.
      expect(result, isNull);
    });
  });
}
