import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, int> _testPalette() => const {
  'deletion': 0xFFFF7B72,
  'addition': 0xFF7EE787,
};

void main() {
  group('applyInlineWordDiff', () {
    test('no-ops on empty specs list', () {
      final specs = <DiffLineSpec>[];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs, isEmpty);
    });

    test('no-ops when palette missing deletion key', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('old line', 0xFFFF0000)],
          oldLine: 1,
        ),
      ];
      final original = List<DiffLineSpec>.from(specs);
      applyInlineWordDiff(specs, <String, int>{});
      for (var i = 0; i < specs.length; i++) {
        expect(specs[i].tokens.length, original[i].tokens.length);
      }
    });

    test('no-ops when palette missing addition key', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('new line', 0xFF00FF00)],
          newLine: 1,
        ),
      ];
      final original = List<DiffLineSpec>.from(specs);
      applyInlineWordDiff(specs, <String, int>{'deletion': 0xFFFF7B72});
      for (var i = 0; i < specs.length; i++) {
        expect(specs[i].tokens.length, original[i].tokens.length);
      }
    });

    test('processes single addition with no matching deletion as-is', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,2 @@', null)],
          hunkHeader: '@@ -1,1 +1,2 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('  new line', null)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 2);
      expect(specs[1].kind, DiffLineKind.addition);
    });

    test('processes single deletion with no matching addition as-is', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,2 +1,1 @@', null)],
          hunkHeader: '@@ -1,2 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('  old line', null)],
          oldLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 2);
      expect(specs[1].kind, DiffLineKind.deletion);
    });

    test('processes multiple hunks independently', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.context,
          tokens: [DiffToken('  context', null)],
          oldLine: 1,
          newLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -5,1 +5,1 @@', null)],
          hunkHeader: '@@ -5,1 +5,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('  removed', null)],
          oldLine: 5,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('  added', null)],
          newLine: 5,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 5);
    });

    test('preserves context lines unchanged', () {
      const contextToken = DiffToken('  keep me', 0xFF888888);
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,3 +1,3 @@', null)],
          hunkHeader: '@@ -1,3 +1,3 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.context,
          tokens: [contextToken],
          oldLine: 1,
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs[1].tokens.length, 1);
      expect(specs[1].tokens[0].text, '  keep me');
    });

    test('handles empty deletion and addition lines within hunk', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('', null)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('', null)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 3);
    });

    test('hunk header tokens preserved', () {
      const headerToken = DiffToken('@@ -1,2 +1,2 @@', 0xFF888888);
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [headerToken],
          hunkHeader: '@@ -1,2 +1,2 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('old', null)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('new', null)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs[0].tokens, equals([headerToken]));
    });

    test('handles multiple deletions and additions within one hunk', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,3 +1,3 @@', null)],
          hunkHeader: '@@ -1,3 +1,3 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('line a', null)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('line b', null)],
          oldLine: 2,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('line x', null)],
          newLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('line y', null)],
          newLine: 2,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 5);
    });

    test('handles identical deletion and addition passed through', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('same text', 0xFFFF0000)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('same text', 0xFF00FF00)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs[1].tokens.length, 1);
      expect(specs[2].tokens.length, 1);
    });

    test('handles specs with no hunk headers', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('deleted', null)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('added', null)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 2);
    });

    test('keeps syntax colors and applies the palette word backgrounds', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('const a = 1;', 0xFF112233)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('const a = 2;', 0xFF112233)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, const {
        'deletion': 0xFFFF7B72,
        'addition': 0xFF7EE787,
        kDeletionWordBgKey: 0x66F85149,
        kAdditionWordBgKey: 0x662EA043,
      });
      final delChanged = specs[1].tokens
          .where((t) => t.backgroundColorValue != null)
          .toList();
      final addChanged = specs[2].tokens
          .where((t) => t.backgroundColorValue != null)
          .toList();
      expect(delChanged, isNotEmpty);
      expect(addChanged, isNotEmpty);
      expect(
        delChanged.every((t) => t.backgroundColorValue == 0x66F85149),
        isTrue,
      );
      expect(
        addChanged.every((t) => t.backgroundColorValue == 0x662EA043),
        isTrue,
      );
      // Glyphs keep their original syntax color — the emphasis comes from the
      // stronger background, never from recoloring the text.
      expect(delChanged.every((t) => t.colorValue == 0xFF112233), isTrue);
      expect(addChanged.every((t) => t.colorValue == 0xFF112233), isTrue);
    });

    test('falls back to a 40% accent tint when word-bg keys are absent', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('old value', null)],
          oldLine: 1,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('new value', null)],
          newLine: 1,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      final delChanged = specs[1].tokens
          .where((t) => t.backgroundColorValue != null)
          .toList();
      expect(delChanged, isNotEmpty);
      expect(
        delChanged.every((t) => t.backgroundColorValue == 0x66FF7B72),
        isTrue,
      );
    });

    test('handles consecutive hunk headers', () {
      final specs = <DiffLineSpec>[
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -1,1 +1,1 @@', null)],
          hunkHeader: '@@ -1,1 +1,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.hunkHeader,
          tokens: [DiffToken('@@ -5,1 +5,1 @@', null)],
          hunkHeader: '@@ -5,1 +5,1 @@',
        ),
        const DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: [DiffToken('old', null)],
          oldLine: 5,
        ),
        const DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: [DiffToken('new', null)],
          newLine: 5,
        ),
      ];
      applyInlineWordDiff(specs, _testPalette());
      expect(specs.length, 4);
    });
  });
}
