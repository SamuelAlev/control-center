import 'package:control_center/core/theme/design_system_dark_theme.dart';
import 'package:control_center/core/theme/design_system_light_theme.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  group('designSystemLight', () {
    test('maps design system semantic tokens onto FColors', () {
      final colors = designSystemLight().colors;
      expect(colors.brightness, Brightness.light);
      // Page canvas is near-white (gray-50 #fcfbf9), not pure white.
      expect(colors.background, DesignSystemPalette.gray50);
      expect(colors.foreground, DesignSystemPalette.gray900);
      // Primary affordance is ink black (not orange) — warms on hover.
      expect(colors.primary, DesignSystemPalette.gray900);
      expect(colors.primaryForeground, DesignSystemPalette.white);
      // Secondary surface is the warm neutral (gray-100 #f2f0e9).
      expect(colors.secondary, DesignSystemPalette.gray100);
      expect(colors.muted, DesignSystemPalette.gray100);
      expect(colors.mutedForeground, DesignSystemPalette.gray600);
      // border-secondary (gray-200) — applied to FCard/FDivider globally.
      expect(colors.border, DesignSystemPalette.gray200);
      expect(colors.card, DesignSystemPalette.white);
      expect(colors.destructive, DesignSystemPalette.red600);
    });

    test('is usable inside FTheme', (
    ) async {
      // Smoke test: constructing FTheme with the theme should not throw.
      final widget = FTheme(
        data: designSystemLight(),
        child: const SizedBox(),
      );
      expect(widget, isNotNull);
    });

    test('threads the selected font family into the forui typography', () {
      // Regression: forui surfaces (field hints, select placeholders/items,
      // sidebar labels) read FThemeData.typography, which previously ignored
      // the user font. A non-Google family keeps the test binding-free.
      final typography = designSystemLight(fontFamily: 'Arial').typography;
      expect(typography.fontFamily, 'Arial');
      expect(typography.sm.fontFamily, 'Arial');
      expect(typography.xs.fontFamily, 'Arial');
      expect(typography.lg.fontFamily, 'Arial');
    });
  });

  group('designSystemDark', () {
    test('maps the dark CSS variables to FColors', () {
      final colors = designSystemDark().colors;
      expect(colors.brightness, Brightness.dark);
      expect(colors.background, DesignSystemPalette.gray950);
      expect(colors.foreground, DesignSystemPalette.gray50);
      // Inverted primary in dark: warm off-white fill (mirror of light's black).
      expect(colors.primary, DesignSystemPalette.gray50);
      expect(colors.secondary, DesignSystemPalette.gray900);
      expect(colors.muted, DesignSystemPalette.gray800);
      expect(colors.mutedForeground, DesignSystemPalette.gray400);
      // border-secondary (gray-800).
      expect(colors.border, DesignSystemPalette.gray800);
      // FCard sits on bg-primary (gray-950), not the lifted bg-secondary.
      expect(colors.card, DesignSystemPalette.gray950);
      expect(colors.error, DesignSystemPalette.red400);
    });

    test('threads the selected font family into the forui typography', () {
      final typography = designSystemDark(fontFamily: 'Arial').typography;
      expect(typography.fontFamily, 'Arial');
      expect(typography.sm.fontFamily, 'Arial');
      expect(typography.xs.fontFamily, 'Arial');
      expect(typography.lg.fontFamily, 'Arial');
    });
  });

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

    testWidgets('context.designSystem returns the registered extension', (
      tester,
    ) async {
      final tokens = DesignSystemTokens.dark();
      late DesignSystemTokens? found;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light().copyWith(extensions: [tokens]),
          home: Builder(
            builder: (context) {
              found = context.designSystem;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(found, same(tokens));
    });
  });
}
