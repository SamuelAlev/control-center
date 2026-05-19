import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesignSystemTokens', () {
    test('light factory uses the documented semantic mapping', () {
      final tokens = DesignSystemTokens.light();
      expect(tokens.bgPrimary, DesignSystemPalette.white);
      expect(tokens.bgSecondary, DesignSystemPalette.gray50);
      expect(tokens.bgTertiary, DesignSystemPalette.gray100);
      expect(tokens.bgBrandSolid, DesignSystemPalette.brand600);
      expect(tokens.bgBrandSolidHover, DesignSystemPalette.brand700);
      expect(tokens.textPrimary, DesignSystemPalette.gray900);
      expect(tokens.textSecondary, DesignSystemPalette.gray700);
      expect(tokens.textPlaceholder, DesignSystemPalette.gray500);
      expect(tokens.borderPrimary, DesignSystemPalette.gray300);
      expect(tokens.borderBrand, DesignSystemPalette.brand500);
      expect(tokens.fgBrandPrimary, DesignSystemPalette.brand600);
      expect(tokens.fgBrandSecondaryHover, DesignSystemPalette.brand600);
      expect(tokens.bgBrandSection, DesignSystemPalette.brand800);
      // Focus ring is the orange accent (brand-600 #fa520f).
      expect(tokens.focusRing, DesignSystemPalette.brand600);
    });

    test('palette uses the signal-orange brand scale', () {
      // The brand scale is the single orange signal: flame (500) -> accent (600).
      expect(DesignSystemPalette.brand500, const Color(0xFFFB6424));
      expect(DesignSystemPalette.brand600, const Color(0xFFFA520F));
    });

    test('new semantic aliases resolve to the design-system values', () {
      final light = DesignSystemTokens.light();
      expect(light.canvas, DesignSystemPalette.gray50);
      expect(light.panel, DesignSystemPalette.white);
      expect(light.fg, DesignSystemPalette.gray900);
      expect(light.accent, DesignSystemPalette.brand600);
      expect(light.success, DesignSystemPalette.green600);
      expect(light.warn, DesignSystemPalette.yellow500);
      expect(light.danger, DesignSystemPalette.red600);
      expect(light.sunshine900, DesignSystemPalette.sunshine900);
    });

    test('dark factory mirrors the design source CSS', () {
      final tokens = DesignSystemTokens.dark();
      // Backgrounds — mirror --color-bg-* from the CSS.
      expect(tokens.bgPrimary, DesignSystemPalette.gray950);
      expect(tokens.bgPrimaryHover, DesignSystemPalette.gray900);
      expect(tokens.bgSecondary, DesignSystemPalette.gray900);
      expect(tokens.bgSecondaryHover, DesignSystemPalette.gray800);
      expect(tokens.bgTertiary, DesignSystemPalette.gray800);
      expect(tokens.bgQuaternary, DesignSystemPalette.gray700);
      expect(tokens.bgBrandPrimary, DesignSystemPalette.brand500);
      expect(tokens.bgBrandSolid, DesignSystemPalette.brand600);
      expect(tokens.bgBrandSolidHover, DesignSystemPalette.brand500);
      expect(tokens.bgErrorPrimary, DesignSystemPalette.red950);
      expect(tokens.bgWarningPrimary, DesignSystemPalette.yellow950);
      expect(tokens.bgSuccessPrimary, DesignSystemPalette.green950);

      // Text — mirror --color-text-* from the CSS.
      expect(tokens.textPrimary, DesignSystemPalette.gray50);
      expect(tokens.textSecondary, DesignSystemPalette.gray300);
      expect(tokens.textSecondaryHover, DesignSystemPalette.gray200);
      expect(tokens.textTertiary, DesignSystemPalette.gray400);
      expect(tokens.textPlaceholder, DesignSystemPalette.gray500);
      expect(tokens.textErrorPrimary, DesignSystemPalette.red400);
      expect(tokens.textErrorPrimaryHover, DesignSystemPalette.red300);

      // Borders — mirror --color-border-* from the CSS.
      expect(tokens.borderPrimary, DesignSystemPalette.gray700);
      expect(tokens.borderSecondary, DesignSystemPalette.gray800);
      expect(tokens.borderBrand, DesignSystemPalette.brand400);
      expect(tokens.borderError, DesignSystemPalette.red400);

      // Foreground — mirror --color-fg-* from the CSS.
      expect(tokens.fgPrimary, DesignSystemPalette.white);
      expect(tokens.fgSecondary, DesignSystemPalette.gray300);
      expect(tokens.fgTertiary, DesignSystemPalette.gray400);
      expect(tokens.fgQuaternary, DesignSystemPalette.gray600);
      expect(tokens.fgBrandPrimary, DesignSystemPalette.brand500);
    });

    test('lerp at t=0 returns the source theme', () {
      final light = DesignSystemTokens.light();
      final dark = DesignSystemTokens.dark();
      final result = light.lerp(dark, 0);
      expect(result.bgPrimary, light.bgPrimary);
      expect(result.textPrimary, light.textPrimary);
    });

    test('lerp at t=1 returns the target theme', () {
      final light = DesignSystemTokens.light();
      final dark = DesignSystemTokens.dark();
      final result = light.lerp(dark, 1);
      expect(result.bgPrimary, dark.bgPrimary);
      expect(result.textPrimary, dark.textPrimary);
    });

    test('copyWith only replaces specified fields', () {
      final tokens = DesignSystemTokens.light().copyWith(
        bgPrimary: const Color(0xFF123456),
      );
      expect(tokens.bgPrimary, const Color(0xFF123456));
      expect(tokens.textPrimary, DesignSystemPalette.gray900);
    });

    testWidgets('context.designSystem returns tokens from the CcTheme ancestor', (
      tester,
    ) async {
      final tokens = DesignSystemTokens.dark();
      late DesignSystemTokens? found;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(tokens: tokens, brightness: CcBrightness.dark),
            child: Builder(
              builder: (context) {
                found = context.designSystem;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(found, same(tokens));
    });
  });
}
