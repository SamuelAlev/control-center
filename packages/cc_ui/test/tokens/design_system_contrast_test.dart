import 'dart:math' as math;
import 'dart:ui';

import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the WCAG contrast floor for every load-bearing token pairing in both
/// themes. DESIGN.md sets AAA (7:1) as the target for body/essential text and
/// AA (4.5:1) as the hard floor; non-text graphical objects (dots, rings,
/// borders, icon glyphs, indicator bars) need 3:1.
///
/// This is the regression guard for the accessibility pass that darkened the
/// functional accent to the brand's burnt orange (`brand850` #B0390C) and moved
/// the dark-theme `bgBrandPrimary` off the solid flame. If a future token edit
/// drops a real pairing below its floor, this test fails with the exact ratio.
void main() {
  // Flatten a (possibly translucent) foreground over an OPAQUE background.
  Color flatten(Color fg, Color bg) {
    final a = fg.a;
    return Color.from(
      alpha: 1,
      red: fg.r * a + bg.r * (1 - a),
      green: fg.g * a + bg.g * (1 - a),
      blue: fg.b * a + bg.b * (1 - a),
    );
  }

  // WCAG 2.1 contrast ratio. `bg` must be opaque; `fg` is composited over it.
  double contrast(Color fg, Color bg) {
    final f = flatten(fg, bg);
    final l1 = f.computeLuminance();
    final l2 = bg.computeLuminance();
    final hi = math.max(l1, l2);
    final lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }

  const bodyFloor = 4.5; // small text
  const nonTextFloor = 3.0; // dots, rings, borders, icon glyphs, bars

  // Each theme is checked against the same pairing set. `soft(x, base)` flattens
  // an alpha tint token over the surface it visually sits on.
  void checkTheme(String name, DesignSystemTokens t) {
    Color soft(Color tint, Color base) => flatten(tint, base);

    final pairings = <(String, Color, Color, double)>[
      // Neutral text on the surface ladder.
      ('muted on canvas', t.muted, t.canvas, bodyFloor),
      ('muted on surface', t.muted, t.surface, bodyFloor),
      ('muted on panel', t.muted, t.panel, bodyFloor),
      ('textQuaternary on canvas', t.textQuaternary, t.canvas, bodyFloor),
      (
        'placeholder on field (surface)',
        t.textPlaceholder,
        t.surface,
        bodyFloor,
      ),
      // Brand-colored text on light/dark surfaces.
      ('accent text on canvas', t.accent, t.canvas, bodyFloor),
      ('accent text on panel', t.accent, t.panel, bodyFloor),
      ('textBrandTertiary on canvas', t.textBrandTertiary, t.canvas, bodyFloor),
      (
        'textBrandSecondary on canvas',
        t.textBrandSecondary,
        t.canvas,
        bodyFloor,
      ),
      // Brand-colored text on its own soft tint (chips, badges, selected rows).
      (
        'accent text on accentSoft/canvas',
        t.accent,
        soft(t.accentSoft, t.canvas),
        bodyFloor,
      ),
      (
        'accent text on accentSoft/panel',
        t.accent,
        soft(t.accentSoft, t.panel),
        bodyFloor,
      ),
      // White on solid brand fills (accent button, primary-button warm-up).
      ('white on bgBrandSolid', t.textWhite, t.bgBrandSolid, bodyFloor),
      (
        'white on bgBrandSolidHover',
        t.textWhite,
        t.bgBrandSolidHover,
        bodyFloor,
      ),
      (
        'textSecondaryOnBrand on bgBrandSolid',
        t.textSecondaryOnBrand,
        t.bgBrandSolid,
        bodyFloor,
      ),
      // The selected-state stack that rides bgBrandPrimary (feature surfaces).
      (
        'textPrimary on bgBrandPrimary',
        t.textPrimary,
        t.bgBrandPrimary,
        bodyFloor,
      ),
      (
        'textTertiary on bgBrandPrimary',
        t.textTertiary,
        t.bgBrandPrimary,
        bodyFloor,
      ),
      (
        'textQuaternary on bgBrandPrimary',
        t.textQuaternary,
        t.bgBrandPrimary,
        bodyFloor,
      ),
      // Status text on its own soft pill.
      (
        'successText on successSoft',
        t.textSuccessPrimary,
        soft(t.successSoft, t.canvas),
        bodyFloor,
      ),
      (
        'warnText on warnSoft',
        t.textWarningPrimary,
        soft(t.warnSoft, t.canvas),
        bodyFloor,
      ),
      (
        'dangerText on dangerSoft',
        t.textErrorPrimary,
        soft(t.dangerSoft, t.canvas),
        bodyFloor,
      ),
      // White on solid status fills (destructive button, solid banners).
      ('white on bgErrorSolid', t.textWhite, t.bgErrorSolid, bodyFloor),
      ('white on bgSuccessSolid', t.textWhite, t.bgSuccessSolid, bodyFloor),
      // Tooltip.
      ('white on bgOverlay (tooltip)', t.textWhite, t.bgOverlay, bodyFloor),
      // Non-text graphical objects (3:1 floor).
      ('accent dot/ring on panel', t.accent, t.panel, nonTextFloor),
      ('warn dot on canvas', t.warn, t.canvas, nonTextFloor),
      ('success dot on canvas', t.success, t.canvas, nonTextFloor),
      (
        'fgBrandPrimary icon on bgBrandPrimary',
        t.fgBrandPrimary,
        t.bgBrandPrimary,
        nonTextFloor,
      ),
    ];

    final failures = <String>[];
    for (final (label, fg, bg, floor) in pairings) {
      final ratio = contrast(fg, bg);
      if (ratio < floor) {
        failures.add(
          '  [$name] $label: ${ratio.toStringAsFixed(2)}:1 '
          '(needs ${floor.toStringAsFixed(1)}:1)',
        );
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'WCAG contrast failures in $name theme:\n${failures.join('\n')}',
    );
  }

  test('light theme token pairings clear the WCAG contrast floor', () {
    checkTheme('light', DesignSystemTokens.light());
  });

  test('dark theme token pairings clear the WCAG contrast floor', () {
    checkTheme('dark', DesignSystemTokens.dark());
  });
}
