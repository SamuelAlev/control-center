import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:control_center/features/vscode_theme/domain/vscode_editor_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiffColors.forBrightness', () {
    test(
      'light uses GitHub hand-tuned solid tints, not accent alpha blends',
      () {
        final c = DiffColors.forBrightness(Brightness.light);
        expect(c.additionAccent, const Color(0xFF2DA44E));
        expect(c.deletionAccent, const Color(0xFFCF222E));
        // Solid tints keep the dominant channel at 255 so the tint stays
        // luminous — an alpha blend over white always reads grey.
        expect(c.additionBg, const Color(0xFFE6FFEC));
        expect(c.deletionBg, const Color(0xFFFFEBE9));
        expect(c.additionWordBg, const Color(0xFFABF2BC));
        expect(c.deletionWordBg, const Color(0xFFFFCECB));
        expect(c.additionGutterBg, const Color(0xFFCCFFD8));
        expect(c.deletionGutterBg, const Color(0xFFFFD7D5));
      },
    );

    test('dark blends GitHub dark hues over the surface', () {
      final c = DiffColors.forBrightness(Brightness.dark);
      expect(c.additionAccent, const Color(0xFF3FB950));
      expect(c.deletionAccent, const Color(0xFFF85149));
      expect(c.additionBg.a, closeTo(0.15, 0.001));
      expect(c.deletionBg.a, closeTo(0.15, 0.001));
      // Word emphasis is a visibly stronger tint of the same hue.
      expect(c.additionWordBg.a, closeTo(0.4, 0.001));
      expect(c.deletionWordBg.a, closeTo(0.4, 0.001));
      expect(c.additionGutterBg.a, closeTo(0.3, 0.001));
      expect(c.deletionGutterBg.a, closeTo(0.3, 0.001));
    });
  });

  group('unification invariant', () {
    test('the PR diff palette draws its add/delete from DiffColors', () {
      // The PR canvas diff and the shared source must agree, so all three diff
      // surfaces render identical add/delete backgrounds.
      final shared = DiffColors.forBrightness(Brightness.light);
      final pr = DiffPalette.forBrightness(Brightness.light);
      expect(pr.additionBg, shared.additionBg);
      expect(pr.deletionBg, shared.deletionBg);
      expect(pr.additionAccent, shared.additionAccent);
      expect(pr.deletionAccent, shared.deletionAccent);
      expect(pr.additionGutterBg, shared.additionGutterBg);
      expect(pr.deletionGutterBg, shared.deletionGutterBg);
      expect(pr.additionGutterFg, shared.additionGutterFg);
      expect(pr.deletionGutterFg, shared.deletionGutterFg);

      final sharedDark = DiffColors.forBrightness(Brightness.dark);
      final prDark = DiffPalette.forBrightness(Brightness.dark);
      expect(prDark.additionBg, sharedDark.additionBg);
      expect(prDark.deletionBg, sharedDark.deletionBg);
      expect(prDark.additionGutterBg, sharedDark.additionGutterBg);
      expect(prDark.deletionGutterBg, sharedDark.deletionGutterBg);
    });

    test('the word-emphasis backgrounds cross into the worker palette map', () {
      for (final brightness in Brightness.values) {
        final shared = DiffColors.forBrightness(brightness);
        final syntax = DiffPalette.forBrightness(brightness).syntax;
        expect(syntax[kAdditionWordBgKey], shared.additionWordBg.toARGB32());
        expect(syntax[kDeletionWordBgKey], shared.deletionWordBg.toARGB32());
      }
    });
  });

  group('DiffColors.fromVsCode', () {
    test('maps the imported theme diff backgrounds', () {
      const theme = VsCodeEditorTheme(
        name: 'X',
        brightness: Brightness.dark,
        background: Color(0xFF1E1E1E),
        foreground: Color(0xFFD4D4D4),
        lineNumber: Color(0xFF858585),
        addedBackground: Color(0x3300FF00),
        removedBackground: Color(0x33FF0000),
        selection: Color(0x33FFFFFF),
      );
      final c = DiffColors.fromVsCode(theme);
      expect(c.additionBg, const Color(0x3300FF00));
      expect(c.deletionBg, const Color(0x33FF0000));
      expect(c.contextFg, const Color(0xFFD4D4D4));
      expect(c.gutterFg, const Color(0xFF858585));
      // VS Code themes only carry line-level diff colors: the gutter reuses
      // them, and the word emphasis is a translucent accent overlay.
      expect(c.additionGutterBg, const Color(0x3300FF00));
      expect(c.deletionGutterBg, const Color(0x33FF0000));
      expect(c.additionGutterFg, const Color(0xFF858585));
      expect(c.additionWordBg.a, closeTo(0.4, 0.001));
      expect(c.deletionWordBg.a, closeTo(0.4, 0.001));
    });
  });
}
