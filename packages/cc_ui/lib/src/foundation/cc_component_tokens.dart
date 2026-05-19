import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// Resolved color set for a [CcButton] variant, derived from
/// [DesignSystemTokens]. Reifies the DESIGN.md `button-*` specs.
@immutable
class CcButtonTokens {
  /// Creates a [CcButtonTokens].
  const CcButtonTokens({
    required this.bg,
    required this.bgHover,
    required this.bgPressed,
    required this.fg,
    required this.border,
    required this.borderHover,
  });

  /// Primary — ink-black at rest, warming to orange on hover (DESIGN.md).
  ///
  /// `fg` is ink-black in light mode, but it doubles as the primary-text token
  /// and flips to near-white in dark mode — so using it as the button fill would
  /// render the CTA white-on-white. In dark mode the primary uses a brand-tinted
  /// dark ink instead: still calm and dark at rest, but its warm tint separates
  /// it from the neutral `secondary` surface (so the primary action stays the
  /// clear CTA) and previews the orange hover.
  factory CcButtonTokens.primary(DesignSystemTokens t) {
    final dark = t.fg.computeLuminance() > 0.5;
    return CcButtonTokens(
      bg: dark ? Color.lerp(t.surface, t.accent, 0.2)! : t.fg,
      // The orange warm-up uses the accessible solid brand fill (not the raw
      // `accent`, which in dark mode stays bright for text-on-dark and can't
      // carry white — white on it is 3.0:1). `bgBrandSolid` clears 4.5:1 with
      // white in both themes.
      bgHover: t.bgBrandSolid,
      bgPressed: t.bgBrandSolidHover,
      fg: t.accentOn,
      border: _transparent,
      borderHover: _transparent,
    );
  }

  /// Accent — solid orange. Fills with the accessible `bgBrandSolid` (white on
  /// it clears 4.5:1 in both themes) rather than the raw `accent` signal.
  factory CcButtonTokens.accent(DesignSystemTokens t) => CcButtonTokens(
    bg: t.bgBrandSolid,
    bgHover: t.bgBrandSolidHover,
    bgPressed: t.bgBrandSolidHover,
    fg: t.accentOn,
    border: _transparent,
    borderHover: _transparent,
  );

  /// Secondary — bordered surface, border strengthens on hover.
  factory CcButtonTokens.secondary(DesignSystemTokens t) => CcButtonTokens(
    bg: t.surface,
    // Pre-blend semi-transparent washes against the opaque bg so
    // AnimatedContainer lerps only RGB (two opaque endpoints), avoiding a
    // dark alpha-bump peak at t≈0.5.
    bgHover: Color.alphaBlend(t.hover, t.surface),
    bgPressed: Color.alphaBlend(t.hoverStrong, t.surface),
    fg: t.textPrimary,
    border: t.borderPrimary,
    borderHover: Color.alphaBlend(t.lineStrong, t.surface),
  );

  /// Line — panel fill, border darkens to ink on hover.
  factory CcButtonTokens.line(DesignSystemTokens t) => CcButtonTokens(
    bg: t.panel,
    bgHover: Color.alphaBlend(t.hover, t.panel),
    bgPressed: Color.alphaBlend(t.hoverStrong, t.panel),
    fg: t.textPrimary,
    border: t.borderPrimary,
    borderHover: t.fg,
  );

  /// Ghost — transparent, only a hover wash.
  factory CcButtonTokens.ghost(DesignSystemTokens t) => CcButtonTokens(
    // Alpha-0 hover (not transparent-black) so AnimatedContainer lerps only
    // alpha on hover↔idle, avoiding a dark-gray flash.
    bg: t.hover.withValues(alpha: 0),
    bgHover: t.hover,
    bgPressed: t.hoverStrong,
    fg: t.textPrimary,
    border: _transparent,
    borderHover: _transparent,
  );

  /// Destructive — solid red for delete/remove actions.
  factory CcButtonTokens.destructive(DesignSystemTokens t) => CcButtonTokens(
    bg: t.bgErrorSolid,
    bgHover: t.bgErrorSolidHover,
    bgPressed: t.bgErrorSolidHover,
    fg: t.textWhite,
    border: _transparent,
    borderHover: _transparent,
  );

  /// Resting background.
  final Color bg;

  /// Hover background.
  final Color bgHover;

  /// Pressed background.
  final Color bgPressed;

  /// Foreground (text + icon).
  final Color fg;

  /// Resting border.
  final Color border;

  /// Hover border.
  final Color borderHover;
}

/// Resolved color set for [CcTextField] / [CcTextArea] and the select /
/// autocomplete trigger boxes.
///
/// Field anatomy: a quiet [bg] fill (one step off the surrounding surface)
/// closed by a single 1px [border] underline along the bottom edge; no side
/// or top chrome at rest. Focus/error/warn draw a 2px outline around the
/// whole box (via `foregroundDecoration`, so layout never shifts).
@immutable
class CcInputTokens {
  /// Creates a [CcInputTokens].
  const CcInputTokens({
    required this.bg,
    required this.border,
    required this.borderFocused,
    required this.text,
    required this.placeholder,
    required this.cursor,
    required this.selection,
    required this.borderError,
    required this.bgError,
  });

  /// Resolves input colors from [t].
  factory CcInputTokens.resolve(DesignSystemTokens t) => CcInputTokens(
    bg: t.surface,
    // The bottom underline — a warm mid gray strong enough to read as
    // "this is a field" (hairline tokens are too faint here).
    border: t.textPlaceholder,
    borderFocused: t.accent,
    text: t.textPrimary,
    placeholder: t.textPlaceholder,
    cursor: t.accent,
    selection: t.accentSoft,
    borderError: t.danger,
    bgError: t.dangerSoft,
  );

  /// Resting background (one step off the surrounding surface).
  final Color bg;

  /// The 1px bottom underline.
  final Color border;

  /// The 2px focus outline color (accent).
  final Color borderFocused;

  /// Text color.
  final Color text;

  /// Placeholder/hint color.
  final Color placeholder;

  /// Caret color.
  final Color cursor;

  /// Selection highlight color.
  final Color selection;

  /// Border in the error state.
  final Color borderError;

  /// Field tint in the error state.
  final Color bgError;
}

/// Resolved color set for [CcCard]-like surfaces.
@immutable
class CcCardTokens {
  /// Creates a [CcCardTokens].
  const CcCardTokens({
    required this.bg,
    required this.border,
    required this.hoverBg,
  });

  /// White panel surface (DESIGN.md `panel`).
  factory CcCardTokens.panel(DesignSystemTokens t) =>
      CcCardTokens(bg: t.panel, border: t.borderPrimary, hoverBg: t.hover);

  /// Tighter secondary surface (DESIGN.md `card`).
  factory CcCardTokens.surface(DesignSystemTokens t) =>
      CcCardTokens(bg: t.surface, border: t.borderPrimary, hoverBg: t.hover);

  /// Background fill.
  final Color bg;

  /// Hairline border.
  final Color border;

  /// Background when hovered (for interactive cards).
  final Color hoverBg;
}
