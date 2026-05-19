import 'package:cc_ui/src/theme/cc_font_registry.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-logic coverage for the [CcFonts] style helpers: the bundled default and
/// the on-demand path through [CcFontRegistry].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(CcFontRegistry.instance.resetForTests);
  tearDown(CcFontRegistry.instance.resetForTests);

  group('CcFonts', () {
    test('ui() with no family uses the bundled Manrope family', () {
      final style = CcFonts.ui(textStyle: const TextStyle(fontSize: 14));
      expect(style.fontFamily, CcFonts.uiFamily);
      expect(style.fontSize, 14);
    });

    test('code() with no family uses the bundled Fira Code family', () {
      final style = CcFonts.code();
      expect(style.fontFamily, CcFonts.codeFamily);
    });

    test('ui() with no textStyle defaults to an empty base style', () {
      final style = CcFonts.ui();
      expect(style.fontFamily, CcFonts.uiFamily);
    });

    test('a named family resolves to its per-weight variant', () {
      final style = CcFonts.ui(family: 'Custom-Host-Font');
      expect(
        style.fontFamily,
        'Custom-Host-Font 400',
        reason: 'each weight is registered under its own family name',
      );
    });

    test('the raw family remains reachable as a fallback', () {
      // This is what keeps an OS-installed font working: it is registered under
      // its real name, so the variant name misses and the fallback hits.
      final style = CcFonts.code(family: 'MyMono');
      expect(style.fontFamilyFallback, contains('MyMono'));
      expect(
        style.fontFamilyFallback,
        contains(CcFonts.codeFamily),
        reason: 'a code surface stays monospaced while the family loads',
      );
    });

    // Regression: a bundled family is registered with the engine under its real
    // name, so it must be applied by name. Routing it through the registry
    // named a per-weight variant (`packages/cc_ui/Manrope 400`) that nothing
    // ever registers, leaving the real font reachable only through
    // `fontFamilyFallback` — which any call site that names its own fallback
    // list drops. That is how the chat body ended up shaping its spaces and
    // digits in the emoji font.
    test('a bundled family is applied by name, not through the registry', () {
      final ui = CcFonts.ui(family: CcFonts.uiFamily);
      expect(ui.fontFamily, CcFonts.uiFamily);
      expect(ui.fontFamilyFallback, isNull);

      final code = CcFonts.code(family: CcFonts.codeFamily);
      expect(code.fontFamily, CcFonts.codeFamily);
      expect(code.fontFamilyFallback, isNull);
    });

    test('a bundled family survives a non-regular weight', () {
      final style = CcFonts.ui(
        family: CcFonts.uiFamily,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      );
      expect(style.fontFamily, CcFonts.uiFamily);
    });

    test('a bundled family from the other lane is still applied by name', () {
      // A proportional call site asking for the bundled mono font gets it, not
      // the UI lane's own bundled family.
      expect(CcFonts.ui(family: CcFonts.codeFamily).fontFamily,
          CcFonts.codeFamily);
    });

    test('the requested weight and slant pick the variant', () {
      final style = CcFonts.ui(
        family: 'Inter',
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      );
      expect(style.fontFamily, 'Inter 700 italic');
    });
  });
}
