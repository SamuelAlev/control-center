import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the design system's "Tabular Figures Follow The Mono Family" rule
/// (DESIGN.md §3): `FontFeature.tabularFigures()` belongs to the MONOSPACE
/// lane and nowhere else.
///
/// Fixed-advance digits are what stop a column of counts, durations or line
/// numbers from jittering — and what makes running prose look mechanical. So
/// the feature rides the family: [CcFonts.code] (and the app's mono helpers)
/// apply it, while the family-agnostic [CcTypography] scale, the proportional
/// [AppTextStyles] roles and the root Material text theme carry none. The last
/// one matters most: `MaterialApp` derives the ambient `DefaultTextStyle` from
/// `bodyMedium`, so a feature list there reaches every raw `TextStyle` in the
/// app.
void main() {
  const tabular = FontFeature.tabularFigures();

  group('CcTypography', () {
    const styles = <String, TextStyle>{
      'displayHero': CcTypography.displayHero,
      'display': CcTypography.display,
      'title': CcTypography.title,
      'body': CcTypography.body,
      'bodySm': CcTypography.bodySm,
      'caption': CcTypography.caption,
      'label': CcTypography.label,
      'monoNum': CcTypography.monoNum,
    };
    styles.forEach((name, style) {
      test('$name names no font features', () {
        // The scale sets no family either, so it cannot know whether its digits
        // will land in Manrope or Fira Code. The call site's font helper does.
        expect(style.fontFeatures, isNull, reason: name);
      });
    });

    test('numeralFeatures is exactly one tabular-figures entry', () {
      expect(CcTypography.numeralFeatures, const [tabular]);
    });
  });

  group('CcFonts', () {
    test('code() applies tabular figures with the monospace family', () {
      final style = CcFonts.code(textStyle: CcTypography.monoNum);
      expect(style.fontFamily, CcFonts.codeFamily);
      expect(style.fontFeatures, contains(tabular));
    });

    test('code() keeps a caller-supplied feature list verbatim', () {
      const ligaturesOff = [FontFeature.disable('liga')];
      final style = CcFonts.code(
        textStyle: const TextStyle(fontFeatures: ligaturesOff),
      );
      expect(style.fontFeatures, ligaturesOff);
    });

    test('code() carries tabular figures onto a user-selected mono family', () {
      final style = CcFonts.code(textStyle: CcTypography.monoNum, family: 'X');
      expect(style.fontFeatures, contains(tabular));
      expect(style.fontFamilyFallback, contains(CcFonts.codeFamily));
    });

    test('ui() leaves digits proportional', () {
      final style = CcFonts.ui(textStyle: CcTypography.body);
      expect(style.fontFamily, CcFonts.uiFamily);
      expect(style.fontFeatures, isNull);
    });
  });

  group('AppFonts', () {
    test('code helpers enable tabular figures', () {
      expect(AppFonts.code().fontFeatures, contains(tabular));
      expect(AppFonts.codeStyle(fontSize: 12).fontFeatures, contains(tabular));
      expect(
        AppFonts.codeDynamic('X').fontFeatures,
        contains(tabular),
        reason: 'codeDynamic',
      );
      expect(
        AppFonts.codeStyleDynamic('X', fontSize: 12).fontFeatures,
        contains(tabular),
        reason: 'codeStyleDynamic',
      );
    });

    test('ui() leaves digits proportional', () {
      expect(AppFonts.ui().fontFeatures, isNull);
    });

    test('codeFontFeatures keeps tnum in both ligature modes', () {
      // These lists REPLACE the mono lane's features at the call site, so they
      // have to carry tnum themselves or a diff gutter loses its alignment.
      for (final ligatures in [true, false]) {
        expect(
          AppFonts.codeFontFeatures(ligatures: ligatures),
          contains(tabular),
          reason: 'ligatures: $ligatures',
        );
      }
    });
  });

  group('AppTextStyles', () {
    final tokens = DesignSystemTokens.light();
    test('mono enables tabular figures', () {
      final style = AppTextStyles.mono(tokens);
      expect(style.fontFamily, CcFonts.codeFamily);
      expect(style.fontFeatures, contains(tabular));
    });

    final proportional = <String, TextStyle>{
      'labelSmall': AppTextStyles.labelSmall(tokens),
      'labelLarge': AppTextStyles.labelLarge(tokens),
      'bodySmall': AppTextStyles.bodySmall(tokens),
      'bodyMedium': AppTextStyles.bodyMedium(tokens),
    };
    proportional.forEach((name, style) {
      test('$name leaves digits proportional', () {
        expect(style.fontFamily, CcFonts.uiFamily, reason: name);
        expect(style.fontFeatures, isNull, reason: name);
      });
    });
  });

  group('root Material text theme', () {
    for (final brightness in Brightness.values) {
      test('${brightness.name} theme carries tnum into no role', () {
        final textTheme = brightness == Brightness.light
            ? AppTheme.light().textTheme
            : AppTheme.dark().textTheme;
        final roles = <String, TextStyle?>{
          'displayLarge': textTheme.displayLarge,
          'displayMedium': textTheme.displayMedium,
          'displaySmall': textTheme.displaySmall,
          'headlineLarge': textTheme.headlineLarge,
          'headlineMedium': textTheme.headlineMedium,
          'headlineSmall': textTheme.headlineSmall,
          'titleLarge': textTheme.titleLarge,
          'titleMedium': textTheme.titleMedium,
          'titleSmall': textTheme.titleSmall,
          'bodyLarge': textTheme.bodyLarge,
          'bodyMedium': textTheme.bodyMedium,
          'bodySmall': textTheme.bodySmall,
          'labelLarge': textTheme.labelLarge,
          'labelMedium': textTheme.labelMedium,
          'labelSmall': textTheme.labelSmall,
        };
        roles.forEach((name, style) {
          expect(
            style?.fontFeatures ?? const [],
            isNot(contains(tabular)),
            reason: name,
          );
        });
      });
    }
  });
}
