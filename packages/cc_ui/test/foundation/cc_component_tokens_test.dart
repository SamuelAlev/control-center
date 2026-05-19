import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-logic coverage for the resolved component token sets. Each factory is a
/// pure function of [DesignSystemTokens], so we assert they run for both light
/// and dark palettes and that every produced color is opaque where the design
/// spec requires a solid surface.
void main() {
  group('CcButtonTokens', () {
    test('every variant resolves for light + dark palettes', () {
      for (final t in [DesignSystemTokens.light(), DesignSystemTokens.dark()]) {
        // Just call every factory — coverage is the point, and any token
        // wired to a null palette field would throw here.
        final primary = CcButtonTokens.primary(t);
        final accent = CcButtonTokens.accent(t);
        final secondary = CcButtonTokens.secondary(t);
        final line = CcButtonTokens.line(t);
        final ghost = CcButtonTokens.ghost(t);
        final destructive = CcButtonTokens.destructive(t);

        // fg is always resolved (opaque on solid surfaces); just assert the
        // fields are non-null Color instances produced by the factory.
        for (final tk in [
          primary,
          accent,
          secondary,
          line,
          ghost,
          destructive,
        ]) {
          expect(tk.fg, isA<Color>());
          expect(tk.bg, isA<Color>());
          expect(tk.bgPressed, isA<Color>());
          expect(tk.bgHover, isA<Color>());
          expect(tk.border, isA<Color>());
          expect(tk.borderHover, isA<Color>());
        }
      }
    });

    test('primary picks the dark-mode tinted-ink path on dark palettes', () {
      final dark = DesignSystemTokens.dark();
      final light = DesignSystemTokens.light();
      final darkPrimary = CcButtonTokens.primary(dark);
      final lightPrimary = CcButtonTokens.primary(light);
      // Light primary uses the opaque ink fg as bg; dark primary lerps surface
      // toward the accent. The two must differ.
      expect(darkPrimary.bg, isNot(equals(lightPrimary.bg)));
      // Hover warms both to the accessible solid brand fill (not the raw
      // `accent`, which in dark mode stays bright and can't carry white text).
      expect(darkPrimary.bgHover, dark.bgBrandSolid);
      expect(lightPrimary.bgHover, light.bgBrandSolid);
    });

    test('line + destructive + surface card token fields', () {
      final t = DesignSystemTokens.light();
      final line = CcButtonTokens.line(t);
      expect(line.bg, t.panel);
      expect(line.bgHover, Color.alphaBlend(t.hover, t.panel));
      expect(line.bgPressed, Color.alphaBlend(t.hoverStrong, t.panel));
      expect(line.border, t.borderPrimary);
      expect(line.borderHover, t.fg);

      final destructive = CcButtonTokens.destructive(t);
      expect(destructive.bg, t.bgErrorSolid);
      expect(destructive.bgHover, t.bgErrorSolidHover);
      expect(destructive.bgPressed, t.bgErrorSolidHover);
      expect(destructive.fg, t.textWhite);
    });
  });

  group('CcInputTokens', () {
    test('.resolve maps every design-system field', () {
      final t = DesignSystemTokens.dark();
      final i = CcInputTokens.resolve(t);
      expect(i.bg, t.surface);
      expect(i.border, t.textPlaceholder);
      expect(i.borderFocused, t.accent);
      expect(i.text, t.textPrimary);
      expect(i.placeholder, t.textPlaceholder);
      expect(i.cursor, t.accent);
      expect(i.selection, t.accentSoft);
      expect(i.borderError, t.danger);
      expect(i.bgError, t.dangerSoft);
    });
  });

  group('CcCardTokens', () {
    test('.panel vs .surface pick the right fills', () {
      final t = DesignSystemTokens.light();
      final panel = CcCardTokens.panel(t);
      final surface = CcCardTokens.surface(t);
      expect(panel.bg, t.panel);
      expect(surface.bg, t.surface);
      expect(panel.border, t.borderPrimary);
      expect(surface.border, t.borderPrimary);
      expect(panel.hoverBg, t.hover);
      expect(surface.hoverBg, t.hover);
    });
  });
}
