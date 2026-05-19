import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_text_styles.dart';
import 'package:control_center/core/theme/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the design system's "Tabular Figures Everywhere" rule (DESIGN.md §3):
/// every style that can render digits carries
/// `FontFeature.tabularFigures()` — directly on the [`CcTypography`] scale and
/// the widgets-only [`AppTextStyles`], and through the root Material text
/// theme whose entries seed the ambient `DefaultTextStyle` raw `TextStyle`s
/// inherit from.
///
/// A style missing here silently reverts its digits to proportional widths:
/// columns stop aligning and ticking values jitter.
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
      test('$name enables tabular figures', () {
        expect(style.fontFeatures, contains(tabular), reason: name);
      });
    });

    test('numeralFeatures is exactly one tabular-figures entry', () {
      expect(CcTypography.numeralFeatures, const [tabular]);
    });
  });

  group('AppTextStyles', () {
    final tokens = DesignSystemTokens.light();
    final styles = <String, TextStyle>{
      'labelSmall': AppTextStyles.labelSmall(tokens),
      'labelLarge': AppTextStyles.labelLarge(tokens),
      'bodySmall': AppTextStyles.bodySmall(tokens),
      'bodyMedium': AppTextStyles.bodyMedium(tokens),
      'mono': AppTextStyles.mono(tokens),
    };
    styles.forEach((name, style) {
      test('$name enables tabular figures', () {
        expect(style.fontFeatures, contains(tabular), reason: name);
      });
    });
  });

  group('root Material text theme', () {
    for (final brightness in Brightness.values) {
      test('${brightness.name} theme carries tnum into every role', () {
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
          expect(style?.fontFeatures, contains(tabular), reason: name);
        });
      });
    }
  });
}
