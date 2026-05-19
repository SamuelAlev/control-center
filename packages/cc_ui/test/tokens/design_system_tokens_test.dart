import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The semantic design-token set is a large pure data class: the two factory
/// themes, a [copyWith] that threads every field, and a [lerp] for animated
/// light/dark transitions. These tests exercise each construction path so the
/// whole token table is covered (the real app reaches it only through
/// `CcThemeData`, which leaves the factories themselves unmeasured).
void main() {
  group('DesignSystemTokens.light', () {
    test('constructs with the documented canvas/surface/panel aliasing', () {
      final tokens = DesignSystemTokens.light();
      expect(tokens.canvas, DesignSystemPalette.gray50);
      expect(tokens.surface, DesignSystemPalette.gray100);
      expect(tokens.panel, DesignSystemPalette.white);
      // Brand accent and its on-color are a matched pair. The functional
      // accent is the accessible burnt orange (brand850); the bright brand600
      // signal is reserved for the bounded brand graphics.
      expect(tokens.accent, DesignSystemPalette.brand850);
      expect(tokens.accentOn, DesignSystemPalette.white);
      // Focus rings route through the brand/danger colors.
      expect(tokens.focusRing, DesignSystemPalette.brand850);
      expect(tokens.focusRingError, DesignSystemPalette.red500);
    });

    test('text and foreground primaries are dark on the light theme', () {
      final tokens = DesignSystemTokens.light();
      expect(tokens.textPrimary, DesignSystemPalette.gray900);
      expect(tokens.fgPrimary, DesignSystemPalette.gray900);
      expect(tokens.fgDisabled, DesignSystemPalette.gray400);
      // The white text token is pure white in both themes.
      expect(tokens.textWhite, DesignSystemPalette.white);
    });

    test('borders and solid variants populate', () {
      final tokens = DesignSystemTokens.light();
      expect(tokens.borderPrimary, DesignSystemPalette.gray300);
      expect(tokens.borderError, DesignSystemPalette.red500);
      // a11y: solid brand/status fills darkened so white text clears 4.5:1.
      expect(tokens.bgBrandSolid, DesignSystemPalette.brand850);
      expect(tokens.bgBrandSolidHover, DesignSystemPalette.brand900);
      expect(tokens.bgErrorSolid, DesignSystemPalette.red700);
    });

    test('golden-hour brand mosaic colors are present', () {
      final tokens = DesignSystemTokens.light();
      expect(tokens.sunshine900, DesignSystemPalette.sunshine900);
      expect(tokens.sunshine700, DesignSystemPalette.sunshine700);
      expect(tokens.sunshine500, DesignSystemPalette.sunshine500);
      expect(tokens.sunshine300, DesignSystemPalette.sunshine300);
      expect(tokens.brightYellow, DesignSystemPalette.brightYellow);
      expect(tokens.blockEdge, DesignSystemPalette.blockEdge);
    });
  });

  group('DesignSystemTokens.dark', () {
    test('constructs with the inverted canvas/surface/panel aliasing', () {
      final tokens = DesignSystemTokens.dark();
      expect(tokens.canvas, DesignSystemPalette.gray950);
      expect(tokens.surface, DesignSystemPalette.gray800);
      expect(tokens.panel, DesignSystemPalette.gray900);
      expect(tokens.accent, DesignSystemPalette.brand500);
      expect(tokens.focusRing, DesignSystemPalette.brand500);
    });

    test('text and foreground primaries are light on the dark theme', () {
      final tokens = DesignSystemTokens.dark();
      expect(tokens.textPrimary, DesignSystemPalette.gray50);
      expect(tokens.fgPrimary, DesignSystemPalette.white);
      expect(tokens.textSecondary, DesignSystemPalette.gray300);
      expect(tokens.borderPrimary, DesignSystemPalette.gray700);
    });

    test('error/warning/success solid states populate', () {
      final tokens = DesignSystemTokens.dark();
      expect(tokens.bgErrorSolid, DesignSystemPalette.red600);
      expect(tokens.bgWarningSolid, DesignSystemPalette.yellow600);
      // a11y: darkened so white text clears 4.5:1 (green600 was 3.3:1).
      expect(tokens.bgSuccessSolid, DesignSystemPalette.green700);
    });
  });

  group('DesignSystemTokens.light vs dark differ on key tokens', () {
    test('the primary backgrounds and text flip', () {
      final light = DesignSystemTokens.light();
      final dark = DesignSystemTokens.dark();
      expect(light.bgPrimary, isNot(dark.bgPrimary));
      expect(light.textPrimary, isNot(dark.textPrimary));
      expect(light.canvas, isNot(dark.canvas));
      expect(light.accent, isNot(dark.accent));
    });
  });

  group('copyWith', () {
    test('returns an equal token set when called with all-null overrides', () {
      final tokens = DesignSystemTokens.light();
      final copy = tokens.copyWith();
      expect(copy.bgPrimary, tokens.bgPrimary);
      expect(copy.accent, tokens.accent);
      expect(copy.focusRing, tokens.focusRing);
      expect(copy.blockEdge, tokens.blockEdge);
    });

    test('overrides only the supplied fields, leaving the rest untouched', () {
      final tokens = DesignSystemTokens.light();
      const newAccent = Color(0xFF123456);
      final copy = tokens.copyWith(accent: newAccent, textPrimary: newAccent);
      expect(copy.accent, newAccent);
      expect(copy.textPrimary, newAccent);
      // Untouched fields keep their original values.
      expect(copy.accentOn, tokens.accentOn);
      expect(copy.canvas, tokens.canvas);
      expect(copy.borderPrimary, tokens.borderPrimary);
    });

    test('overrides border / background / success fields end to end', () {
      final tokens = DesignSystemTokens.dark();
      final copy = tokens.copyWith(
        borderSecondary: const Color(0xFFAABBCC),
        bgBrandSection: const Color(0xFF112233),
        successSoft: const Color(0xFF445566),
        hoverStrong: const Color(0xFF778899),
      );
      expect(copy.borderSecondary, const Color(0xFFAABBCC));
      expect(copy.bgBrandSection, const Color(0xFF112233));
      expect(copy.successSoft, const Color(0xFF445566));
      expect(copy.hoverStrong, const Color(0xFF778899));
      expect(copy.accent, tokens.accent);
    });
  });

  group('lerp', () {
    test('t=0 reproduces the start tokens exactly', () {
      final start = DesignSystemTokens.light();
      final end = DesignSystemTokens.dark();
      final at0 = start.lerp(end, 0);
      expect(at0.bgPrimary, start.bgPrimary);
      expect(at0.accent, start.accent);
      expect(at0.textPrimary, start.textPrimary);
      expect(at0.blockEdge, start.blockEdge);
    });

    test('t=1 reproduces the end tokens exactly', () {
      final start = DesignSystemTokens.light();
      final end = DesignSystemTokens.dark();
      final at1 = start.lerp(end, 1);
      expect(at1.bgPrimary, end.bgPrimary);
      expect(at1.accent, end.accent);
      expect(at1.canvas, end.canvas);
      expect(at1.focusRingError, end.focusRingError);
    });

    test('t=0.5 is the midpoint color for a sampled field', () {
      final start = DesignSystemTokens.light();
      final end = DesignSystemTokens.dark();
      final atHalf = start.lerp(end, 0.5);
      expect(atHalf.accent, Color.lerp(start.accent, end.accent, 0.5));
      expect(
        atHalf.borderPrimary,
        Color.lerp(start.borderPrimary, end.borderPrimary, 0.5),
      );
    });
  });
}
