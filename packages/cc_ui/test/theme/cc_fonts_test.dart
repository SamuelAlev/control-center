import 'package:cc_ui/src/theme/cc_font_registry.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-logic coverage for the [CcFonts] style helpers: the bundled default and
/// the on-demand path through [CcFontRegistry].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CcFontRegistry.instance.resetForTests();
    CcFonts.resetForTests();
  });
  tearDown(() {
    CcFontRegistry.instance.resetForTests();
    CcFonts.resetForTests();
  });

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
      final ui = CcFonts.ui(
        family: CcFonts.uiFamily,
        textStyle: const TextStyle(fontFamilyFallback: ['Apple Color Emoji']),
      );
      expect(ui.fontFamily, CcFonts.uiFamily);
      // The bundled name is primary, never a fallback; a call site's own
      // list survives after the (currently empty) script companion slot.
      expect(ui.fontFamilyFallback, isNot(contains(CcFonts.uiFamily)));
      expect(ui.fontFamilyFallback, contains('Apple Color Emoji'));

      CcFonts.activateForLocale(const Locale('th', 'TH'), load: false);
      final thai = CcFonts.ui(
        family: CcFonts.uiFamily,
        textStyle: const TextStyle(fontFamilyFallback: ['Apple Color Emoji']),
      );
      expect(
        thai.fontFamilyFallback,
        containsAllInOrder(['Sarabun', 'Apple Color Emoji']),
      );

      final code = CcFonts.code(family: CcFonts.codeFamily);
      expect(code.fontFamily, CcFonts.codeFamily);
    });

    test('Latin locales attach no script companion', () {
      CcFonts.activateForLocale(const Locale('en', 'US'), load: false);
      expect(CcFonts.scriptFallbackFamilies, isEmpty);
      expect(CcFonts.ui().fontFamilyFallback, isEmpty);
    });

    test('Thai attaches Sarabun and not the Hebrew or Arabic faces', () {
      CcFonts.activateForLocale(const Locale('th', 'TH'), load: false);
      expect(CcFonts.scriptFallbackFamilies, contains('Sarabun'));
      expect(CcFonts.scriptFallbackFamilies, contains('Thonburi'));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('Rubik')));
      expect(
        CcFonts.scriptFallbackFamilies,
        isNot(contains('IBM Plex Sans Arabic')),
      );
      expect(CcFonts.ui().fontFamilyFallback!.first, 'Sarabun');
    });

    test('Hebrew attaches Rubik and not Thai', () {
      CcFonts.activateForLocale(const Locale('he', 'IL'), load: false);
      expect(CcFonts.scriptFallbackFamilies, contains('Rubik'));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('Sarabun')));
    });

    test('Arabic, Persian and Urdu share IBM Plex Sans Arabic', () {
      for (final locale in const [
        Locale('ar', 'SA'),
        Locale('fa', 'IR'),
        Locale('ur', 'PK'),
      ]) {
        CcFonts.resetForTests();
        CcFonts.activateForLocale(locale, load: false);
        expect(
          CcFonts.scriptFallbackFamilies,
          contains('IBM Plex Sans Arabic'),
        );
        expect(CcFonts.scriptFallbackFamilies, isNot(contains('Sarabun')));
        expect(CcFonts.scriptFallbackFamilies, isNot(contains('Rubik')));
      }
    });

    test('CJK locales attach only that language\'s OS face', () {
      CcFonts.activateForLocale(const Locale('ja', 'JP'), load: false);
      expect(CcFonts.scriptFallbackFamilies, contains('Hiragino Sans'));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('PingFang SC')));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('Sarabun')));

      CcFonts.resetForTests();
      CcFonts.activateForLocale(const Locale('zh', 'TW'), load: false);
      expect(CcFonts.scriptFallbackFamilies, contains('PingFang TC'));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('Hiragino Sans')));
    });

    test('switching locale drops the previous companion', () {
      CcFonts.activateForLocale(const Locale('th', 'TH'), load: false);
      CcFonts.activateForLocale(const Locale('he', 'IL'), load: false);
      expect(CcFonts.scriptFallbackFamilies, contains('Rubik'));
      expect(CcFonts.scriptFallbackFamilies, isNot(contains('Sarabun')));
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
      expect(
        CcFonts.ui(family: CcFonts.codeFamily).fontFamily,
        CcFonts.codeFamily,
      );
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
